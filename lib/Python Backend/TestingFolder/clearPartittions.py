# TestingFolder/clearPartitions.py
from __future__ import annotations
import sys, os, argparse

# --- Make sure we can import main.db ---
PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))  # -> ".../Python Backend"
if PROJECT_ROOT not in sys.path:
    sys.path.append(PROJECT_ROOT)

from main import db  # now import works

def clear_partition(bucket_id: str, partition: str) -> int:
    """Delete all user docs (except 'centroid') under Buckets/{bucket_id}/{partition}."""
    col = db.collection("Buckets").document(bucket_id).collection(partition)
    batch = db.batch()
    count = 0
    deleted = 0
    for snap in col.stream():
        if snap.id == "centroid":
            continue
        batch.delete(col.document(snap.id))
        count += 1
        if count >= 450:
            batch.commit()
            deleted += count
            batch = db.batch()
            count = 0
    if count:
        batch.commit()
        deleted += count
    print(f"Cleared {partition}: {deleted} docs")
    return deleted

def clear_bucket_partitions(bucket_id: str, k_ocean: int = 4, k_llm: int = 5) -> int:
    """Delete all user docs across the grid (keeps centroid)."""
    total_deleted = 0
    for i in range(1, k_ocean + 1):
        for j in range(1, k_llm + 1):
            part = f"partition{i}{j}"
            total_deleted += clear_partition(bucket_id, part)
    print(f"Done. Deleted {total_deleted} docs from Buckets/{bucket_id}.")
    return total_deleted

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--bucket", default="Stanford_University")
    ap.add_argument("--k_ocean", type=int, default=4)
    ap.add_argument("--k_llm", type=int, default=5)
    ap.add_argument("--partition", help="If set, only clear this partition (e.g. partition23)")
    args = ap.parse_args()

    if args.partition:
        clear_partition(args.bucket, args.partition)
    else:
        clear_bucket_partitions(args.bucket, args.k_ocean, args.k_llm)

if __name__ == "__main__":
    main()
