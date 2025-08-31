# TestingFolder/SeedReadyFlags.py
"""
SeedReadyFlags.py
=================

Set `ready_to_match` for EVERY user doc under Buckets/{bucket}/partitionXY/*
(skips the 'centroid' doc). Optionally mirror the flag into Users/{user_id}.

Run (from 'Python Backend'):
  python TestingFolder/SeedReadyFlags.py --bucket Stanford_University --value true

Options:
  --value true|false        # what to set (default: true)
  --only-missing            # only set when the field is absent
  --mirror-users            # also write Users/{uid}.ready_to_match
  --clear-active            # clear active_match_id + matched_at on partition docs
"""

from __future__ import annotations
import sys, os, argparse
from datetime import datetime, timezone

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if PROJECT_ROOT not in sys.path:
    sys.path.append(PROJECT_ROOT)

from main import db  # Firestore client

def _iter_partitions(bucket_id: str):
    for coll in db.collection("Buckets").document(bucket_id).collections():
        cid = coll.id
        if cid.startswith("partition"):
            yield cid

def seed_ready_flags(
    bucket: str,
    value: bool = True,
    only_missing: bool = False,
    mirror_users: bool = False,
    clear_active: bool = False,
):
    bucket_ref = db.collection("Buckets").document(bucket)
    total = 0
    per_part = {}

    for part in sorted(_iter_partitions(bucket)):
        col = bucket_ref.collection(part)
        wrote = 0

        for snap in col.stream():
            if snap.id == "centroid":
                continue
            data = snap.to_dict() or {}

            # skip if only_missing and field already present
            if only_missing and "ready_to_match" in data:
                continue

            patch = {"ready_to_match": bool(value)}
            if clear_active:
                patch.update({"active_match_id": None, "matched_at": None})

            col.document(snap.id).set(patch, merge=True)
            if mirror_users:
                db.collection("Users").document(snap.id).set({"ready_to_match": bool(value)}, merge=True)

            wrote += 1
            total += 1

        per_part[part] = wrote
        print(f"{part}: updated {wrote} users")

    print("\n===== READY FLAG SUMMARY =====")
    for p in sorted(per_part):
        print(f"  {p}: {per_part[p]}")
    print(f"Total updated: {total}")
    print("==============================")

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--bucket", default="Stanford_University", help="Bucket doc id under Buckets/")
    ap.add_argument("--value", default="true", choices=["true", "false"], help="Value to set")
    ap.add_argument("--only-missing", action="store_true", help="Only set when ready_to_match is absent")
    ap.add_argument("--mirror-users", action="store_true", help="Also write Users/{uid}.ready_to_match")
    ap.add_argument("--clear-active", action="store_true", help="Clear active_match_id and matched_at")
    args = ap.parse_args()

    seed_ready_flags(
        bucket=args.bucket,
        value=(args.value.lower() == "true"),
        only_missing=args.only_missing,
        mirror_users=args.mirror_users,
        clear_active=args.clear_active,
    )

if __name__ == "__main__":
    main()
