from matching_calculations.matching_algo import get_trait_means, ocean_compatibility
import pytest

import os
import sys

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from matching_calculations.matching_algo import get_trait_means, ocean_compatibility
from models.user_model import User
import pytest


# --- Mock User model for test purposes ---
class MockUser:
    def __init__(self, quizAnswers):
        self.quizAnswers = quizAnswers

# --- Wrapper function for testing ---
def get_users_ocean_compatibility(
    user1,
    user2,
    reverse_keys,
    weights=None,
    n_traits=5,
    min_val=1,
    max_val=7
) -> float:
    traits1 = get_trait_means(user1.quizAnswers, reverse_keys, n_traits, min_val, max_val)
    traits2 = get_trait_means(user2.quizAnswers, reverse_keys, n_traits, min_val, max_val)
    return ocean_compatibility(traits1, traits2, weights)

# --- Pytest tests ---

def test_users_ocean_compatibility_identical():
    answers = {0: 5, 1: 2, 2: 6, 3: 2, 4: 5, 5: 2, 6: 4, 7: 2, 8: 3, 9: 2}
    reverse_keys = {1, 3, 5, 7, 9}
    userA = MockUser(answers)
    userB = MockUser(answers.copy())
    score = get_users_ocean_compatibility(userA, userB, reverse_keys)
    assert score == pytest.approx(1.0)

def test_users_ocean_compatibility_opposite():
    answersA = {0: 1, 1: 7, 2: 1, 3: 7, 4: 1, 5: 7, 6: 1, 7: 7, 8: 1, 9: 7}
    answersB = {0: 7, 1: 1, 2: 7, 3: 1, 4: 7, 5: 1, 6: 7, 7: 1, 8: 7, 9: 1}
    reverse_keys = {1, 3, 5, 7, 9}
    userA = MockUser(answersA)
    userB = MockUser(answersB)
    score = get_users_ocean_compatibility(userA, userB, reverse_keys)
    assert 0.0 <= score < 0.2  # Opposite answers, expect low compatibility

def test_users_ocean_compatibility_partial():
    answersA = {0: 4, 1: 3, 2: 5, 3: 4, 4: 3, 5: 5, 6: 2, 7: 5, 8: 5, 9: 4}
    answersB = {0: 3, 1: 4, 2: 4, 3: 5, 4: 4, 5: 4, 6: 5, 7: 2, 8: 2, 9: 5}
    reverse_keys = {1, 3, 5, 7, 9}
    userA = MockUser(answersA)
    userB = MockUser(answersB)
    score = get_users_ocean_compatibility(userA, userB, reverse_keys)
    assert 0.0 <= score <= 1.0  # Just check it's a valid value

