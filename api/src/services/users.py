from fastapi import HTTPException
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from ..models.user import User
from ..schemas.user import PaginatedUsers, UpdateUserRequest, UserResponse


class UsersService:
    def __init__(self, db: AsyncSession) -> None:
        self.db = db

    async def list_users(self, page: int, limit: int) -> PaginatedUsers:
        offset = (page - 1) * limit
        result = await self.db.execute(
            select(User).order_by(User.created_at.desc()).offset(offset).limit(limit)
        )
        users = result.scalars().all()

        count_result = await self.db.execute(select(func.count()).select_from(User))
        total = count_result.scalar_one()

        return PaginatedUsers(
            data=[UserResponse.model_validate(u) for u in users],
            pagination={"page": page, "limit": limit, "total": total, "pages": -(-total // limit)},
        )

    async def get_by_id(self, user_id: str) -> UserResponse:
        result = await self.db.execute(select(User).where(User.id == user_id))
        user = result.scalar_one_or_none()
        if not user:
            raise HTTPException(status_code=404, detail=f"User '{user_id}' not found")
        return UserResponse.model_validate(user)

    async def update(self, user_id: str, body: UpdateUserRequest) -> UserResponse:
        result = await self.db.execute(select(User).where(User.id == user_id))
        user = result.scalar_one_or_none()
        if not user:
            raise HTTPException(status_code=404, detail=f"User '{user_id}' not found")

        if body.name is not None:
            user.name = body.name
        if body.email is not None:
            user.email = body.email

        await self.db.commit()
        await self.db.refresh(user)
        return UserResponse.model_validate(user)

    async def delete(self, user_id: str) -> None:
        result = await self.db.execute(select(User).where(User.id == user_id))
        user = result.scalar_one_or_none()
        if not user:
            raise HTTPException(status_code=404, detail=f"User '{user_id}' not found")
        await self.db.delete(user)
        await self.db.commit()
