# testing/seed_testing_users.py
"""
seed_testing_users.py
=====================

Purpose
- Create a sandbox collection in Firestore named "TestingUsers" filled with realistic test data.

What it writes
- Collection: TestingUsers/{user_id}
  Fields per doc:
    - bio: str
    - answers_text: { "q1": str, "q2": str, "q3": str, "q4": str, "q5": str }
    - ocean_answers: [int, ...]  # length 10, values 1..7
    - who_want_query: str (may be empty)
    - created_at: Firestore timestamp

How this fits into HeyU
- Use these users to exercise your downstream pipelines (profile processing, embeddings,
  OCEAN scoring, partitioning, and matching). This script does NOT assign partitions
  or write to Buckets; it only creates raw test users in "TestingUsers".

How to run
- From your project root (where `main.py` is importable):
    python -m testing.seed_testing_users --n 100
- Optional args:
    --collection TestingUsers   # change target collection name
    --prefix tuser              # document id prefix
    --seed 42                   # RNG seed for reproducibility
"""


from __future__ import annotations
import sys, os

# Go up one directory from TestingFolder to reach Python Backend
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from main import db


import argparse
import random
from datetime import datetime, timezone
from typing import List, Dict

import numpy as np

# Firestore handle from your project
from main import db


FIVE_QUESTIONS = [
    "What are you studying or working on right now?",
    "What do you like to do for fun?",
    "What's something you’re passionate about?",
    "Favorite places to hang out near campus?",
    "What are you hoping to find on HeyU?",
]

# Short bios to sample from
BIO_SNIPPETS = [
    "CS undergrad who loves coffee walks and side projects.",
    "Film buff and late‑night diner explorer.",
    "Entrepreneurial, into hackathons and building MVPs.",
    "Basketball + pickup games; always down for a run.",
    "Bookworm, museum-hopper, and weekend baker.",
    "Vegan foodie hunting the best falafel in the city.",
    "Guitar, indie music, and chill campus hangs.",
    "Robotics & machine learning nerd; podcasts on 2x speed.",
    "Photography + long walks around the park.",
    "Board games, trivia nights, and D&D campaigns.",
]

# Answer fragments for the 5 text questions
TEXT_ANSWERS_POOL = {
    "q1": [
        "Working on a computer vision project.",
        "Studying economics and data science.",
        "TA for intro psychology; researching habit formation.",
        "Finishing a short documentary for a film class.",
    ],
    "q2": [
        "Pick-up basketball and gym sessions.",
        "Coffee tastings and trying new cafes.",
        "Board games and weekly trivia.",
        "Running in the park and photography.",
    ],
    "q3": [
        "Accessible education and mentorship.",
        "Sustainable food systems.",
        "Open-source software and communities.",
        "Storytelling through film and writing.",
    ],
    "q4": [
        "The campus green and the library steps.",
        "Riverside Park and the farmer’s market.",
        "Student center lounge and nearby diners.",
        "Local museums and indie theaters.",
    ],
    "q5": [
        "New friends to study and hang with.",
        "People to build side projects with.",
        "Movie buddies and cafe partners.",
        "Basketball teammates and gym partners.",
    ],
}

# Optional "who do you want to meet" prompts
WHO_WANT_POOL = [
    "someone who loves chess and coffee near campus",
    "basketball fans for pickup games this week",
    "film lovers who watch indie movies",
    "vegans who know great falafel spots",
    "people who want to build startup ideas",
    "fellow photographers for weekend walks",
    "board gamers for weekly sessions",
]


def sample_text_answers(rng: random.Random) -> Dict[str, str]:
    # For each of the 5 questions, pick an answer snippet
    answers = {}
    for i in range(5):
        key = f"q{i+1}"
        answers[key] = rng.choice(TEXT_ANSWERS_POOL[key])
    return answers


def sample_ocean_answers(rng: random.Random) -> List[int]:
    # 10 Likert answers 1..7; we bias slightly toward mid/high to look realistic
    return [int(rng.choices(range(1, 8), weights=[1, 2, 3, 4, 3, 2, 1])[0]) for _ in range(10)]


def make_user_doc(rng: random.Random, idx: int) -> Dict:
    bio = rng.choice(BIO_SNIPPETS)
    answers_text = sample_text_answers(rng)
    ocean_answers = sample_ocean_answers(rng)
    who = rng.choice(WHO_WANT_POOL) if rng.random() < 0.4 else ""  # ~40% have a query
    return {
        "bio": bio,
        "answers_text": answers_text,
        "ocean_answers": ocean_answers,
        "who_want_query": who,
        "created_at": datetime.now(timezone.utc),
    }


def seed(collection: str, n: int, prefix: str, seed_val: int):
    rng = random.Random(seed_val)
    np.random.seed(seed_val)

    print(f"Writing {n} users to collection '{collection}' with id prefix '{prefix}_'...")
    written = 0
    for i in range(n):
        uid = f"{prefix}_{i+1:03d}"
        doc = make_user_doc(rng, i)
        db.collection(collection).document(uid).set(doc)
        written += 1
        if written % 20 == 0 or written == n:
            print(f"  ✓ {written}/{n}")

    print("✅ Done seeding TestingUsers.")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--collection", default="TestingUsers", help="Target Firestore collection name")
    ap.add_argument("--n", type=int, default=100, help="Number of users to create")
    ap.add_argument("--prefix", default="tuser", help="Document id prefix (e.g., tuser_001)")
    ap.add_argument("--seed", type=int, default=42, help="RNG seed for reproducibility")
    args = ap.parse_args()
    seed(args.collection, args.n, args.prefix, args.seed)


if __name__ == "__main__":
    main()
