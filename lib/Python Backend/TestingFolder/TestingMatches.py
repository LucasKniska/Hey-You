"""
RunFullMatchingCycle.py
=======================

Drives the full matching pipeline for a bucket:
  1) Runs one matching cycle (matchmaker.run_matching_cycle)
  2) Prints "MAtches" and lists pairs grouped by partition
  3) Writes a per-partition summary at:
       Buckets/{bucket}/{partition}/Matches
     and also a historical record at:
       Buckets/{bucket}/{partition}/Matches/runs/{run_id}

Run (from 'Python Backend'):
  python TestingFolder/RunFullMatchingCycle.py --bucket Stanford_University
  # or restrict partitions:
  python TestingFolder/RunFullMatchingCycle.py --bucket Stanford_University --partitions partition11 partition12
"""

from __future__ import annotations
import sys, os, uuid
from typing import Dict, List, Any
from datetime import datetime, timezone
import argparse

# --- make project root importable ---
PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if PROJECT_ROOT not in sys.path:
    sys.path.append(PROJECT_ROOT)

from main import db
from matchingSuite.NotNeeded.matchmaker import run_matching_cycle

def _parse_args():
    p = argparse.ArgumentParser()
    p.add_argument("--bucket", required=True, help="University doc id (Buckets/<id>)")
    p.add_argument("--partitions", nargs="*", help="Optional subset like: partition11 partition23")
    return p.parse_args()

def _query_new_matches(bucket_id: str, since_ts):
    """
    Fetch Matches for a bucket without requiring a composite index.
    We query by bucket only (single-field index) and filter by created_at in Python.
    """
    try:
        # Newer Firestore client (preferred): keyword 'filter' with FieldFilter
        from google.cloud.firestore_v1 import FieldFilter
        q = db.collection("Matches").where(filter=FieldFilter("bucket", "==", bucket_id))
    except Exception:
        # Fallback for older clients
        q = db.collection("Matches").where("bucket", "==", bucket_id)

    out = []
    for snap in q.stream():
        d = snap.to_dict() or {}
        created = d.get("created_at")
        # Keep only matches created during/after this run
        if created is None or created < since_ts:
            continue
        d["id"] = snap.id
        out.append(d)
    return out


def _write_partition_summaries(bucket_id: str, matches_by_part: Dict[str, List[Dict[str, Any]]], run_id: str, run_ts: datetime):
    bucket_ref = db.collection("Buckets").document(bucket_id)
    for part, rows in matches_by_part.items():
        # keep a rolling pointer
        bucket_ref.collection(part).document("Matches").set({
            "last_run_id": run_id,
            "last_run_ts": run_ts,
            "last_count": len(rows),
        }, merge=True)
        # keep history under runs/{run_id}
        runs_doc = bucket_ref.collection(part).document("Matches").collection("runs").document(run_id)
        pairs = [{
            "match_id": m.get("id"),
            "users": m.get("users", []),
            "created_at": m.get("created_at"),
            "reason": m.get("reason", ""),
            "who_want_reason": m.get("who_want_reason", ""),
            "special_who_want": bool(m.get("special_who_want", False)),
        } for m in rows]
        runs_doc.set({
            "run_id": run_id,
            "run_ts": run_ts,
            "count": len(pairs),
            "pairs": pairs,
        })

def main():
    args = _parse_args()

    # mark start time so we only collect matches created in THIS run
    run_ts = datetime.now(timezone.utc)
    run_id = uuid.uuid4().hex[:12]

    # run one full cycle
    if args.partitions:
        print(f"▶ Running matching cycle for {args.bucket} on partitions: {', '.join(args.partitions)}")
        run_matching_cycle(args.bucket, args.partitions)
    else:
        print(f"▶ Running matching cycle for {args.bucket} on ALL partitions")
        run_matching_cycle(args.bucket)

    # gather new matches
    matches = _query_new_matches(args.bucket, since_ts=run_ts)
    by_part: Dict[str, List[Dict[str, Any]]] = {}
    for m in matches:
        by_part.setdefault(m.get("partition", "unknown"), []).append(m)

    # print required header + results
    print("\nMAtches")
    if not matches:
        print("  (no new matches created in this cycle)")
    else:
        total = 0
        for part in sorted(by_part):
            rows = by_part[part]
            total += len(rows)
            print(f"{part}: {len(rows)}")
            for m in rows:
                users = m.get("users", [])
                reason = m.get("reason", "")
                special = " [SPECIAL]" if m.get("special_who_want") else ""
                print(f"  • {users}  reason={reason}{special}")
        print(f"Total matches this run: {total}")

    # write partition summaries
    if by_part:
        _write_partition_summaries(args.bucket, by_part, run_id, run_ts)
        print(f"\n✓ Wrote partition Matches summaries (run_id={run_id})")
    else:
        print("\n(no partition summaries written since no matches were created)")

if __name__ == "__main__":
    main()
