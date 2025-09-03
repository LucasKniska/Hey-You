# matchingSuite/entrypoint.py
from __future__ import annotations
from typing import Dict, Any, List, Optional, Tuple
from datetime import datetime, timezone
import math

from google.cloud import firestore
import os, sys

# Ensure we can import main.py (Firestore client) and the k-means runner
THIS_DIR = os.path.dirname(__file__)
PARENT_DIR = os.path.abspath(os.path.join(THIS_DIR, os.pardir))
if PARENT_DIR not in sys.path:
    sys.path.insert(0, PARENT_DIR)


from auth import db
from matchingSuite.partition_switch import (
    parse_partition, format_partition, GRID_I, GRID_J,
    recompute_and_write_centroid_distances,
)
from matchingSuite.readyWorker import _txn_try_pair

# ─────────────────────────────────────────────────────────────
# Config
# ─────────────────────────────────────────────────────────────
# Point this at "TestingUsers" for your test runs; switch to "Users" in prod.
USER_COLLECTION = "Users"

HALF_MILE_M    = 804.672
ONE_MILE_M     = 1609.344
EARTH_RADIUS_M = 6_371_009

# ─────────────────────────────────────────────────────────────
# Firestore helpers
# ─────────────────────────────────────────────────────────────
def _users_doc(uid: str):
    return db.collection(USER_COLLECTION).document(uid)

def _bucket_partition_doc(bucket: str, partition: str):
    return db.collection("Buckets").document(bucket).collection(partition)

def _partition_user_doc(bucket: str, partition: str, uid: str):
    return _bucket_partition_doc(bucket, partition).document(uid)

def _read_user_core(uid: str) -> Dict[str, Any]:
    """Users/{uid} must contain: bucket_id, partition."""
    u = (_users_doc(uid).get().to_dict() or {})
    bucket = u.get("bucket_id")
    partition = u.get("partition")
    if not bucket or not partition:
        raise ValueError(f"Users/{uid} missing bucket_id or partition")
    return {"bucket_id": bucket, "partition": partition}

def _ensure_aware(dt: datetime) -> datetime:
    if isinstance(dt, datetime):
        return dt if dt.tzinfo is not None else dt.replace(tzinfo=timezone.utc)
    return datetime.now(timezone.utc)

def _set_ready(bucket: str, partition: str, uid: str) -> datetime:
    """Mark caller ready and preserve first-ready time for expansion schedule."""
    now = datetime.now(timezone.utc)
    ref = _partition_user_doc(bucket, partition, uid)
    d = ref.get().to_dict() or {}
    ready_started_at = _ensure_aware(d.get("ready_started_at") or now)
    ref.set({
        "ready_to_match": True,
        "ready_started_at": ready_started_at,
        "match_state": "ready",
        "ready_job_id": None
    }, merge=True)
    return ready_started_at

# ─────────────────────────────────────────────────────────────
# Geometry
# ─────────────────────────────────────────────────────────────
def _haversine_m(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    rlat1, rlon1, rlat2, rlon2 = map(math.radians, [lat1, lon1, lat2, lon2])
    dlat = rlat2 - rlat1
    dlon = rlon2 - rlon1
    a = math.sin(dlat/2)**2 + math.cos(rlat1)*math.cos(rlat2)*math.sin(dlon/2)**2
    return 2 * EARTH_RADIUS_M * math.asin(math.sqrt(a))

# ─────────────────────────────────────────────────────────────
# Expansion schedule
# ─────────────────────────────────────────────────────────────
def _allowed_partition_count(elapsed_min: float) -> int:
    # 0–20m:1, 20–40m:2, 40–80m:4, 80m+:5 (cap)
    if elapsed_min < 20:  return 1
    if elapsed_min < 40:  return 2
    if elapsed_min < 80:  return 4
    return 5

def _neighbors_in_manhattan_order(i: int, j: int) -> List[Tuple[int,int]]:
    coords: List[Tuple[int,int]] = []
    for di in range(-(GRID_I-1), GRID_I):
        for dj in range(-(GRID_J-1), GRID_J):
            ni, nj = i + di, j + dj
            if 1 <= ni <= GRID_I and 1 <= nj <= GRID_J:
                coords.append((ni, nj))
    coords.sort(key=lambda xy: (abs(xy[0]-i) + abs(xy[1]-j), abs(xy[0]-i), abs(xy[1]-j)))
    return coords

def _expansion_partitions(current_partition: str, count: int) -> List[str]:
    i, j = parse_partition(current_partition)
    coords = _neighbors_in_manhattan_order(i, j)
    out: List[str] = []
    for (ni, nj) in coords:
        p = format_partition(ni, nj)
        if p not in out:
            out.append(p)
        if len(out) >= count:
            break
    return out

# ─────────────────────────────────────────────────────────────
# Atomic move within transaction
# ─────────────────────────────────────────────────────────────
def _move_user_in_tx(tx, bucket: str, from_p: str, to_p: str, uid: str) -> None:
    if from_p == to_p:
        return
    src = _partition_user_doc(bucket, from_p, uid)
    dst = _partition_user_doc(bucket, to_p, uid)
    data = src.get(transaction=tx).to_dict() or {}
    tx.set(dst, data, merge=True)
    tx.delete(src)

# @firestore.transactional
# def _txn_pair_move(tx, *, bucket: str, from_p: str, to_p: str, caller: str, partner: str) -> Optional[str]:
#     if to_p != from_p:
#         _move_user_in_tx(tx, bucket, from_p, to_p, caller)
#     # pair inside target partition
#     return _txn_try_pair(tx, bucket, to_p, caller, partner)

# ─────────────────────────────────────────────────────────────
# Ready candidates + distance (pre-filtered query)
# ─────────────────────────────────────────────────────────────
def _ready_candidates_by_distance(
    *,
    bucket: str,
    partition: str,
    caller_id: str,
    caller_lat: float,
    caller_lon: float,
) -> List[Dict[str, Any]]:
    """
    Streams only docs where ready_to_match==True and active_match_id is None,
    computes distance for those, orders by:
      - priority users (<=1 mile) first, by distance
      - then regular users (<=0.5 mile), by distance
    Returns [{user_id, distance_m}]
    """
    col = _bucket_partition_doc(bucket, partition)

    # Pre-filter on server side
    q = col.where("discoverable", "==", True)

    rows_regular:  List[Dict[str, Any]] = []

    for s in q.stream():
        if s.id in ("centroid", caller_id):
            continue
        d = s.to_dict() or {}
        pos = d.get('location')
        lat, lon = pos.get("lat"), pos.get("long")
        if not isinstance(lat, (int, float)) or not isinstance(lon, (int, float)):
            continue

        dist = _haversine_m(caller_lat, caller_lon, float(lat), float(lon))
        if dist <= HALF_MILE_M:
            rows_regular.append({"user_id": s.id, "distance_m": dist})

    rows_regular.sort(key=lambda r: r["distance_m"])
    return rows_regular

# ─────────────────────────────────────────────────────────────
# Main entrypoint
# ─────────────────────────────────────────────────────────────
def try_match_for_user(*, user_id: str) -> Dict[str, Optional[str]]:
    """
    API-facing, single-user matching call.
    Input: user_id
    Output: { "user_id": <id>, "matched_user_id": <id|None> }
    """
    # 1) locate user & current partition
    core = _read_user_core(user_id)
    bucket = core["bucket_id"]         # Buckets/{bucket_id} == university
    partition = core["partition"]      # e.g., 'partition11'

    # 2) mark ready and compute expansion scope from first-ready time
    ready_started_at = _set_ready(bucket, partition, user_id)
    elapsed_min = (datetime.now(timezone.utc) - _ensure_aware(ready_started_at)).total_seconds() / 60.0
    search_partitions = _expansion_partitions(partition, _allowed_partition_count(elapsed_min))

    # 3) caller coords from its partition doc
    caller_doc = _partition_user_doc(bucket, partition, user_id).get().to_dict() or {}
    caller_pos = caller_doc.get("location")
    caller_lat = caller_pos.get('lat')
    caller_lon = caller_pos.get('long')
    if not isinstance(caller_lat, (int, float)) or not isinstance(caller_lon, (int, float)):
        raise ValueError(f"Caller {user_id} missing lat/lon")

    # 5) iterate partitions; only compute distances for ready users
    for p in search_partitions:
        candidates = _ready_candidates_by_distance(
            bucket=bucket,
            partition=p,
            caller_id=user_id,
            caller_lat=float(caller_lat),
            caller_lon=float(caller_lon),
        )
        if not candidates:
            continue

        # 6) pair with the first viable candidate (atomic). If across partitions, move+pair in one tx.
        for row in candidates:
            partner_id = row["user_id"]
            # mid = _txn_pair_move(
            #     db.transaction(),
            #     bucket=bucket, from_p=partition, to_p=p,
            #     caller=user_id, partner=partner_id
            # )
            return partner_id
    # 7) no match
    return None