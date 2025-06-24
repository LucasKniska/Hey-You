from models.models import Geolocation, PreviousConnection, TemporaryModification
from pydantic import BaseModel
from datetime import datetime
from typing import List


class User(BaseModel):
    id: str
    email: str
    firstName: str
    lastName: str
    biography: str
    quizAnswers: List[int]
    temporaryModifications: List[TemporaryModification]
    permanentModifications: List[str]
    location: Geolocation
    currentMatch: str
    previousConnections: List[str]
    scheduledConnections: List[str]
    totalConnections: int = 0

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
            location=Geolocation.from_json(data.get('Location', {})),
            currentMatch=data.get("CurrentMatch") or "",
            previousConnections=data.get("PreviousConnections", []),
            scheduledConnections=data.get("ScheduledConnections", []),
            totalConnections=data.get("TotalConnections", 0)
        )