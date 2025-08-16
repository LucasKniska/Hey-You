from datetime import datetime, timezone, timedelta, time
from zoneinfo import ZoneInfo

def update_user_stats():
    meeting_day = datetime(year=2025, month=8, day=12)
    last_match_day = datetime(year=2025, month=8, day=5)
    window_end = datetime(year=2025, month=8, day=7)

    # Roll the timer forward in fixed X-day blocks until it covers the meeting day
    missed_blocks = 0
    while meeting_day > window_end:
        window_end += timedelta(days=3)
        missed_blocks += 1

    window_start = window_end - timedelta(days=3 - 1)

    # Check if we've already counted a match in this same window
    already_counted_this_window = (
        last_match_day is not None and
        window_start <= last_match_day <= window_end and
        window_start <= meeting_day   <= window_end
    )

    if missed_blocks == 0:
        # Match fell inside the current window
        if not already_counted_this_window:
            print('Streak increase 1')
    else:
        # At least one full window passed since the timer
        if missed_blocks == 1:
            print('Streak increase 1')
        else:
            print('Streak reset')

    print(f"Window Start: {window_start}, Window End: {window_end}")
    print(f"Missed Blocks: {missed_blocks}, Already Counted: {already_counted_this_window}")

update_user_stats()
