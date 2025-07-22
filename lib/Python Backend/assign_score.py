import firebase_admin
from firebase_admin import credentials, firestore

from typing import Dict, List
from models.user_model import User
from helpers import build_paragraph          # <-- your helper that builds the text blob
import matching_calculations.matching_algoLLM as cleaner    # extract_profile & embeddings
import matching_calculations.vector_distance as dist        # cosine_sim & profile_similarity

def text_score_fn(user: User) -> float:
    return float(len(user.biography))

def personality_score_fn(my_vec: Dict[str, list], other_vecs: List[Dict[str, list]]) -> float:
    if not other_vecs:
        return 0.0
    sims = [dist.profile_similarity(my_vec, o) for o in other_vecs]
    return sum(sims) / len(sims)

def embed_user(user: User) -> Dict[str, list]:
    paragraph = build_paragraph(user)
    _, vectors = cleaner.process_user_profile(paragraph)
    return vectors

def main():
    if not firebase_admin._apps:
        cred = credentials.Certificate("serviceAccountKey.json")
        firebase_admin.initialize_app(cred)
    db = firestore.client()

    # ----------- CHANGED HERE ----------------
    snapshots = (
        db.collection("Users")
          .where("Discoverable", "==", True)
          .stream()
    )
    # -----------------------------------------

    users: List[User] = []
    for snap in snapshots:
        u = User.from_json(snap.to_dict())
        users.append(u)


    embeds = {u.id: embed_user(u) for u in users}

    for me in users:
        others = [vec for uid, vec in embeds.items() if uid != me.id]
        # personality = personality_score_fn(embeds[me.id], others)
        text_score  = text_score_fn(me)

        db.collection("Users").document(me.id).update({
            # "PersonalityScore": personality,
            "TextScore": text_score
        })
        print(f"{me.id}: Text={text_score:.0f}")

    print("All users scored and updated.")

if __name__ == "__main__":
    main()
