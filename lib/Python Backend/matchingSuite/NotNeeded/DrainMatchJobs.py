from __future__ import annotations
import sys, os, argparse
from datetime import datetime, timezone

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if PROJECT_ROOT not in sys.path:
    sys.path.append(PROJECT_ROOT)

from main import db
from matchingSuite.readyWorker import drain_jobs

def _query_recent_matches(bucket: str, since_ts):
    q = (db.collection("Matches")
           .where("bucket", "==", bucket))
    out = []
    for s in q.stream():
        d = s.to_dict() or {}
        if d.get("created_at") and d["created_at"] >= since_ts:
            d["id"] = s.id
            out.append(d)
    return out

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--bucket", required=True)
    ap.add_argument("--limit", type=int, default=50)
    args = ap.parse_args()

    since = datetime.now(timezone.utc)
    counts = drain_jobs(limit=args.limit)

    matches = _query_recent_matches(args.bucket, since)
    print("\nMAtches")
    if not matches:
        print("  (no new matches created in this drain)")
    else:
        for m in matches:
            print(f"{m['partition']}: {m['users']} reason={m.get('reason','')}")
        print(f"Total: {len(matches)}")

    print("\nDrain summary:", counts)

if __name__ == "__main__":
    main()
