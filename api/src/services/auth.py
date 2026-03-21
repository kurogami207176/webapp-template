import secrets
from datetime import datetime, timedelta, timezone

from jose import jwt
from passlib.context import CryptContext
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..config import settings
from ..models.user import Session, User
from ..schemas.auth import AuthResponse, LoginRequest, RegisterRequest, UserInToken

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


class AuthService:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def register(self, body: RegisterRequest) -> AuthResponse:
        result = await self.db.execute(select(User).where(User.email == body.email))
        if result.scalar_one_or_none():
            from fastapi import HTTPException
            raise HTTPException(status_code=409, detail="Email already registered")

        user = User(
            email=body.email,
            name=body.name,
            hashed_password=pwd_context.hash(body.password),
        )
        self.db.add(user)
        await self.db.commit()
        await self.db.refresh(user)

        return await self._create_auth_response(user)

    async def login(self, body: LoginRequest) -> AuthResponse:
        result = await self.db.execute(select(User).where(User.email == body.email))
        user = result.scalar_one_or_none()

        if not user or not pwd_context.verify(body.password, user.hashed_password):
            from fastapi import HTTPException
            raise HTTPException(status_code=401, detail="Invalid email or password")

        return await self._create_auth_response(user)

    async def refresh(self, refresh_token: str) -> AuthResponse:
        from fastapi import HTTPException
        result = await self.db.execute(select(Session).where(Session.refresh_token == refresh_token))
        session = result.scalar_one_or_none()

        if not session or session.expires_at < datetime.now(timezone.utc):
            raise HTTPException(status_code=401, detail="Invalid or expired refresh token")

        user_result = await self.db.execute(select(User).where(User.id == session.user_id))
        user = user_result.scalar_one()

        await self.db.delete(session)
        await self.db.commit()

        return await self._create_auth_response(user)

    async def logout(self, refresh_token: str) -> None:
        result = await self.db.execute(select(Session).where(Session.refresh_token == refresh_token))
        session = result.scalar_one_or_none()
        if session:
            await self.db.delete(session)
            await self.db.commit()

    async def _create_auth_response(self, user: User) -> AuthResponse:
        access_token = self._create_access_token(user.id)
        refresh_token = secrets.token_hex(32)
        expires_at = datetime.now(timezone.utc) + timedelta(days=settings.refresh_token_expire_days)

        session = Session(user_id=user.id, refresh_token=refresh_token, expires_at=expires_at)
        self.db.add(session)
        await self.db.commit()

        return AuthResponse(
            access_token=access_token,
            refresh_token=refresh_token,
            user=UserInToken(id=user.id, email=user.email, name=user.name),
        )

    def _create_access_token(self, user_id: str) -> str:
        expire = datetime.now(timezone.utc) + timedelta(minutes=settings.access_token_expire_minutes)
        return jwt.encode(
            {"sub": user_id, "exp": expire},
            settings.jwt_secret,
            algorithm=settings.jwt_algorithm,
        )
