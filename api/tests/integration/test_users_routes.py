import pytest


async def _register(client, email="test@example.com"):
    resp = await client.post(
        "/api/v1/auth/register",
        json={"email": email, "password": "password123", "name": "Test User"},
    )
    return resp.json()


@pytest.mark.asyncio
async def test_list_users_requires_auth(client):
    response = await client.get("/api/v1/users/")
    assert response.status_code == 403


@pytest.mark.asyncio
async def test_list_users_authenticated(client):
    auth = await _register(client)
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
    auth = await _register(client)
    response = await client.get(
        f"/api/v1/users/{auth['user']['id']}",
        headers={"Authorization": f"Bearer {auth['access_token']}"},
    )
    assert response.status_code == 200
    assert response.json()["email"] == "test@example.com"


@pytest.mark.asyncio
async def test_update_own_profile(client):
    auth = await _register(client)
    response = await client.patch(
        f"/api/v1/users/{auth['user']['id']}",
        json={"name": "Updated Name"},
        headers={"Authorization": f"Bearer {auth['access_token']}"},
    )
    assert response.status_code == 200
    assert response.json()["name"] == "Updated Name"


@pytest.mark.asyncio
async def test_update_other_user_returns_403(client):
    auth1 = await _register(client, "user1@example.com")
    auth2 = await _register(client, "user2@example.com")

    response = await client.patch(
        f"/api/v1/users/{auth2['user']['id']}",
        json={"name": "Hacker"},
        headers={"Authorization": f"Bearer {auth1['access_token']}"},
    )
    assert response.status_code == 403


@pytest.mark.asyncio
async def test_delete_own_account(client):
    auth = await _register(client)
    response = await client.delete(
        f"/api/v1/users/{auth['user']['id']}",
        headers={"Authorization": f"Bearer {auth['access_token']}"},
    )
    assert response.status_code == 204
