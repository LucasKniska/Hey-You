from fastapi import FastAPI
from typing import List
from pydantic import BaseModel
import firebase_admin
from firebase_admin import credentials, firestore
import math
from models import *
from helpers import *
import constants as const

app = FastAPI()

# Initialize Firebase
cred = credentials.Certificate("serviceAccountKey.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

# === API Endpoints ===

@app.post("/similar-interests")
def similar_interests(request: UserIDRequest):
    uid1, uid2 = request.user_ids
    ans1 = get_quiz_answers(uid1, db)
    ans2 = get_quiz_answers(uid2, db)
    score = cosine_similarity(ans1, ans2)
    return {"similarity_score": score}

@app.post("/match-users")
def match_users(request: SingleUserRequest):
    base_doc = db.collection('users').document(request.user_id).get()
    base_user = base_doc.to_dict()
    base_loc = base_user.get('location', {})
    base_lat, base_lon = base_loc.get('lat', 0), base_loc.get('lon', 0)

    users = db.collection('users').stream()
    matched_users = []

    for user in users:
        u = user.to_dict()
        if user.id == request.user_id:
            continue
        loc = u.get('location', {})

        # Makes sure users are close to each other for the match to happen
        if abs(loc.get('lat', 0) - base_lat) < 0.2 and abs(loc.get('lon', 0) - base_lon) < 0.2:
            matched_users.append(user.id)
        if len(matched_users) == 2:
            break

    return {"matched_users": matched_users}

@app.post("/meeting-place")
def meeting_place(request: UserIDRequest):
    uid1, uid2 = request.user_ids
    loc1 = get_location(uid1, db)
    loc2 = get_location(uid2, db)
    meet = midpoint(loc1['lat'], loc1['lon'], loc2['lat'], loc2['lon'])
    return {"meeting_point": meet}

@app.post("/reject-match")
def reject_match(match_id, db):
    # Keeps a reference of the match document
    match_ref = db.collection(const.Matches).document(match_id)
    match_data = match_ref.get().to_dict()

    if not match_data:
        return {"error": "Match not found"}
    
    # Gets the users from the match
    user1 = match_data['userData'][0]['id']
    user2 = match_data['userData'][1]['id']

    # Update the user documents to remove the match reference
    user1_ref = db.collection(const.Users).document(user1).update({
        'CurrentMatch': None
    })
    user2_ref = db.collection(const.Users).document(user2).update({
        'CurrentMatch': None
    })

    # Move document to rejected matches
    db.collection(const.RejectedMatches).document(match_id).set(match_data)
    match_ref.delete()

    return {"status": "Match rejected", "match_id": match_id}



"""
1. Create a new match (After two users are analyzed to be connected)

2a. If one of the user rejects the match
"""

# user1 and 2 are User Objects
def create_new_match(user1, user2, db):
    match = get_match_object(user1, user2)
    match_id = initialize_new_match(user1, user2, match, db)
    return match_id