# test_matching.py
from matching_calculations.matching_algoLLM import process_user_profile
from matching_calculations.DistanceCalculator import profile_similarity

user1 = """
I’m from New York City. I love playing with dogs, cats are cool too.
Career-wise I’m aiming for finance (though engineering is a close second).
My favorite pastimes include hiking and reading.
"""

user2 = """
I’m from Boston. I adore cats, but dogs are fine too.
My current career is in finance.
Hiking is a big hobby, along with cooking and reading.
"""

user3 = """
I’m from Los Angeles. I have no pets.
I’m interested in architecture and urban planning.
I spend my free time painting and cycling.
"""

profiles = []
vectors = []
for u in [user1, user2, user3]:
    p, v = process_user_profile(u)
    profiles.append(p)
    vectors.append(v)

print("User 1 vs User 2 similarity:", profile_similarity(vectors[0], vectors[1]))
print("User 1 vs User 3 similarity:", profile_similarity(vectors[0], vectors[2]))
print("User 2 vs User 3 similarity:", profile_similarity(vectors[1], vectors[2]))
