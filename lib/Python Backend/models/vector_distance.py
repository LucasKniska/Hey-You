import numpy as np

PROFILE_FIELDS = [
    "hometown",
    "hometown_description",
    "career",
    "favorite_animals",
    "favorite_pastimes",
    "religion",
    "favorite_tv_shows_and_movies",
    "values_and_causes",
    "favorite_sport",
    "favorite_food_and_drink",
    "favorite_video_games"
]

def cosine_sim(a, b):
    a = np.array(a)
    b = np.array(b)
    if np.linalg.norm(a) == 0 or np.linalg.norm(b) == 0:
        return 0
    return float(np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b)))

def profile_similarity(userA_vectors, userB_vectors):
    scores = []
    for field in PROFILE_FIELDS:
        vecA = userA_vectors.get(field)
        vecB = userB_vectors.get(field)
        if vecA is not None and vecB is not None:
            sim = cosine_sim(vecA, vecB)
            scores.append(sim)
    if not scores:
        return 0.0  # No comparable fields
    return sum(scores) / len(scores)
