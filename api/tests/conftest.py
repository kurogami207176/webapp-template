import os

import boto3
import pytest
from httpx import ASGITransport, AsyncClient
from moto import mock_aws

# Set env vars before importing app modules so config validation passes
os.environ.setdefault("JWT_SECRET", "test-secret-that-is-long-enough-32ch")
os.environ.setdefault("AWS_DEFAULT_REGION", "us-east-1")
os.environ.setdefault("AWS_ACCESS_KEY_ID", "testing")
os.environ.setdefault("AWS_SECRET_ACCESS_KEY", "testing")
os.environ.setdefault("USERS_TABLE_NAME", "webapp-users")
os.environ.setdefault("SESSIONS_TABLE_NAME", "webapp-sessions")


def create_tables() -> None:
    ddb = boto3.resource("dynamodb", region_name="us-east-1")

    ddb.create_table(
        TableName="webapp-users",
        KeySchema=[{"AttributeName": "id", "KeyType": "HASH"}],
        AttributeDefinitions=[
            {"AttributeName": "id", "AttributeType": "S"},
            {"AttributeName": "email", "AttributeType": "S"},
        ],
        GlobalSecondaryIndexes=[
            {
                "IndexName": "email-index",
                "KeySchema": [{"AttributeName": "email", "KeyType": "HASH"}],
                "Projection": {"ProjectionType": "ALL"},
            }
        ],
        BillingMode="PAY_PER_REQUEST",
    )

    ddb.create_table(
        TableName="webapp-sessions",
        KeySchema=[{"AttributeName": "refresh_token", "KeyType": "HASH"}],
        AttributeDefinitions=[{"AttributeName": "refresh_token", "AttributeType": "S"}],
        BillingMode="PAY_PER_REQUEST",
    )


@pytest.fixture
def aws_mock():
    """Spin up moto mock DynamoDB tables for a single test."""
    with mock_aws():
        create_tables()
        yield


@pytest.fixture
async def client(aws_mock):
    from src.main import app

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        yield ac
