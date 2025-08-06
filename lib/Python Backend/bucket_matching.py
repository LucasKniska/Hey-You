
# All of the buckets
#   include loaction of school and name of bucket

from math import radians, sin, cos, sqrt, atan2
from constants import BUCKETS  # Make sure BUCKETS is imported from your constants file

def get_nearest_bucket_name(user_lat, user_long):
    def haversine(lat1, lon1, lat2, lon2):
        R = 6371  # Earth radius in kilometers
        dlat = radians(lat2 - lat1)
        dlon = radians(lon2 - lon1)
        a = sin(dlat/2)**2 + cos(radians(lat1)) * cos(radians(lat2)) * sin(dlon/2)**2
        return 2 * R * atan2(sqrt(a), sqrt(1 - a))

    return min(BUCKETS, key=lambda b: haversine(user_lat, user_long, b.lat, b.long)).name


if __name__ == "__main__":
    # Example usage
    user_lat, user_long = 59.50020275641778, -70.92660396798898
    nearest_bucket = get_nearest_bucket_name(user_lat, user_long)
    print(f"The nearest bucket is: {nearest_bucket}")
