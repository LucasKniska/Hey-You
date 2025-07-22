
import pytest
from matching_calculations.matching_algo import normalize_answer, get_trait_means, ocean_compatibility

def test_normalize_answer_non_reverse():
    assert normalize_answer(1) == 0.0
    assert normalize_answer(7) == 1.0
    assert normalize_answer(4) == 0.5

def test_normalize_answer_reverse():
    assert normalize_answer(1, reverse=True) == 1.0
    assert normalize_answer(7, reverse=True) == 0.0
    assert normalize_answer(4, reverse=True) == 0.5

def test_get_trait_means_basic():
    # O: idx 0, 5 | C: idx 1, 6 | E: idx 2, 7 | A: idx 3, 8 | N: idx 4, 9
    quiz_answers = {0: 5, 1: 3, 2: 4, 3: 2, 4: 7, 5: 2, 6: 6, 7: 4, 8: 3, 9: 5}
    reverse_keys = {1, 3, 5, 7, 9}  #Values need to be flipped --
    means = get_trait_means(quiz_answers, reverse_keys, n_traits=5, min_val=1, max_val=7)
    # Just check output is in correct format/range
    assert len(means) == 5
    assert all(0.0 <= m <= 1.0 for m in means)
    

def test_get_trait_means_basic_values():
    # O: idx 0, 5 | C: idx 1, 6 | E: idx 2, 7 | A: idx 3, 8 | N: idx 4, 9
    quiz_answers = {0: 5, 1: 3, 2: 4, 3: 2, 4: 7, 5: 2, 6: 6, 7: 4, 8: 3, 9: 5}
    reverse_keys = {1, 3, 5, 7, 9}
    means = get_trait_means(quiz_answers, reverse_keys, n_traits=5, min_val=1, max_val=7)
    # Calculated by hand:
    # O: (normalize(5) + normalize(2, reverse)) / 2 = (4/6 + (7-2)/6) / 2 = (0.6667 + 0.8333) / 2 = 0.75
    # C: (normalize(3, reverse) + normalize(6)) / 2 = ((7-3)/6 + 5/6) / 2 = (0.6667 + 0.8333) / 2 = 0.75
    # E: (normalize(4) + normalize(4, reverse)) / 2 = (3/6 + (7-4)/6) / 2 = (0.5 + 0.5) / 2 = 0.5
    # A: (normalize(2, reverse) + normalize(3)) / 2 = ((7-2)/6 + 2/6) / 2 = (0.8333 + 0.3333) / 2 = 0.5833
    # N: (normalize(7) + normalize(5, reverse)) / 2 = (6/6 + (7-5)/6) / 2 = (1.0 + 0.3333) / 2 = 0.6667
    expected = [0.75, 0.75, 0.5, 0.5833, 0.6667]
    for m, exp in zip(means, expected):
        assert m == pytest.approx(exp, abs=1e-4)


def test_ocean_compatibility_identical():
    traits = [0.3, 0.7, 0.5, 0.9, 0.4]
    score = ocean_compatibility(traits, traits)
    assert score == pytest.approx(1.0)

def test_ocean_compatibility_opposites():
    traitsA = [0.0, 0.0, 0.0, 0.0, 0.0]
    traitsB = [1.0, 1.0, 1.0, 1.0, 1.0]
    score = ocean_compatibility(traitsA, traitsB)
    # Max distance for 5 traits, each weight 0.2: sqrt(5*0.2*1^2) = sqrt(1) = 1
    # 1 - 1 = 0
    assert score == pytest.approx(0.0)

def test_end_to_end_matching():
    # User A mostly high, User B mostly low
    userA = {0: 6, 1: 2, 2: 6, 3: 2, 4: 6, 5: 2, 6: 6, 7: 2, 8: 6, 9: 2}
    userB = {0: 2, 1: 6, 2: 2, 3: 6, 4: 2, 5: 6, 6: 2, 7: 6, 8: 2, 9: 6}
    reverse_keys = {1, 3, 5, 7, 9}
    traitsA = get_trait_means(userA, reverse_keys)
    traitsB = get_trait_means(userB, reverse_keys)
    score = ocean_compatibility(traitsA, traitsB)
    # Should be low (opposites)
    assert 0.0 <= score < 0.5

