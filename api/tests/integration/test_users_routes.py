import pytest


async def _register_and_login(client, email="test@example.com"):
    reg = await client.post(
        "/api/v1/auth/register",
        json={"email": email, "password": "password123", "name": "Test User"},
    )
    return reg.json()


@pytest.mark.asyncio
async def test_list_users_requires_auth(client):
    response = await client.get("/api/v1/users/")
    assert response.status_code == 403


@pytest.mark.asyncio
async def test_list_users_authenticated(client):
    auth = await _register_and_login(client)
    response = await client.get(
        "/api/v1/users/",
        headers={"Authorization": f"Bearer {auth['access_token']}"},
    )
    assert response.status_code == 200
    body = response.json()
    assert "data" in body
    assert "pagination" in body


@pytest.mark.asyncio
async def test_get_own_user(client):
    auth = await _register_and_login(client)
    response = await client.get(
        f"/api/v1/users/{auth['user']['id']}",
        headers={"Authorization": f"Bearer {auth['access_token']}"},
    )
    assert response.status_code == 200
    assert response.json()["email"] == "test@example.com"


@pytest.mark.asyncio
async def test_update_other_user_returns_403(client):
    auth1 = await _register_and_login(client, "user1@example.com")
    auth2 = await _register_and_login(client, "user2@example.com")

    response = await client.patch(
        f"/api/v1/users/{auth2['user']['id']}",
        json={"name": "Hacker"},
        headers={"Authorization": f"Bearer {auth1['access_token']}"},
    )
    assert response.status_code == 403
