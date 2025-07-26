from datetime import datetime
from typing import List, Optional
from enums import *
from models.models import Geolocation
from pydantic import BaseModel


# Matching Object
class UserMatchData(BaseModel):
    id: str
    userName: str
    userBio: str
    response: UserResponse
    location: Geolocation
    connections: Optional[int] = 0  # Added field

    def to_json(self) -> dict:
        return {
            "id": self.id,
            "userName": self.userName,
            "userBio": self.userBio,
            "response": self.response,
            "location": self.location.to_json(),
            "connections": self.connections  # Added field
        }

    @classmethod
    def from_json(cls, data: dict):
        return cls(
            id=data["id"],
            userName=data["userName"],
            userBio=data["userBio"],
            response=UserResponse.from_json(data["response"]),
            location=Geolocation.from_json(data["location"]),
            connections=data.get("connections", 0)  # Added field
        )

class Match(BaseModel):
    id: Optional[str] = None
    expirationTime: datetime
    related: List[str]
    createdOn: datetime
    possibleTimes: List[datetime]
    possiblePlaces: List[Geolocation]
    meetingPlace: Optional[Geolocation] = None
    userData: List[UserMatchData]
    status: MatchStatus
    distance: Optional[float] = None  # Added field

    def to_json(self) -> dict:
        return {
            "id": self.id,
            "expirationTime": self.expirationTime.isoformat(),
            "related": self.related,
            "createdOn": self.createdOn.isoformat(),
            "possibleTimes": [dt.isoformat() for dt in self.possibleTimes],
            "possiblePlaces": [place.to_json() for place in self.possiblePlaces],
            "meetingPlace": self.meetingPlace.to_json() if self.meetingPlace else None,
            "userData": [user.to_json() for user in self.userData],
            "status": self.status,
            "distance": self.distance  # Added field
        }

    @classmethod
    def from_json(cls, data: dict):
        print(data)
        return cls(
            id=data.get("id"),
            expirationTime=datetime.fromisoformat(data["expirationTime"]),
            related=data["related"],
            createdOn=datetime.fromisoformat(data["createdOn"]),
            possibleTimes=[datetime.fromisoformat(dt) for dt in data["possibleTimes"]],
            possiblePlaces=[Geolocation.from_json(p) for p in data["possiblePlaces"]],
            meetingPlace=Geolocation.from_json(data["meetingPlace"]) if data.get("meetingPlace") else None,
            userData=[UserMatchData.from_json(u) for u in data["userData"]],
            status=data.get("status") if data.get("status") else MatchStatus.NEW,
            distance=data.get("distance")  # Added field
        )
