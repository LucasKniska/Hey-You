# drivers/driver_single_user_partition.py
# ---------------------------------------

from __future__ import annotations
import argparse, os, sys, json

# Make project imports work
THIS_DIR = os.path.dirname(__file__)
PARENT_DIR = os.path.abspath(os.path.join(THIS_DIR, os.pardir))
if PARENT_DIR not in sys.path:
    sys.path.insert(0, PARENT_DIR)

from UsersInBuckets import (
    assign_single_user_to_partition,
    DEFAULT_USER_COLLECTION,
    DEFAULT_K_OCEAN,
    DEFAULT_K_LLM,
    DEFAULT_LLM_DIM,
)

def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Assign ONE user to a bucket partition.")
    p.add_argument("--user-id", required=True, help="User document ID")
    p.add_argument("--bucket",   required=True, help="Bucket doc id (e.g., Columbia_University)")
    p.add_argument("--user-coll", default=DEFAULT_USER_COLLECTION, help="Source collection (default TestingUsers)")
    p.add_argument("--k-ocean", type=int, default=DEFAULT_K_OCEAN, help="OCEAN clusters (rows)")
    p.add_argument("--k-llm",   type=int, default=DEFAULT_K_LLM,   help="LLM clusters (cols)")
    p.add_argument("--llm-dim", type=int, default=DEFAULT_LLM_DIM, help="LLM embedding dim (default 1536)")
    return p.parse_args()

if __name__ == "__main__":
    # args = parse_args()
    res = assign_single_user_to_partition(
        user_id='jiBsMOEwoNgAMYgE7Y6OfwhKgdJ3',
        user_collection='Users',
        bucket_id='Columbia_University',
        k_ocean=max(1, 3),
        k_llm=max(1, 3),
    )
    print(json.dumps(res, indent=2, default=str))
