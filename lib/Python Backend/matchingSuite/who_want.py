"""
who_want.py
===========

Implements the "who do you want to meet?" helpers used by matchmaker.py:
- evaluate_who_want(query, candidate_profile_text) -> (bool is_match, str reason, float score)
- upsert_watchlist(user_id, hits)
- has_watchlink(watchlist, other_user_id)
- scan_who_want_and_maybe_switch(...)  (optional end-to-end helper)

LLM can be disabled if OPENAI_API_KEY is not present (or DISABLE_WHO_WANT=1).
"""

from __future__ import annotations
from typing import Tuple, List, Dict, Optional
from datetime import datetime, timezone
from pathlib import Path
import os, json

from dotenv import load_dotenv, find_dotenv
import openai

from main import db
from .partition_switch import (
    parse_partition, format_partition,
    move_user_to_partition, recompute_and_write_centroid_distances,
)

# ----- Grid bounds -----
GRID_I, GRID_J = 4, 5  # i in [1..4], j in [1..5]

# ----- Env / OpenAI setup -----
# 1) Load a root-level .env if present (searches up from CWD)
load_dotenv(find_dotenv(usecwd=True))
# 2) Also load a .env that sits next to this file (matchingSuite/.env)
load_dotenv(Path(__file__).with_name(".env"))

OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
WHO_WANT_ENABLED = bool(OPENAI_API_KEY) and os.getenv("DISABLE_WHO_WANT", "0") != "1"
if OPENAI_API_KEY:
    openai.api_key = OPENAI_API_KEY
else:
    # Soft warning; we don't crash — matchmaker can still run proximity-only.
    print("[who_want] OPENAI_API_KEY not set; who-want checks will be skipped.")

JUDGE_SYSTEM_PROMPT = """
You are a matching judge. Decide if the candidate fits what the user is looking for.
Return STRICT JSON with this schema:

{
  "is_match": true|false,
  "reason": "short, concrete reason (<=40 words)"
}

Guidelines:
- ONLY return JSON, no markdown.
- Be conservative (prefer false) if unsure.
"""

# ---------- LLM call (YES/NO + short reason, optional score) ----------
def evaluate_who_want(query: str, candidate_profile_text: str) -> Tuple[bool, str, float]:
    """
    Returns (is_match, reason, score). When LLM disabled or query empty, returns (False, "", 0.0).
    """
    if not query or not query.strip() or not WHO_WANT_ENABLED:
        return (False, "", 0.0)

    user_prompt = f"User request:\n{query}\n\nCandidate profile:\n{candidate_profile_text}\n"
    try:
        resp = openai.chat.completions.create(
            model="gpt-4o-mini",
            temperature=0.2,
            max_tokens=200,
            messages=[
                {"role": "system", "content": JUDGE_SYSTEM_PROMPT},
                {"role": "user", "content": user_prompt},
            ],
        )
        json_str = resp.choices[0].message.content.strip()
        data = json.loads(json_str)
        is_match = bool(data.get("is_match", False))
        reason = str(data.get("reason", ""))[:300]
        score = 1.0 if is_match else 0.0  # simple binary score (schema compatibility)
        return (is_match, reason, score)
    except Exception:
        # Fail closed (no match)
        return (False, "", 0.0)

# ---------- Watchlist helpers used by matchmaker.py ----------
def upsert_watchlist(user_id: str, hits: List[Dict]) -> None:
    """
    Merge a list of hits into Users/{user_id}.who_watchlist.
    hits: [{user_id, reason, partition?, score?}, ...]
    - De-duplicates by candidate user_id.
    - Updates reason/partition/score and refreshes ts.
    """
    uref = db.collection("Users").document(user_id)
    snap = uref.get()
    now = datetime.now(timezone.utc)

    existing = (snap.to_dict() or {}).get("who_watchlist", [])
    by_uid: Dict[str, Dict] = {}
    for item in existing:
        cid = item.get("user_id")
        if cid:
            by_uid[cid] = dict(item)

    for h in hits:
        cid = h.get("user_id")
        if not cid:
            continue
        entry = by_uid.get(cid, {"user_id": cid})
        if "reason" in h:
            entry["reason"] = h["reason"]
        if "partition" in h:
            entry["partition"] = h["partition"]
        if "score" in h:
            entry["score"] = h["score"]
        entry["ts"] = now
        by_uid[cid] = entry

    # Optional: cap list to avoid unbounded growth (keep most recent 200)
    merged = sorted(by_uid.values(), key=lambda x: x.get("ts", now), reverse=True)[:200]
    uref.set({"who_watchlist": merged}, merge=True)

def has_watchlink(watchlist: List[Dict], other_user_id: str) -> str:
    """
    Return the reason if other_user_id is present in watchlist; else "".
    """
    if not isinstance(watchlist, list):
        return ""
    for item in watchlist:
        if item.get("user_id") == other_user_id:
            return item.get("reason", "") or "watchlist"
    return ""

# ---------- Helpers to list/scan partitions ----------
def _clamp(i: int, lo: int, hi: int) -> int:
    return min(max(i, lo), hi)

def _neighbor_partitions(current_partition: str) -> List[str]:
    """
    Return [current, (i-1,j), (i+1,j), (i,j-1), (i,j+1)] within grid bounds.
    """
    i, j = parse_partition(current_partition)
    parts = set()
    parts.add(format_partition(i, j))
    parts.add(format_partition(_clamp(i-1, 1, GRID_I), j))
    parts.add(format_partition(_clamp(i+1, 1, GRID_I), j))
    parts.add(format_partition(i, _clamp(j-1, 1, GRID_J)))
    parts.add(format_partition(i, _clamp(j+1, 1, GRID_J)))
    return list(parts)

def _list_users_in_partition(bucket_id: str, partition: str) -> List[str]:
    out: List[str] = []
    coll = db.collection("Buckets").document(bucket_id).collection(partition)
    for snap in coll.stream():
        if snap.id != "centroid":
            out.append(snap.id)
    return out

def _get_profile_text(user_id: str) -> str:
    s = db.collection("Users").document(user_id).get()
    d = s.to_dict() or {}
    return d.get("profile_text", d.get("bio", "")) or ""

def _get_query(user_id: str) -> str:
    s = db.collection("Users").document(user_id).get()
    d = s.to_dict() or {}
    return (d.get("who_want_query") or "").strip()

# Keep for the standalone flow (used by some tests/tools)
def _write_watchlist(user_id: str, partition: str, hits: List[Dict]):
    # Reuse upsert but ensure partition is annotated on each hit
    _hits = []
    for h in hits:
        hh = dict(h)
        hh.setdefault("partition", partition)
        _hits.append(hh)
    upsert_watchlist(user_id, _hits)

# ---------- Optional end-to-end helper ----------
def scan_who_want_and_maybe_switch(bucket_id: str, current_partition: str, user_id: str) -> Dict:
    """
    Evaluate 'who you want' across the current partition and the four adjacents.
    Move the user to the partition with the most YES hits (ties -> stay).
    Returns a summary dict.
    """
    query = _get_query(user_id)
    if not query:
        return {
            "scanned_partitions": {},
            "chosen_partition": current_partition,
            "moved": False,
            "note": "No who_want_query set for user; nothing to do."
        }

    parts = _neighbor_partitions(current_partition)

    summary: Dict[str, Dict] = {}
    best_partition = current_partition
    best_count = -1  # ensures current wins ties when equal and first

    for p in parts:
        user_ids = [uid for uid in _list_users_in_partition(bucket_id, p) if uid != user_id]

        hits: List[Dict] = []
        for cand_id in user_ids:
            cand_text = _get_profile_text(cand_id)
            ok, reason, score = evaluate_who_want(query, cand_text)
            if ok:
                hits.append({"user_id": cand_id, "reason": reason, "score": score, "partition": p})

        summary[p] = {"yes_count": len(hits), "hits": hits}

        # Choose partition with max YES; tie -> prefer current_partition
        if len(hits) > best_count or (len(hits) == best_count and p == current_partition):
            best_partition = p
            best_count = len(hits)

    moved = False
    if best_partition != current_partition and best_count > 0:
        move_user_to_partition(bucket_id, current_partition, best_partition, user_id)
        recompute_and_write_centroid_distances(bucket_id, best_partition, user_id)
        moved = True
        _write_watchlist(user_id, best_partition, summary[best_partition]["hits"])
    else:
        _write_watchlist(user_id, current_partition, summary.get(current_partition, {}).get("hits", []))

    return {
        "scanned_partitions": summary,
        "chosen_partition": best_partition,
        "moved": moved
    }
# ... keep your existing imports and constants ...

# ---------- LLM call (YES/NO + short reason, optional score) ----------
def evaluate_who_want(query: str, candidate_profile_text: str) -> Tuple[bool, str, float]:
    """
    Returns (is_match, reason, score). When LLM disabled or query empty, returns (False, "", 0.0).
    """
    if not query or not query.strip() or not WHO_WANT_ENABLED:
        return (False, "", 0.0)

    user_prompt = f"User request:\n{query}\n\nCandidate profile:\n{candidate_profile_text}\n"
    try:
        resp = openai.chat.completions.create(
            model="gpt-4o-mini",
            temperature=0.2,
            max_tokens=200,
            messages=[
                {"role": "system", "content": JUDGE_SYSTEM_PROMPT},
                {"role": "user", "content": user_prompt},
            ],
        )
        json_str = (resp.choices[0].message.content or "").strip()
        # Guard against stray formatting
        if json_str.startswith("```"):
            json_str = json_str.strip("`").strip()
            if json_str.startswith("json"):
                json_str = json_str[4:].strip()
        data = json.loads(json_str)
        is_match = bool(data.get("is_match", False))
        reason = str(data.get("reason", ""))[:300]
        score = 1.0 if is_match else 0.0
        return (is_match, reason, score)
    except Exception:
        return (False, "", 0.0)

# ---------- NEW: single-user, top-K helper ----------
def evaluate_for_user(user_id: str, candidate_ids: List[str], max_candidates: int = 25) -> List[Dict]:
    """
    Evaluate 'who you want' ONLY for a single user against a limited candidate list.
    Returns hits: [{user_id, reason, score}]
    Also upserts the user's who_watchlist with the results.
    """
    query = _get_query(user_id)
    if not query:
        return []

    hits: List[Dict] = []
    for cid in candidate_ids[:max_candidates]:
        if cid == user_id:
            continue
        cand_text = _get_profile_text(cid)
        ok, reason, score = evaluate_who_want(query, cand_text)
        if ok:
            hits.append({"user_id": cid, "reason": reason, "score": score})

    upsert_watchlist(user_id, hits)
    return hits

# ---------- existing helpers and scan_who_want_and_maybe_switch stay unchanged below ----------
# (Keep your _clamp, _neighbor_partitions, _list_users_in_partition, etc.)
