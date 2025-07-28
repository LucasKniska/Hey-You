from fastapi import FastAPI
import firebase_admin
from firebase_admin import credentials, firestore
from enums import UserResponse
from models.models import *
from helpers import *
import constants as const
from fastapi import Body


app = FastAPI()

# Initialize Firebase
cred = credentials.Certificate("serviceAccountKey.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

# === API Endpoints ===
@app.post("/update-question-answers")
def update_question_answers(request: QuestionAnswersRequest):
    user_ref = db.collection(const.USERS).document(request.user_id)

    print(request)

    if not user_ref.get().exists:
        return {"error": "User not found"}
    try:
        user_ref.update({
            'QuestionAnswers': request.question_answers
        })
        return {"status": "QuestionAnswers updated", "user_id": request.user_id}
    except Exception as e:
        return {"error": str(e)}

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
def complete_match(match: UserMatchRequest):
    # Check if other user is already completed
    # If it is, call close match
    
    user_id_ref = db.collection(const.USERS).document(match.user_id)
    if user_id_ref.get().exists:
        user_data = User.from_json(user_id_ref.get().to_dict())
        match.match_id = user_data.currentMatch
    else:
        return {"error": "User not found"}


    # Keeps a reference of the match document
    match_ref = db.collection(const.NEW_MATCHES).document(match.match_id)

    if match_ref.get().exists:
        match_data = Match.from_json(match_ref.get().to_dict())
    else:
        return {"error": "Match not found"}

    if match_data.userData[0].id == match.user_id:
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
        
        return {"status": "Match not completed by both users", "match_id": match.match_id}
    
    # Both users have completed the match and have made a connection
    match_data.meetingTime = datetime.now() 

    match_data.meetingPlace = {
        "lat": match_data.userData[0].location.lat,
        "long": match_data.userData[0].location.long,
        "location": match.address
    }

    match_data.status = MatchStatus.COMPLETED

    # Gets the users from the match
    user1 = match_data.userData[0].id
    user2 = match_data.userData[1].id

    # Update the user documents to remove the match reference
    db.collection(const.USERS).document(user1).update({
        'CurrentMatch': None,
        'PreviousConnections': firestore.ArrayUnion([match.match_id]),
        'TotalConnections': firestore.Increment(1)
    })
    db.collection(const.USERS).document(user2).update({
        'CurrentMatch': None,
        'PreviousConnections': firestore.ArrayUnion([match.match_id]),
        'TotalConnections': firestore.Increment(1)
    })

    # Move document to closed matches
    db.collection(const.COMPLETED_MATCHES).document(match.match_id).set(match_data.to_json())
    match_ref.delete()

    return {"status": "Match closed", "match_id": match}

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
    # Get user document once
    user_doc = db.collection(const.USERS).document(user_id).get()
    if not user_doc.exists:
        return {"error": "User not found"}

    user = User.from_json(user_doc.to_dict())

    # Get previous connection IDs
    previous_connections = user.previousConnections
    if not previous_connections:
        return {"status": "No previous connections found"}

    # Batch get all match documents
    match_refs = [db.collection(const.COMPLETED_MATCHES).document(mid) for mid in previous_connections]
    match_docs = db.get_all(match_refs)

    # Parse existing matches only
    matches = [
        Match.from_json(doc.to_dict()).to_json()
        for doc in match_docs if doc.exists
    ]

    return {"previous_connections": matches}


@app.post("/update-user-match-data")
def update_user_match_data(request: UpdateUserMatchDataRequest):
    # Reference to the match document
    match_ref = db.collection(const.NEW_MATCHES).document(request.matchId)
    match_doc = match_ref.get()
    if not match_doc.exists:
        return {"error": "Match not found"}

    match_data = Match.from_json(match_doc.to_dict())

    userNumber = 0 if match_data.userData[0].id == request.userId else 1

    match_data.userData[userNumber].response = request.decision

    # Update the match document in Firestore
    match_ref.update({
        'userData': [user.to_json() for user in match_data.userData]
    })

    return {"status": "User match data updated", "match_id": request.matchId}

@app.post("/update-search-filters")
def update_search_filters(request: UpdateSearchFiltersRequest):
    user_ref = db.collection(const.USERS).document(request.user_id)
    if not user_ref.get().exists:
        return {"error": "User not found"}

    try:
        user_ref.update({
            'TemporaryModifications': request.temporary_modifications,
            'PermanentModifications': request.permanent_modifications
        })
        return {"status": "Search filters updated", "user_id": request.user_id}
    except Exception as e:
        return {"error": str(e)}
    
@app.post("/create-new-user")
def create_new_user(request: CreateNewUserRequest):
    user_id = request.id
    user_ref = db.collection(const.USERS).document(user_id)
    if user_ref.get().exists:
        return {"error": "User already exists"}

    try:
        # Convert the request to a dict for Firestore
        user_data = request.model_dump()
        user_ref.set(user_data)
        return {"status": "User created", "user_id": user_id}
    except Exception as e:
        return {"error": str(e)}
    

@app.post("/update-user-field")
def update_user_field(request: UpdateUserFieldRequest):
    user_ref = db.collection(const.USERS).document(request.user_id)
    if not user_ref.get().exists:
        return {"error": "User not found"}

    try:
        user_ref.update({request.field: request.value})
        return {"status": "User field updated", "user_id": request.user_id, "field": request.field}
    except Exception as e:
        return {"error": str(e)}