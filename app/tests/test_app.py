import pytest
from app import app as flask_app


@pytest.fixture
def client():
    flask_app.config["TESTING"] = True
    with flask_app.test_client() as c:
        yield c


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
