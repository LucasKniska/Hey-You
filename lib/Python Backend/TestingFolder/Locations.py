# TestingFolder/SeedPartitionLocations.py
"""
SeedPartitionLocations.py
=========================

Assigns lat/lon to EVERY user doc under Buckets/{bucket}/partitionXY/* (skips 'centroid').
Coordinates are sampled around a center (default: Stanford University) so that:
  - inner ring users fall within 0.1–0.4 miles of center (default ~60% of users)
  - outer ring users fall within 0.6–1.0 miles of center (default ~40% of users)
This helps you test that only pairs within 0.5 miles are matched.

Run (from 'Python Backend'):
  python TestingFolder/SeedPartitionLocations.py --bucket Stanford_University

Optional flags:
  --inner-mi-min 0.1  --inner-mi-max 0.4
  --outer-mi-min 0.6  --outer-mi-max 1.0
  --inner-frac 0.6
  --center-lat 37.4275 --center-lon -122.1697
  --seed 42
  --no-overwrite               # don't change docs that already have lat/lon
  --also-write-users           # also mirror lat/lon into Users/{user_id}
"""

from __future__ import annotations
import sys, os, math, random
from typing import Tuple, Dict
import argparse
import numpy as np

# project root import path
PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if PROJECT_ROOT not in sys.path:
    sys.path.append(PROJECT_ROOT)

from main import db

EARTH_RADIUS_M = 6_371_009.0
MI_TO_M = 1609.344

def _rand_radius_m(rmin_m: float, rmax_m: float) -> float:
    """Sample radius uniformly by AREA in an annulus [rmin, rmax]."""
    if rmax_m <= rmin_m:
        return rmin_m
    u = random.random()
    return math.sqrt(u * (rmax_m**2 - rmin_m**2) + rmin_m**2)

def _dest_point(lat_deg: float, lon_deg: float, distance_m: float, bearing_rad: float) -> Tuple[float, float]:
    """Great-circle destination given start, distance (m), and bearing (rad)."""
    lat1 = math.radians(lat_deg)
    lon1 = math.radians(lon_deg)
    dR   = distance_m / EARTH_RADIUS_M

    sin_lat1, cos_lat1 = math.sin(lat1), math.cos(lat1)
    sin_dR,   cos_dR   = math.sin(dR), math.cos(dR)
    sin_b,    cos_b    = math.sin(bearing_rad), math.cos(bearing_rad)

    sin_lat2 = sin_lat1 * cos_dR + cos_lat1 * sin_dR * cos_b
    lat2 = math.asin(sin_lat2)
    y = sin_b * sin_dR * cos_lat1
    x = cos_dR - sin_lat1 * sin_lat2
    lon2 = lon1 + math.atan2(y, x)

    # normalize lon to [-180, 180)
    lon2 = (lon2 + math.pi) % (2 * math.pi) - math.pi
    return math.degrees(lat2), math.degrees(lon2)

def _iter_partitions(bucket_id: str):
    """Yield partition collection names under the bucket (e.g., 'partition11')."""
    for coll in db.collection("Buckets").document(bucket_id).collections():
        name = coll.id
        if name.startswith("partition"):
            yield name

def seed_partition_locations(
    bucket_id: str,
    center_lat: float,
    center_lon: float,
    inner_min_mi: float,
    inner_max_mi: float,
    outer_min_mi: float,
    outer_max_mi: float,
    inner_frac: float,
    overwrite: bool,
    also_write_users: bool,
    rng_seed: int | None,
) -> Dict[str, int]:
    if rng_seed is not None:
        random.seed(rng_seed)

    inner_min_m = inner_min_mi * MI_TO_M
    inner_max_m = inner_max_mi * MI_TO_M
    outer_min_m = outer_min_mi * MI_TO_M
    outer_max_m = outer_max_mi * MI_TO_M

    bucket_ref = db.collection("Buckets").document(bucket_id)
    summary: Dict[str, int] = {}

    for part in sorted(_iter_partitions(bucket_id)):
        col = bucket_ref.collection(part)
        updated = 0
        inner_ct = 0
        outer_ct = 0

        for snap in col.stream():
            if snap.id == "centroid":
                continue
            data = snap.to_dict() or {}

            if not overwrite and isinstance(data.get("lat"), (int, float)) and isinstance(data.get("lon"), (int, float)):
                continue

            use_inner = random.random() < inner_frac
            if use_inner:
                r = _rand_radius_m(inner_min_m, inner_max_m)
                inner_ct += 1
            else:
                r = _rand_radius_m(outer_min_m, outer_max_m)
                outer_ct += 1

            bearing = random.random() * 2 * math.pi
            lat, lon = _dest_point(center_lat, center_lon, r, bearing)

            col.document(snap.id).set({"lat": float(lat), "lon": float(lon)}, merge=True)
            if also_write_users:
                db.collection("Users").document(snap.id).set({"lat": float(lat), "lon": float(lon)}, merge=True)
            updated += 1

        summary[part] = updated
        print(f"{part}: updated {updated} users (inner={inner_ct}, outer={outer_ct})")

    total = sum(summary.values())
    print(f"\n✓ Done. Total users updated: {total}")
    return summary

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--bucket", default="Stanford_University", help="Bucket doc id under Buckets/")
    ap.add_argument("--center-lat", type=float, default=37.4275, help="Center latitude (deg)")
    ap.add_argument("--center-lon", type=float, default=-122.1697, help="Center longitude (deg)")

    ap.add_argument("--inner-mi-min", type=float, default=0.1)
    ap.add_argument("--inner-mi-max", type=float, default=0.4)
    ap.add_argument("--outer-mi-min", type=float, default=0.6)
    ap.add_argument("--outer-mi-max", type=float, default=1.0)
    ap.add_argument("--inner-frac", type=float, default=0.6, help="Fraction of users placed in inner ring")

    ap.add_argument("--seed", type=int, default=42, help="RNG seed for reproducibility")
    ap.add_argument("--no-overwrite", action="store_true", help="Do not modify docs that already have lat/lon")
    ap.add_argument("--also-write-users", action="store_true", help="Also mirror lat/lon into Users/{user_id}")
    args = ap.parse_args()

    seed_partition_locations(
        bucket_id=args.bucket,
        center_lat=args.center_lat,
        center_lon=args.center_lon,
        inner_min_mi=args.inner_mi_min,
        inner_max_mi=args.inner_mi_max,
        outer_min_mi=args.outer_mi_min,
        outer_max_mi=args.outer_mi_max,
        inner_frac=args.inner_frac,
        overwrite=not args.no_overwrite,
        also_write_users=args.also_write_users,
        rng_seed=args.seed,
    )

if __name__ == "__main__":
    main()
