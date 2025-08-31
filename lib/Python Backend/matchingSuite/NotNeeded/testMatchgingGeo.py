import math
import numpy as np
import pytest

from .matchingGeo import build_tree, neighbors_by_geo_distance, _rad, haversine_m, EARTH_RADIUS_M

def brute_force_order(users, idx):
    """Compute neighbor order and distances with a pure haversine formula (meters)."""
    # Convert to radians
    pts = np.array([_rad(u["lat"], u["lon"]) for u in users], dtype=float)
    lat0, lon0 = pts[idx]
    # Haversine formula
    dlat = pts[:, 0] - lat0
    dlon = pts[:, 1] - lon0
    a = np.sin(dlat/2.0)**2 + np.cos(lat0)*np.cos(pts[:,0])*(np.sin(dlon/2.0)**2)
    c = 2.0 * np.arctan2(np.sqrt(a), np.sqrt(1.0 - a))  # radians
    d_m = haversine_m(c)  # meters

    # Exclude self and sort
    ids = list(range(len(users)))
    ids.remove(idx)
    ids_sorted = sorted(ids, key=lambda j: d_m[j])
    return ids_sorted, d_m

def test_single_user_returns_empty():
    users = [{"user_id": "A", "lat": 0.0, "lon": 0.0}]
    tree = build_tree(users)
    assert neighbors_by_geo_distance(0, users, tree) == []

def test_two_users_mutual_distances():
    users = [
        {"user_id": "A", "lat": 0.0, "lon": 0.0},
        {"user_id": "B", "lat": 0.0, "lon": 1.0},  # ~111 km east
    ]
    tree = build_tree(users)

    a_neighbors = neighbors_by_geo_distance(0, users, tree)
    b_neighbors = neighbors_by_geo_distance(1, users, tree)

    assert len(a_neighbors) == 1 and a_neighbors[0]["user_id"] == "B"
    assert len(b_neighbors) == 1 and b_neighbors[0]["user_id"] == "A"

    # Sanity: 1 degree of longitude at equator ≈ 111.32 km
    # Haversine will give close to that; use a tolerance.
    approx_km = a_neighbors[0]["distance_m"] / 1000.0
    assert 100.0 < approx_km < 120.0

def test_sorted_and_excludes_self():
    users = [
        {"user_id": "A", "lat": 40.7128, "lon": -74.0060},   # NYC
        {"user_id": "B", "lat": 40.7306, "lon": -73.9352},   # NYC (close)
        {"user_id": "C", "lat": 34.0522, "lon": -118.2437},  # LA (far)
    ]
    tree = build_tree(users)
    res = neighbors_by_geo_distance(0, users, tree)

    # Should return B then C
    assert [r["user_id"] for r in res] == ["B", "C"]
    assert res[0]["distance_m"] < res[1]["distance_m"]
    # No self
    assert all(r["user_id"] != "A" for r in res)

def test_units_are_meters_reasonable_scale():
    # NYC → LA ≈ 3930–3960 km along great-circle
    users = [
        {"user_id": "NYC", "lat": 40.7128, "lon": -74.0060},
        {"user_id": "LA",  "lat": 34.0522, "lon": -118.2437},
    ]
    tree = build_tree(users)
    res = neighbors_by_geo_distance(0, users, tree)
    km = res[0]["distance_m"] / 1000.0
    assert 3800.0 < km < 4100.0

@pytest.mark.parametrize("n,seed", [(25, 0), (50, 42)])
def test_matches_bruteforce_order(n, seed):
    # Random lat/lon, compare BallTree ordering vs brute force
    rng = np.random.default_rng(seed)
    lats = rng.uniform(-80, 80, size=n)
    lons = rng.uniform(-180, 180, size=n)
    users = [{"user_id": f"U{i}", "lat": float(lat), "lon": float(lon)} for i, (lat, lon) in enumerate(zip(lats, lons))]

    tree = build_tree(users)
    idx = rng.integers(0, n)
    res = neighbors_by_geo_distance(idx, users, tree)
    order_balltree = [next(j for j,u in enumerate(users) if u["user_id"] == r["user_id"]) for r in res]

    order_brute, d_m = brute_force_order(users, idx)

    # Allow tiny deviations only if exact ties occur; otherwise must match exactly
    assert order_balltree == order_brute

def test_near_ties_are_handled_stably():
    # Place two points ~equidistant from origin point
    base = {"user_id": "O", "lat": 0.0, "lon": 0.0}
    a = {"user_id": "A", "lat": 0.0, "lon": 1.0}
    b = {"user_id": "B", "lat": 0.0, "lon": 1.000001}
    users = [base, a, b]
    tree = build_tree(users)
    res = neighbors_by_geo_distance(0, users, tree)
    # A should come before B since it’s infinitesimally closer
    assert [r["user_id"] for r in res] == ["A", "B"]
