from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_get_chargers_with_coordinates():
    response = client.get("/api/chargers/?northEast_latitude=50.0&northEast_longitude=20.0&southWest_latitude=49.0&southWest_longitude=19.0")
    assert response.status_code == 200
    assert len(response.json()) != 0

def test_get_chargers_with_wrong_coordinates():
    response = client.get("/api/chargers/?northEast_latitude=10.0&northEast_longitude=15.0&southWest_latitude=10.0&southWest_longitude=15.0")
    assert response.status_code == 404

def test_get_chargers_with_connection_type():
    response = client.get("/api/chargers/?northEast_latitude=50.0&northEast_longitude=20.0&southWest_latitude=49.0&southWest_longitude=19.0&min_power=50&max_power=100&connector_type=Chademo")
    assert response.status_code == 200
    assert len(response.json()) != 0

def test_get_chargers_with_min_power():
    response = client.get("/api/chargers/?northEast_latitude=50.0&northEast_longitude=20.0&southWest_latitude=49.0&southWest_longitude=19.0&min_power=50")
    assert response.status_code == 200
    assert len(response.json()) != 0

def test_get_chargers_with_max_power():
    response = client.get("/api/chargers/?northEast_latitude=50.0&northEast_longitude=20.0&southWest_latitude=49.0&southWest_longitude=19.0&max_power=100")
    assert response.status_code == 200
    assert len(response.json()) != 0

def test_get_chargers_with_min_max_power():
    response = client.get("/api/chargers/?northEast_latitude=50.0&northEast_longitude=20.0&southWest_latitude=49.0&southWest_longitude=19.0&min_power=50&max_power=100")
    assert response.status_code == 200
    assert len(response.json()) != 0