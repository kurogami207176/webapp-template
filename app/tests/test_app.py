from unittest.mock import MagicMock, patch

import pytest

from app import app as flask_app


@pytest.fixture
def client():
    flask_app.config["TESTING"] = True
    with flask_app.test_client() as c:
        yield c


# ---------------------------------------------------------------------------
# Existing routes (DB pool not configured — get_pool returns None)
# ---------------------------------------------------------------------------

@pytest.fixture(autouse=True)
def no_db_pool():
    """Ensure get_pool() returns None for all tests by default."""
    with patch("app.get_pool", return_value=None):
        yield


def test_health(client):
    res = client.get("/health")
    assert res.status_code == 200
    data = res.get_json()
    assert data["status"] == "ok"
    assert "timestamp" in data


def test_index(client):
    res = client.get("/")
    assert res.status_code == 200
    assert res.get_json()["message"] == "webapp-template API"


def test_hello(client):
    res = client.get("/hello")
    assert res.status_code == 200
    assert res.get_json()["message"] == "Hello, world!"


def test_404(client):
    res = client.get("/nonexistent")
    assert res.status_code == 404
    assert res.get_json()["error"] == "Not found"


# ---------------------------------------------------------------------------
# /health/db — pool not configured
# ---------------------------------------------------------------------------

def test_health_db_unconfigured(client):
    res = client.get("/health/db")
    assert res.status_code == 503
    assert res.get_json()["status"] == "unconfigured"


# ---------------------------------------------------------------------------
# /health/db — pool configured and healthy
# ---------------------------------------------------------------------------

def test_health_db_ok(client):
    mock_conn = MagicMock()
    mock_pool = MagicMock()
    mock_pool.connection.return_value.__enter__ = lambda s: mock_conn
    mock_pool.connection.return_value.__exit__ = MagicMock(return_value=False)

    with patch("app.get_pool", return_value=mock_pool):
        res = client.get("/health/db")

    assert res.status_code == 200
    assert res.get_json()["status"] == "ok"
    mock_conn.execute.assert_called_once_with("SELECT 1")


# ---------------------------------------------------------------------------
# /health/db — pool configured but query fails
# ---------------------------------------------------------------------------

def test_health_db_error(client):
    mock_pool = MagicMock()
    mock_pool.connection.return_value.__enter__ = MagicMock(side_effect=Exception("connection refused"))
    mock_pool.connection.return_value.__exit__ = MagicMock(return_value=False)

    with patch("app.get_pool", return_value=mock_pool):
        res = client.get("/health/db")

    assert res.status_code == 503
    assert res.get_json()["status"] == "error"
