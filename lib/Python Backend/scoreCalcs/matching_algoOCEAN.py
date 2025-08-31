"""
matching_algoOCEAN.py
=====================
Purpose
- Compute a single averaged OCEAN score (0..1) from a 10-item Likert questionnaire.

Output
- single float: average across all traits
"""

from __future__ import annotations
from typing import List, Dict, Set

TRAITS = ["O", "C", "E", "A", "N"]

def _clamp(v: float, lo: float, hi: float) -> float:
    return max(lo, min(hi, v))

def _normalize(ans: int, reverse: bool, lo: int = 1, hi: int = 7) -> float:
    ans = int(_clamp(ans, lo, hi))
    num = (hi - ans) if reverse else (ans - lo)
    return num / (hi - lo)

def compute_ocean_average(
    answers: List[int],
    item_trait_map: Dict[int, str],
    reverse_items: Set[int]
) -> float:
    """
    Returns a single averaged OCEAN score (float 0..1)
    """
    sums = {t: 0.0 for t in TRAITS}
    counts = {t: 0 for t in TRAITS}

    for idx, ans in enumerate(answers):
        trait = item_trait_map.get(idx)
        if trait not in TRAITS:
            continue
        rev = idx in reverse_items
        val = _normalize(ans, reverse=rev)
        sums[trait] += val
        counts[trait] += 1

    means = [sums[t] / counts[t] if counts[t] else 0.5 for t in TRAITS]
    return sum(means) / len(means)  # single average score

# Defaults
DEFAULT_ITEM_TRAIT_MAP = {
    0: "O", 1: "C",
    2: "E", 3: "A",
    4: "N", 5: "O",
    6: "C", 7: "E",
    8: "A", 9: "N",
}
DEFAULT_REVERSE_ITEMS = {1, 4, 7}
