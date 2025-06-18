from fastapi import FastAPI
import firebase_admin
from firebase_admin import credentials, firestore
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

@app.post("/complete-match")
def complete_match(match_id: UserMatchRequest):
    # Check if other user is already completed
    # If it is, call close match
    
    user_id_ref = db.collection(const.USERS).document(match_id.user_id)
    if user_id_ref.get().exists:
        user_data = User.from_json(user_id_ref.get().to_dict())
        match_id.id = user_data.currentMatch
    else:
        return {"error": "User not found"}


    # Keeps a reference of the match document
    match_ref = db.collection(const.NEW_MATCHES).document(match_id.id)

    if match_ref.get().exists:
        match_data = Match.from_json(match_ref.get().to_dict())
    else:
        return {"error": "Match not found"}

    if match_data.userData[0].id == match_id.user_id:
        match_data.userData[0].response = UserResponse.COMPLETED
    else:
        match_data.userData[1].response = UserResponse.COMPLETED

    # Check if both users have completed the match
    if(match_data.userData[0].response != UserResponse.COMPLETED or match_data.userData[1].response != UserResponse.COMPLETED):        

        print("Match not completed by both users")

        # updated this users response
        match_ref.update({
            'userData': [
                match_data.userData[0].to_json(),
                match_data.userData[1].to_json()
            ]
        })
        
        return {"status": "Match not completed by both users", "match_id": match_id.id}
    
    # Both users have completed the match and have made a connection
    match_data.meetingPlace = match_data.userData[0].location

    match_data.status = MatchStatus.COMPLETED

    # Gets the users from the match
    user1 = match_data.userData[0].id
    user2 = match_data.userData[1].id

    # Update the user documents to remove the match reference
    db.collection(const.USERS).document(user1).update({
        'CurrentMatch': None,
        'PreviousConnections': firestore.ArrayUnion([match_id.id])
    })
    db.collection(const.USERS).document(user2).update({
        'CurrentMatch': None,
        'PreviousConnections': firestore.ArrayUnion([match_id.id])
    })

    # Move document to closed matches
    db.collection(const.COMPLETED_MATCHES).document(match_id.id).set(match_data.to_json())
    match_ref.delete()

    return {"status": "Match closed", "match_id": match_id}

@app.post("/cancel-complete-match")
def cancel_complete_match(match_id: UserMatchRequest):

    user_id_ref = db.collection(const.USERS).document(match_id.user_id)
    if user_id_ref.get().exists:
        user_data = User.from_json(user_id_ref.get().to_dict())
        match_id.id = user_data.currentMatch
    else:
        return {"error": "User not found"}

    # Keeps a reference of the match document
    match_ref = db.collection(const.NEW_MATCHES).document(match_id.id)
    match_data = Match.from_json(match_ref.get().to_dict())

    if not match_data:
        return {"error": "Match not found"}

    # Check if the user is part of the match
    if match_data.userData[0].id != match_id.user_id and match_data.userData[1].id != match_id.user_id:
        return {"error": "User not part of the match"}

    # Update the user's response to not selected
    if match_data.userData[0].id == match_id.user_id:
        match_data.userData[0].response = UserResponse.MEET_NOW
    else:
        match_data.userData[1].response = UserResponse.MEET_NOW

    # Update the match document
    match_ref.update({
        'userData': [
            match_data.userData[0].to_json(),
            match_data.userData[1].to_json()
        ]
    })

    return {"status": "Match cancelled", "match_id": match_id.id}

@app.post("/update-location")
def update_location(request: LocationUpdateRequest):
    
    # Keeps a reference of the user document
    user_ref = db.collection(const.USERS).document(request.user_id)
    if user_ref.get().exists:
        user = User.from_json(user_ref.get().to_dict())
    else:
        return {"error": "User not found"}

    # updates the user location
    user_ref.update({
        'Location': request.geolocation.to_json()
    })

    # Checks if the user has a current match
    if not user.currentMatch:
        return {"status": "No current match to update location"}

    # Keeps a reference of the match document
    match_ref = db.collection(const.NEW_MATCHES).document(user.currentMatch)

    match_data = Match.from_json(match_ref.get().to_dict())
    if not match_data:
        return {"error": "No match found"}

    # Update the user's location in the match if it exists    
    if(match_data.userData[0].id == request.user_id):
        match_data.userData[0].location = request.geolocation
    else:
        match_data.userData[1].location = request.geolocation

    match_ref.update({
        'userData': [
            match_data.userData[0].to_json(),
            match_data.userData[1].to_json()
        ]
    })

    return {"status": "Location updated", "user_id": request.user_id}

@app.get("/get-previous-connections")
def get_previous_connections(user_id: str):
    # Keeps a reference of the user document
    user_ref = db.collection(const.USERS).document(user_id)
    if user_ref.get().exists:
        user = User.from_json(user_ref.get().to_dict())
    else:
        return {"error": "User not found"}

    # Get previous connections
    previous_connections = user.previousConnections

    if not previous_connections:
        return {"status": "No previous connections found"}

    matches = []
    for match_id in previous_connections:
        match_ref = db.collection(const.COMPLETED_MATCHES).document(match_id)
        if match_ref.get().exists:
            match_data = Match.from_json(match_ref.get().to_dict())
            matches.append(match_data.to_json())

    return {"previous_connections": matches}