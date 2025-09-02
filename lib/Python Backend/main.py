from datetime import datetime, timezone, timedelta, time
from zoneinfo import ZoneInfo
from fastapi import FastAPI
import firebase_admin
from firebase_admin import credentials, firestore
from enums import UserResponse
from models.models import *
from helpers import *
import constants as const
from bucket_matching import *
from bucket_matching import update_new_bucket_rankings
import random
from helpers.helpers import *
import constants.constants as const
from scoreCalcs import DRIVERscoring

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
        DRIVERscoring.update_user_scores_for_one(request.user_id, db, const.USERS)
        return {"status": "QuestionAnswers updated", "user_id": request.user_id}
    except Exception as e:
        return {"error": str(e)}

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
    match_data.meetingTime = datetime.now(timezone.utc)
    
    match_data.meetingPlace = {
        "lat": match_data.userData[0].location.lat,
        "long": match_data.userData[0].location.long,
        "location": match.address
    }

    match_data.status = MatchStatus.COMPLETED

    # Gets the users from the match
    user1 = match_data.userData[0].id
    user2 = match_data.userData[1].id

    # Update the user documents to remove the match reference and update connections and stats
    user1_ref = db.collection(const.USERS).document(user1)
    user2_ref = db.collection(const.USERS).document(user2)

    def update_user_stats(user_ref):
        u = User.from_json(user_ref.get().to_dict())

        u.totalConnections += 1

        EASTERN = ZoneInfo("America/New_York")

        meeting_day = match_data.meetingTime.astimezone(EASTERN).date()
        last_match_day = u.lastMatch.astimezone(EASTERN).date() if u.lastMatch else None
        window_end = u.currentStreakTimer.astimezone(EASTERN).date() if u.currentStreakTimer else last_match_day

        # Roll the timer forward in fixed X-day blocks until it covers the meeting day
        missed_blocks = 0
        while meeting_day > window_end:
            window_end += timedelta(days=const.STREAK_WINDOW_DAYS)
            missed_blocks += 1

        window_start = window_end - timedelta(days=const.STREAK_WINDOW_DAYS - 1)

        # Check if we've already counted a match in this same window
        already_counted_this_window = (
            last_match_day is not None and
            window_start <= last_match_day <= window_end and
            window_start <= meeting_day   <= window_end
        )

        if missed_blocks == 0:
            # Match fell inside the current window
            if not already_counted_this_window:
                u.currentStreak += 1
        else:
            # At least one full window passed since the timer
            if missed_blocks == 1:
                u.currentStreak += 1              # next window continued → streak alive
            else:
                u.currentStreak = 1               # missed ≥2 windows → reset

        # Update longest, timer (to the new window end), and lastMatch
        u.longestStreak = max(u.longestStreak, u.currentStreak)
        u.currentStreakTimer = datetime.combine(window_end, time.min, tzinfo=EASTERN)
        u.lastMatch = match_data.meetingTime
        u.longestStreak = max(u.longestStreak, u.currentStreak)

        # updates the user reference to match with current match
        user_ref.update({
            'CurrentMatch': None,
            'PreviousConnections': firestore.ArrayUnion([match.match_id]),
            'TotalConnections': u.totalConnections,
            'LongestStreak': u.longestStreak,
            'CurrentStreak': u.currentStreak,
            'CurrentStreakTimer': u.currentStreakTimer,
            'LastMatch': u.lastMatch
        })

        # Check if the bucket metadata needs updated
        bucket_ref = db.collection(const.BUCKET_REF).document(u.nearestBucket)
        update_new_bucket_rankings(u, bucket_ref)

    update_user_stats(user1_ref)
    update_user_stats(user2_ref)

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

    # check if the user has changed buckets
    nearest_bucket = get_nearest_bucket_name(request.geolocation.lat, request.geolocation.long)
    print('Bucket recommendation:', nearest_bucket, flush=True)
    if user.nearestBucket != nearest_bucket:
        user.nearestBucket, user.partition = change_user_bucket(db, user, request, nearest_bucket, user_ref)

    # updates the user location
    user_ref.update({
        'Location': request.geolocation.to_json()
    })

    # Updates either the match object or partition object
    if not user.currentMatch:
        # update the partition location
        bucket_ref = db.collection(const.BUCKET_REF).document(nearest_bucket).collection(user.partition).document(user.id)
        bucket_ref.update({
            'location': request.geolocation.to_json()
        })
        return {"status": "updated partition location"}
    else: 
        # Keeps a reference of the match document
        match_ref = db.collection(const.NEW_MATCHES).document(user.currentMatch)

        match_data = Match.from_json(match_ref.get().to_dict())
        if not match_data:
            return {"status": "No match found"}

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

        return {"status": "Updated match location", "user_id": request.user_id}

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

    if request.user_id is None or request.field is None or request.value is None or request.user_id == '':
        return {"error": "Invalid request parameters"}

    user_ref = db.collection(const.USERS).document(request.user_id)
    if not user_ref.get().exists:
        return {"error": "User not found"}

    try:
        user_ref.update({request.field: request.value})
        return {"status": "User field updated", "user_id": request.user_id, "field": request.field}
    except Exception as e:
        return {"error": str(e)}

@app.post("/end-current-streak")
def end_current_streak(request: SingleUserRequest):
    user_ref = db.collection(const.USERS).document(request.user_id)
    if not user_ref.get().exists:
        return {"error": "User not found"}

    user = User.from_json(user_ref.get().to_dict())
    bucket_ref = db.collection(const.BUCKET_REF).document(user.nearestBucket)
    data = bucket_ref.get().to_dict()

    # remove current streak from bucket if needed
    cS = update_bucket_ranking_field(data.get('currentStreak', []), user, user.currentStreak)

    bucket_ref.update({
        'currentStreak': cS
    })

    user_ref.update({
        'CurrentStreak': 0,
        'CurrentStreakTimer': None
    })
    return {"status": "Current streak ended", "user_id": request.user_id}

@app.get("/get-bucket-rankings")
def get_bucket_rankings(bucket_id: str):
    bucket_ref = db.collection(const.BUCKET_REF).document(bucket_id)
    data = bucket_ref.get().to_dict()

    return {
        "longestStreak": data.get('longestStreak', []),
        "currentStreak": data.get('currentStreak', []),
        "totalConnections": data.get('totalConnections', [])
    }

@app.get("/get-users-near-me")
def get_users_near_me(user_id: str):
    user_ref = db.collection(const.USERS).document(user_id)
    if not user_ref.get().exists:
        return {"error": "User not found"}

    user = User.from_json(user_ref.get().to_dict())

    # Get all users in the nearest bucket
    partition_ref = db.collection(const.BUCKET_REF).document(user.nearestBucket).collection(user.partition)
    docs = list(partition_ref.stream())

    # Randomly picks 3 users from the partition
    sampled_docs = random.sample(docs, min(10, len(docs)))

    user_data = []
    distances = []
    for doc in sampled_docs: 
        data = doc.to_dict()
        username = data.get('username', None)
        location = data.get('location', None)

        if username and location:
            user_data.append(username)
            distance = haversine(user.location.lat, user.location.long, location['lat'], location['long'])
            distances.append(str(distance))

    return {"users": user_data[0:3], "distances": distances[0:3]}
