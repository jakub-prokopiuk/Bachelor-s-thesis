from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_register_user():
    response = client.post("/api/register", json={
        "username": "testuser",
        "email": "testuser@example.com",
        "password": "password123"
    })
    assert response.status_code == 200
    assert response.json() == {"message": "User created successfully", "username": "testuser"}

def test_register_existing_user():
    response = client.post("/api/register", json={
        "username": "testuser",
        "email": "testuser@example.com",
        "password": "password123"
    })
    assert response.status_code == 400
    assert response.json() == {"detail": "Username already registered"}

def test_login_user():
    response = client.post("/api/login", json={
        "username": "testuser",
        "password": "password123"
    })
    assert response.status_code == 200
    assert "access_token" in response.json()

def test_non_existing_login_user():
    response = client.post("/api/login", json={
        "username": "nonexistinguser",
        "password": "nonexistingpassword"
    })
    assert response.status_code == 401
    assert response.json() == {"detail": "Invalid credentials"}