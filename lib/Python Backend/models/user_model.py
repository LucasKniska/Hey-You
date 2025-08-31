from pydantic import BaseModel
from typing import List, Dict, Any, Optional
from datetime import datetime, time, timezone
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
    nearestBucket: str
    partition: str
    currentStreakTimer: Optional[datetime]
    llmScore: float = 0.0
    OCEANScore: float = 0.0
    llmCleanedJSON: Dict[str, Any] = {}
    llmEmbedding: Optional[List[float]] = None     # <-- NEW

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
                ) for tm in data.get("TemporaryModifications", [])
            ],
            llmScore=float(data.get("LLMScore", data.get("llmScore", 0.0)) or 0.0),
            OCEANScore=float(data.get("OCEANScore", 0.0) or 0.0),
            llmCleanedJSON=data.get("llmCleanedJSON", {}),
            llmEmbedding=data.get("llmEmbedding"),              # <-- NEW
            permanentModifications=data.get("PermanentModifications", []),
            location=Geolocation.from_json(data.get("Location", {})),
            currentMatch=data.get("CurrentMatch") or "",
            previousConnections=data.get("PreviousConnections", []),
            totalConnections=data.get("TotalConnections", 0),
            discoverable=data.get("Discoverable", False),
            longestStreak=data.get("LongestStreak", 0),
            currentStreakTimer=data.get("CurrentStreakTimer", None),
            currentStreak=data.get("CurrentStreak", 0),
            lastMatch=data["LastMatch"] if "LastMatch" in data else datetime.now(),
            nearestBucket=data.get("NearestBucket", ""),
            partition=data.get("Partition", "default")
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
            "llmCleanedJSON": self.llmCleanedJSON,
            "llmEmbedding": self.llmEmbedding,      # <-- NEW
            "TemporaryModifications": [tm.to_dict() for tm in self.temporaryModifications],
            "PermanentModifications": self.permanentModifications,
            "Location": self.location.to_dict(),
            "CurrentMatch": self.currentMatch,
            "PreviousConnections": self.previousConnections,
            "TotalConnections": self.totalConnections,
            "Discoverable": self.discoverable,
            "LongestStreak": self.longestStreak,
            "CurrentStreakTimer": self.currentStreakTimer.isoformat(),
            "CurrentStreak": self.currentStreak,
            "LastMatch": self.lastMatch.isoformat(),
            "NearestBucket": self.nearestBucket,
            "Partition": self.partition
        }
