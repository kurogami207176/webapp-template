import pytest
from unittest.mock import AsyncMock, MagicMock, patch

from src.schemas.auth import LoginRequest, RegisterRequest


@pytest.mark.asyncio
async def test_register_raises_on_duplicate_email(db):
    from src.services.auth import AuthService
    from fastapi import HTTPException

    service = AuthService(db)
    body = RegisterRequest(email="test@example.com", password="password123", name="Test")

    await service.register(body)

    with pytest.raises(HTTPException) as exc_info:
        await service.register(body)

    assert exc_info.value.status_code == 409


@pytest.mark.asyncio
async def test_login_raises_on_wrong_password(db):
    from src.services.auth import AuthService
    from fastapi import HTTPException

    service = AuthService(db)
    await service.register(
        RegisterRequest(email="test@example.com", password="correct", name="Test")
    )

    with pytest.raises(HTTPException) as exc_info:
        await service.login(LoginRequest(email="test@example.com", password="wrong"))

    assert exc_info.value.status_code == 401


@pytest.mark.asyncio
async def test_login_raises_on_unknown_email(db):
    from src.services.auth import AuthService
    from fastapi import HTTPException

    service = AuthService(db)

    with pytest.raises(HTTPException) as exc_info:
        await service.login(LoginRequest(email="nobody@example.com", password="pass"))

    assert exc_info.value.status_code == 401
