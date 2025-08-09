from models import bucket

# --- Constants ---

MINUTES_FOR_NEW_MATCH = 10 # The amount of time a new match will last if it is not acted upon
RELATED_INFO_MAX = 3 # The maximum number of related interests to show in the match

# --- Firestore Collections ---
USERS = "Users"
NEW_MATCHES = "Matches"
REJECTED_MATCHES = "RejectedMatches"
COMPLETED_MATCHES = "CompletedMatches"
BUCKET_REF = "Buckets"


BUCKETS = [
    bucket.Bucket("West_Virginia_University", 39.64795, -79.96970),
    bucket.Bucket("Columbia_University", 40.80754, -73.96254),
    bucket.Bucket("Stanford_University", 37.42755, -122.170169)
]
