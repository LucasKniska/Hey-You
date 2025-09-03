# locationFinder/geo_neighbors.py
import argparse
from typing import List, Dict, Optional

import numpy as np
from sklearn.neighbors import BallTree

import os, sys
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from auth import db


EARTH_RADIUS_M = 6_371_009  # mean Earth radius (meters)

# ------------- Geo helpers -------------
def _rad(lat: float, lon: float) -> np.ndarray:
    """Degrees -> radians as a 2-vector (float64 for BallTree)."""
    return np.radians([lat, lon]).astype(np.float64)

def build_tree(users: List[Dict]) -> BallTree:
    """Build a BallTree on user coords (in radians) using haversine metric."""
    coords = np.array([_rad(u["lat"], u["lon"]) for u in users], dtype=np.float64)
    # BallTree expects shape (n_samples, n_features) with float64
    return BallTree(coords, metric="haversine")

def haversine_m(rad: np.ndarray) -> np.ndarray:
    """Convert arc distance (radians on unit sphere) to meters."""
    return rad * EARTH_RADIUS_M

# ------------- Firestore I/O -------------
def load_partition_users(bucket_id: str, partition: str) -> List[Dict]:
    """
    Reads: Buckets/{bucket_id}/{partition}/*
    Requires each doc to have doubles 'lat' and 'lon'.
    Returns: [{ 'user_id', 'lat', 'lon' }, ...] (filters out missing/invalid coords)
    """
    coll = db.collection("Buckets").document(bucket_id).collection(partition)
    users: List[Dict] = []
    for snap in coll.stream():
        if snap.id == "centroid":
            continue
        data = snap.to_dict() or {}
        pos = data.get("location")
        if isinstance(pos, dict):
            lat, lon = pos.get("lat", 0), pos.get("long", 0)
        else: 
            lat, lon = 0, 0
        if isinstance(lat, (int, float)) and isinstance(lon, (int, float)):
            users.append({"user_id": snap.id, "lat": float(lat), "lon": float(lon)})
    return users

# ------------- Core ranking -------------
def neighbors_by_geo_distance(
    idx: int,
    users: List[Dict],
    tree: BallTree,
    topk: Optional[int] = None,
) -> List[Dict]:
    """
    Return other users ordered by geographic distance (meters).
    Output: [{ 'user_id': str, 'distance_m': float }, ...]
    - If topk is provided, only the nearest topk neighbors are returned (excluding self).
    """
    n = len(users)
    if n <= 1:
        return []

    # Ask BallTree for k neighbors; include self then drop it
    k = n if topk is None else min(n, topk + 1)  # +1 to include self at distance 0
    tgt = users[idx]
    dist_rad, nbr_idx = tree.query([_rad(tgt["lat"], tgt["lon"])], k=k)
    dist_m = haversine_m(dist_rad[0])
    order = nbr_idx[0]

    result: List[Dict] = []
    for j, d in zip(order, dist_m):
        if j == idx:
            continue  # skip self
        result.append({"user_id": users[j]["user_id"], "distance_m": float(d)})
    return result

def rank_one_user(
    bucket_id: str,
    partition: str,
    target_user_id: str,
    topk: Optional[int] = None,
) -> List[Dict]:
    """Load users from a partition and return neighbors for a single target user."""
    users = load_partition_users(bucket_id, partition)
    index = {u["user_id"]: i for i, u in enumerate(users)}
    if target_user_id not in index:
        raise ValueError(f"User '{target_user_id}' not found in Buckets/{bucket_id}/{partition}")

    tree = build_tree(users)
    return neighbors_by_geo_distance(index[target_user_id], users, tree, topk=topk)

def rank_all_users_by_geo(
    bucket_id: str,
    partition: str,
    topk: Optional[int] = None,
) -> Dict[str, List[Dict]]:
    """
    For every user in Buckets/{bucket_id}/{partition},
    return { user_id: [ {user_id, distance_m}, ... ] } ordered by distance.
    """
    users = load_partition_users(bucket_id, partition)
    results: Dict[str, List[Dict]] = {}
    if len(users) == 0:
        return results
    if len(users) == 1:
        return {users[0]["user_id"]: []}

    tree = build_tree(users)
    for i, u in enumerate(users):
        results[u["user_id"]] = neighbors_by_geo_distance(i, users, tree, topk=topk)
    return results

# ------------- CLI (unchanged) -------------
def _parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Rank users in a partition by geographic distance.")
    p.add_argument("--bucket", required=True, help="Bucket (university) doc ID, e.g. 'Columbia_University'")
    p.add_argument("--partition", required=True, help="Partition name, e.g. 'partition11'")
    g = p.add_mutually_exclusive_group(required=True)
    g.add_argument("--user", help="Target user_id to rank neighbors for (single user).")
    g.add_argument("--all", action="store_true", help="Rank neighbors for all users in the partition.")
    return p.parse_args()

def main():
    result = rank_one_user(bucket_id='Columbia_University', partition='partition11', target_user_id='jiBsMOEwoNgAMYgE7Y6OfwhKgdJ3')
    print("Neighbors for user 'jiBsMOEwoNgAMYgE7Y6OfwhKgdJ3' in {Columbia}/{partition11}:")
    for row in result:
        print(f"  • {row['user_id']}: {row['distance_m']:.2f} m")


if __name__ == "__main__":
    main()
