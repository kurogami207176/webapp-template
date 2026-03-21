import secrets
from datetime import datetime, timedelta, timezone

from fastapi import HTTPException
from jose import jwt
from passlib.context import CryptContext

from ..config import settings
from ..database import get_table
from ..models.user import Session, User
from ..schemas.auth import AuthResponse, LoginRequest, RegisterRequest, UserInToken

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


class AuthService:
    def __init__(self) -> None:
        self.users = get_table(settings.users_table_name)
        self.sessions = get_table(settings.sessions_table_name)

    def register(self, body: RegisterRequest) -> AuthResponse:
        # Check for existing email via GSI
        result = self.users.query(
            IndexName="email-index",
            KeyConditionExpression="email = :email",
            ExpressionAttributeValues={":email": body.email},
        )
        if result["Items"]:
            raise HTTPException(status_code=409, detail="Email already registered")

        user = User(
            id=secrets.token_urlsafe(16),
            email=body.email,
            name=body.name,
            hashed_password=pwd_context.hash(body.password),
        )
        self.users.put_item(Item=user.to_item())
        return self._create_auth_response(user)

    def login(self, body: LoginRequest) -> AuthResponse:
        result = self.users.query(
            IndexName="email-index",
            KeyConditionExpression="email = :email",
            ExpressionAttributeValues={":email": body.email},
        )
        items = result["Items"]
        if not items or not pwd_context.verify(body.password, items[0]["hashed_password"]):
            raise HTTPException(status_code=401, detail="Invalid email or password")

        return self._create_auth_response(User.from_item(items[0]))

    def refresh(self, refresh_token: str) -> AuthResponse:
        result = self.sessions.get_item(Key={"refresh_token": refresh_token})
        session_item = result.get("Item")

        if not session_item:
            raise HTTPException(status_code=401, detail="Invalid or expired refresh token")

        session = Session.from_item(session_item)
        if datetime.fromisoformat(session.expires_at) < datetime.now(timezone.utc):
            self.sessions.delete_item(Key={"refresh_token": refresh_token})
            raise HTTPException(status_code=401, detail="Invalid or expired refresh token")

        user_result = self.users.get_item(Key={"id": session.user_id})
        user = User.from_item(user_result["Item"])

        self.sessions.delete_item(Key={"refresh_token": refresh_token})
        return self._create_auth_response(user)

    def logout(self, refresh_token: str) -> None:
        self.sessions.delete_item(Key={"refresh_token": refresh_token})

    def _create_auth_response(self, user: User) -> AuthResponse:
        access_token = self._create_access_token(user.id)
        refresh_token = secrets.token_hex(32)
        expires_at = (
            datetime.now(timezone.utc) + timedelta(days=settings.refresh_token_expire_days)
        ).isoformat()

        session = Session(
            refresh_token=refresh_token, user_id=user.id, expires_at=expires_at
        )
        self.sessions.put_item(Item=session.to_item())

        return AuthResponse(
            access_token=access_token,
            refresh_token=refresh_token,
            user=UserInToken(id=user.id, email=user.email, name=user.name),
        )

    def _create_access_token(self, user_id: str) -> str:
        expire = datetime.now(timezone.utc) + timedelta(
            minutes=settings.access_token_expire_minutes
        )
        return jwt.encode(
            {"sub": user_id, "exp": expire},
            settings.jwt_secret,
            algorithm=settings.jwt_algorithm,
        )
