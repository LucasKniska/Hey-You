"""
RunKMeansTraining.py
====================

Run k-means on a source collection (default: 'TestingUsers'),
write centroids to Buckets/{bucket}, and verify grid + shapes.

Usage (from 'Python Backend'):
  python TestingFolder/RunKMeansTraining.py \
    --collection TestingUsers \
    --bucket Stanford_University \
    --k_ocean 4 \
    --k_llm 5 \
    --llm_mode strict \
    --audit_n 50
"""

from __future__ import annotations
import sys, os
import argparse
from collections import Counter

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if PROJECT_ROOT not in sys.path:
    sys.path.append(PROJECT_ROOT)

from main import db
from k_means.buckInAbuck import run_clustering_and_write_partitions, TARGET_LLM_DIM
# If you keep this in k_means/buckInAbuck.py instead, swap the import accordingly.

def audit_llm_lengths(collection: str, sample_n: int | None = 50) -> tuple[dict[int, int], int]:
    """
    Inspect LLM embedding lengths.
    - sample_n > 0: audit first N docs
    - sample_n <= 0 or None: audit ALL docs (may be slow)
    Returns: (length_counts, audited_total)
    """
    lengths = Counter()
    ref = db.collection(collection)
    docs = list(ref.stream()) if not sample_n or sample_n <= 0 else list(ref.limit(sample_n).stream())
    for d in docs:
        data = d.to_dict() or {}
        emb = data.get("llmEmbedding")
        if isinstance(emb, list):
            lengths[len(emb)] += 1
            continue

        # legacy fallbacks
        llm = data.get("LLMScore", [])
        if isinstance(llm, list):
            lengths[len(llm)] += 1
        elif isinstance(llm, dict):
            total = 0
            for k in sorted(llm.keys()):
                v = llm.get(k, [])
                try:
                    total += len(v)
                except Exception:
                    pass
            lengths[total] += 1
        else:
            lengths[-1] += 1  # missing/invalid
    return dict(lengths), len(docs)

def verify_partitions(bucket_name: str, expected_parts: list[str], target_llm_dim: int) -> None:
    """Ensure each partition exists and centroid vectors have expected lengths."""
    bucket_doc = db.collection("Buckets").document(bucket_name)
    actual_subcols = {c.id for c in bucket_doc.collections()}
    missing = [p for p in expected_parts if p not in actual_subcols]
    if missing:
        raise RuntimeError(f"Missing partitions under Buckets/{bucket_name}: {missing}")

    for part in expected_parts:
        snap = bucket_doc.collection(part).document("centroid").get()
        if not snap.exists:
            raise RuntimeError(f"Missing centroid doc in {bucket_name}/{part}")
        data = snap.to_dict() or {}
        ocean = data.get("ocean_centroid")
        llm   = data.get("llm_centroid")
        if not (isinstance(ocean, list) and len(ocean) == 5):
            raise RuntimeError(f"OCEAN centroid wrong shape in {bucket_name}/{part}")
        if not (isinstance(llm, list) and len(llm) == target_llm_dim):
            raise RuntimeError(f"LLM centroid wrong shape in {bucket_name}/{part}")

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--collection", default="TestingUsers", help="Source collection")
    ap.add_argument("--bucket", default="Stanford_University", help="Destination bucket under Buckets/")
    ap.add_argument("--k_ocean", type=int, default=4, help="Number of OCEAN clusters")
    ap.add_argument("--k_llm",   type=int, default=5, help="Number of LLM clusters")
    ap.add_argument("--llm_mode", default="strict", choices=["strict", "pad", "truncate"],
                    help="LLM length enforcement")
    ap.add_argument("--audit_n", type=int, default=50, help="Docs to audit (0 = ALL)")
    args = ap.parse_args()

    print(f"▶ Auditing LLM embedding lengths in '{args.collection}' "
          f"({'ALL docs' if args.audit_n <= 0 else f'first {args.audit_n} docs'})...")
    length_counts, audited_total = audit_llm_lengths(args.collection, args.audit_n)
    if length_counts:
        pretty = ", ".join(f"{L}: {cnt} docs" for L, cnt in sorted(length_counts.items()))
        print(f"  Observed LLM vector lengths → {pretty}")
        print(f"  Audited total: {audited_total} doc(s)")
    else:
        print("  (No docs found during audit.)")

    print(f"\n▶ Running K-means on '{args.collection}' → Buckets/{args.bucket}")
    print(f"   params: k_ocean={args.k_ocean}, k_llm={args.k_llm}, llm_mode={args.llm_mode}, target_llm_dim={TARGET_LLM_DIM}")

    parts = run_clustering_and_write_partitions(
        user_collection=args.collection,
        bucket_name=args.bucket,
        k_ocean=args.k_ocean,
        k_llm=args.k_llm,
        expected_fields=[f"field{i+1}" for i in range(5)],  # only used for legacy dict format
        llm_mode=args.llm_mode,
        target_llm_dim=TARGET_LLM_DIM,
    )

    print(f"✓ Wrote centroids for {len(parts)} partitions:")
    print("  " + ", ".join(sorted(parts)))

    print("\n▶ Verifying partition grid and centroid shapes...")
    verify_partitions(args.bucket, parts, TARGET_LLM_DIM)
    print("✅ Verification passed: all partitions present with correct centroid shapes.")

if __name__ == "__main__":
    main()
