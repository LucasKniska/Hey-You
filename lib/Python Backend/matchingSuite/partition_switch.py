from __future__ import annotations
from typing import Tuple, Optional, List, Any
import re
import numpy as np
from auth import db

OCEAN_DIM = 5
TARGET_LLM_DIM = 1536
GRID_I, GRID_J = 4, 5

_PARTITION_RE = re.compile(r"^partition(\d)(\d+)$")

def parse_partition(p: str) -> Tuple[int, int]:
    m = _PARTITION_RE.match(p)
    if not m:
        raise ValueError(f"Bad partition name: {p}")
    return int(m.group(1)), int(m.group(2))

def format_partition(i: int, j: int) -> str:
    return f"partition{i}{j}"

def choose_adjacent_partition(curr: str) -> str:
    import random
    i, j = parse_partition(curr)
    if random.choice([True, False]):
        i = min(max(1, i + random.choice([-1, 1])), GRID_I)
    else:
        j = min(max(1, j + random.choice([-1, 1])), GRID_J)
    return format_partition(i, j)

def _flatten_llm_score(
    llm_score: Any,
    target_dim: int = TARGET_LLM_DIM,
    mode: str = "strict",  # 'strict' | 'pad' | 'truncate'
) -> np.ndarray:
    if isinstance(llm_score, (list, tuple, np.ndarray)):
        vec = np.asarray(llm_score, dtype=np.float32).ravel()
    elif isinstance(llm_score, dict):
        parts: List[np.ndarray] = []
        for k in sorted(llm_score.keys()):
            parts.append(np.asarray(llm_score.get(k, []), dtype=np.float32).ravel())
        vec = np.concatenate(parts) if parts else np.zeros(0, dtype=np.float32)
    else:
        vec = np.zeros(0, dtype=np.float32)

    n = vec.shape[0]
    if n == target_dim:
        return vec

    if mode == "strict":
        raise ValueError(f"LLM embedding length {n} != {target_dim}")

    if mode == "pad":
        out = np.zeros((target_dim,), dtype=np.float32)
        out[: min(n, target_dim)] = vec[:target_dim]
        return out

    if mode == "truncate":
        return vec[:target_dim] if n >= target_dim else np.pad(vec, (0, target_dim - n))

    raise ValueError(f"Unknown mode '{mode}'")

def _read_centroid(bucket_id: str, partition: str):
    ref = db.collection("Buckets").document(bucket_id).collection(partition).document("centroid")
    data = ref.get().to_dict() or {}
    ocean = np.array(data.get("ocean_centroid", [0.0] * OCEAN_DIM), dtype=np.float32)
    llm   = np.array(data.get("llm_centroid",   [0.0] * TARGET_LLM_DIM), dtype=np.float32)
    if ocean.shape != (OCEAN_DIM,):
        raise ValueError(f"{bucket_id}/{partition} ocean centroid bad shape {ocean.shape}")
    if llm.shape != (TARGET_LLM_DIM,):
        raise ValueError(f"{bucket_id}/{partition} llm centroid bad shape {llm.shape}")
    return ocean, llm

def _get_user_profile(user_id: str):
    snap = db.collection("Users").document(user_id).get()
    return snap.to_dict() or {}

def move_user_to_partition(bucket_id: str, from_partition: str, to_partition: str, user_id: str):
    if user_id == "centroid":
        return
    src = db.collection("Buckets").document(bucket_id).collection(from_partition).document(user_id)
    dst = db.collection("Buckets").document(bucket_id).collection(to_partition).document(user_id)
    data = src.get().to_dict() or {}
    dst.set(data, merge=True)
    src.delete()

def recompute_and_write_centroid_distances(bucket_id: str, partition: str, user_id: str):
    prof = _get_user_profile(user_id)
    ocean = np.asarray(prof.get("OCEANScore", [0.0] * OCEAN_DIM), dtype=np.float32).ravel()
    raw_llm = prof.get("llmEmbedding", prof.get("LLMScore", []))
    try:
        llm = _flatten_llm_score(raw_llm, target_dim=TARGET_LLM_DIM, mode="strict")
    except Exception:
        # Fallback to pad so moves never explode due to shape drift
        llm = _flatten_llm_score(raw_llm, target_dim=TARGET_LLM_DIM, mode="pad")
    oc, lc = _read_centroid(bucket_id, partition)
    d2_o = float(np.sum((oc - ocean) ** 2))
    d2_l = float(np.sum((lc - llm) ** 2))
    db.collection("Buckets").document(bucket_id).collection(partition).document(user_id).set(
        {
            "distance_sq_ocean": d2_o,
            "distance_sq_llm": d2_l,
            "distance_sq_total": d2_o + d2_l,
        },
        merge=True,
    )
