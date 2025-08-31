#We are no longer utilizing this way of calculating similarities


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



def ocean_compatibility(userA, userB, weights=None):
    """userA, userB: vectors [O, C, E, A, N], each 0–1 floats
       weights: list of 5 floats, sum to 1.0"""
    if weights is None:
        weights = [0.2] * 5
    dist_sq = sum(w * (a - b) ** 2 for w, a, b in zip(weights, userA, userB))
    score = 1 - dist_sq ** 0.5
    return score

def total_compatibility_score(userA_vectors, userB_vectors, userA_ocean, userB_ocean,
                              llm_weight=0.6, ocean_weight=0.4, ocean_weights=None):
    """
    userA_vectors, userB_vectors: dicts of profile field embeddings
    userA_ocean, userB_ocean: lists [O, C, E, A, N], floats 0–1
    llm_weight, ocean_weight: how much to weight each component (should sum to 1.0)
    ocean_weights: optional, for OCEAN weighting
    """
    llm_sim = profile_similarity(userA_vectors, userB_vectors)
    ocean_sim = ocean_compatibility(userA_ocean, userB_ocean, weights=ocean_weights)
    total = llm_weight * llm_sim + ocean_weight * ocean_sim
    return total

# Example usage (assume you have these vectors ready, e.g., from OpenAI API + your quiz function):
# userA_vectors = {...}    # output of get_profile_embeddings
# userB_vectors = {...}
# userA_ocean = [0.8, 0.6, 0.7, 0.4, 0.9]
# userB_ocean = [0.9, 0.7, 0.6, 0.4, 0.8]
# score = total_compatibility_score(userA_vectors, userB_vectors, userA_ocean, userB_ocean)
