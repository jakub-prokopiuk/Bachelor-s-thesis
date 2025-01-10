from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_get_user_info():
    response = client.get("/api/user/22")
    assert response.status_code == 200
    data = response.json()
    assert "username" in data
    assert "email" in data
    assert "created_at" in data

def test_get_user_info_not_found():
    response = client.get("/api/user/9999")
    assert response.status_code == 404

def test_update_user():
    response = client.put("/api/user/22", json={"username": "test", "email": "changed_email@test.com", "password": "new_password"})
    assert response.status_code == 200
    data = response.json()
    assert "message" in data
    assert "username" in data
    assert data["username"] == "test"
    assert data["message"] == "User information updated successfully"


def test_update_user_not_found():
    response = client.put("/api/user/9999", json={"username": "test", "email": "changed_email@test.com", "password": "new_password"})
    assert response.status_code == 404
    assert response.json() == {"detail": "User not found"}

def test_delete_user_account():
    response = client.delete("/api/user/23")
    assert response.status_code == 200
    data = response.json()
    assert "message" in data
    assert data["message"] == "User account deleted successfully"

def test_delete_user_account_not_found():
    response = client.delete("/api/user/9999")
    assert response.status_code == 404
    assert response.json() == {"detail": "User not found"}

def test_reset_password():
    response = client.post("/api/reset-password", json={"email": "changed_email@test.com"})
    assert response.status_code == 200
    data = response.json()
    assert "message" in data
    assert data["message"] == "Password reset successful, email sent."

def test_reset_password_not_found():
    response = client.post("/api/reset-password", json={"email": "random@email.xyz"})
    assert response.status_code == 404
    assert response.json() == {"detail": "User not found"}