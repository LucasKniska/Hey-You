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
from typing import Any, Dict, List, Optional

import argparse
from main import db

from scoreCalcs.matching_algoOCEAN import (
    compute_ocean_average,
    DEFAULT_ITEM_TRAIT_MAP,
    DEFAULT_REVERSE_ITEMS,
)
from scoreCalcs.matching_algoLLM import process_user_profile


# ---------- Helpers (mirrors batch script) ----------
def _answers_text(d: Dict[str, Any]) -> Dict[str, str]:
    # Preferred shape (TestingUsers)
    if isinstance(d.get("answers_text"), dict):
        at = d["answers_text"]
        return {f"q{i}": str(at.get(f"q{i}", "")) for i in range(1, 6)}
    # Fallback shape (Users.quizAnswers mixed types)
    qa = d.get("quizAnswers") or {}
    strings = [v for v in qa.values() if isinstance(v, str)]
    while len(strings) < 5:
        strings.append("")
    return {f"q{i+1}": strings[i] for i in range(5)}


def _ocean_answers(d: Dict[str, Any]) -> List[int]:
    # Preferred (TestingUsers)
    if isinstance(d.get("ocean_answers"), list):
        arr = [int(x) for x in d["ocean_answers"] if isinstance(x, (int, float))]
        return arr[:10]
    # Fallback (Users.quizAnswers numeric)
    qa = d.get("quizAnswers") or {}
    nums = [int(v) for v in qa.values() if isinstance(v, (int, float))]
    return nums[:10]


def _bio_text(d: Dict[str, Any]) -> str:
    return str(d.get("bio") or d.get("biography") or "")


def _coerce_legacy_types(doc_ref, data: Dict[str, Any]) -> None:
    """
    Clear wrong-typed legacy fields so future reads don't break models elsewhere.
    Keeps behavior consistent with your batch updater.
    """
    updates: Dict[str, Optional[Any]] = {}
    if isinstance(data.get("OCEANScore"), list):
        updates["OCEANScore"] = None
    if isinstance(data.get("LLMScore"), dict):
        updates["LLMScore"] = None
    if isinstance(data.get("llmScore"), dict):
        updates["llmScore"] = None
    if updates:
        doc_ref.update(updates)


# ---------- Core ----------
def update_user_scores_for_one(user_id: str, collection: str = "Users") -> None:
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
    _coerce_legacy_types(doc_ref, data)

    bio = _bio_text(data)
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
        "LLMScore": llm_score,         # duplicate for UI/back-compat
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


# ---------- CLI ----------
def _parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Update OCEAN/LLM scores for a single user.")
    p.add_argument("--user-id", required=True, help="Firestore document ID for the user")
    p.add_argument(
        "--collection",
        default="Users",
        help="Firestore collection name (e.g., 'Users' or 'TestingUsers')",
    )
    return p.parse_args()


if __name__ == "__main__":
    args = _parse_args()
    update_user_scores_for_one(args.user_id, collection=args.collection)
