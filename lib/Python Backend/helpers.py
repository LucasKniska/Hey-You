import math
from enums import *
from models.models import *
import constants as const
from datetime import datetime
from datetime import timedelta

from models.models import *
from models.user_model import User
from models.new_match_model import Match, UserMatchData

# === Helper Functions ===

def get_quiz_answers(user_id, db):
    doc = db.collection(const.USERS).document(user_id).get()
    return doc.to_dict().get('TemporaryModifications', [])

def get_location(user_id, db):
    doc = db.collection(const.USERS).document(user_id).get()
    return doc.to_dict().get('location', {'lat': 0, 'lon': 0})

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
    doc = db.collection(const.USERS).document(user_id).get()
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
        response=UserResponse.NOT_SELECTED,
        location=user1.location
    )

    userMatch2 = UserMatchData(
        id=user2.id,
        userName=user2.firstName + " " + user2.lastName[0] + ".",
        userBio=user2.biography,
        response=UserResponse.NOT_SELECTED,
        location=user2.location
    )
    
    match = Match(
        expirationTime=datetime.now() + timedelta(minutes=const.MINUTES_FOR_NEW_MATCH),
        related=get_same_quiz_answers(user1.quizAnswers, user2.quizAnswers),
        createdOn=datetime.now(),
        possibleTimes=[],
        possiblePlaces=[],
        currentProposedPlace=None,
        userData=[userMatch1, userMatch2],
        status=MatchStatus.NEW
    )

    return match

def initialize_new_match(user1, user2, match, db):
    # Add the match to the database
    match_ref = db.collection(const.NEW_MATCHES).add(match.to_json())

    db.collection(const.NEW_MATCHES).document(match_ref[1].id).update({
        'id': match_ref[1].id
    })

    # Update the users with the new match ID
    db.collection(const.USERS).document(user1.id).update({
        'CurrentMatch': match_ref[1].id
    })

    db.collection(const.USERS).document(user2.id).update({
        'CurrentMatch': match_ref[1].id
    })

    return match_ref[1].id

# user1 and 2 are User Objects
def create_new_match(user1, user2, db):
    match = get_match_object(user1, user2)
    match_id = initialize_new_match(user1, user2, match, db)
    return match_id