import firebase_admin
from firebase_admin import credentials, firestore

# Initialize Firebase only once
if not firebase_admin._apps:
    cred = credentials.Certificate("serviceAccountKey.json")
    firebase_admin.initialize_app(cred)
db = firestore.client()

def create_test_user(user_id, bio, answers):
    doc_ref = db.collection("Users").document(user_id)    # <---- CHANGED
    doc_ref.set({
        "Biography": bio,
        "QuestionAnswers": answers,
        "Discoverable": True,
        "CurrentMatch": ""
    })
    print(f"User {user_id} created.")

if __name__ == "__main__":
    # User 1: Outdoor Adventurer (Hiking & Camping)
    create_test_user(
        "user_hiker",
        "Exploring mountain trails and camping under the stars are my favorite ways to spend weekends.",
        {
            "1": "hiking",
            "2": "camping",
            "3": "nature",
            "4": "this food is awesome -> trail mix",
            "5": "I love watching Planet Earth"
        }
    )
    
    # User 2: Outdoor Water Enthusiast (Kayaking & Surfing)
    create_test_user(
        "user_water",
        "I’m passionate about water sports like kayaking and surfing. Beaches and rivers are where I feel most alive.",
        {
            "1": "kayaking",
            "2": "surfing",
            "3": "oceans",
            "4": "my favorite food is fresh fruit",
            "5": "My favorite documentery Blue Planet"
        }
    )
    
    # User 3: Indoor Creative (Books & Board Games)
    create_test_user(
        "user_reader",
        "My idea of fun is curling up with a good novel or spending an evening playing board games with friends.",
        {
            "1": "reading",
            "2": "board games",
            "3": "I love drinking tea",
            "4": "I love reading mystery novels",
            "5": "My favorite show is The Queen's Gambit",
            "6": "I am Christian"
        }
    )
