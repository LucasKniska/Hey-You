# TestingFolder/seed_stanford_locations.py
from __future__ import annotations
import math, os, sys, random
from datetime import datetime, timezone
from typing import List, Tuple

# --- make parent folder importable so "from main import db" works ---
THIS_DIR = os.path.dirname(__file__)
PARENT_DIR = os.path.abspath(os.path.join(THIS_DIR, os.pardir))
if PARENT_DIR not in sys.path:
    sys.path.insert(0, PARENT_DIR)

from main import db  # Firestore client

# ─────────────────────────────────────────────────────────────
# Config
# ─────────────────────────────────────────────────────────────
BUCKET_ID = "Stanford_University"
# Campus center-ish
STANFORD_LAT = 37.42755
STANFORD_LON = -122.170169

# We’ll choose one small “anchor” per partition within ~0.5 mi of campus center,
# then place each user 0.1–2.0 mi from that anchor (uniform bearing).
ANCHOR_MAX_RADIUS_M = int(0.5 * 1609.344)    # ~804 m
USER_MIN_DIST_M     = int(0.1 * 1609.344)    # ~161 m
USER_MAX_DIST_M     = int(2.0 * 1609.344)    # ~3219 m

# Probability a user is immediately ready
READY_PROB = 0.60

# Batch commit size for Firestore
BATCH_SIZE = 400

# ─────────────────────────────────────────────────────────────
# Geo helpers
# ─────────────────────────────────────────────────────────────
EARTH_RADIUS_M = 6_371_009

def destination_point(lat: float, lon: float, bearing_rad: float, distance_m: float) -> Tuple[float, float]:
    """
    Given start lat/lon (deg), initial bearing (rad), and distance (m),
    return the destination (lat, lon) in degrees. Uses great-circle formula.
    """
    lat1 = math.radians(lat)
    lon1 = math.radians(lon)
    ang_dist = distance_m / EARTH_RADIUS_M

    sin_lat1 = math.sin(lat1)
    cos_lat1 = math.cos(lat1)
    sin_ad   = math.sin(ang_dist)
    cos_ad   = math.cos(ang_dist)

    sin_lat2 = sin_lat1 * cos_ad + cos_lat1 * sin_ad * math.cos(bearing_rad)
    lat2 = math.asin(min(1.0, max(-1.0, sin_lat2)))

    y = math.sin(bearing_rad) * sin_ad * cos_lat1
    x = cos_ad - sin_lat1 * sin_lat2
    lon2 = lon1 + math.atan2(y, x)

    # normalize lon to [-180,180)
    lon2 = (lon2 + math.pi) % (2*math.pi) - math.pi
    return (math.degrees(lat2), math.degrees(lon2))

def random_distance_user_m() -> float:
    """
    Draw distance for user placement with more mass in 0.2–1.5 mi,
    but strictly clipped to 0.1–2.0 mi.
    """
    # Sample from a truncated log-normal-ish by rejection for a simple shape
    for _ in range(50):
        # mean ~ 900 m, wide spread
        d = random.lognormvariate(mu=math.log(900), sigma=0.6)
        if USER_MIN_DIST_M <= d <= USER_MAX_DIST_M:
            return d
    # Fallback uniform if rejection fails
    return random.uniform(USER_MIN_DIST_M, USER_MAX_DIST_M)

def random_anchor_near_campus() -> Tuple[float, float]:
    """
    Pick an anchor point within ~0.5 mi of campus center.
    """
    r = random.uniform(0, ANCHOR_MAX_RADIUS_M)
    theta = random.uniform(0, 2*math.pi)
    return destination_point(STANFORD_LAT, STANFORD_LON, theta, r)

# ─────────────────────────────────────────────────────────────
# Firestore operations
# ─────────────────────────────────────────────────────────────
def list_partitions(bucket_id: str) -> List[str]:
    """
    Lists partition subcollection names under Buckets/{bucket_id}.
    We use the "list collections" API on the bucket document.
    """
    bucket_ref = db.collection("Buckets").document(bucket_id)
    return [c.id for c in bucket_ref.collections()]

def seed_partition(bucket_id: str, partition: str) -> Tuple[int, int]:
    """
    Seed one partition: assign lat/lon to each user doc (skip 'centroid'),
    set ~60% ready_to_match, match_state='ready'.
    Returns (updated_docs, ready_count).
    """
    col = db.collection("Buckets").document(bucket_id).collection(partition)

    # Establish a single anchor for this partition so users are close to each other
    anchor_lat, anchor_lon = random_anchor_near_campus()

    docs = list(col.stream())
    docs = [d for d in docs if d.id != "centroid"]  # skip centroid doc
    if not docs:
        return (0, 0)

    now = datetime.now(timezone.utc)
    batch = db.batch()
    updated = 0
    ready_set = 0

    for i, snap in enumerate(docs, start=1):
        uid = snap.id
        # Random point near the anchor
        dist_m  = random_distance_user_m()
        bearing = random.uniform(0, 2*math.pi)
        lat, lon = destination_point(anchor_lat, anchor_lon, bearing, dist_m)

        # 60% ready
        make_ready = (random.random() < READY_PROB)

        ref = col.document(uid)
        payload = {
            "lat": float(lat),
            "lon": float(lon),
            "location_updated_at": now,
            # Leave others untouched unless we set ready
        }
        if make_ready:
            payload.update({
                "ready_to_match": True,
                "match_state": "ready",
                "active_match_id": None,  # clear any stale active
            })
            ready_set += 1

        batch.set(ref, payload, merge=True)
        updated += 1

        # Commit every BATCH_SIZE to avoid Firestore 500-write limit
        if (i % BATCH_SIZE) == 0:
            batch.commit()
            batch = db.batch()

    # final commit
    batch.commit()
    return (updated, ready_set)

def seed_all_stanford() -> None:
    partitions = list_partitions(BUCKET_ID)
    if not partitions:
        print(f"No partitions found under Buckets/{BUCKET_ID}")
        return

    total_docs = 0
    total_ready = 0
    print(f"Seeding {len(partitions)} partitions under Buckets/{BUCKET_ID}...")
    for p in sorted(partitions):
        upd, rdy = seed_partition(BUCKET_ID, p)
        total_docs += upd
        total_ready += rdy
        print(f"  {p:>12}: updated {upd:3d} docs, set ready {rdy:3d}")

    print("-" * 56)
    print(f"TOTAL updated docs: {total_docs}")
    print(f"TOTAL set ready   : {total_ready} (~{(100*total_ready/total_docs if total_docs else 0):.1f}%)")

if __name__ == "__main__":
    random.seed()  # system seed
    seed_all_stanford()
