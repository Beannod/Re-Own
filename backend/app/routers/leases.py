from fastapi import APIRouter, Query, HTTPException, Depends
from typing import Optional
import logging
from ..schemas import lease as lease_schema
from ..database import StoredProcedures
from ..core.dependencies import get_current_user, require_owner_access

router = APIRouter(
    prefix="/leases",
    tags=["Leases"]
)


@router.post("/", response_model=lease_schema.Lease)
def create_lease(payload: lease_schema.LeaseCreate):
    try:
        # Create lease with required fields
        result = StoredProcedures.execute_sp("sp_CreateLease", [
            payload.tenant_id,
            payload.property_id,
            payload.start_date,
            payload.rent_amount
        ])
        
        if not result:
            raise HTTPException(status_code=400, detail="Failed to create lease")
            
        lease_id = int(result[0].get('LeaseId', 0))
        if lease_id == 0:
            raise HTTPException(status_code=400, detail="Failed to obtain new lease ID")
            
        lease = StoredProcedures.get_lease(lease_id)
        if not lease:
            raise HTTPException(status_code=404, detail="Created lease not found")
            
        return lease[0]
        
    except Exception as e:
        # Try to extract a user-friendly SQL error message from pyodbc
        raw = str(e)
        msg = None
        try:
            # Common pyodbc format includes `[SQL Server]Your message (XXXXX)`
            marker = "] [SQL Server]"
            if marker in raw:
                msg = raw.split(marker, 1)[1]
                # Trim trailing code like ` (50000)` and anything after
                if " (" in msg:
                    msg = msg.split(" (", 1)[0]
            else:
                # Fallback: look for our validation phrases
                for key in [
                    "Invalid tenant ID",
                    "Invalid property ID",
                    "Invalid rent amount",
                    "Invalid start date",
                    "Tenant already has an active lease",
                    "Property already has an active lease"
                ]:
                    if key in raw:
                        msg = key
                        break
        except Exception:
            msg = None

        if msg:
            raise HTTPException(status_code=400, detail=msg)

        # Log unexpected errors but don't expose internals to client
        logging.error(f"Lease creation failed: {raw}")
        raise HTTPException(status_code=500, detail="Failed to create lease. Please try again later.")


@router.get("/all")
def get_all_owner_leases(current_user: dict = Depends(require_owner_access)):
    """Get all leases for properties owned by the current user"""
    try:
        # Fetch properties owned by the user
        properties_result = StoredProcedures.execute_sp("sp_GetAllProperties", [current_user['user_id']])
        if not properties_result:
            return []

        property_ids = [str(prop['id']) for prop in properties_result]

        # Get all leases for these properties
        all_leases = []
        for property_id in property_ids:
            leases_result = StoredProcedures.execute_sp("sp_GetLeasesByProperty", [property_id])
            if leases_result:
                for lease in leases_result:
                    # Get property details inline from the already fetched list
                    pid = lease.get('property_id') or lease.get('unit_id')
                    property_info = next((p for p in properties_result if p['id'] == pid), {})

                    # Get tenant details
                    tenant_result = StoredProcedures.execute_sp("sp_GetUserById", [lease['tenant_id']])
                    tenant_info = tenant_result[0] if tenant_result else {}

                    lease_with_details = {
                        **lease,
                        'property_title': property_info.get('title', 'Unknown Property'),
                        'tenant_name': tenant_info.get('full_name') or f"{tenant_info.get('first_name', '')} {tenant_info.get('last_name', '')}".strip(),
                        'tenant_email': tenant_info.get('email', 'Unknown Email')
                    }
                    all_leases.append(lease_with_details)

        return all_leases

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to retrieve leases: {str(e)}")


@router.put("/{lease_id}", response_model=lease_schema.Lease)
def update_lease(lease_id: int, payload: lease_schema.LeaseUpdate):
    result = StoredProcedures.update_lease(
        lease_id=lease_id,
        start_date=payload.start_date,
        end_date=payload.end_date,
        rent_amount=payload.rent_amount,
        deposit_amount=payload.deposit_amount,
        status=payload.status
    )
    if not result or int(result[0]['AffectedRows']) == 0:
        raise HTTPException(status_code=404, detail="Lease not found")
    # Return updated lease
    lease = StoredProcedures.get_lease(lease_id)
    return lease[0]


@router.get("/")
def list_leases(tenant_id: Optional[int] = Query(default=None), unit_id: Optional[int] = Query(default=None), current_user: dict = Depends(get_current_user)):
    # Role-based filtering
    if current_user['role'] == 'renter':
        # Renters can only see their own leases
        tenant_id = current_user['user_id']
    elif current_user['role'] == 'owner':
        # Owners can see leases for their properties (add property ownership check if needed)
        pass
    
    result = StoredProcedures.list_leases(tenant_id=tenant_id, unit_id=unit_id)
    return result or []

@router.get("/current")
def get_current_lease(current_user: dict = Depends(get_current_user)):
    """Get the current active lease for the authenticated renter"""
    if current_user['role'] != 'renter':
        raise HTTPException(status_code=403, detail="Only renters can access this endpoint")
    
    # Get active lease for the current renter
    leases = StoredProcedures.list_leases(tenant_id=current_user['user_id'])
    active_lease = None
    
    for lease in leases or []:
        if lease.get('status', '').lower() == 'active':
            active_lease = lease
            break
    
    if not active_lease:
        raise HTTPException(status_code=404, detail="No active lease found")
    
    # Get property details
    property_result = StoredProcedures.execute_sp("sp_GetProperty", [active_lease.get('property_id') or active_lease.get('unit_id')])
    property_info = property_result[0] if property_result else None
    
    # Get owner details  
    owner_result = None
    if property_info:
        owner_result = StoredProcedures.execute_sp("sp_GetUserById", [property_info['owner_id']])
        # Get owner profile for additional contact info
        if owner_result:
            profile_result = StoredProcedures.execute_sp("sp_GetOwnerProfile", [property_info['owner_id']])
            if profile_result:
                owner_result[0].update(profile_result[0])
    
    return {
        **active_lease,
        'property': property_info,
        'owner': owner_result[0] if owner_result else None
    }

@router.get("/{lease_id}/agreement")
def download_lease_agreement(lease_id: int, current_user: dict = Depends(get_current_user)):
    """Download lease agreement PDF"""
    # Get lease details
    lease_result = StoredProcedures.get_lease(lease_id)
    if not lease_result:
        raise HTTPException(status_code=404, detail="Lease not found")
    
    lease = lease_result[0]
    
    # Verify access
    if current_user['role'] == 'renter':
        if lease['tenant_id'] != current_user['user_id']:
            raise HTTPException(status_code=403, detail="Access denied")
    elif current_user['role'] == 'owner':
        # Verify property ownership
        property_result = StoredProcedures.execute_sp("sp_GetProperty", [lease.get('property_id') or lease.get('unit_id')])
        if not property_result or property_result[0]['owner_id'] != current_user['user_id']:
            raise HTTPException(status_code=403, detail="Access denied")
    
    # For now, return a placeholder response
    # In a real implementation, you would generate or retrieve the actual PDF
    from fastapi.responses import PlainTextResponse
    
    agreement_text = f"""
RENTAL AGREEMENT

Lease ID: {lease_id}
Tenant ID: {lease['tenant_id']}
Property/Unit ID: {lease.get('property_id') or lease.get('unit_id')}
Start Date: {lease['start_date']}
End Date: {lease.get('end_date', 'N/A')}
Monthly Rent: ${lease['rent_amount']}
Security Deposit: ${lease.get('deposit_amount', 'N/A')}
Status: {lease['status']}

This is a placeholder agreement document.
In a production system, this would be a proper PDF lease agreement.
"""
    
    return PlainTextResponse(
        content=agreement_text,
        headers={
            "Content-Disposition": f"attachment; filename=lease-agreement-{lease_id}.txt",
            "Content-Type": "text/plain"
        }
    )

@router.post("/assign")
def assign_property_to_tenant(payload: dict, current_user: dict = Depends(require_owner_access)):
    """Assign a property to a tenant by creating a new lease"""
    try:
        # Extract data from payload
        property_id = payload.get('property_id')
        tenant_email = payload.get('tenant_email')
        start_date = payload.get('start_date')
        end_date = payload.get('end_date')
        rent_amount = payload.get('rent_amount')
        deposit_amount = payload.get('deposit_amount')
        
        if not all([property_id, tenant_email, start_date, rent_amount]):
            raise HTTPException(status_code=400, detail="Missing required fields")
        
        # Verify property ownership
        property_result = StoredProcedures.execute_sp("sp_GetProperty", [property_id])
        if not property_result or property_result[0]['owner_id'] != current_user['user_id']:
            raise HTTPException(status_code=403, detail="Access denied to this property")
        
        # Find tenant by email
        tenant_result = StoredProcedures.execute_sp("sp_GetUserByEmail", [tenant_email])
        if not tenant_result:
            raise HTTPException(status_code=404, detail="Tenant not found with that email")
        
        tenant = tenant_result[0]
        if tenant['role'] != 'renter':
            raise HTTPException(status_code=400, detail="User is not a renter")
        
        # Check if property is already occupied
        existing_lease = StoredProcedures.get_active_lease_by_property(property_id)
        if existing_lease:
            raise HTTPException(status_code=400, detail="Property is already occupied")
        
        # Create the lease
        result = StoredProcedures.create_lease(
            tenant_id=tenant['user_id'],
            unit_id=property_id,
            start_date=start_date,
            end_date=end_date,
            rent_amount=rent_amount,
            deposit_amount=deposit_amount,
            status='active'
        )
        
        if not result:
            raise HTTPException(status_code=400, detail="Failed to create lease")
        
        lease_id = int(result[0]['LeaseId'])
        lease = StoredProcedures.get_lease(lease_id)
        return {"message": "Property assigned successfully", "lease": lease[0]}
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to assign property: {str(e)}")


@router.post("/assign-by-id")
def assign_property_to_tenant_by_id(payload: dict, current_user: dict = Depends(require_owner_access)):
    """Assign a property to a tenant using renter_id instead of email."""
    try:
        property_id = payload.get('property_id')
        renter_id = payload.get('renter_id')
        start_date = payload.get('start_date')
        end_date = payload.get('end_date')
        rent_amount = payload.get('rent_amount')
        deposit_amount = payload.get('deposit_amount')

        if not all([property_id, renter_id, start_date, rent_amount]):
            raise HTTPException(status_code=400, detail="Missing required fields")

        # Verify property ownership
        property_result = StoredProcedures.execute_sp("sp_GetProperty", [property_id])
        if not property_result or property_result[0]['owner_id'] != current_user['user_id']:
            raise HTTPException(status_code=403, detail="Access denied to this property")

        # Get renter by ID and validate role
        renter_result = StoredProcedures.execute_sp("sp_GetUserById", [renter_id])
        if not renter_result:
            raise HTTPException(status_code=404, detail="Renter not found")
        renter = renter_result[0]
        if str(renter.get('role', '')).lower() != 'renter':
            raise HTTPException(status_code=400, detail="User is not a renter")

        # Check if property is already occupied
        existing_lease = StoredProcedures.get_active_lease_by_property(property_id)
        if existing_lease:
            raise HTTPException(status_code=400, detail="Property is already occupied")

        # Create lease
        result = StoredProcedures.create_lease(
            tenant_id=renter['user_id'] if 'user_id' in renter else renter.get('id') or renter_id,
            unit_id=property_id,
            start_date=start_date,
            end_date=end_date,
            rent_amount=rent_amount,
            deposit_amount=deposit_amount,
            status='active'
        )

        if not result:
            raise HTTPException(status_code=400, detail="Failed to create lease")

        lease_id = int(result[0]['LeaseId'])
        lease = StoredProcedures.get_lease(lease_id)
        return {"message": "Property assigned successfully", "lease": lease[0]}

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to assign property by id: {str(e)}")

# Note: Place dynamic leaf route `/{lease_id}` AFTER static routes like `/invite` and `/invites`

@router.post("/invite")
def invite_renter_to_lease(payload: dict, current_user: dict = Depends(require_owner_access)):
    """Owner creates a lease invitation instead of immediate lease creation."""
    try:
        renter_id = payload.get('renter_id')
        property_id = payload.get('property_id')
        start_date = payload.get('start_date')
        rent_amount = payload.get('rent_amount')
        deposit_amount = payload.get('deposit_amount')
        if not all([renter_id, property_id, start_date, rent_amount]):
            raise HTTPException(status_code=400, detail="Missing required fields")

        # Verify property ownership
        prop = StoredProcedures.execute_sp("sp_GetProperty", [property_id])
        if not prop or prop[0]['owner_id'] != current_user['user_id']:
            raise HTTPException(status_code=403, detail="Access denied to this property")

        res = StoredProcedures.execute_sp("sp_CreateLeaseInvitation", [
            current_user['user_id'], renter_id, property_id, start_date, rent_amount, deposit_amount
        ])
        return {"status": "success", "invitation_id": int(res[0]['InvitationId']) if res else None}
    except HTTPException:
        raise
    except Exception as e:
        logging.error(f"Invite creation failed: {e}")
        raise HTTPException(status_code=500, detail="Failed to create lease invitation")

@router.get("/invites")
def list_my_lease_invitations(current_user: dict = Depends(get_current_user)):
    """List pending lease invitations for the current renter."""
    if current_user['role'] != 'renter':
        raise HTTPException(status_code=403, detail="Only renters can view invitations")
    res = StoredProcedures.execute_sp("sp_ListLeaseInvitationsForRenter", [current_user['user_id']])
    return res or []

@router.post("/invites/{invitation_id}/approve")
def approve_invitation(invitation_id: int, current_user: dict = Depends(get_current_user)):
    if current_user['role'] != 'renter':
        raise HTTPException(status_code=403, detail="Only renters can approve invitations")
    try:
        res = StoredProcedures.execute_sp("sp_ApproveLeaseInvitation", [invitation_id])
        if not res:
            raise HTTPException(status_code=400, detail="Invitation not found or not pending")
        # Some drivers return AffectedRows for the update; if present and 0, treat as not pending
        try:
            if 'AffectedRows' in res[0] and int(res[0]['AffectedRows']) == 0:
                raise HTTPException(status_code=400, detail="Invitation not found or not pending")
        except Exception:
            pass
        return {"status": "approved"}
    except HTTPException:
        raise
    except Exception as e:
        # Extract user-friendly SQL Server message if available
        raw = str(e)
        msg = None
        try:
            marker = "] [SQL Server]"
            if marker in raw:
                msg = raw.split(marker, 1)[1]
                if " (" in msg:
                    msg = msg.split(" (", 1)[0]
            else:
                for key in [
                    "Invalid tenant ID",
                    "Invalid property ID",
                    "Invalid rent amount",
                    "Invalid start date",
                    "Tenant already has an active lease",
                    "Property already has an active lease",
                    "Invitation not found or not pending"
                ]:
                    if key in raw:
                        msg = key
                        break
        except Exception:
            msg = None

        if msg:
            raise HTTPException(status_code=400, detail=msg)

        logging.error(f"Approve invitation failed: {raw}")
        raise HTTPException(status_code=500, detail="Failed to approve invitation")

@router.post("/invites/{invitation_id}/reject")
def reject_invitation(invitation_id: int, current_user: dict = Depends(get_current_user)):
    if current_user['role'] != 'renter':
        raise HTTPException(status_code=403, detail="Only renters can reject invitations")
    try:
        res = StoredProcedures.execute_sp("sp_RejectLeaseInvitation", [invitation_id])
        if not res or int(res[0]['AffectedRows']) == 0:
            raise HTTPException(status_code=400, detail="Invitation not found or not pending")
        return {"status": "rejected"}
    except HTTPException:
        raise
    except Exception as e:
        logging.error(f"Reject invitation failed: {e}")
        raise HTTPException(status_code=500, detail="Failed to reject invitation")

@router.get("/{lease_id}", response_model=lease_schema.Lease)
def get_lease(lease_id: int):
    result = StoredProcedures.execute_sp("sp_GetLease", [lease_id])
    if not result:
        raise HTTPException(status_code=404, detail="Lease not found")
    return result[0]

@router.put("/{lease_id}/terminate")
def terminate_lease(lease_id: int, current_user: dict = Depends(require_owner_access)):
    """Terminate an active lease"""
    try:
        # Get lease details
        lease_result = StoredProcedures.get_lease(lease_id)
        if not lease_result:
            raise HTTPException(status_code=404, detail="Lease not found")
        
        lease = lease_result[0]
        
        # Verify property ownership
        property_result = StoredProcedures.execute_sp("sp_GetProperty", [lease.get('property_id') or lease.get('unit_id')])
        if not property_result or property_result[0]['owner_id'] != current_user['user_id']:
            raise HTTPException(status_code=403, detail="Access denied to this property")
        
        # Update lease status to terminated
        result = StoredProcedures.update_lease(
            lease_id=lease_id,
            start_date=lease['start_date'],
            end_date=lease.get('end_date'),
            rent_amount=lease['rent_amount'],
            deposit_amount=lease.get('deposit_amount'),
            status='terminated'
        )
        
        if not result:
            raise HTTPException(status_code=400, detail="Failed to terminate lease")
        
        return {"message": "Lease terminated successfully"}
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to terminate lease: {str(e)}")
