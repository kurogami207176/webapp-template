import pytest
from fastapi import HTTPException

from src.schemas.auth import RegisterRequest
from src.schemas.user import UpdateUserRequest
from src.services.auth import AuthService
from src.services.users import UsersService


@pytest.mark.asyncio
async def test_get_user_not_found(db):
    service = UsersService(db)
    with pytest.raises(HTTPException) as exc_info:
        await service.get_by_id("nonexistent-id")
    assert exc_info.value.status_code == 404


@pytest.mark.asyncio
async def test_list_users_pagination(db):
    auth_service = AuthService(db)
    for i in range(5):
        await auth_service.register(
            RegisterRequest(email=f"user{i}@example.com", password="pass123", name=f"User {i}")
        )

    users_service = UsersService(db)
    result = await users_service.list_users(page=1, limit=3)
    assert len(result.data) == 3
    assert result.pagination["total"] == 5


@pytest.mark.asyncio
async def test_update_user(db):
    auth_service = AuthService(db)
    auth_resp = await auth_service.register(
        RegisterRequest(email="test@example.com", password="pass123", name="Original")
    )

    users_service = UsersService(db)
    updated = await users_service.update(auth_resp.user.id, UpdateUserRequest(name="Updated"))
    assert updated.name == "Updated"
