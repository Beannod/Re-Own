from backend.app.core.logging_config import get_logger, log_exception

api_logger = get_logger('api')

def log_property_event(msg):
    api_logger.info(msg)

def log_property_error(msg, exc=None):
    if exc:
        log_exception(api_logger, msg, exc)
    else:
        api_logger.error(msg)
import os
from fastapi import APIRouter, HTTPException, status, UploadFile, File, Request, Depends
from typing import List, Optional
from ..database import StoredProcedures
from ..schemas import property as property_schema
from ..core.dependencies import get_current_user, require_owner_access
from datetime import datetime

router = APIRouter(
    prefix="/properties",
    tags=["Properties"]
)

@router.get("/", response_model=List[property_schema.Property])
def list_properties(current_user: dict = Depends(require_owner_access)):
    # Return only properties owned by the authenticated user
    result = StoredProcedures.execute_sp("sp_GetAllProperties", [current_user['user_id']])
    return result or []

@router.post("/", response_model=property_schema.Property)
def create_property(property_data: property_schema.PropertyCreate, current_user: dict = Depends(require_owner_access)):
    # Use authenticated user's ID for ownership
    owner_id = current_user['user_id']
    try:
        result = StoredProcedures.create_property(
            owner_id=owner_id,
            title=property_data.title,
            address=property_data.address,
            property_type=property_data.property_type,
            bedrooms=property_data.bedrooms,
            bathrooms=property_data.bathrooms,
            area=property_data.area,
            rent_amount=property_data.rent_amount,
            deposit_amount=property_data.deposit_amount,
            description=property_data.description,
            status=property_data.status
        )
    except Exception as e:
        # Surface DB/validation errors to client with a specific code
        raise HTTPException(status_code=500, detail=str(e), headers={"X-Error-Code": "CREATE_PROPERTY_FAILED"})
    if not result:
        raise HTTPException(status_code=400, detail="Failed to create property", headers={"X-Error-Code": "CREATE_PROPERTY_FAILED"})
    try:
        new_id = int(list(result[0].values())[0]) if 'PropertyId' not in result[0] else int(result[0]['PropertyId'])
    except Exception:
        # Fallback if column alias differs
        new_id = int(result[0].get('id') or result[0].get('ID') or result[0].get('property_id'))
    row = StoredProcedures.execute_sp("sp_GetProperty", [new_id])
    return row[0]

@router.get("/{property_id}", response_model=property_schema.Property)
def get_property(property_id: int, current_user: dict = Depends(require_owner_access)):
    # Verify property ownership
    result = StoredProcedures.execute_sp("sp_GetProperty", [property_id])
    if not result or result[0]['owner_id'] != current_user['user_id']:
        raise HTTPException(status_code=404, detail="Property not found")
    return result[0]

@router.put("/{property_id}", response_model=property_schema.Property)
def update_property(property_id: int, property_data: property_schema.PropertyUpdate, current_user: dict = Depends(require_owner_access)):
    # Verify property ownership
    owner_id = current_user['user_id']
    existing = StoredProcedures.execute_sp("sp_GetProperty", [property_id])
    if not existing or existing[0]['owner_id'] != owner_id:
        raise HTTPException(status_code=404, detail="Property not found or access denied")
    
    try:
        result = StoredProcedures.update_property(
            property_id=property_id,
            title=property_data.title,
            address=property_data.address,
            property_type=property_data.property_type,
            bedrooms=property_data.bedrooms,
            bathrooms=property_data.bathrooms,
            area=property_data.area,
            rent_amount=property_data.rent_amount,
            deposit_amount=property_data.deposit_amount,
            description=property_data.description,
            status=property_data.status
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e), headers={"X-Error-Code": "UPDATE_PROPERTY_FAILED"})
    
    if not result or result[0]['AffectedRows'] == 0:
        raise HTTPException(status_code=404, detail="Property not found")
    row = StoredProcedures.execute_sp("sp_GetProperty", [property_id])
    return row[0]

@router.delete("/{property_id}")
def delete_property(property_id: int, current_user: dict = Depends(require_owner_access)):
    # Verify property ownership
    existing = StoredProcedures.execute_sp("sp_GetProperty", [property_id])
    if not existing or existing[0]['owner_id'] != current_user['user_id']:
        raise HTTPException(status_code=404, detail="Property not found or access denied")
        
    result = StoredProcedures.delete_property(property_id)
    if not result or result[0]['AffectedRows'] == 0:
        raise HTTPException(status_code=404, detail="Property not found")
    return {"message": "Property deleted successfully"}

# Property Documents
UPLOAD_DIR = os.getenv("UPLOAD_DIR", os.path.join(os.getcwd(), "uploads", "property_docs"))
os.makedirs(UPLOAD_DIR, exist_ok=True)

@router.post("/{property_id}/documents")
async def upload_property_documents(property_id: int, files: List[UploadFile] = File(...), current_user: dict = Depends(require_owner_access)):
    # Verify property ownership
    existing = StoredProcedures.execute_sp("sp_GetProperty", [property_id])
    if not existing or existing[0]['owner_id'] != current_user['user_id']:
        raise HTTPException(status_code=404, detail="Property not found or access denied")
        
    saved = []
    for f in files:
        safe_name = f.filename.replace('..', '').replace('/', '_').replace('\\', '_')
        file_path = os.path.join(UPLOAD_DIR, safe_name)
        with open(file_path, 'wb') as out:
            out.write(await f.read())
        StoredProcedures.add_property_document(property_id, safe_name, file_path, f.content_type)
        saved.append({"file_name": safe_name})
    return {"uploaded": len(saved), "files": saved}

@router.get("/{property_id}/documents")
def list_property_documents(property_id: int, request: Request, current_user: dict = Depends(get_current_user)):
    # Verify access based on role
    if current_user['role'] == 'owner':
        # Verify property ownership
        existing = StoredProcedures.execute_sp("sp_GetProperty", [property_id])
        if not existing or existing[0]['owner_id'] != current_user['user_id']:
            raise HTTPException(status_code=404, detail="Property not found or access denied")
    elif current_user['role'] == 'renter':
        # Verify renter has access to this property through active lease
        leases = StoredProcedures.list_leases(tenant_id=current_user['user_id'])
        has_access = False
        for lease in leases or []:
            prop_id = lease.get('property_id') if 'property_id' in lease else lease.get('unit_id')
            if prop_id == property_id and lease.get('status', '').lower() == 'active':
                has_access = True
                break
        if not has_access:
            raise HTTPException(status_code=404, detail="Property not found or access denied")
    else:
        raise HTTPException(status_code=403, detail="Access denied")
        
    docs = StoredProcedures.list_property_documents(property_id) or []
    # Build absolute URL to backend's uploads so it works when frontend is served from a different origin
    base = str(request.base_url).rstrip('/') + '/uploads/property_docs/'
    for d in docs:
        fname = os.path.basename(d.get('file_path', ''))
        d['url'] = base + fname
    return docs

@router.delete("/documents/{document_id}")
def delete_property_document(document_id: int, current_user: dict = Depends(require_owner_access)):
    # Get document and verify property ownership
    docs = StoredProcedures.execute_sp("sp_GetPropertyDocument", [document_id])
    if not docs:
        raise HTTPException(status_code=404, detail="Document not found")
    
    property_id = docs[0]['property_id']
    existing = StoredProcedures.execute_sp("sp_GetProperty", [property_id])
    if not existing or existing[0]['owner_id'] != current_user['user_id']:
        raise HTTPException(status_code=404, detail="Document not found or access denied")
        
    result = StoredProcedures.delete_property_document(document_id)
    if not result or int(result[0]['AffectedRows']) == 0:
        raise HTTPException(status_code=404, detail="Document not found")
    return {"message": "Document deleted successfully"}
