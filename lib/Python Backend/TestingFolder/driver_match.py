# TestingFolder/driver_match.py
from __future__ import annotations
from typing import List
import os, sys

# Add parent directory (…/Python Backend) to module search path so `import main` works
THIS_DIR = os.path.dirname(__file__)
PARENT_DIR = os.path.abspath(os.path.join(THIS_DIR, os.pardir))
if PARENT_DIR not in sys.path:
    sys.path.insert(0, PARENT_DIR)

from main import db
from matchingSuite.DRIVERmatch import try_match_for_user

USER_COLLECTION = "TestingUsers"  # switch to "Users" in prod

def pick_test_users(n: int = 10) -> List[str]:
    # Users must have bucket_id and partition set
    q = (db.collection(USER_COLLECTION)
           .where("bucket_id", ">", "")
           .limit(n))
    return [d.id for d in q.stream()]

def run_driver(user_ids: List[str]):
    print(f"Running try_match_for_user() for {len(user_ids)} users...")
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
    users = pick_test_users(8)   # choose 5–10 as you like
    run_driver(users)
