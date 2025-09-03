from auth import db
import numpy as np
from sklearn.cluster import KMeans
from typing import List, Optional, Dict, Any

TARGET_LLM_DIM = 1536

def _flatten_llm_score(
    llm_score: Any,
    target_dim: int,
    mode: str = "strict",
) -> np.ndarray:
    """
    Normalize LLM vector to length == target_dim.
    Accepts: list/tuple/ndarray OR dict-of-lists (legacy).
    mode: 'strict' | 'pad' | 'truncate'
    """
    if isinstance(llm_score, (list, tuple, np.ndarray)):
        vec = np.asarray(llm_score, dtype=np.float32).ravel()
    elif isinstance(llm_score, dict):
        fields = sorted(llm_score.keys())
        parts = [np.asarray(llm_score.get(f, []), dtype=np.float32).ravel() for f in fields]
        vec = np.concatenate(parts) if parts else np.zeros(0, dtype=np.float32)
    else:
        vec = np.zeros(0, dtype=np.float32)

    n = vec.shape[0]
    if n == target_dim:
        return vec

    if mode == "strict":
        raise ValueError(f"LLM embedding length {n} != {target_dim}")

    if mode == "pad":
        if n > target_dim:
            return vec[:target_dim]
        out = np.zeros((target_dim,), dtype=np.float32)
        out[:n] = vec
        return out

    if mode == "truncate":
        return vec[:target_dim] if n >= target_dim else np.pad(vec, (0, target_dim - n))

    raise ValueError(f"Unknown mode '{mode}'")

# ---------- schema helpers ----------

def _extract_ocean_5d(data: Dict[str, Any]) -> np.ndarray:
    """Prefer OCEANScoreDict (O,C,E,A,N order); fallback to expanding scalar OCEANScore."""
    ocean_dict = data.get("OCEANScore")
    if isinstance(ocean_dict, dict):
        keys = ["O", "C", "E", "A", "N"]
        vec = [ocean_dict[k] for k in keys]
        arr = np.asarray(vec, dtype=np.float32).ravel()
        if arr.shape == (5,):
            return arr
    else:
        arr = np.asarray([0, 0, 0, 0, 0], dtype=np.float32).ravel()
        return arr

def _extract_llm_embedding_container(data: Dict[str, Any]) -> Any:
    """
    Prefer 'llmEmbedding' (list of 1536 floats).
    Fallback: 'LLMScore' if it's a long list or dict-of-lists.
    Ignore scalar 'llmScore'/'LLMScore'.
    """
    if "llmEmbedding" in data:
        return data["llmEmbedding"]
    ls = data.get("LLMScore")
    if isinstance(ls, list) and len(ls) > 32:
        return ls
    if isinstance(ls, dict):
        return ls
    return []

# ---------- main ----------

def run_clustering_and_write_partitions(
    user_collection: str = "Users",
    bucket_name: str = "Stanford_University",
    k_ocean: int = 4,
    k_llm: int = 5,
    llm_mode: str = "strict",                     # 'strict' | 'pad' | 'truncate'
    target_llm_dim: int = TARGET_LLM_DIM,
) -> List[str]:
    """
    Train K-means on ALL users in the collection:
      - OCEAN: 5-D per user
      - LLM:   1536-D per user
    Write centroids under Buckets/{bucket_name}/partitionXY/centroid.
    """
    docs = list(db.collection(user_collection).stream())
    if not docs:
        raise RuntimeError(f"No user records in '{user_collection}'")

    ocean_vecs, llm_vecs = [], []

    for doc in docs:
        data: Dict[str, Any] = doc.to_dict() or {}

        ocean = _extract_ocean_5d(data)
        if ocean.shape != (5,):
            raise ValueError(f"OCEANScore must be len=5; got {ocean.shape} for doc {doc.id}")

        llm_container = _extract_llm_embedding_container(data)
        flat_llm = _flatten_llm_score(llm_container,target_llm_dim, mode=llm_mode)

        ocean_vecs.append(ocean)
        llm_vecs.append(flat_llm)

    ocean_arr = np.vstack(ocean_vecs)  # (n, 5)
    llm_arr   = np.vstack(llm_vecs)    # (n, target_llm_dim)

    kmeans_ocean = KMeans(n_clusters=k_ocean, random_state=42, n_init="auto").fit(ocean_arr)
    kmeans_llm   = KMeans(n_clusters=k_llm,   random_state=42, n_init="auto").fit(llm_arr)

    bucket_doc = db.collection("Buckets").document(bucket_name)
    created: List[str] = []
    for i in range(k_ocean):
        for j in range(k_llm):
            part = f"partition{i+1}{j+1}"
            created.append(part)
            bucket_doc.collection(part).document("centroid").set({
                "ocean_centroid": kmeans_ocean.cluster_centers_[i].tolist(),
                "llm_centroid":   kmeans_llm  .cluster_centers_[j].tolist(),
                "meta": {
                    "k_ocean": k_ocean,
                    "k_llm": k_llm,
                    "dims": {"ocean": 5, "llm": int(target_llm_dim)},
                    "source_collection": user_collection,
                    "llm_mode": llm_mode,
                }
            })
    return created
