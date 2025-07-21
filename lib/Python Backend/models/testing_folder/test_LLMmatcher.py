import pytest
import numpy as np
from unittest.mock import patch, MagicMock

import matching_algoLLM as alg
import vector_distance as dist

def test_cosine_sim_basic():
    assert dist.cosine_sim([1, 2, 3], [1, 2, 3]) == pytest.approx(1.0)
    assert dist.cosine_sim([1, 0], [0, 1]) == pytest.approx(0.0)
    assert dist.cosine_sim([0, 0, 0], [1, 2, 3]) == 0

def test_profile_similarity_full_overlap():
    dummy_vec = [1, 2, 3]
    userA = {f: dummy_vec for f in dist.PROFILE_FIELDS}
    userB = {f: dummy_vec for f in dist.PROFILE_FIELDS}
    assert dist.profile_similarity(userA, userB) == pytest.approx(1.0)

def test_profile_similarity_partial_overlap():
    vecA, vecB = [1, 0], [0, 1]
    userA, userB = {"hometown": vecA}, {"hometown": vecB}
    assert dist.profile_similarity(userA, userB) == pytest.approx(0.0)

def test_profile_similarity_no_overlap():
    userA = {"hometown": [1, 2, 3]}
    userB = {"career":   [1, 2, 3]}
    assert dist.profile_similarity(userA, userB) == 0.0

@patch("matching_algoLLM.openai")
def test_extract_profile_good_json(mock_openai):
    class FakeResp:
        class Choice:
            class Message:
                content = (
                    '{"hometown":"NYC","hometown_description":"Big city","career":"finance",'
                    '"favorite_animals":"dog","favorite_pastimes":"hiking","current_mood_meet":"",'
                    '"religion":"","favorite_tv_shows_and_movies":"","values_and_causes":"",'
                    '"favorite_sport":"","favorite_food_and_drink":"","favorite_video_games":""}'
                )
            message = Message()
        choices = [Choice()]
    mock_openai.chat.completions.create.return_value = FakeResp()
    out = alg.extract_profile("dummy text")
    assert out["hometown"] == "NYC"
    assert out["career"] == "finance"

@patch("matching_algoLLM.openai")
def test_extract_profile_bad_json_raises(mock_openai):
    class FakeResp:
        class Choice:
            class Message:
                content = "{BAD JSON"
            message = Message()
        choices = [Choice()]
    mock_openai.chat.completions.create.return_value = FakeResp()
    with pytest.raises(ValueError):
        alg.extract_profile("bad json")

@patch("matching_algoLLM.openai")
def test_get_profile_embeddings(mock_openai):
    fake_vec = [0.1, 0.2, 0.3]
    mock_openai.embeddings.create.return_value = MagicMock(
        data=[MagicMock(embedding=fake_vec)]
    )
    filled_profile = {f: "text" for f in alg.PROFILE_FIELDS}
    embeddings = alg.get_profile_embeddings(filled_profile)
    assert all(embeddings[f] == fake_vec for f in alg.PROFILE_FIELDS)

    empty_profile = {f: "" for f in alg.PROFILE_FIELDS}
    embeddings = alg.get_profile_embeddings(empty_profile)
    assert all(embeddings[f] is None for f in alg.PROFILE_FIELDS)

@patch("matching_algoLLM.extract_profile")
@patch("matching_algoLLM.get_profile_embeddings")
def test_process_user_profile_returns_both(mock_get_emb, mock_extract):
    mock_extract.return_value = {"hometown": "NYC"}
    mock_get_emb.return_value = {"hometown": [1, 2, 3]}
    prof, vecs = alg.process_user_profile("any text")
    assert prof["hometown"] == "NYC"
    assert vecs["hometown"] == [1, 2, 3]
