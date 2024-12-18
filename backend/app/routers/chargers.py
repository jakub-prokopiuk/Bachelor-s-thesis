from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from app.models import EVCharger, Connector
from app.database import get_db
import requests
from dotenv import load_dotenv
import os
from math import radians, cos, sin, sqrt, atan2
from typing import Optional
from urllib.parse import unquote

load_dotenv()
router = APIRouter()
API_KEY = os.getenv("API_KEY")
BASE_URL = "https://api.tomtom.com/search/2/chargingAvailability.json"


def calculate_distance(lat1, lon1, lat2, lon2):
    R = 6371.0

    lat1_rad = radians(lat1)
    lon1_rad = radians(lon1)
    lat2_rad = radians(lat2)
    lon2_rad = radians(lon2)

    dlon = lon2_rad - lon1_rad
    dlat = lat2_rad - lat1_rad

    a = sin(dlat / 2)**2 + cos(lat1_rad) * cos(lat2_rad) * sin(dlon / 2)**2
    c = 2 * atan2(sqrt(a), sqrt(1 - a))

    distance = R * c
    return distance

@router.get("/chargers/")
def get_chargers(
    user_latitude: Optional[float] = None,
    user_longitude: Optional[float] = None,
    min_power: float = Query(None, description="Minimal power of the connector (in kW)"),
    max_power: float = Query(None, description="Maximal power of the connector (in kW)"),
    connector_types: str = Query(None, description="Comma-separated list of connector types (e.g., 'Type2,CCS,CHAdeMO')"),
    db: Session = Depends(get_db)
):
    query = db.query(EVCharger)

    if min_power is not None or max_power is not None or connector_types is not None:
        query = query.join(Connector)

    if min_power is not None:
        query = query.filter(Connector.rated_power_kw >= min_power)
    if max_power is not None:
        query = query.filter(Connector.rated_power_kw <= max_power)

    if connector_types is not None:
        connector_types_list = unquote(connector_types).split(',')
        query = query.filter(Connector.connector_type.in_(connector_types_list))

    chargers = query.all()

    if not chargers:
        raise HTTPException(status_code=404, detail="No chargers found with the specified filters.")
    
    if user_latitude is not None and user_longitude is not None:
        chargers_with_distance = []
        for charger in chargers:
            distance = calculate_distance(user_latitude, user_longitude, charger.latitude, charger.longitude)
            chargers_with_distance.append((charger, distance))

        chargers_with_distance.sort(key=lambda x: x[1])

        return [charger for charger, _ in chargers_with_distance]
    else:
        return chargers
    
@router.get("/chargers/{charger_id}")
def get_charger_details(charger_id: int, db: Session = Depends(get_db)):
    charger = db.query(EVCharger).filter(EVCharger.id == charger_id).first()

    if not charger:
        raise HTTPException(status_code=404, detail="Charger not found")

    charger_data = {
        "name": charger.name,
        "url": charger.url,
        "latitude": charger.latitude,
        "longitude": charger.longitude,
        "freeform_address": charger.freeform_address,
        "charging_availability": charger.charging_availability,
        "connectors": [
            {
                "connector_type": connector.connector_type,
                "rated_power_kw": connector.rated_power_kw,
                "current_type": connector.current_type,
            }
            for connector in charger.connectors
        ],
    }

    return charger_data

@router.get("/charging-status/{charger_id}")
def get_charging_status(
    charger_id: int,
    db: Session = Depends(get_db)
):
    charger = db.query(EVCharger).filter(EVCharger.id == charger_id).first()

    if not charger:
        raise HTTPException(status_code=404, detail="Charger not found")
    
    if not charger.charging_availability:
        raise HTTPException(status_code=400, detail="Charging availability not found for this charger")

    url = f"{BASE_URL}?key={API_KEY}&chargingAvailability={charger.charging_availability}"

    try:
        response = requests.get(url)
        response.raise_for_status()

        availability_data = response.json()

        connectors = availability_data.get("connectors", [])
        status = {}
        
        for connector in connectors:
            connector_type = connector.get("type")
            availability = connector.get("availability", {}).get("current", {})
            status[connector_type] = {
                "available": availability.get("available"),
                "occupied": availability.get("occupied"),
                "reserved": availability.get("reserved"),
                "outOfService": availability.get("outOfService")
            }

        return status

    except requests.exceptions.RequestException as e:
        raise HTTPException(status_code=500, detail=f"Error making the request: {e}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"An unexpected error occurred: {e}")
