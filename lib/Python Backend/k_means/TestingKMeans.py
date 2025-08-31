import numpy as np
import sys, os

# Let Python find main.py so we can import its Firestore client
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from main import db

from k_means.buckInAbuck import run_clustering_and_write_partitions

print("START OF SCRIPT")

TEST_USER_COLL = "UsersKMeans"          # isolated test collection
NUM_FAKE_USERS = 40

# 1. ── create fake users ─────────────────────────────────────
for i in range(NUM_FAKE_USERS):
    uid = f"testuser{i+1}"
    ocean = np.random.rand(5).tolist()
    llm   = {f"field{j+1}": np.random.rand(10).tolist() for j in range(5)}
    db.collection(TEST_USER_COLL).document(uid).set({
        "OCEANScore": ocean,
        "LLMScore" : llm
    })
    print(f"✓ wrote {uid}")

print("✅ All fake users written. Running clustering…")

# 2. ── run clustering on the *same* collection ───────────────
run_clustering_and_write_partitions(user_collection=TEST_USER_COLL)

print("✅ Clustering complete — centroids stored in "
      "Buckets/Columbia_University/partitionXY/centroid")

# 3. ── list test users for sanity check ──────────────────────
print("Current users in", TEST_USER_COLL)
for doc in db.collection(TEST_USER_COLL).stream():
    print(" •", doc.id)
