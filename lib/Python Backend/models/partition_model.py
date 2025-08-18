from pydantic import BaseModel
from typing import Any
from models.models import Geolocation

class PartitionModel(BaseModel):
    id: str
    location: Geolocation  # Replace 'Any' with Geolocation if you have that model
    username: str

    def to_json(self) -> dict:
        return {
            "id": self.id,
            "location": self.location.to_json() if hasattr(self.location, "to_json") else self.location,
            "username": self.username
        }

    @classmethod
    def from_json(cls, data: dict):
        return cls(
            id=data.get("id", ""),
            location=data.get("location"),
            username=data.get("username", "")
        )