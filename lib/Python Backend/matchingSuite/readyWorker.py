from __future__ import annotations
from datetime import datetime, timezone, timedelta
from typing import Optional, Dict, Any

from auth import db
from matchingSuite.locationMatching import rank_one_user as neighbors_rank_one
from matchingSuite.partition_switch import (
    choose_adjacent_partition,
    recompute_and_write_centroid_distances,  # still used post-commit if you prefer
)

HALF_MILE_M = 804.672
JOBS = "MatchJobs"
MATCHES = "Matches"
LEASE = timedelta(minutes=5)

def _job_doc(job_id: str):
    return db.collection(JOBS).document(job_id)

def _partition_doc(bucket: str, partition: str, uid: str):
    return db.collection("Buckets").document(bucket).collection(partition).document(uid)

def _match_id(a: str, b: str) -> str:
    """Deterministic id to act as a lock across workers."""
    x, y = sorted([a, b])
    return f"match_{x}_{y}"

def _nearest_viable_neighbor(bucket: str, partition: str, uid: str) -> Optional[Dict[str, Any]]:
    """Read-only neighbor pick (distance-filtered); do NOT trust until rechecked in txn."""
    try:
        neighbors = neighbors_rank_one(bucket, partition, uid, topk=None)
    except Exception:
        return None
    col = db.collection("Buckets").document(bucket).collection(partition)
    for n in neighbors:
        if n["distance_m"] > HALF_MILE_M:
            break
        cand = col.document(n["user_id"]).get().to_dict() or {}
        if cand.get("ready_to_match") and not cand.get("active_match_id"):
            return {"user_id": n["user_id"], "distance_m": n["distance_m"]}
    return None

def _txn_try_pair(tx, bucket: str, partition: str, a_id: str, b_id: str) -> Optional[str]:
    """
    Inside a Firestore transaction:
      - Re-read both users.
      - Ensure both are ready and free.
      - Create deterministic Matches/{id} (acts as a lock).
      - Update both users to matched.
    Returns match_id or None.
    """
    ucol = db.collection("Buckets").document(bucket).collection(partition)
    a_ref = ucol.document(a_id)
    b_ref = ucol.document(b_id)

    a = a_ref.get(transaction=tx).to_dict() or {}
    b = b_ref.get(transaction=tx).to_dict() or {}

    if not a.get("ready_to_match") or a.get("active_match_id"):
        return None
    if not b.get("ready_to_match") or b.get("active_match_id"):
        return None

    mid = _match_id(a_id, b_id)
    mref = db.collection(MATCHES).document(mid)
    if mref.get(transaction=tx).exists:
        return None

    now = datetime.now(timezone.utc)
    tx.set(mref, {
        "users": [a_id, b_id],
        "bucket": bucket,
        "partition": partition,
        "created_at": now,
        "status": "matched",
        "reason": "proximity",
        "who_want_reason": "",
        "special_who_want": False,
    })
    tx.update(a_ref, {
        "ready_to_match": False,
        "active_match_id": mid,
        "matched_at": now,
        "match_state": "matched",
        "ready_job_id": None
    })
    tx.update(b_ref, {
        "ready_to_match": False,
        "active_match_id": mid,
        "matched_at": now,
        "match_state": "matched"
    })
    return mid

def _process_one_job(job_id: str) -> Optional[str]:
    """
    Returns match_id if matched, "" if processed with no match, or None if job was skipped.
    Idempotent via ready_job_id on the user doc + Firestore transaction.
    """
    jref = _job_doc(job_id)
    js = jref.get()
    if not js.exists:
        return None
    job = js.to_dict() or {}
    if job.get("state") not in ("queued", "processing"):
        return None

    now = datetime.now(timezone.utc)
    lease_until = job.get("lease_until")
    if job.get("state") == "queued" or (lease_until and lease_until < now):
        jref.set({
            "state": "processing",
            "lease_until": now + LEASE,
            "attempts": job.get("attempts", 0) + 1
        }, merge=True)

    bucket = job["bucket"]
    partition = job["partition"]
    uid = job["uid"]
    uref = _partition_doc(bucket, partition, uid)

    # Preselect a candidate by distance only (will be rechecked in txn)
    cand = _nearest_viable_neighbor(bucket, partition, uid)

    @db.transactional
    def _txn_proc(tx):
        usnap = uref.get(transaction=tx)
        user = usnap.to_dict() or {}

        # Idempotency checks on the caller
        if not user.get("ready_to_match"):
            tx.update(jref, {"state": "done", "note": "not_ready"})
            if user.get("ready_job_id") == job_id:
                tx.update(uref, {"ready_job_id": None, "match_state": "idle"})
            return None

        if user.get("active_match_id"):
            tx.update(jref, {"state": "done", "note": "already_matched"})
            if user.get("ready_job_id") == job_id:
                tx.update(uref, {"ready_job_id": None, "match_state": "matched"})
            return None

        if user.get("ready_job_id") != job_id:
            tx.update(jref, {"state": "done", "note": "stale_job"})
            return None

        # Try current partition (pair inside the same transaction)
        if cand:
            mid = _txn_try_pair(tx, bucket, partition, uid, cand["user_id"])
            if mid:
                tx.update(jref, {"state": "done", "match_id": mid})
                return mid

        # Try one adjacent; move + pair inside the SAME transaction
        new_p = choose_adjacent_partition(partition)
        # Read neighbor candidate from adjacent after we move our user doc in this txn
        # Move the user doc (copy -> delete)
        src = db.collection("Buckets").document(bucket).collection(partition).document(uid)
        dst = db.collection("Buckets").document(bucket).collection(new_p).document(uid)

        # Snapshot before move (so we don't lose any fields)
        src_data = src.get(transaction=tx).to_dict() or {}
        tx.set(dst, src_data, merge=True)
        tx.delete(src)

        # After moving, attempt to pick a candidate in the new partition based on current state
        # We still must re-check readiness in _txn_try_pair.
        # Note: _nearest_viable_neighbor is read-only outside tx; here we pick by scanning a few docs directly.
        # To keep it simple, we just fallback to pairing attempt if a viable candidate exists by ID.
        # If you want distance-order in-adjacent, do a pre-read outside tx then re-try here.

        # Minimal viable: no preselected candidate; just end as no_match but we've moved.
        tx.update(jref, {"state": "no_match", "checked_at": datetime.now(timezone.utc), "moved_to": new_p})
        return ""

    res = _txn_proc(db.transaction())

    # Optional: if we moved partitions (note is on the job doc), recompute centroid distances post-commit
    try:
        j = jref.get().to_dict() or {}
        moved_to = j.get("moved_to")
        if moved_to:
            recompute_and_write_centroid_distances(bucket, moved_to, uid)
    except Exception:
        pass

    return res

def drain_jobs(limit: int = 50) -> Dict[str, int]:
    """
    Pull up to 'limit' queued/processing jobs and process them.
    Returns counts: {"matched": x, "no_match": y, "done": z, "skipped": w}
    """
    counts = {"matched": 0, "no_match": 0, "done": 0, "skipped": 0}
    q = (db.collection(JOBS)
           .where("state", "in", ["queued", "processing"])
           .limit(limit))
    jobs = list(q.stream())
    for js in jobs:
        job_id = js.id
        res = _process_one_job(job_id)
        if res is None:
            counts["skipped"] += 1
        elif res == "":
            counts["no_match"] += 1
        else:
            counts["matched"] += 1
        counts["done"] += 1
    return counts
