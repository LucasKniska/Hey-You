"""
run_cycle.py
============
Purpose
- Small CLI wrapper to run one matching cycle for a given bucket (university).
- Handy for crons/systemd timers or quick manual runs.

How it fits into HeyU
- Calls run_matching_cycle() from matchmaker.py, which implements the 4 scenarios.

How to run
- Example:
    python -m matching.run_cycle --bucket Columbia_University
- Optional: limit to certain partitions:
    python -m matching.run_cycle --bucket Columbia_University --partitions partition11 partition12
"""

from __future__ import annotations
import argparse
from .matchmaker import run_matching_cycle

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--bucket", required=True, help="University doc id, e.g. 'Columbia_University'")
    ap.add_argument("--partitions", nargs="*", help="Optional list like partition11 partition12")
    args = ap.parse_args()
    run_matching_cycle(args.bucket, args.partitions)

if __name__ == "__main__":
    main()
