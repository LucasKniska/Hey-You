from main import db
from models.models import *
from models.user_model import User
import constants.constants as const



# Loop through all documents in the "Users" collection
users_ref = db.collection(const.USERS)
docs = users_ref.stream()

for doc in docs:
    print(f'User ID: {doc.id}')
    print(f'User Data: {doc.to_dict()}')
    
    user = User.from_json(doc.to_dict())

    # Questions split between text and not
    # Bio

    print(f'User Biography: {user.biography}')

    numberedQuestionAnswers = [i for i in user.quizAnswers.values() if isinstance(i, int)]
    textQuestionAnswers = [i for i in user.quizAnswers.values() if isinstance(i, str)]

    print(numberedQuestionAnswers)
    print(textQuestionAnswers)

    # Import the OCEAN and LLM scores

    user.OCEANScore = 1
    user.llmScore = 1

    doc.reference.update({
        'OCEANScore': user.OCEANScore,
        'LLMScore': user.llmScore
    })


