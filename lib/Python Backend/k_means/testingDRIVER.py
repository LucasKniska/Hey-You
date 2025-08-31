# TestingFolder/test_group_driver_kmeans.py
# -----------------------------------------
# Minimal tester for the group K-means driver.
# - Invokes run_group_driver(...) with the provided collection & bucket
# - Prints the partitions created
# - Reads back one centroid for a quick sanity check (shapes only)
#
# Usage examples:
#   python TestingFolder/test_group_driver_kmeans.py \
#       --user-coll TestingUsers --bucket Columbia_University
#
#   python TestingFolder/test_group_driver_kmeans.py \
#       --user-coll ColumbiaUsers --bucket Columbia_University \
#       --k-ocean 4 --k-llm 6 --llm-mode pad --target-dim 1536
#
# Notes:
# - Assumes `group_driver_kmeans.py` sits one directory up from this file.
# - Firestore credentials/OPENAI env should already be configured in your env.

from __future__ import annotations
import os, sys, argparse
from typing import List, Optional, Dict, Any

# Ensure imports resolve (parent is “…/Python Backend”)
THIS_DIR = os.path.dirname(__file__)
PARENT_DIR = os.path.abspath(os.path.join(THIS_DIR, os.pardir))
if PARENT_DIR not in sys.path:
    sys.path.insert(0, PARENT_DIR)

from main import db
from DRIVERkmeans import run_group_driver

def read_back_one_centroid(bucket_name: str, partitions: List[str]) -> None:
    """Read one centroid doc to confirm it was written; print vector lengths."""
    if not partitions:
        print("No partitions returned; nothing to read back.")
        return
    part = partitions[0]
    ref = (db.collection("Buckets")
             .document(bucket_name)
             .collection(part)
             .document("centroid"))
    snap = ref.get()
    if not snap.exists:
        print(f"[sanity] centroid missing at Buckets/{bucket_name}/{part}/centroid")
        return
    data: Dict[str, Any] = snap.to_dict() or {}
    ocean = data.get("ocean_centroid") or []
    llm   = data.get("llm_centroid") or []
    print(f"[sanity] {bucket_name}/{part}/centroid → "
          f"ocean_dim={len(ocean)} llm_dim={len(llm)} "
          f"(k_ocean={data.get('meta', {}).get('k_ocean')}, "
          f"k_llm={data.get('meta', {}).get('k_llm')})")

def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Test the group K-means driver (one run).")
    p.add_argument("--user-coll", required=True,
                   help="User collection to cluster (e.g., TestingUsers, ColumbiaUsers)")
    p.add_argument("--bucket", required=True,
                   help="Bucket doc to write under Buckets/ (e.g., Columbia_University)")
    p.add_argument("--k-ocean", type=int, default=4,
                   help="Clusters for OCEAN (default 4)")
    p.add_argument("--k-llm", type=int, default=5,
                   help="Clusters for LLM (default 5)")
    p.add_argument("--llm-mode", choices=["strict","pad","truncate"], default="strict",
                   help="Handle non-1536 embeddings (default strict)")
    p.add_argument("--expected-fields", type=str, default="",
                   help="CSV keys if embeddings are dict-of-lists (legacy)")
    p.add_argument("--target-dim", type=int, default=1536,
                   help="Target LLM embedding length (default 1536)")
    return p.parse_args()

if __name__ == "__main__":
    args = parse_args()
    fields = [s.strip() for s in args.expected_fields.split(",") if s.strip()] or None

    partitions = run_group_driver(
        user_collection=args.user_coll,
        bucket_name=args.bucket,
        k_ocean=max(1, args.k_ocean),
        k_llm=max(1, args.k_llm),
        llm_mode=args.llm_mode,
        expected_fields=fields,
        target_llm_dim=max(1, args.target_dim),
    )

    # Print a concise summary and sanity-check one centroid
    if partitions:
        print(f"Partitions created ({len(partitions)}): "
              + ", ".join(partitions[:12]) + (" ..." if len(partitions) > 12 else ""))
    read_back_one_centroid(args.bucket, partitions)
