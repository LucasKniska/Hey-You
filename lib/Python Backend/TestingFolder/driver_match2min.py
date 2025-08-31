# TestingFolder/driver_match.py
from __future__ import annotations
from typing import List
import os, sys, random, time

# Add parent directory (…/Python Backend) to module search path so `import main` works
THIS_DIR = os.path.dirname(__file__)
PARENT_DIR = os.path.abspath(os.path.join(THIS_DIR, os.pardir))
if PARENT_DIR not in sys.path:
    sys.path.insert(0, PARENT_DIR)

from google.cloud.firestore_v1 import FieldFilter
from main import db
from matchingSuite.DRIVERmatch import try_match_for_user

USER_COLLECTION = "TestingUsers"  # switch to "Users" in prod


def pick_test_users(n: int) -> List[str]:
    """Pick n random users with bucket_id present."""
    # Pull all IDs first (Firestore limits random access)
    q = db.collection(USER_COLLECTION).where(
        filter=FieldFilter("bucket_id", ">", "")
    )
    all_ids = [d.id for d in q.stream()]
    if len(all_ids) <= n:
        return all_ids
    return random.sample(all_ids, n)


def run_driver(user_ids: List[str]):
    print(f"\nRunning try_match_for_user() for {len(user_ids)} users...")
    results = []
    for uid in user_ids:
        try:
            res = try_match_for_user(user_id=uid)
            print(f"{uid:>28} → matched: {res['matched_user_id']}")
            results.append(res)
        except Exception as e:
            print(f"{uid:>28} → ERROR: {e}")
    return results


if __name__ == "__main__":
    # First batch of 40
    batch1_users = pick_test_users(40)
    run_driver(batch1_users)

    # Wait 5 seconds
    print("\nWaiting 5 seconds before next batch...\n")
    time.sleep(5)

    # Second batch of 40
    batch2_users = pick_test_users(40)
    run_driver(batch2_users)
