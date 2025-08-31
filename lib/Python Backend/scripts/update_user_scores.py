"""
update_user_scores.py
---------------------
Batch-updates OCEAN and LLM scores for every doc in a collection.
- Paginates to avoid Firestore gRPC timeouts.
- Writes ONLY floats to OCEANScore and llmScore (also LLMScore for back-compat).
- Works with TestingUsers (bio, answers_text, ocean_answers) and Users (quizAnswers).
"""

from __future__ import annotations
from typing import Any, Dict, List

from main import db
from google.api_core.retry import Retry

from scoreCalcs.matching_algoOCEAN import (
    compute_ocean_average,
    DEFAULT_ITEM_TRAIT_MAP,
    DEFAULT_REVERSE_ITEMS,
)
from scoreCalcs.matching_algoLLM import process_user_profile

BATCH_SIZE = 20
TARGET_COLLECTION = "TestingUsers"  # change to your live collection when ready

# ---------- Helpers ----------
def _answers_text(d: Dict[str, Any]) -> Dict[str, str]:
    if isinstance(d.get("answers_text"), dict):
        at = d["answers_text"]
        return {f"q{i}": str(at.get(f"q{i}", "")) for i in range(1, 6)}
    qa = d.get("quizAnswers") or {}
    strings = [v for v in qa.values() if isinstance(v, str)]
    while len(strings) < 5:
        strings.append("")
    return {f"q{i+1}": strings[i] for i in range(5)}

def _ocean_answers(d: Dict[str, Any]) -> List[int]:
    if isinstance(d.get("ocean_answers"), list):
        arr = [int(x) for x in d["ocean_answers"] if isinstance(x, (int, float))]
        return arr[:10]
    qa = d.get("quizAnswers") or {}
    nums = [int(v) for v in qa.values() if isinstance(v, (int, float))]
    return nums[:10]

def _bio_text(d: Dict[str, Any]) -> str:
    return str(d.get("bio") or d.get("biography") or "")

def _coerce_legacy_types(doc_ref, data: Dict[str, Any]) -> None:
    """Clear wrong-typed legacy fields so future reads don't break models elsewhere."""
    updates = {}
    if isinstance(data.get("OCEANScore"), list):
        updates["OCEANScore"] = None
    if isinstance(data.get("LLMScore"), dict):
        updates["LLMScore"] = None
    if isinstance(data.get("llmScore"), dict):
        updates["llmScore"] = None
    if updates:
        doc_ref.update(updates)

# ---------- Per-doc processing ----------
# scripts/update_user_scores.py (only the parts that changed)

from scoreCalcs.matching_algoLLM import process_user_profile

def process_doc(doc) -> None:
    data = doc.to_dict() or {}

    # ... (same helpers as before to read bio, answers_text, ocean_answers)
    bio = _bio_text(data)
    answers_text = _answers_text(data)
    ocean_answers = _ocean_answers(data)

    # OCEAN float
    ocean_score = compute_ocean_average(ocean_answers, DEFAULT_ITEM_TRAIT_MAP, DEFAULT_REVERSE_ITEMS) \
                  if ocean_answers else None

    # LLM float + embedding + cleaned JSON
    cleaned_json, payload = process_user_profile(
        bio=bio,
        answers_text=answers_text,
        return_only_score=False   # <-- ask for both score + vector
    )
    llm_score = payload.get("LLMScore", None)
    llm_vec   = payload.get("LLMEmbedding", None)  # list[float] or None

    # Write: floats for scores, plus full vector & cleaned JSON
    doc.reference.update({
        "OCEANScore": ocean_score,   # float or None
        "llmScore": llm_score,       # float (model-friendly)
        "LLMScore": llm_score,       # optional duplicate for UI/back-compat
        "llmEmbedding": llm_vec,     # <-- full vector persisted
        "llmCleanedJSON": cleaned_json,
    })
    print(f"✓ {doc.id}: OCEAN={ocean_score}, LLM={llm_score}, vec_dim={len(llm_vec) if llm_vec else 0}")

# ---------- Batch runner ----------
def main():
    coll = db.collection(TARGET_COLLECTION)
    query = coll.limit(BATCH_SIZE)
    last = None

    while True:
        if last:
            query = coll.start_after(last).limit(BATCH_SIZE)
        docs = list(query.stream(retry=Retry(deadline=300)))
        if not docs:
            break
        for snap in docs:
            process_doc(snap)
        last = docs[-1]

if __name__ == "__main__":
    main()
