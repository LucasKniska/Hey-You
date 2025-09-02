# group_driver_kmeans.py
# ----------------------
# Group driver that runs K-means over a given user collection and writes
# centroids under Buckets/{bucket_name}/partitionXY/centroid.
#
# Frontend supplies:
#   - user collection name (e.g., "TestingUsers", "ColumbiaUsers")
#   - bucket name for Buckets (e.g., "Columbia_University", "Stanford_University")
#
# Optional knobs:
#   - k_ocean, k_llm, llm_mode ('strict' | 'pad' | 'truncate'), expected_fields (CSV)
#
# Prints a concise summary of created partitions.

from __future__ import annotations
from typing import List, Optional
import argparse, os, sys
from datetime import datetime, timezone

# Ensure we can import main.py (Firestore client) and the k-means runner
THIS_DIR = os.path.dirname(__file__)
PARENT_DIR = os.path.abspath(os.path.join(THIS_DIR, os.pardir))
if PARENT_DIR not in sys.path:
    sys.path.insert(0, PARENT_DIR)

from main import db
from k_means.buckInAbuck import run_clustering_and_write_partitions

def run_group_driver(
    user_collection: str,
    bucket_name: str,
    k_ocean: int = 4,
    k_llm: int = 5,
    llm_mode: str = "strict",
    expected_fields: Optional[List[str]] = None,
    target_llm_dim: int = 1536,
) -> List[str]:
    """
    Execute clustering and persist centroids to Firestore.

    Returns:
        List of partition IDs created (e.g., ["partition11", "partition12", ...]).
    """
    if not user_collection or not bucket_name:
        raise ValueError("user_collection and bucket_name are required.")

    print("────────────────────────────────────────────────────────")
    print("K-means group driver")
    print(f"  user_collection : {user_collection}")
    print(f"  bucket_name     : {bucket_name}")
    print(f"  k_ocean / k_llm : {k_ocean} / {k_llm}")
    print(f"  llm_mode        : {llm_mode}")
    if expected_fields:
        print(f"  expected_fields : {expected_fields}")
    print("────────────────────────────────────────────────────────")

    created = run_clustering_and_write_partitions(
        user_collection=user_collection,
        bucket_name=bucket_name,
        k_ocean=k_ocean,
        k_llm=k_llm,
        llm_mode=llm_mode,
        target_llm_dim=target_llm_dim,
    )

    # Optional: record a lightweight run log for traceability
    meta_doc = {
        "ts_utc": datetime.now(timezone.utc).isoformat(),
        "source_collection": user_collection,
        "bucket_name": bucket_name,
        "k_ocean": k_ocean,
        "k_llm": k_llm,
        "llm_mode": llm_mode,
        "target_llm_dim": target_llm_dim,
        "partitions_created": created,
        "count": len(created),
        "runner": "group_driver_kmeans.py",
    }
    try:
        db.collection("Buckets").document(bucket_name).collection("_runs").add(meta_doc)
    except Exception as e:
        print(f"[warn] could not write run log: {e}")

    print(f"✅ Clustering complete — wrote {len(created)} partitions under Buckets/{bucket_name}")
    if created:
        # Print a compact grid (first few only if very large)
        preview = ", ".join(created[:12]) + (" ..." if len(created) > 12 else "")
        print(f"   partitions: {preview}")
    return created

def _parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Run K-means and write centroids to Buckets/{bucket}.")
    p.add_argument("--user-coll", required=True, help="User collection (e.g., TestingUsers, ColumbiaUsers)")
    p.add_argument("--bucket", required=True, help="Bucket doc name under Buckets/ (e.g., Columbia_University)")
    p.add_argument("--k-ocean", type=int, default=4, help="Number of clusters for OCEAN (default 4)")
    p.add_argument("--k-llm", type=int, default=5, help="Number of clusters for LLM (default 5)")
    p.add_argument("--llm-mode", choices=["strict","pad","truncate"], default="strict",
                   help="How to handle non-1536 embeddings")
    p.add_argument("--expected-fields", type=str, default="",
                   help="CSV list of dict keys if embeddings are dict-of-lists (legacy)")
    p.add_argument("--target-dim", type=int, default=1536, help="Target LLM embedding length (default 1536)")
    return p.parse_args()

if __name__ == "__main__":
    run_group_driver(
        user_collection="Users",
        bucket_name="Columbia_University",
        k_ocean=3,
        k_llm=3,
        llm_mode="pad",
    )
