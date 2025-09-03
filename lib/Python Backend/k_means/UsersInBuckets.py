# partitioning/single_user_partition.py
# -------------------------------------
# Assign ONE user to a bucket partition using precomputed centroids.
# Idempotent: removes prior placements for this user under the same bucket.

from __future__ import annotations
from typing import Dict, Any, List, Tuple
from datetime import datetime, timezone
import numpy as np
import os, sys

# Ensure we can import main.py (Firestore client) from project root/parent
THIS_DIR = os.path.dirname(__file__)
PARENT_DIR = os.path.abspath(os.path.join(THIS_DIR, os.pardir))
if PARENT_DIR not in sys.path:
    sys.path.insert(0, PARENT_DIR)

from auth import db

# Defaults (override via driver args)
DEFAULT_USER_COLLECTION = "Users"
DEFAULT_K_OCEAN = 4
DEFAULT_K_LLM   = 5
DEFAULT_LLM_DIM = 1536

# ---------------- helpers ----------------

def _extract_ocean_5d(data: Dict[str, Any]) -> np.ndarray:
    """Prefer OCEANScoreDict (O,C,E,A,N); fallback to OCEANScore scalar/list."""
    ocean_dict = data.get("OCEANScoreDict")
    if isinstance(ocean_dict, dict):
        keys = ["O", "C", "E", "A", "N"]
        if all(k in ocean_dict for k in keys):
            vec = [ocean_dict[k] for k in keys]
        else:
            vec = [ocean_dict[k] for k in sorted(ocean_dict.keys())][:5]
        arr = np.asarray(vec, dtype=np.float32).ravel()
        if arr.shape == (5,):
            return arr

    ocean = data.get("OCEANScore", [0, 0, 0, 0, 0])
    if isinstance(ocean, (int, float)):
        ocean = [float(ocean)] * 5
    arr = np.asarray(ocean, dtype=np.float32).ravel()
    if arr.shape != (5,):
        raise ValueError(f"OCEAN 5-vector missing or wrong shape: {arr.shape}")
    return arr

def _extract_llm_embedding(data: Dict[str, Any], target_dim: int) -> np.ndarray:
    """Prefer 'llmEmbedding' (1536-D). Fallback: flatten 'LLMScore' list/dict; pad/truncate."""
    if isinstance(data.get("llmEmbedding"), list):
        vec = np.asarray(data["llmEmbedding"], dtype=np.float32).ravel()
    else:
        ls = data.get("LLMScore")
        if isinstance(ls, list):
            vec = np.asarray(ls, dtype=np.float32).ravel()
        elif isinstance(ls, dict):
            parts = [np.asarray(ls.get(k, []), dtype=np.float32).ravel() for k in sorted(ls.keys())]
            vec = np.concatenate(parts) if parts else np.zeros(0, dtype=np.float32)
        else:
            vec = np.zeros(0, dtype=np.float32)

    n = vec.shape[0]
    if n == target_dim:
        return vec
    if n > target_dim:
        return vec[:target_dim]
    out = np.zeros((target_dim,), dtype=np.float32)
    out[:n] = vec
    return out

def _squared_distances(points: np.ndarray, x: np.ndarray) -> np.ndarray:
    diff = points - x
    return (diff * diff).sum(axis=1)

# ------------- centroids I/O -------------

def fetch_centroids(bucket_id: str, k_ocean: int, k_llm: int, llm_dim: int) -> Tuple[np.ndarray, np.ndarray]:
    """
    Read centroids from Buckets/{bucket_id}/partitionXY/centroid.
    Returns:
      ocean_c: (k_ocean, 5)      # row centroids (OCEAN)
      llm_c:   (k_llm,  llm_dim) # column centroids (LLM)
    """
    bucket_ref = db.collection("Buckets").document(bucket_id)

    ocean_rows: List[np.ndarray] = []
    for i in range(k_ocean):
        snap = bucket_ref.collection(f"partition{i+1}1").document("centroid").get()
        if not snap.exists:
            raise RuntimeError(f"Missing centroid doc at Buckets/{bucket_id}/partition{i+1}1/centroid")
        data = snap.to_dict() or {}
        ocean = np.asarray(data.get("ocean_centroid", [0]*5), dtype=np.float32).ravel()
        if ocean.shape != (5,):
            raise ValueError(f"ocean_centroid wrong shape in row {i+1}: {ocean.shape}")
        ocean_rows.append(ocean)

    llm_cols: List[np.ndarray] = []
    for j in range(k_llm):
        snap = bucket_ref.collection(f"partition1{j+1}").document("centroid").get()
        if not snap.exists:
            raise RuntimeError(f"Missing centroid doc at Buckets/{bucket_id}/partition1{j+1}/centroid")
        data = snap.to_dict() or {}
        llm = np.asarray(data.get("llm_centroid", [0]*llm_dim), dtype=np.float32).ravel()
        if llm.shape != (llm_dim,):
            raise ValueError(f"llm_centroid wrong shape in col {j+1}: {llm.shape}")
        llm_cols.append(llm)

    return np.stack(ocean_rows, axis=0), np.stack(llm_cols, axis=0)

# ------------- cleanup helpers -------------

def _remove_user_from_bucket_partitions(bucket_id: str, k_ocean: int, k_llm: int, user_id: str) -> None:
    """Idempotency: remove this user's doc from ANY partition under Buckets/{bucket_id}."""
    bref = db.collection("Buckets").document(bucket_id)
    for i in range(k_ocean):
        for j in range(k_llm):
            part = f"partition{i+1}{j+1}"
            dref = bref.collection(part).document(user_id)
            if dref.get().exists:
                dref.delete()

# ------------- single-user assignment -------------

def assign_single_user_to_partition(
    user_id: str,
    user_collection: str = DEFAULT_USER_COLLECTION,
    bucket_id: str = "Stanford_University",
    k_ocean: int = DEFAULT_K_OCEAN,
    k_llm: int = DEFAULT_K_LLM,
    llm_dim: int = DEFAULT_LLM_DIM,
) -> Dict[str, Any]:
    """
    Assign one user to their nearest (i,j) partition for the given bucket.

    Returns:
      {
        "user_id": ...,
        "bucket_id": ...,
        "partition": "partition",
        "distance_sq_ocean": float,
        "distance_sq_llm": float,
        "distance_sq_total": float
      }
    """
    # Fetch user
    useref = db.collection(user_collection).document(user_id)
    snap = useref.get()
    if not snap.exists:
        raise RuntimeError(f"User '{user_id}' not found in collection '{user_collection}'")
    udata = snap.to_dict() or {}

    # Pull centroids
    ocean_c, llm_c = fetch_centroids(bucket_id, k_ocean, k_llm, llm_dim)

    # Build vectors
    ocean = _extract_ocean_5d(udata)                # (5,)
    llm   = _extract_llm_embedding(udata, llm_dim)  # (llm_dim,)

    # Argmin per axis
    d2_o = _squared_distances(ocean_c, ocean)       # (k_ocean,)
    i = int(np.argmin(d2_o))
    d2_l = _squared_distances(llm_c, llm)           # (k_llm,)
    j = int(np.argmin(d2_l))

    part  = f"partition{i+1}{j+1}"
    total = float(d2_o[i] + d2_l[j])

    # Idempotent: remove any prior placement for this user under this bucket
    _remove_user_from_bucket_partitions(bucket_id, k_ocean, k_llm, user_id)

    # Write bucket partition doc (carry lat/lon if present)
    lat = udata.get("lat")
    lon = udata.get("lon")
    payload = {
        "distance_sq_ocean": float(d2_o[i]),
        "distance_sq_llm":   float(d2_l[j]),
        "distance_sq_total": total,
        "user_ref": f"{user_collection}/{user_id}",
        "assigned_at": datetime.now(timezone.utc),
    }
    if isinstance(lat, (int, float)) and isinstance(lon, (int, float)):
        payload["lat"] = float(lat)
        payload["lon"] = float(lon)

    bucket_ref = db.collection("Buckets").document(bucket_id)
    bucket_ref.collection(part).document(user_id).set(payload, merge=True)

    # Update Users/{uid} (global) and mirror on the source collection
    db.collection("Users").document(user_id).set({
        "bucket_id": bucket_id,
        "partition": part,
    }, merge=True)

    db.collection(user_collection).document(user_id).set({
        "bucket_id": bucket_id,
        "partition": part,
        "last_partition_assigned_at": datetime.now(timezone.utc),
    }, merge=True)

    return {
        "user_id": user_id,
        "bucket_id": bucket_id,
        "partition": part,
        "distance_sq_ocean": float(d2_o[i]),
        "distance_sq_llm": float(d2_l[j]),
        "distance_sq_total": total,
    }
