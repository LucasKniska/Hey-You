from pydantic import BaseModel
from typing import List, Optional, Dict, Any
from datetime import datetime

# === Models ===
class UpdateUserFieldRequest(BaseModel):
    user_id: str
    field: str
    value: Any

class CreateNewUserRequest(BaseModel):
    id: str
    FirstName: str
    LastName: str
    Email: str
    Biography: str
    QuestionAnswers: Dict[str, Any]
    TemporaryModifications: List[dict]
    PermanentModifications: List[str]
    Location: dict
    CurrentMatch: str
    TotalConnections: int
    Discoverable: bool
    LongestStreak: int
    CurrentStreak: int
    LastMatch: datetime

class UpdateSearchFiltersRequest(BaseModel):
    user_id: str
    temporary_modifications: List[dict]
    permanent_modifications: List[str]

class UpdateUserMatchDataRequest(BaseModel):
    matchId: str
    userId: str
    decision: str

class QuestionAnswersRequest(BaseModel):
    user_id: str
    question_answers: Dict[str, Any]

class UserIDRequest(BaseModel):
    user_ids: List[str]

class SingleUserRequest(BaseModel):
    user_id: str

class MatchMoveRequest(BaseModel):
    match_id: str
    destination: str  # "rejected", "scheduled", "connections"

class IdRequest(BaseModel):
    id: str

class UserMatchRequest(BaseModel):
    id: str
    user_id: str

class LocationUpdateRequest(BaseModel):
    user_id: str
    geolocation: 'Geolocation'

class Geolocation(BaseModel):
    lat: float
    long: float

    def to_json(self) -> dict:
        return {
            "lat": self.lat,
            "long": self.long,
        }

    @classmethod
    def from_json(cls, data: dict):
        return cls(
            lat=data.get("lat", 0.0),
            long=data.get("long", 0.0),
        )


class TemporaryModification(BaseModel):
    start: datetime
    modification: str

class PreviousConnection(BaseModel):
    userId: int
    related: str
    connectionTime: datetime
    connectionPlace: Geolocation  # or Optional[str] if just name