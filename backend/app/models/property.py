from sqlalchemy import Column, Integer, String, Float, ForeignKey, DateTime, Text, Boolean
from sqlalchemy.sql import func
from ..database import Base

class Property(Base):
    __tablename__ = "properties"

    id = Column(Integer, primary_key=True, index=True)
    owner_id = Column(Integer, ForeignKey("users.id"))
    
    # Basic Property Information
    title = Column(String(200))
    property_code = Column(String(50), unique=True, nullable=True)
    address = Column(String(500))
    street = Column(String(200), nullable=True)
    city = Column(String(100), nullable=True)
    state = Column(String(100), nullable=True)
    zip_code = Column(String(20), nullable=True)
    property_type = Column(String(50))  # Flat / House / Commercial / Land
    bedrooms = Column(Integer)
    bathrooms = Column(Integer)
    area = Column(Float)
    floor_number = Column(Integer, nullable=True)
    total_floors = Column(Integer, nullable=True)
    status = Column(String(50))  # Available / Occupied / Under Maintenance
    furnishing_type = Column(String(50), nullable=True)  # Furnished / Semi-Furnished / Unfurnished
    parking_space = Column(String(100), nullable=True)  # Yes / No / Number of slots
    balcony = Column(String(100), nullable=True)  # Yes / No / Number of balconies
    facing_direction = Column(String(20), nullable=True)  # North / South / East / West
    age_of_property = Column(Integer, nullable=True)  # in years
    description = Column(Text)
    
    # Financial / Rate Details
    rent_amount = Column(Float)
    deposit_amount = Column(Float, nullable=True)
    electricity_rate = Column(Float, nullable=True)  # per unit
    internet_rate = Column(Float, nullable=True)  # monthly
    water_bill = Column(Float, nullable=True)  # Monthly / Fixed
    maintenance_charges = Column(Float, nullable=True)  # Monthly / Optional
    gas_charges = Column(Float, nullable=True)  # if applicable
    
    # Amenities / Features
    elevator = Column(Boolean, nullable=True)  # Yes / No
    gym_pool_clubhouse = Column(Boolean, nullable=True)  # Yes / No
    security_features = Column(String(500), nullable=True)  # CCTV, Guard
    garden_park_access = Column(Boolean, nullable=True)
    internet_provider = Column(String(200), nullable=True)  # Plan Name
    
    # Other Info
    owner_name = Column(String(200), nullable=True)
    owner_contact = Column(String(50), nullable=True)
    listing_date = Column(DateTime(timezone=True), server_default=func.now())
    lease_terms_default = Column(String(1000), nullable=True)  # min lease, notice period
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
