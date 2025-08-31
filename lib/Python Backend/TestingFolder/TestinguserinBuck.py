# TestingFolder/RunAssignUsersToPartitions.py
"""
RunAssignUsersToPartitions.py
=============================

Assign all users in a collection to Buckets/{bucket}/partitionXY
based on nearest OCEAN and LLM centroids, and verify the write.

Usage (from 'Python Backend'):
  python TestingFolder/RunAssignUsersToPartitions.py \
    --collection TestingUsers \
    --bucket Stanford_University \
    --k_ocean 4 \
    --k_llm 5 \
    --llm_dim 1536 \
    --clear
"""

from __future__ import annotations
import sys, os
import argparse
from typing import Dict, List

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if PROJECT_ROOT not in sys.path:
    sys.path.append(PROJECT_ROOT)

from main import db

# --- Import the updated assigner (supports both locations) ---

from k_means.UsersInBuckets import assign_users_to_partitions  # type: ignore


def verify_population(bucket: str, k_ocean: int, k_llm: int) -> int:
    """
    Verify that for each partition, user docs exist alongside 'centroid'.
    Returns total user docs counted under all partitions.
    """
    total = 0
    missing_centroids: List[str] = []
    for i in range(k_ocean):
        for j in range(k_llm):
            part = f"partition{i+1}{j+1}"
            col = db.collection("Buckets").document(bucket).collection(part)

            # centroid must exist
            if not col.document("centroid").get().exists:
                missing_centroids.append(part)

            # count user docs (exclude centroid)
            count = sum(1 for d in col.stream() if d.id != "centroid")
            print(f"{part}: {count} users")
            total += count

    if missing_centroids:
        raise RuntimeError(f"Missing centroid doc(s): {missing_centroids}")

    return total


def verify_users_backrefs(user_collection: str, bucket: str) -> Dict[str, List[str]]:
    """
    Optional: confirm Users/{uid} has bucket_id and partition set to the target bucket.
    Returns dicts of any uids with missing fields.
    """
    missing_bucket: List[str] = []
    missing_partition: List[str] = []
    wrong_bucket: List[str] = []

    for s in db.collection(user_collection).stream():
        uid = s.id
        u = (db.collection("Users").document(uid).get().to_dict() or {})
        b = u.get("bucket_id")
        p = u.get("partition")
        if not b:
            missing_bucket.append(uid)
        elif b != bucket:
            wrong_bucket.append(uid)
        if not p:
            missing_partition.append(uid)

    issues = {
        "missing_bucket_id": missing_bucket,
        "missing_partition": missing_partition,
        "wrong_bucket_id": wrong_bucket,
    }
    # Only print if something's off
    if any(issues.values()):
        print("\n⚠️  Backref verification found issues:")
        for k, v in issues.items():
            if v:
                print(f"  - {k}: {len(v)} → {v[:10]}{'...' if len(v) > 10 else ''}")
    else:
        print("\n✅ Users backrefs look good (bucket_id & partition set).")
    return issues


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--collection", default="TestingUsers", help="Source user collection")
    ap.add_argument("--bucket", default="Stanford_University", help="Destination bucket (Buckets/<id>)")
    ap.add_argument("--k_ocean", type=int, default=4)
    ap.add_argument("--k_llm", type=int, default=5)
    ap.add_argument("--llm_dim", type=int, default=1536)
    ap.add_argument("--clear", action="store_true", help="Delete existing user docs in partitions (keeps centroid)")
    ap.add_argument("--skip_user_backref_check", action="store_true", help="Skip verifying Users/{uid} backrefs")
    args = ap.parse_args()

    print(f"▶ Assigning users from '{args.collection}' → Buckets/{args.bucket} (k_ocean={args.k_ocean}, k_llm={args.k_llm})")
    mapping = assign_users_to_partitions(
        user_collection=args.collection,
        bucket_id=args.bucket,
        k_ocean=args.k_ocean,
        k_llm=args.k_llm,
        llm_dim=args.llm_dim,
        clear_existing=args.clear,
    )

    assigned = sum(len(v) for v in mapping.values())
    print(f"\n✓ Assigned {assigned} users across {len(mapping)} partitions\n")

    print("▶ Verifying users are populated next to centroids...")
    total_counted = verify_population(args.bucket, args.k_ocean, args.k_llm)
    print(f"✅ Verification passed: counted {total_counted} user docs under partition subcollections.")

    if not args.skip_user_backref_check:
        print("\n▶ Verifying Users/{uid} backreferences (bucket_id, partition)...")
        verify_users_backrefs(args.collection, args.bucket)

    # Optional: print the mapping summary
    print("\n====== USER PARTITIONS SUMMARY ======")
    for part in sorted(mapping):
        print(f"{part}: {len(mapping[part])} users")
    print("=====================================")


if __name__ == "__main__":
    main()
