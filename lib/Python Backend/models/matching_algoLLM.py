import os, openai
import json
from dotenv import load_dotenv

load_dotenv()
openai.api_key = os.getenv("OPENAI_API_KEY")
if not openai.api_key:
    raise RuntimeError("OPENAI_API_KEY environment variable not set")

SYSTEM_PROMPT = """
You are a data-cleaning assistant. 
Extract the user’s information into EXACTLY this JSON schema:

{
  "hometown": str,
  "hometown_description": str,
  "career": str,
  "favorite_animals": str,
  "favorite_pastimes": str,
  "current_mood_meet": str,
  "religion": str,
  "favorite_tv_shows_and_movies": str,
  "values_and_causes": str,
  "favorite_sport": str,
  "favorite_food_and_drink": str,
  "favorite_video_games": str
}
Rules:
• Always return valid JSON, no markdown.
• If a field is unknown, output an empty string.
"""

EMBEDDING_MODEL = "text-embedding-3-small"  # fast & cheap

# Which fields to embed:
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

def extract_profile(raw_text: str):
    resp = openai.chat.completions.create(
        model="gpt-4o-mini",
        temperature=0.2,
        max_tokens=500,
        messages=[
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": raw_text},
        ],
    )
    json_str = resp.choices[0].message.content.strip()
    try:
        data = json.loads(json_str)
    except json.JSONDecodeError as e:
        raise ValueError(f"Bad JSON from model:\n{json_str}") from e
    return data

def get_profile_embeddings(cleaned_profile):
    embeddings = {}
    for field in PROFILE_FIELDS:
        text = cleaned_profile.get(field, "")
        if not text.strip():
            embeddings[field] = None
            continue
        resp = openai.embeddings.create(
            input=text,
            model=EMBEDDING_MODEL,
        )
        embeddings[field] = resp.data[0].embedding
    return embeddings

def process_user_profile(raw_text: str):
    profile = extract_profile(raw_text)
    vectors = get_profile_embeddings(profile)
    return profile, vectors

if __name__ == "__main__":
    # Test single user
    user_blob = """
    I’m from New York City. I love playing with dogs, cats are cool too.
    Career-wise I’m aiming for finance (though engineering is a close second).
    My favorite pastimes include hiking and reading.
    My religion is Catholic. My favorite shows are Breaking Bad and The Office, and my favorite movies are Inception and The Godfather.
    I care deeply about environmental causes and social justice.
    My favorite sport is basketball, and I love sushi and coffee. My favorite video game is The Legend of Zelda.
    """
    profile, vectors = process_user_profile(user_blob)
    print("Cleaned profile:\n", json.dumps(profile, indent=2))
    print("Field embeddings (truncated):\n", {k: v[:5] if v else None for k,v in vectors.items()})
