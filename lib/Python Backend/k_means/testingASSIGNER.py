# TestingFolder/test_single_user_partition_driver.py
# -------------------------------------------------
# Picks ~25 users and assigns each ONE-BY-ONE to the nearest partition,
# printing a concise line per user. Requires centroids to exist already.

from __future__ import annotations
from typing import List
import os, sys, argparse, random, time

# Path so we can import main + the single-user assigner
THIS_DIR = os.path.dirname(__file__)
PARENT_DIR = os.path.abspath(os.path.join(THIS_DIR, os.pardir))
if PARENT_DIR not in sys.path:
    sys.path.insert(0, PARENT_DIR)

from main import db
from k_means.UsersInBuckets import assign_single_user_to_partition

def pick_users(user_coll: str, count: int = 25) -> List[str]:
    docs = list(db.collection(user_coll).limit(max(100, count)).stream())
    ids = [d.id for d in docs]
    random.shuffle(ids)
    return ids[:count]

def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Test: assign ~25 users individually to partitions.")
    p.add_argument("--user-coll", required=True, help="Source users collection (e.g., TestingUsers)")
    p.add_argument("--bucket", required=True, help="Bucket doc id (e.g., Columbia_University)")
    p.add_argument("--n", type=int, default=25, help="How many users to assign (default 25)")
    p.add_argument("--k-ocean", type=int, default=4, help="OCEAN clusters (rows)")
    p.add_argument("--k-llm",   type=int, default=5, help="LLM clusters (cols)")
    p.add_argument("--llm-dim", type=int, default=1536, help="LLM embedding dim")
    p.add_argument("--sleep", type=float, default=0.0, help="Seconds to sleep between users")
    return p.parse_args()

if __name__ == "__main__":
    args = parse_args()
    user_ids = pick_users(args.user_coll, args.n)
    if not user_ids:
        print("No users found to test.")
        sys.exit(1)

    print(f"Assigning {len(user_ids)} users to bucket '{args.bucket}' from '{args.user_coll}'...\n")

    for i, uid in enumerate(user_ids, start=1):
        try:
            res = assign_single_user_to_partition(
                user_id=uid,
                user_collection=args.user_coll,
                bucket_id=args.bucket,
                k_ocean=max(1, args.k_ocean),
                k_llm=max(1, args.k_llm),
                llm_dim=max(1, args.llm_dim),
            )
            print(f"[{i:02d}/{len(user_ids):02d}] {uid:>24} → {res['partition']}  "
                  f"(OCEAN d²={res['distance_sq_ocean']:.4f}, LLM d²={res['distance_sq_llm']:.4f})")
        except Exception as e:
            print(f"[{i:02d}/{len(user_ids):02d}] {uid:>24} → ERROR: {e}")
        if args.sleep > 0:
            time.sleep(args.sleep)

    print("\nDone.")
