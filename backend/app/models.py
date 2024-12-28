from datetime import datetime
from sqlalchemy import Column, Integer, String, Float, Text, ForeignKey, DateTime
from sqlalchemy.orm import relationship
from app.database import Base

class EVCharger(Base):
    __tablename__ = 'ev_chargers'
    id = Column(Integer, primary_key=True)
    external_id = Column(String(255), unique=True, nullable=False)
    name = Column(String(255))
    brand_name = Column(String(255))
    url = Column(Text)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    street_name = Column(String(255))
    municipality = Column(String(255))
    postal_code = Column(String(10))
    freeform_address = Column(Text)
    charging_availability = Column(Text)
    connectors = relationship("Connector", back_populates="charger", cascade="all, delete-orphan")

    favorited_by = relationship("Favorite", back_populates="charger", cascade="all, delete-orphan")

class Connector(Base):
    __tablename__ = 'connectors'
    id = Column(Integer, primary_key=True)
    charger_id = Column(Integer, ForeignKey('ev_chargers.id'), nullable=False)
    connector_type = Column(String(50), nullable=False)
    rated_power_kw = Column(Float)
    voltage_v = Column(Integer)
    current_a = Column(Integer)
    current_type = Column(String(10))
    charger = relationship("EVCharger", back_populates="connectors")

class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, nullable=False)
    email = Column(String, unique=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    favorites = relationship("Favorite", back_populates="user", cascade="all, delete-orphan")

class Favorite(Base):
    __tablename__ = "favorites"
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    charger_id = Column(Integer, ForeignKey("ev_chargers.id", ondelete="CASCADE"), nullable=False)

    user = relationship("User", back_populates="favorites")
    charger = relationship("EVCharger", back_populates="favorited_by")
