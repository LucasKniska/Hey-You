# test_partition_geo_neighbors.py
import sys, os
import random, math
import numpy as np
from typing import List, Dict, Optional
from sklearn.neighbors import BallTree  # haversine support

# Let Python find main.py so we can import its Firestore client
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from main import db
from k_means.buckInAbuck import run_clustering_and_write_partitions

print("START OF SCRIPT")

# --------------------- CONFIG ---------------------
BUCKET_ID        = "Columbia_University"
TEST_USER_COLL   = "UsersKMeans"     # isolated test collection
NUM_FAKE_USERS   = 60                # <- 60 users
TOPK_PRINT       = None              # None = print ALL neighbors in order
RANDOM_SEED      = 42
MIN_USERS_NEEDED = 3                 # <- need at least 3 users to show >1 neighbor
TARGET_EXAMPLES  = 5                 # <- print 5 partitions that satisfy the threshold

# Campus anchors: Columbia and NYU
COLUMBIA = (40.80754, -73.96254)
NYU      = (40.72951, -73.99646)

# --------------------- GEO HELPERS ---------------------
EARTH_RADIUS_M = 6_371_009  # meters

def _rad(lat: float, lon: float):
    return np.radians([lat, lon])

def build_tree(users: List[Dict]) -> BallTree:
    """Build a BallTree on user coords (in radians) with haversine metric."""
    coords = np.array([_rad(u["lat"], u["lon"]) for u in users], dtype=float)
    return BallTree(coords, metric="haversine")

def haversine_m(rad: np.ndarray) -> np.ndarray:
    """Convert arc distance (radians on unit sphere) to meters."""
    return rad * EARTH_RADIUS_M

def neighbors_by_geo_distance(
    idx: int,
    users: List[Dict],
    tree: BallTree,
    topk: Optional[int] = None,
) -> List[Dict]:
    """
    EXACT return shape your locationMatching.py will use:
    [{ 'user_id': str, 'distance_m': float }, ...]
    """
    n = len(users)
    if n <= 1:
        return []

    k = n if topk is None else min(n, topk + 1)  # include self then drop it
    tgt = users[idx]
    dist_rad, nbr_idx = tree.query([_rad(tgt["lat"], tgt["lon"])], k=k)
    dist_m = haversine_m(dist_rad[0])
    order = nbr_idx[0]

    result = []
    for j, d in zip(order, dist_m):
        if j == idx:
            continue  # skip self
        result.append({"user_id": users[j]["user_id"], "distance_m": float(d)})
    return result

# --------------------- FIRESTORE UTILS ---------------------
def load_partition_users(bucket_id: str, partition: str) -> List[Dict]:
    """
    Reads real users (skips 'centroid') from: Buckets/{bucket_id}/{partition}/*
    Requires 'lat' and 'lon'.
    """
    coll = db.collection("Buckets").document(bucket_id).collection(partition)
    users = []
    for snap in coll.stream():
        if snap.id == "centroid":
            continue
        data = snap.to_dict() or {}
        lat, lon = data.get("lat"), data.get("lon")
        if isinstance(lat, (int, float)) and isinstance(lon, (int, float)):
            users.append({"user_id": snap.id, "lat": float(lat), "lon": float(lon)})
    return users

def copy_lat_lon_into_partitions(bucket_id: str):
    """
    Copy 'lat'/'lon' from UsersKMeans/{user_id} into each partition doc (skips 'centroid').
    """
    latlon = {}
    for u in db.collection(TEST_USER_COLL).stream():
        d = u.to_dict() or {}
        latlon[u.id] = {"lat": d.get("lat"), "lon": d.get("lon")}

    partitions = [f"partition{i+1}{j+1}" for i in range(4) for j in range(5)]
    bucket_ref = db.collection("Buckets").document(bucket_id)

    updated = 0
    for p in partitions:
        coll = bucket_ref.collection(p)
        for snap in coll.stream():
            uid = snap.id
            if uid == "centroid":
                continue
            ll = latlon.get(uid)
            if not ll:
                continue
            lat, lon = ll.get("lat"), ll.get("lon")
            if isinstance(lat, (int, float)) and isinstance(lon, (int, float)):
                coll.document(uid).set({"lat": float(lat), "lon": float(lon)}, merge=True)
                updated += 1
    print(f"✓ Copied lat/lon into partition docs for {updated} users.")

# --------------------- NYC-RANGE FAKE DATA ---------------------
def meters_to_deg_lat(m: float) -> float:
    # ~111_320 meters per degree of latitude
    return m / 111_320.0

def meters_to_deg_lon(m: float, at_lat_deg: float) -> float:
    # ~111_320 * cos(lat) meters per degree of longitude
    return m / (111_320.0 * math.cos(math.radians(at_lat_deg)))

def random_offset_around(lat0: float, lon0: float, r_min_m: float = 300.0, r_max_m: float = 5000.0):
    """
    Uniformly sample a distance in [r_min_m, r_max_m] and a heading in [0, 2π),
    then convert to degree offsets around (lat0, lon0).
    """
    r = random.uniform(r_min_m, r_max_m)
    theta = random.uniform(0.0, 2.0 * math.pi)
    # small-angle approximation on a local tangent plane
    dlat = meters_to_deg_lat(r * math.sin(theta))
    dlon = meters_to_deg_lon(r * math.cos(theta), at_lat_deg=lat0)
    return lat0 + dlat, lon0 + dlon

def random_lat_lon_columbia_or_nyu(p_columbia: float = 0.5):
    """
    50/50 split between Columbia and NYU, with 0.3–5.0 km jitter.
    """
    if random.random() < p_columbia:
        return random_offset_around(*COLUMBIA, r_min_m=300, r_max_m=5000)
    else:
        return random_offset_around(*NYU, r_min_m=300, r_max_m=5000)

# --------------------- COHORTED FAKE PROFILES ---------------------
def make_cohort_centers(seed: int = 123):
    """
    Create 5 stable cohort centers for OCEAN (5-d) and LLM (50-d).
    Keeping variance small pushes k-means to group cohorts together,
    which yields multi-user partitions.
    """
    rng = np.random.default_rng(seed)
    ocean_centers = rng.uniform(0.2, 0.8, size=(5, 5)).astype(np.float32)
    llm_centers   = rng.normal(0.0, 0.5, size=(5, 50)).astype(np.float32)
    return ocean_centers, llm_centers

def sample_user_from_cohort(ocean_c: np.ndarray, llm_c: np.ndarray, rng: np.random.Generator):
    """
    Sample OCEAN/LLM vectors near the cohort centers.
    """
    ocean = np.clip(ocean_c + rng.normal(0, 0.05, size=ocean_c.shape), 0.0, 1.0)
    llm   = llm_c + rng.normal(0, 0.1, size=llm_c.shape)
    # Package LLM into your 5 fields of 10 dims each
    llm_fields = {}
    for j in range(5):
        start = j * 10
        llm_fields[f"field{j+1}"] = llm[start:start+10].tolist()
    return ocean.tolist(), llm_fields

# --------------------- MAIN TEST FLOW ---------------------
def main():
    random.seed(RANDOM_SEED)
    np.random.seed(RANDOM_SEED)

    # 1) Create fake users (tuserXX) with 5 cohesive cohorts
    print(f"Writing {NUM_FAKE_USERS} fake users into {TEST_USER_COLL}…")
    ocean_centers, llm_centers = make_cohort_centers(seed=31415)
    rng = np.random.default_rng(2718)

    # Distribute users roughly evenly across 5 cohorts
    per_cohort = [NUM_FAKE_USERS // 5] * 5
    for i in range(NUM_FAKE_USERS % 5):
        per_cohort[i] += 1  # spread the remainder

    uid_counter = 0
    for cohort_idx, count in enumerate(per_cohort):
        for _ in range(count):
            uid_counter += 1
            uid = f"tuser{uid_counter:02d}"
            ocean, llm = sample_user_from_cohort(ocean_centers[cohort_idx], llm_centers[cohort_idx], rng)
            lat, lon = random_lat_lon_columbia_or_nyu()
            db.collection(TEST_USER_COLL).document(uid).set({
                "OCEANScore": ocean,
                "LLMScore": llm,
                "lat": float(lat),
                "lon": float(lon),
            })
            if uid_counter % 10 == 0:
                print(f"  ✓ wrote {uid_counter}/{NUM_FAKE_USERS}")

    print("✅ All fake users written. Running clustering…")

    # 2) Cluster into partitions
    run_clustering_and_write_partitions(user_collection=TEST_USER_COLL)
    print(f"✅ Clustering complete — users placed under Buckets/{BUCKET_ID}/partitionXY")

    # 3) Ensure lat/lon exist on partition docs
    copy_lat_lon_into_partitions(BUCKET_ID)

    # 4) Choose up to 5 partitions with >= MIN_USERS_NEEDED users
    bucket_ref = db.collection("Buckets").document(BUCKET_ID)
    partitions = [f"partition{i+1}{j+1}" for i in range(4) for j in range(5)]

    candidates: list[tuple[str, str]] = []  # (partition, target_user_id)
    for p in partitions:
        part_users = load_partition_users(BUCKET_ID, p)
        if len(part_users) >= MIN_USERS_NEEDED:
            # pick a stable target (first)
            candidates.append((p, part_users[0]["user_id"]))
        if len(candidates) >= TARGET_EXAMPLES:
            break

    if not candidates:
        print(f"⚠️ No partitions with ≥ {MIN_USERS_NEEDED} users found. Try rerunning; cohorts should help.")
    elif len(candidates) < TARGET_EXAMPLES:
        print(f"⚠️ Only found {len(candidates)} partitions with ≥ {MIN_USERS_NEEDED} users; running those.")

    # 5) For each chosen partition/user, compute and print FULL sorted neighbor list
    for p, uid in candidates:
        print(f"\n===== Partition {p} • Target user {uid} =====")
        part_users = load_partition_users(BUCKET_ID, p)
        if len(part_users) < MIN_USERS_NEEDED:
            print("Skipping — not enough users in this partition.")
            continue

        index = {u["user_id"]: i for i, u in enumerate(part_users)}
        if uid not in index:
            print(f"Skipping — target user {uid} missing from partition after filtering.")
            continue

        tree = build_tree(part_users)  # BallTree(haversine)
        rows = neighbors_by_geo_distance(index[uid], part_users, tree, topk=TOPK_PRINT)  # None => ALL

        if len(rows) < 2:
            print("Skipping — need more than one neighbor to show variety.")
            continue

        print(f"Neighbor list returned by neighbors_by_geo_distance (len={len(rows)}):")
        for r in rows:
            print(f"  • {r['user_id']}: {r['distance_m']:.0f} m")

    print("\n✅ Done.")

if __name__ == "__main__":
    main()
