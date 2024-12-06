import requests
from sqlalchemy.exc import IntegrityError
from app.database import SessionLocal
from app.crud import update_db
from dotenv import load_dotenv
import os

load_dotenv()

API_KEY = os.getenv("API_KEY")
BASE_URL = 'https://api.tomtom.com/search/2/poiSearch'

def fetch_chargers_for_rectangle(top_left, btm_right, limit=100):
    """
    Fetches chargers for rectangle defined by top left and bottom right coordinates
    """
    url = f"{BASE_URL}/EV charging station.json"
    params = {
        'key': API_KEY,
        'countrySet': 'PL',
        'topLeft': f"{top_left[0]},{top_left[1]}",
        'btmRight': f"{btm_right[0]},{btm_right[1]}",
        'limit': limit,
    }
    response = requests.get(url, params=params)
    if response.status_code == 200:
        data = response.json()
        return data.get('results', []), data.get('summary', {}).get('totalResults', 0)
    else:
        print(f"Error: {response.status_code} for rectangle {top_left}, {btm_right}")
        return [], 0

def fetch_with_split_and_update_db(session, top_left, btm_right, step_lat, step_lon, limit=100):
    """
    Recursively fetch chargers for a rectangle and save them to the database.
    """
    results, total_results = fetch_chargers_for_rectangle(top_left, btm_right, limit)
    
    if total_results == limit:  # If we have to divide grid into smaller pieces
        mid_lat = (top_left[0] + btm_right[0]) / 2
        mid_lon = (top_left[1] + btm_right[1]) / 2
        
        sub_rects = [
            ((top_left[0], top_left[1]), (mid_lat, mid_lon)),
            ((top_left[0], mid_lon), (mid_lat, btm_right[1])),
            ((mid_lat, top_left[1]), (btm_right[0], mid_lon)),
            ((mid_lat, mid_lon), (btm_right[0], btm_right[1]))
        ]
        
        for sub_rect in sub_rects:
            fetch_with_split_and_update_db(session, *sub_rect, step_lat / 2, step_lon / 2, limit)
    else:
        try:
            update_db(session, results)
            print(f"Saved {len(results)} chargers for rectangle {top_left}, {btm_right}")
        except IntegrityError as e:
            print(f"Error saving chargers for rectangle {top_left}, {btm_right}: {e}")
            session.rollback()

def generate_grid_with_corners(min_lat, max_lat, min_lon, max_lon, step_lat, step_lon):
    """
    Divides the area into a grid of rectangles in top left and bottom right format.
    """
    grid = []
    lat = min_lat
    while lat < max_lat:
        lon = min_lon
        while lon < max_lon:
            top_left = (lat + step_lat, lon)
            btm_right = (lat, lon + step_lon)
            
            if top_left[0] > max_lat:
                top_left = (max_lat, top_left[1])
            if btm_right[1] > max_lon:
                btm_right = (btm_right[0], max_lon)
            
            grid.append((top_left, btm_right))
            lon += step_lon
        lat += step_lat
    return grid

def fetch_and_save_ev_chargers_in_poland():
    """
    Fetches all EV chargers in Poland and saves them directly to the database.
    """
    min_lat, max_lat = 49.0, 55.0
    min_lon, max_lon = 14.0, 24.0
    step_lat, step_lon = 0.5, 0.5

    grid = generate_grid_with_corners(min_lat, max_lat, min_lon, max_lon, step_lat, step_lon)
    session = SessionLocal()
    
    try:
        for rectangle in grid:
            top_left, btm_right = rectangle
            fetch_with_split_and_update_db(session, top_left, btm_right, step_lat, step_lon)
        print("All chargers saved successfully.")
    except Exception as e:
        print(f"An error occurred: {e}")
        session.rollback()
    finally:
        session.close()

if __name__ == "__main__":
    fetch_and_save_ev_chargers_in_poland()
