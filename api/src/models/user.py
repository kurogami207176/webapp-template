from dataclasses import dataclass, field
from datetime import datetime, timezone


def _now() -> str:
    return datetime.now(timezone.utc).isoformat()


@dataclass
class User:
    id: str
    email: str
    name: str
    hashed_password: str
    created_at: str = field(default_factory=_now)
    updated_at: str = field(default_factory=_now)

    def to_item(self) -> dict:
        return {
            "id": self.id,
            "email": self.email,
            "name": self.name,
            "hashed_password": self.hashed_password,
            "created_at": self.created_at,
            "updated_at": self.updated_at,
        }

    @classmethod
    def from_item(cls, item: dict) -> "User":
        return cls(
            id=item["id"],
            email=item["email"],
            name=item["name"],
            hashed_password=item["hashed_password"],
            created_at=item["created_at"],
            updated_at=item["updated_at"],
        )


@dataclass
class Session:
    refresh_token: str
    user_id: str
    expires_at: str  # ISO 8601

    def to_item(self) -> dict:
        return {
            "refresh_token": self.refresh_token,
            "user_id": self.user_id,
            "expires_at": self.expires_at,
        }

    @classmethod
    def from_item(cls, item: dict) -> "Session":
        return cls(
            refresh_token=item["refresh_token"],
            user_id=item["user_id"],
            expires_at=item["expires_at"],
        )
