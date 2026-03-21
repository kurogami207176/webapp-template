from datetime import datetime, timezone

from fastapi import HTTPException

from ..config import settings
from ..database import get_table
from ..models.user import User
from ..schemas.user import PaginatedUsers, UpdateUserRequest, UserResponse


class UsersService:
    def __init__(self) -> None:
        self.users = get_table(settings.users_table_name)

    def get_by_id(self, user_id: str) -> UserResponse:
        result = self.users.get_item(Key={"id": user_id})
        item = result.get("Item")
        if not item:
            raise HTTPException(status_code=404, detail=f"User '{user_id}' not found")
        return _to_response(User.from_item(item))

    def list_users(self, page: int, limit: int) -> PaginatedUsers:
        # DynamoDB scan — acceptable for user management at this scale.
        # For high-volume listing, use a GSI or ElasticSearch.
        result = self.users.scan()
        all_items = sorted(result["Items"], key=lambda x: x["created_at"], reverse=True)

        total = len(all_items)
        offset = (page - 1) * limit
        page_items = all_items[offset : offset + limit]

        return PaginatedUsers(
            data=[_to_response(User.from_item(i)) for i in page_items],
            pagination={"page": page, "limit": limit, "total": total, "pages": -(-total // limit)},
        )

    def update(self, user_id: str, body: UpdateUserRequest) -> UserResponse:
        result = self.users.get_item(Key={"id": user_id})
        item = result.get("Item")
        if not item:
            raise HTTPException(status_code=404, detail=f"User '{user_id}' not found")

        updates: dict = {"updated_at": datetime.now(timezone.utc).isoformat()}
        if body.name is not None:
            updates["name"] = body.name
        if body.email is not None:
            updates["email"] = body.email

        update_expr = "SET " + ", ".join(f"#k{i} = :v{i}" for i in range(len(updates)))
        names = {f"#k{i}": k for i, k in enumerate(updates)}
        values = {f":v{i}": v for i, v in enumerate(updates.values())}

        self.users.update_item(
            Key={"id": user_id},
            UpdateExpression=update_expr,
            ExpressionAttributeNames=names,
            ExpressionAttributeValues=values,
        )

        updated = {**item, **updates}
        return _to_response(User.from_item(updated))

    def delete(self, user_id: str) -> None:
        result = self.users.get_item(Key={"id": user_id})
        if not result.get("Item"):
            raise HTTPException(status_code=404, detail=f"User '{user_id}' not found")
        self.users.delete_item(Key={"id": user_id})


def _to_response(user: User) -> UserResponse:
    return UserResponse(
        id=user.id,
        email=user.email,
        name=user.name,
        created_at=user.created_at,
        updated_at=user.updated_at,
    )
