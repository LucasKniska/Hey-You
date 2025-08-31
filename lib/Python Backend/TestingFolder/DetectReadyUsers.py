# TestingFolder/DetectReadyUsers.py
"""
DetectReadyUsers.py
===================

Quick utilities to detect users with ready_to_match=True.

Run (from 'Python Backend'):
  # 1) Scan once: list all ready users
  python TestingFolder/DetectReadyUsers.py --bucket Stanford_University --scan

  # 2) Check specific users (comma-separated)
  python TestingFolder/DetectReadyUsers.py --bucket Stanford_University --check tuser_007,tuser_042

  # 3) Watch for flips live (Ctrl+C to stop)
  python TestingFolder/DetectReadyUsers.py --bucket Stanford_University --watch
"""

from __future__ import annotations
import sys, os, argparse, threading, time
from typing import List, Tuple, Optional, Dict, Any

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if PROJECT_ROOT not in sys.path:
    sys.path.append(PROJECT_ROOT)

from main import db

def _iter_partitions(bucket: str) -> List[str]:
    parts = []
    bref = db.collection("Buckets").document(bucket)
    for coll in bref.collections():
        pid = coll.id
        if pid.startswith("partition"):
            parts.append(pid)
    return sorted(parts)

def _find_user_partition(bucket: str, uid: str) -> Optional[str]:
    bref = db.collection("Buckets").document(bucket)
    for pid in _iter_partitions(bucket):
        if bref.collection(pid).document(uid).get().exists:
            return pid
    return None

def _scan_ready(bucket: str) -> List[Tuple[str, str]]:
    """Return [(partition, user_id), ...] where ready_to_match=True and not centroid."""
    out: List[Tuple[str, str]] = []
    bref = db.collection("Buckets").document(bucket)
    for pid in _iter_partitions(bucket):
        col = bref.collection(pid)
        for snap in col.stream():
            if snap.id == "centroid":
                continue
            d = snap.to_dict() or {}
            if bool(d.get("ready_to_match", False)):
                out.append((pid, snap.id))
    return out

def scan_once(bucket: str) -> None:
    ready = _scan_ready(bucket)
    print(f"▶ Ready users in {bucket}: {len(ready)} found\n")
    if not ready:
        print("(none)")
        return
    for pid, uid in ready:
        print(f"  {pid}/{uid}")

def check_users(bucket: str, user_ids: List[str]) -> None:
    print(f"▶ Checking {len(user_ids)} user(s) in {bucket}\n")
    for uid in user_ids:
        part = _find_user_partition(bucket, uid)
        if not part:
            print(f"  {uid}: NOT FOUND in any partition")
            continue
        d = (db.collection("Buckets").document(bucket)
                 .collection(part).document(uid).get().to_dict() or {})
        print(f"  {uid}: partition={part}  ready_to_match={bool(d.get('ready_to_match', False))}")

def watch_flips(bucket: str) -> None:
    print(f"▶ Watching {bucket} for ready_to_match flips (Ctrl+C to stop)...")
    listeners = []
    stop = threading.Event()

    def attach(pid: str):
        col = db.collection("Buckets").document(bucket).collection(pid)
        def on_snapshot(col_snapshot, changes, read_time):
            for ch in changes:
                doc = ch.document
                if doc.id == "centroid":
                    continue
                d = doc.to_dict() or {}
                if "ready_to_match" in d:
                    print(f"  [{pid}/{doc.id}] ready_to_match -> {bool(d.get('ready_to_match'))}")
        return col.on_snapshot(on_snapshot)

    try:
        for pid in _iter_partitions(bucket):
            listeners.append(attach(pid))
        while not stop.is_set():
            time.sleep(1.0)
    except KeyboardInterrupt:
        print("\nStopping watchers...")
    finally:
        for l in listeners:
            l.unsubscribe()

def _parse_args():
    ap = argparse.ArgumentParser()
    ap.add_argument("--bucket", required=True, help="Bucket (university) doc id")
    mode = ap.add_mutually_exclusive_group(required=True)
    mode.add_argument("--scan", action="store_true", help="Scan once and list all ready users")
    mode.add_argument("--check", help="Comma-separated user ids to check (e.g., tuser_001,tuser_075)")
    mode.add_argument("--watch", action="store_true", help="Watch for ready flag flips live")
    return ap.parse_args()

if __name__ == "__main__":
    args = _parse_args()
    if args.scan:
        scan_once(args.bucket)
    elif args.check:
        check_users(args.bucket, [s.strip() for s in args.check.split(",") if s.strip()])
    else:
        watch_flips(args.bucket)
