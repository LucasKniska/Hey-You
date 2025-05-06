from fastapi import FastAPI
from typing import List
from pydantic import BaseModel
import firebase_admin
from firebase_admin import credentials, firestore
import math
from models import *
from helpers import *


app = FastAPI()

# Initialize Firebase
cred = credentials.Certificate("serviceAccountKey.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

def testCreateMatch():
    user1 = 'gmwlBqTibHhob4nD5LwYuHJKq8p2'
    user2 = 'XVPG8lYKGKOBddsh7FZznrD4EaT2'


    user1 = get_user_by_id(user1, db)
    user2 = get_user_by_id(user2, db)

    match = get_match_object(user1, user2)
    match_id = initialize_new_match(user1, user2, match, db)
    return match_id


testCreateMatch()