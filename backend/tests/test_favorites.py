import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

@pytest.fixture
def access_token():
    login_response = client.post("/api/login", json={
        "username": "exampleUser",
        "password": "examplePassword"
    })
    assert login_response.status_code == 200
    token = login_response.json().get("access_token")
    assert token is not None
    return token


def test_add_to_favorites(access_token):
    response = client.post(
        "/api/favorites/",
        json={"charger_id": 123},
        headers={"Authorization": f"Bearer {access_token}"}
    )

    assert response.status_code == 200
    assert response.json() == {"message": "Charger added to favorites"}

def test_already_added_charger_to_favorites(access_token):
    response = client.post(
        "/api/favorites/",
        json={"charger_id": 123},
        headers={"Authorization": f"Bearer {access_token}"}
    )
    
    assert response.status_code == 409
    assert response.json() == {"detail": "Charger already in to favorites"}

def test_adding_non_existing_charger(access_token):
    response = client.post(
        "/api/favorites/",
        json={"charger_id": 123123123151},
        headers={"Authorization": f"Bearer {access_token}"}
    )
    
    assert response.status_code == 404
    assert response.json() == {"detail": "Charger not found"}
