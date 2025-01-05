from sqlalchemy import create_engine, Column, Integer, String, Text, DECIMAL, ForeignKey, TIMESTAMP
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship
from sqlalchemy.orm import sessionmaker
import os

Base = declarative_base()

class EVCharger(Base):
    __tablename__ = 'ev_chargers'
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    external_id = Column(String(255), unique=True, nullable=False)
    name = Column(String(255))
    brand_name = Column(String(255))
    url = Column(Text)
    latitude = Column(DECIMAL(9, 6), nullable=False)
    longitude = Column(DECIMAL(9, 6), nullable=False)
    street_name = Column(String(255))
    municipality = Column(String(255))
    postal_code = Column(String(10))
    freeform_address = Column(Text)
    charging_availability = Column(Text)

class Connector(Base):
    __tablename__ = 'connectors'
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    charger_id = Column(Integer, ForeignKey('ev_chargers.id', ondelete='CASCADE'))
    connector_type = Column(String(50), nullable=False)
    rated_power_kw = Column(DECIMAL(5, 2))
    voltage_v = Column(Integer)
    current_a = Column(Integer)
    current_type = Column(String(10))
    
    charger = relationship('EVCharger', backref='connectors')

class User(Base):
    __tablename__ = 'users'
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    username = Column(String(255), unique=True, nullable=False)
    email = Column(String(255), unique=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    created_at = Column(TIMESTAMP, default='CURRENT_TIMESTAMP')

class Favorite(Base):
    __tablename__ = "favorites"

    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    charger_id = Column(Integer, ForeignKey("ev_chargers.id", ondelete="CASCADE"), nullable=False)

    user = relationship("User", back_populates="favorites")
    charger = relationship("EVCharger", back_populates="favorited_by")


DATABASE_URL = "sqlite:///" + os.path.join(os.path.dirname(os.path.dirname(__file__)), "ev_chargers.db")
engine = create_engine(DATABASE_URL, echo=True)

Base.metadata.create_all(engine)

Session = sessionmaker(bind=engine)
session = Session()

session.close()
