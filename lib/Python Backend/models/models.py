from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime


# === Models ===
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