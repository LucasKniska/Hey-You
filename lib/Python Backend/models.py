from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime
from enum import Enum

# === Models ===
class UserIDRequest(BaseModel):
    user_ids: List[str]

class SingleUserRequest(BaseModel):
    user_id: str

class MatchMoveRequest(BaseModel):
    match_id: str
    destination: str  # "rejected", "scheduled", "connections"

class Geolocation(BaseModel):
    lat: float
    lon: float
    name: Optional[str] = None

    @classmethod
    def from_json(cls, data: dict):
        return cls(
            lat=data.get("lat", 0.0),
            lon=data.get("lon", 0.0),
            name=data.get("name", None)
        )
    
class UserResponse(str, Enum):
    MEET_NOW = "meet_now"
    MEET_LATER = "meet_later"
    REJECT = "reject"
    NOT_SELECTED = "not_selected"

class TemporaryModification(BaseModel):
    start: datetime
    modification: str

class PreviousConnection(BaseModel):
    userId: int
    related: str
    connectionTime: datetime
    connectionPlace: Geolocation  # or Optional[str] if just name

class User(BaseModel):
    id: str
    email: str
    firstName: str
    lastName: str
    biography: str
    quizAnswers: List[int]
    temporaryModifications: List[TemporaryModification]
    permanentModifications: List[str]
    geolocation: Geolocation
    currentMatch: str
    previousConnections: List[PreviousConnection]
    scheduledConnections: List[str]

    @classmethod
    def from_json(cls, data: dict):
        return cls(
            id=data.get("id", ""),
            email=data.get("Email", ""),
            firstName=data.get("FirstName", ""),
            lastName=data.get("LastName", ""),
            biography=data.get("Biography", ""),
            quizAnswers=data.get("QuizAnswers", []),
            temporaryModifications=[
                TemporaryModification(
                    start=datetime.fromisoformat(tm["start"]),
                    modification=tm["modification"]
                )
                for tm in data.get("TemporaryModifications", [])
            ],
            permanentModifications=data.get("PermanentModifications", []),
            geolocation=Geolocation.from_json(data.get('Location', {})),
            currentMatch=data.get("CurrentMatch") or "",
            previousConnections=[
                PreviousConnection(
                    userId=pc["serId"],
                    related=pc["related"],
                    connectionTime=datetime.fromisoformat(pc["connectionTime"]),
                    connectionPlace=Geolocation(**pc["connectionPlace"])
                )
                for pc in data.get("PreviousConnections", [])
            ],
            scheduledConnections=data.get("ScheduledConnections", [])
        )



# Matching Object
class UserMatchData(BaseModel):
    id: str
    userName: str
    userBio: str
    response: UserResponse

class Match(BaseModel):
    id: Optional[str] = None
    expirationTime: datetime
    related: List[str]  # should be length 2
    createdOn: datetime
    possibleTimes: List[datetime]  # up to 3 timestamps
    possiblePlaces: List[Geolocation]  # up to 3 geolocations
    currentProposedPlace: Optional[Geolocation] = None  # agreed midpoint
    userData: List[UserMatchData]