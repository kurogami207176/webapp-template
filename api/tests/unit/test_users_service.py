import pytest
from fastapi import HTTPException

from src.schemas.auth import RegisterRequest
from src.schemas.user import UpdateUserRequest
from src.services.auth import AuthService
from src.services.users import UsersService


def test_get_user_not_found(aws_mock):
    service = UsersService()
    with pytest.raises(HTTPException) as exc_info:
        service.get_by_id("nonexistent-id")
    assert exc_info.value.status_code == 404


def test_list_users_pagination(aws_mock):
    auth_service = AuthService()
    for i in range(5):
        auth_service.register(
            RegisterRequest(email=f"user{i}@example.com", password="pass123", name=f"User {i}")
        )

    result = UsersService().list_users(page=1, limit=3)
    assert len(result.data) == 3
    assert result.pagination["total"] == 5
    assert result.pagination["pages"] == 2


def test_update_user(aws_mock):
    auth_service = AuthService()
    auth_resp = auth_service.register(
        RegisterRequest(email="test@example.com", password="pass123", name="Original")
    )

    updated = UsersService().update(auth_resp.user.id, UpdateUserRequest(name="Updated"))
    assert updated.name == "Updated"


def test_update_user_not_found(aws_mock):
    with pytest.raises(HTTPException) as exc_info:
        UsersService().update("nonexistent", UpdateUserRequest(name="X"))
    assert exc_info.value.status_code == 404


def test_delete_user(aws_mock):
    auth_resp = AuthService().register(
        RegisterRequest(email="test@example.com", password="pass123", name="Test")
    )
    UsersService().delete(auth_resp.user.id)

    with pytest.raises(HTTPException) as exc_info:
        UsersService().get_by_id(auth_resp.user.id)
    assert exc_info.value.status_code == 404


def test_delete_user_not_found(aws_mock):
    with pytest.raises(HTTPException) as exc_info:
        UsersService().delete("nonexistent")
    assert exc_info.value.status_code == 404
