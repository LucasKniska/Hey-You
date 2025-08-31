"""
matchmaker.py
=============
Purpose
- Implements the 4 matching scenarios:
  (1) No neighbor within 0.5 miles for 3+ hours → switch to adjacent partition
  (2) If someone in partition is within 0.5 miles AND both are ready → match them
  (3) If user has "who do you want to meet" text, evaluate candidates in partition; store a watchlist
  (4) If user has who-want text but zero candidates in this partition → switch to adjacent partition

How it fits into HeyU
- Called on a schedule (e.g., every minute) to process each partition once.
- Leverages your existing locationMatching.py (via geo_adapter) for distance ranking.
- Writes Matches/{match_id} to record matched pairs and flags "special who_want" matches.

Firestore I/O
- Reads partition users: Buckets/{bucket}/{partition}/{user_id}
  Fields used: lat, lon, ready_to_match (0/1), active_match_id?, no_proximity_since_ts?
- Reads user profile text: Users/{user_id} (who_want_query, bio/profile_text, who_watchlist)
- Writes:
  - Matches/{auto_id}: {users, bucket, partition, created_at, status, reason, who_want_reason, special_who_want}
  - Updates partition users with: ready_to_match, active_match_id, matched_at, no_proximity_since_ts, last_close_contact_ts
  - Moves user to adjacent partition when required and recomputes centroid distances there

How to run in HeyU context
- From a worker/cron: call run_matching_cycle("Columbia_University")
- Or use the CLI in run_cycle.py
"""

from __future__ import annotations
from typing import List, Dict, Optional
from datetime import datetime, timedelta, timezone

from main import db

from ..locationMatching import neighbors_by_geo_distance, load_partition_users, build_tree
from ..partition_switch import (
    choose_adjacent_partition,
    move_user_to_partition,
    recompute_and_write_centroid_distances,
)
from ..who_want import evaluate_who_want, upsert_watchlist, has_watchlink

HALF_MILE_M = 804.672
NO_NEIGHBOR_TIMEOUT = timedelta(hours=3)
GRID_I, GRID_J = 4, 5  # partition indices

def _users_in_partition(bucket_id: str, partition: str) -> List[Dict]:
    coll = db.collection("Buckets").document(bucket_id).collection(partition)
    users = []
    for snap in coll.stream():
        if snap.id == "centroid":
            continue
        d = snap.to_dict() or {}
        lat, lon = d.get("lat"), d.get("lon")
        if not isinstance(lat, (int, float)) or not isinstance(lon, (int, float)):
            continue
        users.append({
            "user_id": snap.id,
            "lat": float(lat),
            "lon": float(lon),
            "ready_to_match": bool(d.get("ready_to_match", 0)),
            "active_match_id": d.get("active_match_id"),
            "no_proximity_since_ts": d.get("no_proximity_since_ts"),
        })
    return users

def _get_user_text_profile(user_id: str) -> Dict:
    s = db.collection("Users").document(user_id).get()
    d = s.to_dict() or {}
    return {
        "who_want_query": (d.get("who_want_query") or "").strip(),
        "profile_text": d.get("profile_text", d.get("bio", "")) or "",
        "who_watchlist": d.get("who_watchlist") or [],
    }

def _set_partition_user(bucket_id: str, partition: str, user_id: str, **patch):
    db.collection("Buckets").document(bucket_id).collection(partition).document(user_id).set(patch, merge=True)

def _create_match(bucket_id: str, partition: str, user_a: str, user_b: str, reason: str, who_reason: str = "", special: bool = False):
    mref = db.collection("Matches").document()
    now = datetime.now(timezone.utc)
    mref.set({
        "users": [user_a, user_b],
        "bucket": bucket_id,
        "partition": partition,
        "created_at": now,
        "status": "matched",
        "reason": reason,
        "who_want_reason": who_reason,
        "special_who_want": special,
    })
    for uid in (user_a, user_b):
        _set_partition_user(bucket_id, partition, uid,
                            ready_to_match=False,
                            active_match_id=mref.id,
                            matched_at=now)

def process_partition_once(bucket_id: str, partition: str):
    """
    Process a single partition one time; safe to call repeatedly on a schedule.
    """
    users = _users_in_partition(bucket_id, partition)
    if not users:
        return

    # Preload text info once
    text_info = {u["user_id"]: _get_user_text_profile(u["user_id"]) for u in users}
    now = datetime.now(timezone.utc)

    for u in users:
        uid = u["user_id"]
        if u.get("active_match_id"):
            continue  # already matched; skip

        # (3) WHO-WANT: build/refresh watchlist
        q = text_info[uid]["who_want_query"]
        who_hits = []
        if q:
            for cand in users:
                if cand["user_id"] == uid:
                    continue
                cand_text = text_info[cand["user_id"]]["profile_text"]
                ok, reason, score = evaluate_who_want(q, cand_text)
                if ok:
                    who_hits.append({"user_id": cand["user_id"], "reason": reason, "score": score})
            upsert_watchlist(uid, who_hits)

        # Location-based neighbors via your adapter (calls your algorithm)
        # Use locationMatching's geo ranking for neighbors
        users_in_partition = load_partition_users(bucket_id, partition)
        index = {u["user_id"]: i for i, u in enumerate(users_in_partition)}
        if uid not in index:
            neighbors = []
        else:
            tree = neighbors_by_geo_distance(index[uid], users_in_partition, build_tree(users_in_partition))
            neighbors = tree
        within = [n for n in neighbors if n["distance_m"] <= HALF_MILE_M]

        # (2) If neighbor within 0.5 mi and both ready → match the closest ready one
        if within:
            partner_id = None
            for n in neighbors:  # ordered by distance already
                if n["distance_m"] > HALF_MILE_M:
                    break
                vid = n["user_id"]
                v_snap = db.collection("Buckets").document(bucket_id).collection(partition).document(vid).get()
                vd = v_snap.to_dict() or {}
                if bool(u["ready_to_match"]) and bool(vd.get("ready_to_match", 0)) and not vd.get("active_match_id"):
                    partner_id = vid
                    break

            if partner_id:
                # flag special if either side had the other in watchlist
                u_watch = text_info[uid]["who_watchlist"]
                v_watch = text_info[partner_id]["who_watchlist"]
                reason = has_watchlink(u_watch, partner_id) or has_watchlink(v_watch, uid) or ""
                _create_match(bucket_id, partition, uid, partner_id, reason="proximity",
                              who_reason=reason, special=bool(reason))
                _set_partition_user(bucket_id, partition, uid, no_proximity_since_ts=None, last_close_contact_ts=now)
                _set_partition_user(bucket_id, partition, partner_id, no_proximity_since_ts=None, last_close_contact_ts=now)
                continue  # done with uid in this pass
            else:
                # neighbors exist but readiness misaligned → clear no_proximity clock so we don't switch prematurely
                _set_partition_user(bucket_id, partition, uid, no_proximity_since_ts=None, last_close_contact_ts=now)
        else:
            # (1) No neighbor within radius → start/advance the "no proximity" timer
            ts = u.get("no_proximity_since_ts")
            if ts is None:
                _set_partition_user(bucket_id, partition, uid, no_proximity_since_ts=now)
            else:
                if now - ts >= NO_NEIGHBOR_TIMEOUT:
                    new_p = choose_adjacent_partition(partition)
                    from ..partition_switch import move_user_to_partition, recompute_and_write_centroid_distances
                    move_user_to_partition(bucket_id, partition, new_p, uid)
                    recompute_and_write_centroid_distances(bucket_id, new_p, uid)
                    _set_partition_user(bucket_id, new_p, uid, no_proximity_since_ts=None)
                    continue

        # (4) who-want exists but no hits in this partition → switch once
        if q and not who_hits:
            new_p = choose_adjacent_partition(partition)
            move_user_to_partition(bucket_id, partition, new_p, uid)
            recompute_and_write_centroid_distances(bucket_id, new_p, uid)
            _set_partition_user(bucket_id, new_p, uid, no_proximity_since_ts=None)
            continue

def run_matching_cycle(bucket_id: str, partitions: Optional[List[str]] = None):
    """
    Run one full cycle across partitions. Call this on a schedule.
    """
    if partitions is None:
        partitions = [f"partition{i}{j}" for i in range(1, GRID_I+1) for j in range(1, GRID_J+1)]
    for p in partitions:
        try:
            process_partition_once(bucket_id, p)
        except Exception as e:
            print(f"[WARN] {bucket_id}/{p}: {e}")
