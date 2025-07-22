from pydantic import BaseModel
from typing import List, Dict, Any
from datetime import datetime
from models.models import Geolocation, TemporaryModification


class User(BaseModel):
    id: str
    email: str
    firstName: str
    lastName: str
    biography: str
    quizAnswers: Dict[str, Any]
    temporaryModifications: List[TemporaryModification]
    permanentModifications: List[str]
    location: Geolocation
    currentMatch: str
    previousConnections: List[str]
    totalConnections: int = 0
    discoverable: bool = False
    longestStreak: int = 0
    currentStreak: int = 0
    lastMatch: datetime = datetime.now()
    llmScore: float = 0.0
    OCEANScore: float = 0.0

    @classmethod
    def from_json(cls, data: Dict[str, Any]):
        return cls(
            id=data.get("id", ""),
            email=data.get("Email", ""),
            firstName=data.get("FirstName", ""),
            lastName=data.get("LastName", ""),
            biography=data.get("Biography", ""),
            quizAnswers=data.get("QuestionAnswers", {}),
            temporaryModifications=[
                TemporaryModification(
                    start=datetime.fromisoformat(tm["start"]),
                    modification=tm["modification"]
                )
                for tm in data.get("TemporaryModifications", [])
            ],
            llmScore=data.get("LLMScore", 0.0),
            OCEANScore=data.get("OCEANScore", 0.0),
            permanentModifications=data.get("PermanentModifications", []),
            location=Geolocation.from_json(data.get("Location", {})),
            currentMatch=data.get("CurrentMatch") or "",
            previousConnections=data.get("PreviousConnections", []),
            totalConnections=data.get("TotalConnections", 0),
            discoverable=data.get("Discoverable", False),
            longestStreak=data.get("LongestStreak", 0),
            currentStreak=data.get("CurrentStreak", 0),
            lastMatch=datetime.fromisoformat(data["LastMatch"]) if "LastMatch" in data else datetime.now()
        )

    def to_json(self):
        return {
            "id": self.id,
            "FirstName": self.firstName,
            "LastName": self.lastName,
            "Email": self.email,
            "Biography": self.biography,
            "QuestionAnswers": self.quizAnswers,
            "LLMScore": self.llmScore,
            "OCEANScore": self.OCEANScore,
            "TemporaryModifications": [tm.to_dict() for tm in self.temporaryModifications],
            "PermanentModifications": self.permanentModifications,
            "Location": self.location.to_dict(),
            "CurrentMatch": self.currentMatch,
            "PreviousConnections": self.previousConnections,
            "TotalConnections": self.totalConnections,
            "Discoverable": self.discoverable,
            "LongestStreak": self.longestStreak,
            "CurrentStreak": self.currentStreak,
            "LastMatch": self.lastMatch.isoformat()
        }