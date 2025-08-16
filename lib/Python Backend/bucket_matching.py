# All of the buckets
#   include loaction of school and name of bucket

from math import radians, sin, cos, sqrt, atan2
from constants import BUCKETS  # Make sure BUCKETS is imported from your constants file
from models.partition_model import PartitionModel
from models.models import *
from helpers import *
import constants as const
from models.partition_model import PartitionModel
import firebase_admin
from firebase_admin import credentials, firestore



def get_nearest_bucket_name(user_lat, user_long):
    def haversine(lat1, lon1, lat2, lon2):
        R = 6371  # Earth radius in kilometers
        dlat = radians(lat2 - lat1)
        dlon = radians(lon2 - lon1)
        a = sin(dlat/2)**2 + cos(radians(lat1)) * cos(radians(lat2)) * sin(dlon/2)**2
        return 2 * R * atan2(sqrt(a), sqrt(1 - a))

    return min(BUCKETS, key=lambda b: haversine(user_lat, user_long, b.lat, b.long)).name


def change_user_bucket(db, user, request, nearest_bucket, user_ref):
    print('User has changed buckets', flush=True)

    # TODO send request to backend api for which partition to set user into
    # async request to backend api to get name of which partition to set user into

    partition_name = assign_user_partition(db, user, nearest_bucket)

    # set user into partition
    user_partition = PartitionModel(
        id=user.id,
        location=request.geolocation
    )

    # Buckets/<Bucket-Name>/<Partition-Name> => Field: <User-ID>
    bucket_ref = db.collection(const.BUCKET_REF).document(nearest_bucket).collection(partition_name).document(user.id)
    bucket_ref.set(user_partition.to_json(), merge=True)

    bucket_ref = db.collection(const.BUCKET_REF).document(nearest_bucket)

    # Check if other bucket fields need to be updated
    bucket_ref.update({
        'numUsers': firestore.Increment(1)
    })

    # Updates any of the rankings for the bucket
    update_new_bucket_rankings(user, bucket_ref)
    update_old_bucket_rankings(user, db, user.nearestBucket)

    try: 
        # delete the last partition document if it exists
        last_partition_ref = db.collection(const.BUCKET_REF).document(user.nearestBucket).collection(user.partition).document(user.id)
        if last_partition_ref.get().exists:
            last_partition_ref.delete()
        
        last_partition_ref = db.collection(const.BUCKET_REF).document(user.nearestBucket)
        last_partition_ref.update({
            'numUsers': firestore.Increment(-1)
        })
    except Exception as e:
        print(f"Error removing user from last bucket: {e}", flush=True)

    # update user reference for nearest bucket and partition
    user_ref.update({
        'NearestBucket': nearest_bucket,
        'Partition': partition_name
    })     
    return nearest_bucket, partition_name


def assign_user_partition(db, user, nearest_bucket):
    return "partition11"

def update_new_bucket_rankings(user, bucket_ref):

    data = bucket_ref.get().to_dict()
    lS = update_bucket_ranking_field(data.get('longestStreak', []), user, user.longestStreak)
    cS = update_bucket_ranking_field(data.get('currentStreak', []), user, user.currentStreak)
    tC = update_bucket_ranking_field(data.get('totalConnections', []), user, user.totalConnections)

    print('Updating: ', bucket_ref)
    bucket_ref.update({
        'longestStreak': lS,
        'currentStreak': cS,
        'totalConnections': tC
    })

    # remove from previous bucket if necessary

def update_bucket_ranking_field(rankings, user, value):
    """
    Updates a ranking array field in the bucket document.
    Keeps top 5 entries sorted by the value (descending).
    Uses dicts instead of arrays for Firestore compatibility.
    """
    # Remove existing entry for this user
    rankings = [entry for entry in rankings if entry.get("id") != user.id]
    # Add or update the user's value
    rankings.append({"id": user.id, "name": f"{user.firstName} {user.lastName}", "value": value})
    # Sort by value (dict key 'value'), descending
    rankings.sort(key=lambda x: x["value"], reverse=True)
    # Keep only top 10
    rankings = rankings[:10]
    return rankings

def update_old_bucket_rankings(user, db, old_bucket_name):
    old_bucket_ref = db.collection(const.BUCKET_REF).document(old_bucket_name)
    data = old_bucket_ref.get().to_dict()

    lS = [entry for entry in data.get('longestStreak', []) if entry.get("id") != user.id]
    cS = [entry for entry in data.get('currentStreak', []) if entry.get("id") != user.id]
    tC = [entry for entry in data.get('totalConnections', []) if entry.get("id") != user.id]

    old_bucket_ref.update({
        'longestStreak': lS,
        'currentStreak': cS,
        'totalConnections': tC
    })
