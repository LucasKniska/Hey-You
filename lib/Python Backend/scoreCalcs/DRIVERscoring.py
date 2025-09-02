# single_user_update.py
# ---------------------
# Updates OCEAN and LLM scores for ONE user document.
# - Reads bio + answers from either TestingUsers (bio, answers_text, ocean_answers)
#   or Users (quizAnswers).
# - Persists floats to OCEANScore and llmScore (plus LLMScore for back-compat),
#   along with llmEmbedding and llmCleanedJSON.
#
# Usage:
#   python single_user_update.py --user-id <DOC_ID> [--collection Users]
#
# Programmatic:
#   from single_user_update import update_user_scores_for_one
#   update_user_scores_for_one("abc123", collection="Users")

from __future__ import annotations
from typing import Any, Dict, List

from scoreCalcs.matching_algoOCEAN import (
    compute_ocean_average,
    DEFAULT_ITEM_TRAIT_MAP,
    DEFAULT_REVERSE_ITEMS,
)
from scoreCalcs.matching_algoLLM import process_user_profile


# ---------- Helpers (mirrors batch script) ----------
def _answers_text(d: Dict[str, Any]) -> Dict[str, str]:
    # Fallback shape (Users.quizAnswers mixed types)
    qa = d.get("QuestionAnswers") or {}
    strings = [v for v in qa.values() if isinstance(v, str)]
    return {f"q{i+1}": each for i, each in enumerate(strings)}


def _ocean_answers(d: Dict[str, Any]) -> List[int]:
    qa = d.get("QuestionAnswers") or {}
    nums = [int(v) for v in qa.values() if isinstance(v, (int, float))]
    return nums

# ---------- Core ----------
def update_user_scores_for_one(user_id: str, db, collection: str = "Users") -> None:
    """
    Loads one user by ID from `collection`, computes OCEAN + LLM, and updates the doc.
    Safe on missing/partial data. Idempotent.
    """
    doc_ref = db.collection(collection).document(user_id)
    snap = doc_ref.get()
    if not snap.exists:
        print(f"✗ {user_id}: no such document in '{collection}'")
        return

    data = snap.to_dict() or {}


    bio = data.get("Biography", "")
    answers_text = _answers_text(data)
    ocean_answers = _ocean_answers(data)

    # OCEAN (float or None if not enough inputs)
    ocean_score = (
        compute_ocean_average(ocean_answers, DEFAULT_ITEM_TRAIT_MAP, DEFAULT_REVERSE_ITEMS)
        if ocean_answers
        else None
    )

    # LLM (float + embedding + cleaned JSON)
    cleaned_json, payload = process_user_profile(
        bio=bio,
        answers_text=answers_text,
        return_only_score=False  # get both score + vector
    )
    llm_score = payload.get("LLMScore", None)
    llm_vec = payload.get("LLMEmbedding", None)

    updates = {
        "OCEANScore": ocean_score,     # float or None
        "llmScore": llm_score,         # float (model-friendly)
        "llmEmbedding": llm_vec,       # list[float] or None
        "llmCleanedJSON": cleaned_json # cleaned JSON from the LLM pass
    }
    doc_ref.update(updates)

    print(
        f"✓ {user_id}: "
        f"OCEAN={ocean_score}, "
        f"LLM={llm_score}, "
        f"vec_dim={len(llm_vec) if isinstance(llm_vec, list) else 0}"
    )
