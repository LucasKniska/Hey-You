# TestingFolder/RunFiveReadyPerspectives.py
"""
RunFiveReadyPerspectives.py
===========================

Runs 5 *separate* trials. In each trial:
  - Randomly pick one tuser_### (1..100)
  - Find which partition they are in
  - Set their ready_to_match=True (no job queue, no writes to Matches)
  - From THEIR perspective only, find the nearest neighbor within 0.5 miles
    in the same partition and print the result. We also show whether the
    neighbor is ready, but we do NOT require joint readiness and we do NOT
    create a match record.

Run (from 'Python Backend'):
  python TestingFolder/RunFiveReadyPerspectives.py --bucket Stanford_University --trials 5 --seed 42
"""

from __future__ import annotations
import sys, os, argparse, random
from typing import Optional, Tuple, Dict, Any

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if PROJECT_ROOT not in sys.path:
    sys.path.append(PROJECT_ROOT)

from main import db
from matchingSuite.locationMatching import rank_one_user

HALF_MILE_M = 804.672

def _find_user_partition(bucket: str, user_id: str) -> Optional[str]:
    """Return the partition name that contains user_id, or None."""
    bref = db.collection("Buckets").document(bucket)
    for coll in bref.collections():
        pid = coll.id
        if not pid.startswith("partition"):
            continue
        snap = coll.document(user_id).get()
        if snap.exists:
            return pid
    return None

def _set_ready(bucket: str, partition: str, user_id: str, ready: bool = True) -> None:
    db.collection("Buckets").document(bucket).collection(partition).document(user_id).set(
        {
            "ready_to_match": bool(ready),
            # ensure test is clean; we don't write Matches in this runner
            "active_match_id": None,
            "matched_at": None,
        },
        merge=True,
    )

def _nearest_from_perspective(bucket: str, partition: str, user_id: str) -> Optional[Dict[str, Any]]:
    """Return nearest neighbor within 0.5 mi: {user_id, distance_m, neighbor_ready}, else None."""
    try:
        neighbors = rank_one_user(bucket, partition, user_id, topk=None)
    except Exception as e:
        print(f"  [WARN] neighbor lookup failed for {partition}/{user_id}: {e}")
        return None

    for n in neighbors:  # already sorted by distance
        if n["distance_m"] <= HALF_MILE_M:
            # annotate neighbor readiness for display
            d = (db.collection("Buckets").document(bucket)
                        .collection(partition).document(n["user_id"]).get().to_dict() or {})
            return {
                "user_id": n["user_id"],
                "distance_m": float(n["distance_m"]),
                "neighbor_ready": bool(d.get("ready_to_match", False)),
            }
        else:
            break
    return None

def _format_user(n: int) -> str:
    return f"tuser_{n:03d}"

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--bucket", required=True, help="Bucket doc id under Buckets/")
    ap.add_argument("--trials", type=int, default=5, help="How many distinct single-user trials to run")
    ap.add_argument("--seed", type=int, default=42, help="RNG seed for reproducibility")
    args = ap.parse_args()

    rng = random.Random(args.seed)

    print(f"▶ Running {args.trials} single-user perspective trials in {args.bucket}\n")

    used_ids = set()
    attempts = 0
    done = 0

    while done < args.trials and attempts < 1000:
        attempts += 1
        # pick a new random tuser_###
        n = rng.randint(1, 100)
        uid = _format_user(n)
        if uid in used_ids:
            continue

        part = _find_user_partition(args.bucket, uid)
        if not part:
            # user might not be present in bucket partitions; try another
            continue

        used_ids.add(uid)
        done += 1

        # Ensure this user's ready flag is True for the test (we don't require partner readiness)
        _set_ready(args.bucket, part, uid, ready=True)

        # Perspective-only nearest neighbor within 0.5 mi
        best = _nearest_from_perspective(args.bucket, part, uid)

        # Pretty print this trial's result
        print(f"[Trial {done}] {part}/{uid}")
        if best:
            rflag = "READY" if best["neighbor_ready"] else "not-ready"
            print(f"  → nearest: {best['user_id']}  distance={best['distance_m']:.1f} m  ({rflag})")
        else:
            print("  → no neighbor within 0.5 mi in this partition")
        print()

    if done < args.trials:
        print(f"(Note) Only {done} unique users found across partitions.")

if __name__ == "__main__":
    main()
