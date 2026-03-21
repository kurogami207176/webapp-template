from fastapi import APIRouter

from ..config import settings
from ..database import get_dynamodb

router = APIRouter(tags=["health"])


@router.get("/health")
def health():
    ddb_status = "ok"
    try:
        ddb = get_dynamodb()
        ddb.meta.client.describe_table(TableName=settings.users_table_name)
    except Exception:
        ddb_status = "error"

    status = "ok" if ddb_status == "ok" else "degraded"
    return {"status": status, "services": {"dynamodb": ddb_status}}
