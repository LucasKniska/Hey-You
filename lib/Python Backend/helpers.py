import math
from models import *
import constants as const
from datetime import datetime
from datetime import timedelta

# === Helper Functions ===

def get_quiz_answers(user_id, db):
    doc = db.collection(const.Users).document(user_id).get()
    return doc.to_dict().get('TemporaryModifications', [])

def cosine_similarity(vec1, vec2):
    dot = sum(x * y for x, y in zip(vec1, vec2))
    norm1 = math.sqrt(sum(x ** 2 for x in vec1))
    norm2 = math.sqrt(sum(x ** 2 for x in vec2))
    return dot / (norm1 * norm2 + 1e-8)

def get_location(user_id, db):
    doc = db.collection(const.Users).document(user_id).get()
    return doc.to_dict().get('location', {'lat': 0, 'lon': 0})

def midpoint(lat1, lon1, lat2, lon2):
    return {'lat': (lat1 + lat2) / 2, 'lon': (lon1 + lon2) / 2}

def get_same_quiz_answers(userQuizAnswers, user2QuizAnswers):
    sameAnswers = []
    for i in range(len(userQuizAnswers)):
        if userQuizAnswers[i] == user2QuizAnswers[i]:

            # TODO Append the string that is similar about the related question
            sameAnswers.append(str(userQuizAnswers[i]))

            if len(sameAnswers) >= const.RELATED_INFO_MAX:
                break

    return sameAnswers

def get_user_by_id(user_id, db):
    doc = db.collection(const.Users).document(user_id).get()
    if doc.exists:
        return User.from_json(doc.to_dict())
    else:
        return None
    

"""
Creating a new match object once two users are matched
"""
def get_match_object(user1, user2):
    # Check if both users have similar interests
    
    userMatch1 = UserMatchData(
        id=user1.id,
        userName=user1.firstName + " " + user1.lastName[0] + ".",
        userBio=user1.biography,
        response=UserResponse.NOT_SELECTED
    )

    userMatch2 = UserMatchData(
        id=user2.id,
        userName=user2.firstName + " " + user2.lastName[0] + ".",
        userBio=user2.biography,
        response=UserResponse.NOT_SELECTED
    )
    
    match = Match(
        expirationTime=datetime.now() + timedelta(minutes=const.MINUTES_FOR_NEW_MATCH),
        related=get_same_quiz_answers(user1.quizAnswers, user2.quizAnswers),
        createdOn=datetime.now(),
        possibleTimes=[],
        possiblePlaces=[],
        currentProposedPlace=None,
        userData=[userMatch1, userMatch2]
    )

    return match

def initialize_new_match(user1, user2, match, db):
    # Add the match to the database
    match_ref = db.collection(const.Matches).add(match.dict())

    # Update the users with the new match ID
    db.collection(const.Users).document(user1.id).update({
        'CurrentMatch': match_ref[1].id
    })

    db.collection(const.Users).document(user2.id).update({
        'CurrentMatch': match_ref[1].id
    })

    db.collection(const.Matches).document(match_ref[1].id).update({
        'id': match_ref[1].id
    })

    return match_ref[1].id