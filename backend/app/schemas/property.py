from pydantic import BaseModel, validator
from typing import Optional
from datetime import datetime

class PropertyBase(BaseModel):
    # Basic Property Information
    title: str
    property_code: Optional[str] = None
    address: str
    street: Optional[str] = None
    city: Optional[str] = None
    state: Optional[str] = None
    zip_code: Optional[str] = None
    property_type: str  # Flat / House / Commercial / Land
    bedrooms: int
    bathrooms: int
    area: float
    floor_number: Optional[int] = None
    total_floors: Optional[int] = None
    status: str  # Available / Occupied / Under Maintenance
    furnishing_type: Optional[str] = None  # Furnished / Semi-Furnished / Unfurnished
    parking_space: Optional[str] = None  # Yes / No / Number of slots
    balcony: Optional[str] = None  # Yes / No / Number of balconies
    facing_direction: Optional[str] = None  # North / South / East / West
    age_of_property: Optional[int] = None  # in years
    description: Optional[str] = None
    
    # Financial / Rate Details
    rent_amount: float
    deposit_amount: Optional[float] = None
    electricity_rate: Optional[float] = None  # per unit
    internet_rate: Optional[float] = None  # monthly
    water_bill: Optional[float] = None  # Monthly / Fixed
    maintenance_charges: Optional[float] = None  # Monthly / Optional
    gas_charges: Optional[float] = None  # if applicable
    
    # Amenities / Features
    elevator: Optional[bool] = None  # Yes / No
    gym_pool_clubhouse: Optional[bool] = None  # Yes / No
    security_features: Optional[str] = None  # CCTV, Guard
    garden_park_access: Optional[bool] = None
    internet_provider: Optional[str] = None  # Plan Name
    
    # Other Info
    owner_name: Optional[str] = None
    owner_contact: Optional[str] = None
    listing_date: Optional[datetime] = None
    lease_terms_default: Optional[str] = None  # min lease, notice period

    @validator('property_type')
    def validate_property_type(cls, v):
        valid_types = ['Flat', 'House', 'Commercial', 'Land', 'Room', 'Apartment', 'Studio', 'Villa', 'Condo', 'Townhouse']
        if v not in valid_types:
            raise ValueError(f'Property type must be one of: {", ".join(valid_types)}')
        return v

    @validator('status')
    def validate_status(cls, v):
        # Normalize to proper case for consistency
        status_map = {
            'available': 'Available',
            'occupied': 'Occupied', 
            'under maintenance': 'Under Maintenance',
            'vacant': 'vacant',
            'rented': 'rented',
            'maintenance': 'maintenance'
        }
        normalized = status_map.get(v.lower() if v else '', v)
        valid_statuses = ['Available', 'Occupied', 'Under Maintenance', 'vacant', 'rented', 'maintenance']
        if normalized not in valid_statuses:
            raise ValueError(f'Status must be one of: {", ".join(valid_statuses)}')
        return normalized

    @validator('furnishing_type')
    def validate_furnishing_type(cls, v):
        if v is not None:
            valid_types = ['Furnished', 'Semi-Furnished', 'Unfurnished']
            if v not in valid_types:
                raise ValueError(f'Furnishing type must be one of: {", ".join(valid_types)}')
        return v

    @validator('facing_direction')
    def validate_facing_direction(cls, v):
        if v is not None:
            valid_directions = ['North', 'South', 'East', 'West', 'North-East', 'North-West', 'South-East', 'South-West']
            if v not in valid_directions:
                raise ValueError(f'Facing direction must be one of: {", ".join(valid_directions)}')
        return v

class PropertyCreate(PropertyBase):
    pass

class PropertyUpdate(PropertyBase):
    # Make all fields optional for updates
    title: Optional[str] = None
    address: Optional[str] = None
    property_type: Optional[str] = None
    bedrooms: Optional[int] = None
    bathrooms: Optional[int] = None
    area: Optional[float] = None
    rent_amount: Optional[float] = None
    status: Optional[str] = None

class PropertySummary(BaseModel):
    """Lightweight property model for list views"""
    id: int
    title: str
    address: str
    city: Optional[str] = None
    state: Optional[str] = None
    status: str
    monthly_rent: float
    rent_amount: float  # Alias for monthly_rent
    property_type: str
    bedrooms: int
    bathrooms: float
    area: float
    owner_id: int
    created_at: datetime
    updated_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True

class Property(PropertyBase):
    id: int
    owner_id: int
    created_at: datetime
    updated_at: Optional[datetime]

    class Config:
        from_attributes = True
