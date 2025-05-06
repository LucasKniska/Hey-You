from enum import Enum


class MatchStatus(str, Enum):
    NEW = "new"
    REJECTED = "rejected"
    SCHEDULED = "scheduled"
    SCHEDULED_ACCEPTED = "scheduled_accepted"
    NOW = "now"

    def to_json(self) -> str:
        return self.value

    @classmethod
    def from_json(cls, data: str):
        return cls(data)


class UserResponse(str, Enum):
    MEET_NOW = "meet_now"
    MEET_LATER = "meet_later"
    MEET_LATER_ACCEPTED = "meet_later_accepted"
    REJECT = "reject"
    NOT_SELECTED = "not_selected"

    def to_json(self) -> str:
        return self.value

    @classmethod
    def from_json(cls, data: str):
        return cls(data)