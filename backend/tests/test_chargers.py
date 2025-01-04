from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_get_chargers():
    response = client.get("/api/chargers/")
    assert response.status_code == 200
    assert len(response.json()) != 0

def test_get_chargers_with_coordinates():
    response = client.get("/api/chargers/?user_latitude=52.0&user_longitude=21.0")
    assert response.status_code == 200
    assert len(response.json()) != 0

def test_get_chargers_with_wrong_filters():
    response = client.get("/api/chargers/?min_power=1000")
    assert response.status_code == 404

def test_get_chargers_with_connector_types():
    response = client.get("/api/chargers/?connector_types=IEC62196Type3,Chademo")
    assert response.status_code == 200
    assert len(response.json()) != 0 

def test_get_chargers_with_min_power():
    response = client.get("/api/chargers/?min_power=22")
    assert response.status_code == 200
    assert len(response.json()) != 0 

def test_get_chargers_with_max_power():
    response = client.get("/api/chargers/?max_power=50")
    assert response.status_code == 200
    assert len(response.json()) != 0 

def test_get_chargers_with_min_max_power():
    response = client.get("/api/chargers/?min_power=22&max_power=50")
    assert response.status_code == 200
    assert len(response.json()) != 0 

def test_get_charger_details():
    response = client.get("/api/chargers/1")
    assert response.status_code == 200
    data = response.json()
    assert "name" in data
    assert "connectors" in data
    assert len(data["connectors"]) > 0

def test_get_charger_details_not_found():
    response = client.get("/api/chargers/9999")
    assert response.status_code == 404

def test_get_charging_status():
    response = client.get("/api/charging-status/7")
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, dict)

def test_get_charging_status_not_found():
    response = client.get("/api/charging-status/9999")
    assert response.status_code == 404
