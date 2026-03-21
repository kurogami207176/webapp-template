import pytest
from fastapi import HTTPException

from src.schemas.auth import LoginRequest, RegisterRequest
from src.services.auth import AuthService


def test_register_raises_on_duplicate_email(aws_mock):
    service = AuthService()
    body = RegisterRequest(email="test@example.com", password="password123", name="Test")
    service.register(body)

    with pytest.raises(HTTPException) as exc_info:
        service.register(body)

    assert exc_info.value.status_code == 409


def test_register_returns_tokens(aws_mock):
    service = AuthService()
    result = service.register(
        RegisterRequest(email="new@example.com", password="password123", name="New User")
    )
    assert result.access_token
    assert result.refresh_token
    assert result.user.email == "new@example.com"


def test_login_raises_on_wrong_password(aws_mock):
    service = AuthService()
    service.register(RegisterRequest(email="test@example.com", password="correct", name="Test"))

    with pytest.raises(HTTPException) as exc_info:
        service.login(LoginRequest(email="test@example.com", password="wrong"))

    assert exc_info.value.status_code == 401


def test_login_raises_on_unknown_email(aws_mock):
    service = AuthService()

    with pytest.raises(HTTPException) as exc_info:
        service.login(LoginRequest(email="nobody@example.com", password="pass"))

    assert exc_info.value.status_code == 401


def test_refresh_rotates_token(aws_mock):
    service = AuthService()
    first = service.register(
        RegisterRequest(email="test@example.com", password="pass123", name="Test")
    )
    second = service.refresh(first.refresh_token)

    assert second.access_token
    assert second.refresh_token != first.refresh_token


def test_refresh_fails_with_invalid_token(aws_mock):
    service = AuthService()

    with pytest.raises(HTTPException) as exc_info:
        service.refresh("not-a-real-token")

    assert exc_info.value.status_code == 401
