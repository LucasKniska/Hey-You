# TestingFolder/driver_update_scores_testing.py
# ---------------------------------------------
# Ad-hoc tester: sequentially updates LLM/OCEAN for 20 individual users
# in the "TestingUsers" collection, printing the result after each update.
#
# Usage:
#   python TestingFolder/driver_update_scores_testing.py           # default: 20 users
#   python TestingFolder/driver_update_scores_testing.py --n 20    # choose how many
#   python TestingFolder/driver_update_scores_testing.py --only-missing
#   python TestingFolder/driver_update_scores_testing.py --sleep 0.2
#
# Requirements:
# - The single-user driver `update_user_scores_for_one` must be importable.
# - OPENAI_API_KEY must be set in env for LLM embedding/scoring.

from __future__ import annotations
from typing import List
import os, sys, argparse, random, time

# Ensure we can `import main` and the single-user updater from the parent dir
THIS_DIR = os.path.dirname(__file__)
PARENT_DIR = os.path.abspath(os.path.join(THIS_DIR, os.pardir))
if PARENT_DIR not in sys.path:
    sys.path.insert(0, PARENT_DIR)

from main import db
from google.api_core.retry import Retry

# Import the single-user updater we wrote previously
#   from single_user_update import update_user_scores_for_one
try:
    from scoreCalcs.DRIVERscoring import update_user_scores_for_one
except Exception as e:
    print("ERROR: Could not import update_user_scores_for_one from single_user_update.py")
    print("Make sure single_user_update.py is in the parent directory and importable.")
    raise

USER_COLLECTION = "TestingUsers"

def pick_test_users(n: int = 20, only_missing: bool = False) -> List[str]:
    """
    Pick N users from TestingUsers.
    If only_missing=True, prefer users that are missing one or both scores.
    """
    coll = db.collection(USER_COLLECTION)

    if only_missing:
        # Try to bias toward users missing OCEAN/LLM (Firetore doesn't support OR easily,
        # so we do two small pulls and merge).
        q1 = coll.where("OCEANScore", "==", None).limit(n)
        q2 = coll.where("llmScore", "==", None).limit(n)
        ids = {d.id for d in q1.stream(retry=Retry(deadline=120))}
        ids |= {d.id for d in q2.stream(retry=Retry(deadline=120))}
        ids = list(ids)
        if len(ids) < n:
            # Top up with any users
            rest = [d.id for d in coll.limit(n * 2).stream(retry=Retry(deadline=120))]
            for x in rest:
                if x not in ids:
                    ids.append(x)
                if len(ids) >= n:
                    break
        random.shuffle(ids)
        return ids[:n]

    # Default: just grab some users
    docs = list(coll.limit(max(50, n)).stream(retry=Retry(deadline=120)))
    ids = [d.id for d in docs]
    random.shuffle(ids)
    return ids[:n]

def print_scores(user_id: str) -> None:
    """Re-read the document and print the latest OCEAN/LLM scores."""
    snap = db.collection(USER_COLLECTION).document(user_id).get(retry=Retry(deadline=120))
    if not snap.exists:
        print(f"{user_id:>28} → (doc missing)")
        return
    d = snap.to_dict() or {}
    ocean = d.get("OCEANScore")
    llm   = d.get("llmScore")
    dim   = len(d.get("llmEmbedding") or []) if isinstance(d.get("llmEmbedding"), list) else 0
    print(f"{user_id:>28} → OCEAN={ocean} | LLM={llm} | vec_dim={dim}")

def run_testing_driver(n: int = 20, only_missing: bool = False, sleep_s: float = 0.0) -> None:
    user_ids = pick_test_users(n=n, only_missing=only_missing)
    if not user_ids:
        print("No users found in TestingUsers.")
        return

    print(f"Running single-user score updates for {len(user_ids)} users...\n")
    for i, uid in enumerate(user_ids, start=1):
        try:
            # 1) Update one user at a time
            update_user_scores_for_one(uid, collection=USER_COLLECTION)
            # 2) Re-read and print fresh values
            print(f"[{i:02d}/{len(user_ids):02d}]", end=" ")
            print_scores(uid)
        except Exception as e:
            print(f"[{i:02d}/{len(user_ids):02d}] {uid:>28} → ERROR: {e}")
        if sleep_s > 0:
            time.sleep(sleep_s)

def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Test: update LLM/OCEAN scores one user at a time (20 runs).")
    p.add_argument("--n", type=int, default=20, help="How many users to process (default 20).")
    p.add_argument("--only-missing", action="store_true",
                   help="Prefer users missing OCEANScore or llmScore.")
    p.add_argument("--sleep", type=float, default=0.0, help="Seconds to sleep between users.")
    return p.parse_args()

if __name__ == "__main__":
    args = parse_args()
    run_testing_driver(n=max(1, min(50, args.n)), only_missing=args.only_missing, sleep_s=args.sleep)
