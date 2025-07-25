from fastapi import FastAPI
from typing import List
from pydantic import BaseModel
import firebase_admin
from firebase_admin import credentials, firestore
import math
from models.models import *
from helpers import *
from main import *


def testCreateMatch():
    user1 = 'gmwlBqTibHhob4nD5LwYuHJKq8p2'
    user2 = 'nA1zXRlK0tQjkHVwJnv2d3myUON2'

    user1 = get_user_by_id(user1, db)
    user2 = get_user_by_id(user2, db)

    match = get_match_object(user1, user2)
    match_id = initialize_new_match(user1, user2, match, db)
    return match_id

def testGetPreviousConnections():
    previous = get_previous_connections('gmwlBqTibHhob4nD5LwYuHJKq8p2')
    print(previous)

def testCreateAcceptMatch():
    user1 = 'gmwlBqTibHhob4nD5LwYuHJKq8p2'
    user2 = 'E1BkpJHUUldUVwON21ucPr4hFJ13'

    user12 = get_user_by_id(user1, db)
    user22 = get_user_by_id(user2, db)

    match = get_match_object(user12, user22)
    match_id = initialize_new_match(user12, user22, match, db)

    accept_match(IdRequest(id=match_id))

def testResetMatchesDatabase():
    cred = credentials.Certificate("serviceAccountKey.json")
    firebase_admin.initialize_app(cred)
    db = firestore.client()

    for each in db.collection(const.USERS).stream():
        db.collection(const.USERS).document(each.id).update({
            'PreviousConnections': [],
        })
    for each in db.collection(const.NEW_MATCHES).stream():
        db.collection(const.NEW_MATCHES).document(each.id).delete()
    for each in db.collection(const.REJECTED_MATCHES).stream():
        db.collection(const.REJECTED_MATCHES).document(each.id).delete()
    for each in db.collection(const.COMPLETED_MATCHES).stream():
        db.collection(const.COMPLETED_MATCHES).document(each.id).delete()


"""
Tests making a match between two users
"""
matchId = testCreateMatch()
# matchId = testCreateAcceptMatch()

""" 
Tests if closing the match works
"""
# match = IdRequest(id=matchId)
# print(close_match(match))

"""
Tests if updated the match based off of user responses works
"""
# print(accept_match('h4ZYOobcNXeDHg9Csy0W'))

"""
Tests if getting previous connections works
"""
# testGetPreviousConnections()