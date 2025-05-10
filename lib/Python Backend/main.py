from fastapi import FastAPI
from typing import List
from pydantic import BaseModel
import firebase_admin
from firebase_admin import credentials, firestore
import math
from enums import UserResponse
from models.models import *
from helpers import *
import constants as const

app = FastAPI()

# Initialize Firebase
cred = credentials.Certificate("serviceAccountKey.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

# === API Endpoints ===

@app.post("/match-users")
def match_users(request: SingleUserRequest):
    # create_new_match(user1, user2, db)
    pass


@app.post("/reject-match")
def reject_match(match_id: IdRequest):


    # Keeps a reference of the match document
    match_ref = db.collection(const.NEW_MATCHES).document(match_id.id)
    match_data = match_ref.get().to_dict()

    if not match_data:
        return {"error": "Match not found"}
    
    # Gets the users from the match
    user1 = match_data['userData'][0]['id']
    user2 = match_data['userData'][1]['id']

    # Update the user documents to remove the match reference
    user1_ref = db.collection(const.USERS).document(user1).update({
        'CurrentMatch': None
    })
    user2_ref = db.collection(const.USERS).document(user2).update({
        'CurrentMatch': None
    })

    # Move document to rejected matches
    db.collection(const.REJECTED_MATCHES).document(match_id.id).set(match_data)
    match_ref.delete()

    return {"status": "Match rejected", "match_id": match_id}


@app.post("/accept-match")
def accept_match(match_id: IdRequest):
    # Keeps a reference of the match document
    match_ref = db.collection(const.NEW_MATCHES).document(match_id.id)
    match_data = Match.from_json(match_ref.get().to_dict())

    if not match_data:
        return {"error": "Match not found"}
    
    if match_data.userData[0].response != UserResponse.MEET_NOW and match_data.userData[0].response != UserResponse.MEET_LATER:
        return {"error": "Match not accepted by both users"}
    if match_data.userData[1].response != UserResponse.MEET_NOW and match_data.userData[1].response != UserResponse.MEET_LATER:
        return {"error": "Match not accepted by both users"}
    
    # Gets the users from the match; matches either right now or later
    if match_data.userData[0].response == UserResponse.MEET_NOW and match_data.userData[1].response == UserResponse.MEET_NOW:
        match_data.status = MatchStatus.NOW
    else:
        match_data.status = MatchStatus.SCHEDULED

    match_ref.update({
        'status': match_data.status.to_json()
    })

    return {"status": "Match accepted", "match_id": match_id}


@app.post("/close-match")
def close_match(match_id: IdRequest):
    # Keeps a reference of the match document
    match_ref = db.collection(const.NEW_MATCHES).document(match_id.id)
    match_data = Match.from_json(match_ref.get().to_dict())

    if not match_data:
        return {"error": "Match not found"}
    
    # Gets the users from the match
    user1 = match_data.userData[0].id
    user2 = match_data.userData[1].id

    match_data.meetingPlace = match_data.userData[0].location
    match_data.status = MatchStatus.COMPLETED

    # Update the user documents to remove the match reference
    user1_ref = db.collection(const.USERS).document(user1).update({
        'CurrentMatch': None,
        'PreviousConnections': firestore.ArrayUnion([match_id.id])
    })
    user2_ref = db.collection(const.USERS).document(user2).update({
        'CurrentMatch': None,
        'PreviousConnections': firestore.ArrayUnion([match_id.id])
    })

    # Move document to closed matches
    db.collection(const.COMPLETED_MATCHES).document(match_id.id).set(match_data.to_json())
    match_ref.delete()

    return {"status": "Match closed", "match_id": match_id}
