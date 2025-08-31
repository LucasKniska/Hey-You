# TestingFolder/RunUpdateUserScores.py
"""
RunUpdateUserScores.py
======================

Purpose
- Test driver that invokes your scoring pipeline to update OCEAN + LLM scores
  for every document in Firestore `Users/`.

Project layout assumption
- This file lives in:        Python Backend/TestingFolder/RunUpdateUserScores.py
- Your calculators live in:  Python Backend/scoreCalcs/...
- The runner lives in:       Python Backend/scripts/update_user_scores.py
- Firestore handle:          Python Backend/main.py  (exports `db`)

What it does
- Adds the parent folder to sys.path so `main`, `scoreCalcs`, and `scripts` are importable.
- Calls `scripts.update_user_scores.main()` which:
    * reads each doc in `Users/`  (expects: bio, answers_text{q1..q5}, ocean_answers[10])
    * writes: OCEANScore, OCEANScoreDict, LLMScore, llmCleanedJSON

How to run
- From the “Python Backend” directory:
    python TestingFolder/RunUpdateUserScores.py

Requirements
- Set OPENAI_API_KEY in your environment (for embeddings + LLM cleaning).
"""

from __future__ import annotations
import sys, os
    
import sys, os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


# Make the project root importable (one level up from TestingFolder)
PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if PROJECT_ROOT not in sys.path:
    sys.path.append(PROJECT_ROOT)

# Import and run the updater
try:
    from scripts.update_user_scores import main as run_update  # type: ignore
except Exception as e:
    raise RuntimeError(
        "Could not import scripts.update_user_scores. "
        "Ensure the file exists at Python Backend/scripts/update_user_scores.py "
        "and that you're running this from the 'Python Backend' folder."
    ) from e

if __name__ == "__main__":
    run_update()
