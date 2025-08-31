"""
matching_algoLLM.py
===================
Purpose
- Clean and embed profile data from (bio + 5 answers).
- Return a robust cleaned JSON and a single float LLMScore (or None).
- Never crash on non-JSON responses from the LLM.

Outputs
- cleaned_json: {
    "by_questions": {
      "studying_working_on","fun_activities","passions","favorite_near_campus","hoping_to_find"
    },
    "semantic_profile": {
      "hometown","hometown_description","career","favorite_animals","favorite_pastimes",
      "current_mood_meet","religion","favorite_tv_shows_and_movies","values_and_causes",
      "favorite_sport","favorite_food_and_drink","favorite_video_games"
    }
  }
- llm_payload: {"LLMScore": float|None}
"""

from __future__ import annotations
import os, json, time, re
from typing import Dict, Tuple, Optional

from dotenv import load_dotenv
import openai

load_dotenv()
openai.api_key = os.getenv("OPENAI_API_KEY")
if not openai.api_key:
    raise RuntimeError("OPENAI_API_KEY environment variable not set")

EMBEDDING_MODEL = "text-embedding-3-small"

QUESTION_KEYS = {
    "q1": "studying_working_on",
    "q2": "fun_activities",
    "q3": "passions",
    "q4": "favorite_near_campus",
    "q5": "hoping_to_find",
}

SCHEMA_EMPTY = {
    "by_questions": {
        "studying_working_on": "",
        "fun_activities": "",
        "passions": "",
        "favorite_near_campus": "",
        "hoping_to_find": "",
    },
    "semantic_profile": {
        "hometown": "",
        "hometown_description": "",
        "career": "",
        "favorite_animals": "",
        "favorite_pastimes": "",
        "current_mood_meet": "",
        "religion": "",
        "favorite_tv_shows_and_movies": "",
        "values_and_causes": "",
        "favorite_sport": "",
        "favorite_food_and_drink": "",
        "favorite_video_games": "",
    },
}

SYSTEM_PROMPT = """
You are a careful data cleaner. Return ONLY valid JSON matching this schema:

{
  "by_questions": {
    "studying_working_on": str,
    "fun_activities": str,
    "passions": str,
    "favorite_near_campus": str,
    "hoping_to_find": str
  },
  "semantic_profile": {
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
}

Rules:
- Output JSON **only** (no prose, no markdown).
- All fields must be present. If unknown, use "".
- Keep answers concise; do not invent facts.
"""

def _mk_user_prompt(bio: str, answers_text: Dict[str, str]) -> str:
    return (
        f"User BIO:\n{(bio or '').strip()}\n\n"
        "Their answers to five questions:\n"
        f"Q1 (studying/working on): {answers_text.get('q1','')}\n"
        f"Q2 (fun activities): {answers_text.get('q2','')}\n"
        f"Q3 (passions): {answers_text.get('q3','')}\n"
        f"Q4 (favorite near campus): {answers_text.get('q4','')}\n"
        f"Q5 (hoping to find): {answers_text.get('q5','')}\n"
        "\nReturn ONLY the JSON."
    )

def _force_shape(d: Dict) -> Dict:
    """Ensure required keys exist and are strings."""
    out = json.loads(json.dumps(SCHEMA_EMPTY))  # deep copy
    try:
        bq = d.get("by_questions", {}) or {}
        sp = d.get("semantic_profile", {}) or {}
    except Exception:
        return out
    for k in out["by_questions"]:
        v = bq.get(k, "")
        out["by_questions"][k] = v if isinstance(v, str) else str(v or "")
    for k in out["semantic_profile"]:
        v = sp.get(k, "")
        out["semantic_profile"][k] = v if isinstance(v, str) else str(v or "")
    return out

def _extract_json_loose(text: str) -> Optional[Dict]:
    """Try to pull the first {...} blob; tolerate extra prose."""
    if not text:
        return None
    m = re.search(r"\{.*\}", text, flags=re.DOTALL)
    if not m:
        return None
    try:
        return json.loads(m.group(0))
    except Exception:
        return None

def _chat_clean_json(bio: str, answers_text: Dict[str, str], retries: int = 1) -> Dict:
    user_prompt = _mk_user_prompt(bio, answers_text)
    for attempt in range(retries + 1):
        try:
            resp = openai.chat.completions.create(
                model="gpt-4o-mini",
                temperature=0.1,
                max_tokens=700,
                messages=[
                    {"role": "system", "content": SYSTEM_PROMPT},
                    {"role": "user", "content": user_prompt},
                ],
            )
            content = (resp.choices[0].message.content or "").strip()
        except Exception:
            content = ""

        # Strict parse first
        try:
            d = json.loads(content)
            return _force_shape(d)
        except Exception:
            # Loose parse fallback
            d2 = _extract_json_loose(content)
            if d2 is not None:
                return _force_shape(d2)

        if attempt < retries:
            time.sleep(0.4)

    # Final fallback: empty schema
    return json.loads(json.dumps(SCHEMA_EMPTY))

def _embed(text: str) -> Optional[list]:
    t = (text or "").strip()
    if not t:
        return None
    try:
        r = openai.embeddings.create(input=t, model=EMBEDDING_MODEL)
        return r.data[0].embedding
    except Exception:
        return None

# scoreCalcs/matching_algoLLM.py
def process_user_profile(
    bio: str,
    answers_text: Dict[str, str],
    return_only_score: bool = True
) -> Tuple[Dict, Dict[str, Optional[float | list]]]:
    """
    Returns:
      cleaned_json,
      {"LLMScore": float|None, "LLMEmbedding": list[float]|None}  # LLMEmbedding present when return_only_score=False
    """
    cleaned = _chat_clean_json(bio, answers_text)

    # Combined text to get one vector for storage & future similarity
    combined = " ".join([bio or ""] + [answers_text.get(f"q{i}", "") for i in range(1,6)])
    vec = _embed(combined)  # may be None on failure

    # Derive a lightweight scalar score (placeholder heuristic)
    if vec:
        mean_abs = sum(abs(x) for x in vec) / len(vec)
        score = float(min(1.0, mean_abs / 0.1))
    else:
        score = None

    if return_only_score:
        return cleaned, {"LLMScore": score}

    # Return both score and vector if requested
    return cleaned, {"LLMScore": score, "LLMEmbedding": vec}
