from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict

# Look for .env at the repo root (parent of api/), falling back to cwd.
_root_env = Path(__file__).parents[2] / ".env"


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=[str(_root_env), ".env"],
        env_file_encoding="utf-8",
        extra="ignore",
    )

    environment: str = "development"
    log_level: str = "info"

    # DynamoDB
    aws_region: str = "us-east-1"
    dynamodb_endpoint_url: str | None = None  # set in local/test to point at mock
    users_table_name: str = "webapp-users"
    sessions_table_name: str = "webapp-sessions"

    # Auth
    jwt_secret: str
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 15
    refresh_token_expire_days: int = 7

    cors_origins: list[str] = ["http://localhost:3000"]


settings = Settings()
