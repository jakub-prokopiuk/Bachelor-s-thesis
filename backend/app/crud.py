from sqlalchemy.orm import Session
from app.models import EVCharger, Connector, User
from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# Create or Update chargers in the database
def update_db(session: Session, chargers: list[dict]):
    """
    Updates the database with new or changed chargers.

    :param session: Database session.
    :param chargers: List of dictionaries representing charger data.
    """
    existing_chargers = {c.external_id: c for c in session.query(EVCharger).all()}
    
    for charger in chargers:
        external_id = charger["id"]
        connectors_data = charger.get("chargingPark", {}).get("connectors", [])
        charging_availability = charger.get("dataSources", {}).get("chargingAvailability", {}).get("id")
        
        # Update existing record
        if external_id in existing_chargers:
            ev_charger = existing_chargers[external_id]
            ev_charger.name = charger["poi"].get("name")
            ev_charger.brand_name = charger["poi"]["brands"][0]["name"] if charger["poi"].get("brands") else None
            ev_charger.url = charger["poi"].get("url")
            ev_charger.latitude = charger["position"]["lat"]
            ev_charger.longitude = charger["position"]["lon"]
            ev_charger.street_name = charger["address"].get("streetName")
            ev_charger.municipality = charger["address"].get("municipality")
            ev_charger.postal_code = charger["address"].get("postalCode")
            ev_charger.freeform_address = charger["address"].get("freeformAddress")
            ev_charger.charging_availability = charging_availability
            
            # Update connectors
            ev_charger.connectors.clear()
            for connector in connectors_data:
                ev_charger.connectors.append(Connector(
                    connector_type=connector["connectorType"],
                    rated_power_kw=connector.get("ratedPowerKW"),
                    voltage_v=connector.get("voltageV"),
                    current_a=connector.get("currentA"),
                    current_type=connector.get("currentType"),
                ))
        else:
            # Create a new record
            ev_charger = EVCharger(
                external_id=external_id,
                name=charger["poi"].get("name"),
                brand_name=charger["poi"]["brands"][0]["name"] if charger["poi"].get("brands") else None,
                url=charger["poi"].get("url"),
                latitude=charger["position"]["lat"],
                longitude=charger["position"]["lon"],
                street_name=charger["address"].get("streetName"),
                municipality=charger["address"].get("municipality"),
                postal_code=charger["address"].get("postalCode"),
                freeform_address=charger["address"].get("freeformAddress"),
                charging_availability=charging_availability,
            )
            for connector in connectors_data:
                ev_charger.connectors.append(Connector(
                    connector_type=connector["connectorType"],
                    rated_power_kw=connector.get("ratedPowerKW"),
                    voltage_v=connector.get("voltageV"),
                    current_a=connector.get("currentA"),
                    current_type=connector.get("currentType"),
                ))
            session.add(ev_charger)
    
    # Commit changes
    session.commit()


# Fetch chargers in a specific bounding box
def get_chargers_in_bounds(session: Session, north_east: tuple[float, float], south_west: tuple[float, float]):
    """
    Fetches chargers located within the given bounding box.

    :param session: Database session.
    :param north_east: Tuple with NE coordinates (latitude, longitude).
    :param south_west: Tuple with SW coordinates (latitude, longitude).
    :return: List of EVCharger objects.
    """
    chargers = session.query(EVCharger).filter(
        EVCharger.latitude.between(south_west[0], north_east[0]),
        EVCharger.longitude.between(south_west[1], north_east[1])
    ).all()
    return chargers


# Delete a charger by its external ID
def delete_charger(session: Session, external_id: str):
    """
    Deletes a charger based on its `external_id`.

    :param session: Database session.
    :param external_id: External ID of the charger.
    """
    charger = session.query(EVCharger).filter_by(external_id=external_id).first()
    if charger:
        session.delete(charger)
        session.commit()


# Fetch a single charger by its external ID
def get_charger_by_external_id(session: Session, external_id: str):
    """
    Fetches a charger based on its `external_id`.

    :param session: Database session.
    :param external_id: External ID of the charger.
    :return: EVCharger object or None.
    """
    return session.query(EVCharger).filter_by(external_id=external_id).first()

def get_user_by_username(db: Session, username: str):
    return db.query(User).filter(User.username == username).first()

def create_user(db: Session, username: str, email: str, password: str):
    hashed_password = pwd_context.hash(password)
    user = User(username=username, email=email, hashed_password=hashed_password)
    db.add(user)
    db.commit()
    db.refresh(user)
    return user

def verify_password(plain_password: str, hashed_password: str):
    return pwd_context.verify(plain_password, hashed_password)