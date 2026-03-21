from fastapi import APIRouter, Depends

from ..dependencies import get_current_user
from ..models.user import User
from ..schemas.auth import AuthResponse, LoginRequest, RefreshRequest, RegisterRequest
from ..services.auth import AuthService

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register", response_model=AuthResponse, status_code=201)
def register(body: RegisterRequest):
    return AuthService().register(body)


@router.post("/login", response_model=AuthResponse)
def login(body: LoginRequest):
    return AuthService().login(body)


@router.post("/refresh", response_model=AuthResponse)
def refresh(body: RefreshRequest):
    return AuthService().refresh(body.refresh_token)


@router.post("/logout", status_code=204)
def logout(body: RefreshRequest, _: User = Depends(get_current_user)):
    AuthService().logout(body.refresh_token)
