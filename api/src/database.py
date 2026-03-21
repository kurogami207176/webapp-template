import boto3
from mypy_boto3_dynamodb import DynamoDBServiceResource

from .config import settings


def get_dynamodb() -> DynamoDBServiceResource:
    kwargs: dict = {"region_name": settings.aws_region}
    if settings.dynamodb_endpoint_url:
        kwargs["endpoint_url"] = settings.dynamodb_endpoint_url
    return boto3.resource("dynamodb", **kwargs)  # type: ignore[return-value]


def get_table(table_name: str):  # type: ignore[return-value]
    return get_dynamodb().Table(table_name)
