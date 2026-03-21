from fastapi import APIRouter, Depends, HTTPException, Query

from ..dependencies import get_current_user
from ..models.user import User
from ..schemas.user import PaginatedUsers, UpdateUserRequest, UserResponse
from ..services.users import UsersService

router = APIRouter(prefix="/users", tags=["users"])


@router.get("/", response_model=PaginatedUsers)
def list_users(
    page: int = Query(default=1, ge=1),
    limit: int = Query(default=20, ge=1, le=100),
    _: User = Depends(get_current_user),
):
    return UsersService().list_users(page, limit)


@router.get("/{user_id}", response_model=UserResponse)
def get_user(user_id: str, _: User = Depends(get_current_user)):
    return UsersService().get_by_id(user_id)


@router.patch("/{user_id}", response_model=UserResponse)
def update_user(
    user_id: str,
    body: UpdateUserRequest,
    current_user: User = Depends(get_current_user),
):
    if current_user.id != user_id:
        raise HTTPException(status_code=403, detail="You can only update your own profile")
    return UsersService().update(user_id, body)


@router.delete("/{user_id}", status_code=204)
def delete_user(user_id: str, current_user: User = Depends(get_current_user)):
    if current_user.id != user_id:
        raise HTTPException(status_code=403, detail="You can only delete your own account")
    UsersService().delete(user_id)
