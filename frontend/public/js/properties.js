class Properties {
    static init() {
        this.loadProperties();
        this.bindOwnerActions();

        // Owner notifications bell placeholder
        const ownerBell = document.getElementById('nav-notifications');
        if (ownerBell) {
            ownerBell.addEventListener('click', async (e) => {
                e.preventDefault();
                try {
                    // Placeholder: later fetch owner notifications (e.g., pending invitations for owner)
                    await Swal.fire({
                        icon: 'info',
                        title: 'Notifications',
                        text: 'No new notifications right now.',
                        confirmButtonText: 'Close'
                    });
                } catch (err) {
                    console.error('Failed to open notifications', err);
                }
            });
        }
    }

    static async loadProperties() {
        try {
            const properties = await API.getProperties();
            // populate owner or renter views depending on role
            const token = localStorage.getItem(CONFIG.TOKEN_KEY);
            const payload = (window.Util && Util.decodeJWT) ? (Util.decodeJWT(token) || {}) : {};

            if (payload.role === 'owner') {
                const totalEl = document.getElementById('owner-total-properties');
                if (totalEl) totalEl.textContent = properties.length;
            } else {
                // renter view - show assigned property
                const assigned = properties.find(p => p.tenant_id === payload.user_id);
                const curEl = document.getElementById('renter-current-property');
                if (curEl) curEl.textContent = assigned ? assigned.title : 'Not Assigned';
            }
            // Always cache for pickers
            this._cache = { properties };
        } catch (error) {
            console.error('Failed to load properties', error);
        }
    }

    static bindOwnerActions() {
        const qs = (id) => document.getElementById(id);
        // Helper to log clicks
        const logClick = (action) => {
            fetch(CONFIG.API_BASE_URL.replace(/\/api$/, '') + '/log_click', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ action, timestamp: new Date().toISOString(), user: localStorage.getItem(CONFIG.TOKEN_KEY) })
            });
        };
        // Property management actions
        qs('action-add-property')?.addEventListener('click', () => { logClick('add-property'); Properties.promptAddProperty(); });
        qs('action-edit-property')?.addEventListener('click', () => { logClick('edit-property'); Properties.promptEditProperty(); });
        qs('action-set-rent-deposit')?.addEventListener('click', () => { logClick('set-rent-deposit'); Properties.promptSetRentDeposit(); });
        qs('action-upload-docs')?.addEventListener('click', () => { logClick('upload-docs'); Properties.promptUploadDocuments(); });
        qs('action-change-status')?.addEventListener('click', () => { logClick('change-status'); Properties.promptChangeStatus(); });
        qs('action-view-all-properties')?.addEventListener('click', () => { logClick('view-all-properties'); Properties.showAllProperties(); });

        // Tenant management actions
        qs('action-assign-property')?.addEventListener('click', () => { logClick('assign-property'); Properties.promptAssignProperty(); });
        qs('action-view-tenants')?.addEventListener('click', () => { logClick('view-tenants'); Properties.showTenantList(); });
        qs('action-manage-lease')?.addEventListener('click', () => { logClick('manage-lease'); Properties.promptManageLease(); });
        qs('action-terminate-lease')?.addEventListener('click', () => { logClick('terminate-lease'); Properties.promptTerminateLease(); });
    }

    static _propertiesOptionsHtml() {
    const list = (this._cache?.properties || []);
        if (!list.length) return '<option value="">No properties</option>';
    return list.map(p => `<option value="${p.id}">${p.title} — ${p.address}</option>`).join('');
    }

    static async promptAddProperty() {
        const { value: formValues } = await Swal.fire({
            title: '<span style="color: #00bfa5; font-size: 1.4rem;">Add New Property</span>',
            html: `
                <div style="text-align: left; font-family: Arial, sans-serif; font-size: 0.85rem;">
                    <div class="row g-1 text-start" style="max-height: 70vh; overflow-y: auto; padding: 10px;">
                      
                      <!-- Property Information Section -->
                      <div class="col-12" style="background: #f8f9fa; padding: 8px; border-radius: 4px; margin-bottom: 8px;">
                          <h6 style="color: #495057; margin: 0; font-size: 0.9rem; font-weight: 600;">🏠 Property Information</h6>
                      </div>
                      
                      <div class="col-6">
                          <label for="swal-title" style="font-weight: 600; font-size: 0.8rem;">Property Title</label>
                          <input id="swal-title" class="form-control form-control-sm" placeholder="Property Title" style="border: 1px solid #ddd; border-radius: 4px; font-size: 0.8rem; padding: 4px 8px;" />
                      </div>
                      <div class="col-6">
                          <label for="swal-property-code" style="font-weight: 600; font-size: 0.8rem;">Property Code / ID</label>
                          <input id="swal-property-code" class="form-control form-control-sm" placeholder="Unique Property Code" style="border: 1px solid #ddd; border-radius: 4px; font-size: 0.8rem; padding: 4px 8px;" />
                      </div>
                      
                      <div class="col-12">
                          <label for="swal-address" style="font-weight: 600; font-size: 0.8rem;">Full Address</label>
                          <input id="swal-address" class="form-control form-control-sm" placeholder="Complete Address" style="border: 1px solid #ddd; border-radius: 4px; font-size: 0.8rem; padding: 4px 8px;" />
                      </div>
                      
                      <div class="col-3">
                          <label for="swal-street" style="font-weight: 600; font-size: 0.8rem;">Street</label>
                          <input id="swal-street" class="form-control form-control-sm" placeholder="Street" style="border: 1px solid #ddd; border-radius: 4px; font-size: 0.8rem; padding: 4px 8px;" />
                      </div>
                      <div class="col-3">
                          <label for="swal-city" style="font-weight: 600; font-size: 0.8rem;">City</label>
                          <input id="swal-city" class="form-control form-control-sm" placeholder="City" style="border: 1px solid #ddd; border-radius: 4px; font-size: 0.8rem; padding: 4px 8px;" />
                      </div>
                      <div class="col-3">
                          <label for="swal-state" style="font-weight: 600; font-size: 0.8rem;">State</label>
                          <input id="swal-state" class="form-control form-control-sm" placeholder="State" style="border: 1px solid #ddd; border-radius: 4px; font-size: 0.8rem; padding: 4px 8px;" />
                      </div>
                      <div class="col-3">
                          <label for="swal-zip" style="font-weight: 600; font-size: 0.8rem;">Zip Code</label>
                          <input id="swal-zip" class="form-control form-control-sm" placeholder="Zip" style="border: 1px solid #ddd; border-radius: 4px; font-size: 0.8rem; padding: 4px 8px;" />
                      </div>
                      
                      <div class="col-4">
                          <label for="swal-type" style="font-weight: 600; font-size: 0.8rem;">Property Type</label>
                          <select id="swal-type" class="form-select form-select-sm" style="border: 1px solid #ddd; border-radius: 4px; font-size: 0.8rem; padding: 4px 8px;">
                              <option value="Flat" selected>Flat</option>
                              <option value="House">House</option>
                              <option value="Commercial">Commercial</option>
                              <option value="Land">Land</option>
                              <option value="Room">Room</option>
                              <option value="Apartment">Apartment</option>
                              <option value="Studio">Studio</option>
                              <option value="Villa">Villa</option>
                          </select>
                      </div>
                      <div class="col-2">
                          <label for="swal-bed" style="font-weight: 600; font-size: 0.8rem;">Bedrooms</label>
                          <select id="swal-bed" class="form-select form-select-sm" style="border: 1px solid #ddd; border-radius: 4px; font-size: 0.8rem; padding: 4px 8px;">
                              ${Array.from({length:11},(_,i)=>`<option value="${i}" ${i===1?'selected':''}>${i}</option>`).join('')}
                          </select>
                      </div>
                      <div class="col-2">
                          <label for="swal-bath" style="font-weight: 600; font-size: 0.8rem;">Bathrooms</label>
                          <select id="swal-bath" class="form-select form-select-sm" style="border: 1px solid #ddd; border-radius: 4px; font-size: 0.8rem; padding: 4px 8px;">
                              ${Array.from({length:11},(_,i)=>`<option value="${i}" ${i===1?'selected':''}>${i}</option>`).join('')}
                          </select>
                      </div>
                      <div class="col-4">
                          <label for="swal-area" style="font-weight: 600; font-size: 0.8rem;">Area (sqft)</label>
                          <input id="swal-area" type="number" step="0.01" class="form-control form-control-sm" placeholder="Area" style="border: 1px solid #ddd; border-radius: 4px; font-size: 0.8rem; padding: 4px 8px;" />
                      </div>
                      
                      <div class="col-3">
                          <label for="swal-floor-number" style="font-weight: 600; font-size: 0.8rem;">Floor Number</label>
                          <input id="swal-floor-number" type="number" class="form-control form-control-sm" placeholder="Floor" style="border: 1px solid #ddd; border-radius: 4px; font-size: 0.8rem; padding: 4px 8px;" />
                      </div>
                      <div class="col-3">
                          <label for="swal-total-floors" style="font-weight: 600; font-size: 0.8rem;">Total Floors</label>
                          <input id="swal-total-floors" type="number" class="form-control form-control-sm" placeholder="Total" style="border: 1px solid #ddd; border-radius: 4px; font-size: 0.8rem; padding: 4px 8px;" />
                      </div>
                      <div class="col-3">
                          <label for="swal-status" style="font-weight: 600; font-size: 0.8rem;">Status</label>
                          <select id="swal-status" class="form-select form-select-sm" style="border: 1px solid #ddd; border-radius: 4px; font-size: 0.8rem; padding: 4px 8px;">
                              <option value="Available" selected>Available</option>
                              <option value="Occupied">Occupied</option>
                              <option value="Under Maintenance">Under Maintenance</option>
                          </select>
                      </div>
                      <div class="col-3">
                          <label for="swal-age" style="font-weight: 600; font-size: 0.8rem;">Age (years)</label>
                          <input id="swal-age" type="number" class="form-control form-control-sm" placeholder="Age" style="border: 1px solid #ddd; border-radius: 4px; font-size: 0.8rem; padding: 4px 8px;" />
                      </div>
                      
                      <div class="col-4">
                          <label for="swal-furnishing" style="font-weight: 600; font-size: 0.8rem;">Furnishing Type</label>
                          <select id="swal-furnishing" class="form-select form-select-sm" style="border: 1px solid #ddd; border-radius: 4px; font-size: 0.8rem; padding: 4px 8px;">
                              <option value="">Select...</option>
                              <option value="Furnished">Furnished</option>
                              <option value="Semi-Furnished">Semi-Furnished</option>
                              <option value="Unfurnished" selected>Unfurnished</option>
                          </select>
                      </div>
                      <div class="col-4">
                          <label for="swal-parking" style="font-weight: 600; font-size: 0.8rem;">Parking Space</label>
                          <input id="swal-parking" class="form-control form-control-sm" placeholder="Yes/No/Number" style="border: 1px solid #ddd; border-radius: 4px; font-size: 0.8rem; padding: 4px 8px;" />
                      </div>
                      <div class="col-4">
                          <label for="swal-balcony" style="font-weight: 600; font-size: 0.8rem;">Balcony</label>
                          <input id="swal-balcony" class="form-control form-control-sm" placeholder="Yes/No/Number" style="border: 1px solid #ddd; border-radius: 4px; font-size: 0.8rem; padding: 4px 8px;" />
                      </div>
                      
                      <div class="col-6">
                          <label for="swal-facing" style="font-weight: 600; font-size: 0.8rem;">Facing Direction</label>
                          <select id="swal-facing" class="form-select form-select-sm" style="border: 1px solid #ddd; border-radius: 4px; font-size: 0.8rem; padding: 4px 8px;">
                              <option value="">Select...</option>
                              <option value="North">North</option>
                              <option value="South">South</option>
                              <option value="East">East</option>
                              <option value="West">West</option>
                              <option value="North-East">North-East</option>
                              <option value="North-West">North-West</option>
                              <option value="South-East">South-East</option>
                              <option value="South-West">South-West</option>
                          </select>
                      </div>
                      <div class="col-6">
                          <label for="swal-desc" style="font-weight: 600; font-size: 0.8rem;">Description / Notes</label>
                          <textarea id="swal-desc" class="form-control form-control-sm" placeholder="Property description..." style="border: 1px solid #ddd; border-radius: 4px; font-size: 0.8rem; padding: 4px 8px; height: 60px;"></textarea>
                      </div>

                      <!-- Financial Details Section -->
                      <div class="col-12" style="background: #f0f8f5; padding: 8px; border-radius: 4px; margin-bottom: 8px; margin-top: 10px;">
                          <h6 style="color: #495057; margin: 0; font-size: 0.9rem; font-weight: 600;">💰 Financial / Rate Details</h6>
                      </div>
                      
                      <div class="col-3">
                          <label for="swal-rent" style="font-weight: 600; font-size: 0.8rem;">Rent Amount (Monthly)</label>
                          <input id="swal-rent" type="number" step="0.01" class="form-control form-control-sm" placeholder="Rent" style="border: 1px solid #ddd; border-radius: 4px; font-size: 0.8rem; padding: 4px 8px;" />
                      </div>
                      <div class="col-3">
                          <label for="swal-deposit" style="font-weight: 600; font-size: 0.8rem;">Deposit</label>
                          <input id="swal-deposit" type="number" step="0.01" class="form-control form-control-sm" placeholder="Deposit" style="border: 1px solid #ddd; border-radius: 4px; font-size: 0.8rem; padding: 4px 8px;" />
                      </div>
                      <div class="col-3">
                          <label for="swal-electricity" style="font-weight: 600; font-size: 0.8rem;">Electricity Rate</label>
                          <input id="swal-electricity" type="number" step="0.01" class="form-control form-control-sm" placeholder="Per unit" style="border: 1px solid #ddd; border-radius: 4px; font-size: 0.8rem; padding: 4px 8px;" />
                      </div>
                      <div class="col-3">
                          <label for="swal-internet-rate" style="font-weight: 600; font-size: 0.8rem;">Internet Rate</label>
                          <input id="swal-internet-rate" type="number" step="0.01" class="form-control form-control-sm" placeholder="Monthly" style="border: 1px solid #ddd; border-radius: 4px; font-size: 0.8rem; padding: 4px 8px;" />
                      </div>
                      
                      <div class="col-4">
                          <label for="swal-water" style="font-weight: 600; font-size: 0.8rem;">Water Bill</label>
                          <input id="swal-water" type="number" step="0.01" class="form-control form-control-sm" placeholder="Monthly" style="border: 1px solid #ddd; border-radius: 4px; font-size: 0.8rem; padding: 4px 8px;" />
                      </div>
                      <div class="col-4">
                          <label for="swal-maintenance" style="font-weight: 600; font-size: 0.8rem;">Maintenance Charges</label>
                          <input id="swal-maintenance" type="number" step="0.01" class="form-control form-control-sm" placeholder="Monthly" style="border: 1px solid #ddd; border-radius: 4px; font-size: 0.8rem; padding: 4px 8px;" />
                      </div>
                      <div class="col-4">
                          <label for="swal-gas" style="font-weight: 600; font-size: 0.8rem;">Gas/LPG Charges</label>
                          <input id="swal-gas" type="number" step="0.01" class="form-control form-control-sm" placeholder="Monthly" style="border: 1px solid #ddd; border-radius: 4px; font-size: 0.8rem; padding: 4px 8px;" />
                      </div>

                      <!-- Amenities Section -->
                      <div class="col-12" style="background: #f5f0f8; padding: 8px; border-radius: 4px; margin-bottom: 8px; margin-top: 10px;">
                          <h6 style="color: #495057; margin: 0; font-size: 0.9rem; font-weight: 600;">🔧 Amenities / Features</h6>
                      </div>
                      
                      <div class="col-2">
                          <label for="swal-elevator" style="font-weight: 600; font-size: 0.8rem;">Elevator</label>
                          <select id="swal-elevator" class="form-select form-select-sm" style="border: 1px solid #ddd; border-radius: 4px; font-size: 0.8rem; padding: 4px 8px;">
                              <option value="">Select...</option>
                              <option value="true">Yes</option>
                              <option value="false">No</option>
                          </select>
                      </div>
                      <div class="col-2">
                          <label for="swal-gym" style="font-weight: 600; font-size: 0.8rem;">Gym/Pool</label>
                          <select id="swal-gym" class="form-select form-select-sm" style="border: 1px solid #ddd; border-radius: 4px; font-size: 0.8rem; padding: 4px 8px;">
                              <option value="">Select...</option>
                              <option value="true">Yes</option>
                              <option value="false">No</option>
                          </select>
                      </div>
                      <div class="col-2">
                          <label for="swal-garden" style="font-weight: 600; font-size: 0.8rem;">Garden Access</label>
                          <select id="swal-garden" class="form-select form-select-sm" style="border: 1px solid #ddd; border-radius: 4px; font-size: 0.8rem; padding: 4px 8px;">
                              <option value="">Select...</option>
                              <option value="true">Yes</option>
                              <option value="false">No</option>
                          </select>
                      </div>
                      <div class="col-6">
                          <label for="swal-security" style="font-weight: 600; font-size: 0.8rem;">Security Features</label>
                          <input id="swal-security" class="form-control form-control-sm" placeholder="CCTV, Guard, etc." style="border: 1px solid #ddd; border-radius: 4px; font-size: 0.8rem; padding: 4px 8px;" />
                      </div>
                      
                      <div class="col-12">
                          <label for="swal-internet-provider" style="font-weight: 600; font-size: 0.8rem;">Internet Provider / Plan Name</label>
                          <input id="swal-internet-provider" class="form-control form-control-sm" placeholder="Internet provider details" style="border: 1px solid #ddd; border-radius: 4px; font-size: 0.8rem; padding: 4px 8px;" />
                      </div>

                      <!-- Other Info Section -->
                      <div class="col-12" style="background: #f8f5f0; padding: 8px; border-radius: 4px; margin-bottom: 8px; margin-top: 10px;">
                          <h6 style="color: #495057; margin: 0; font-size: 0.9rem; font-weight: 600;">🏦 Other Information</h6>
                      </div>
                      
                      <div class="col-4">
                          <label for="swal-owner-name" style="font-weight: 600; font-size: 0.8rem;">Owner Name</label>
                          <input id="swal-owner-name" class="form-control form-control-sm" placeholder="Owner name" style="border: 1px solid #ddd; border-radius: 4px; font-size: 0.8rem; padding: 4px 8px;" />
                      </div>
                      <div class="col-4">
                          <label for="swal-owner-contact" style="font-weight: 600; font-size: 0.8rem;">Owner Contact</label>
                          <input id="swal-owner-contact" class="form-control form-control-sm" placeholder="Contact number" style="border: 1px solid #ddd; border-radius: 4px; font-size: 0.8rem; padding: 4px 8px;" />
                      </div>
                      <div class="col-4">
                          <label for="swal-listing-date" style="font-weight: 600; font-size: 0.8rem;">Listing Date</label>
                          <input id="swal-listing-date" type="date" class="form-control form-control-sm" style="border: 1px solid #ddd; border-radius: 4px; font-size: 0.8rem; padding: 4px 8px;" />
                      </div>
                      
                      <div class="col-12">
                          <label for="swal-lease-terms" style="font-weight: 600; font-size: 0.8rem;">Lease Terms Default</label>
                          <textarea id="swal-lease-terms" class="form-control form-control-sm" placeholder="Default lease terms, minimum lease period, notice period..." style="border: 1px solid #ddd; border-radius: 4px; font-size: 0.8rem; padding: 4px 8px; height: 50px;"></textarea>
                      </div>
                      
                    </div>
                </div>
            `,
            width: '900px',
            focusConfirm: false,
            showCancelButton: true,
            confirmButtonText: 'Add Property',
            cancelButtonText: 'Cancel',
            customClass: {
                popup: 'compact-property-modal'
            },
            preConfirm: () => {
                const v = (id) => {
                    const el = document.getElementById(id);
                    return el ? el.value.trim() : '';
                };
                const vNum = (id) => {
                    const val = v(id);
                    return val ? parseFloat(val) : null;
                };
                const vInt = (id) => {
                    const val = v(id);
                    return val ? parseInt(val) : null;
                };
                const vBool = (id) => {
                    const val = v(id);
                    return val === 'true' ? true : val === 'false' ? false : null;
                };
                
                if (!v('swal-title') || !v('swal-address') || !v('swal-type') || !v('swal-rent')) {
                    Swal.showValidationMessage('Title, Address, Property Type and Rent Amount are required');
                    return false;
                }
                
                return {
                    title: v('swal-title'),
                    property_code: v('swal-property-code'),
                    address: v('swal-address'),
                    street: v('swal-street'),
                    city: v('swal-city'),
                    state: v('swal-state'),
                    zip_code: v('swal-zip'),
                    property_type: v('swal-type'),
                    bedrooms: vInt('swal-bed'),
                    bathrooms: vInt('swal-bath'),
                    area: vNum('swal-area'),
                    floor_number: vInt('swal-floor-number'),
                    total_floors: vInt('swal-total-floors'),
                    status: v('swal-status'),
                    furnishing_type: v('swal-furnishing'),
                    parking_space: v('swal-parking'),
                    balcony: v('swal-balcony'),
                    facing_direction: v('swal-facing'),
                    age_of_property: vInt('swal-age'),
                    description: v('swal-desc'),
                    rent_amount: vNum('swal-rent'),
                    deposit_amount: vNum('swal-deposit'),
                    electricity_rate: vNum('swal-electricity'),
                    internet_rate: vNum('swal-internet-rate'),
                    water_bill: vNum('swal-water'),
                    maintenance_charges: vNum('swal-maintenance'),
                    gas_charges: vNum('swal-gas'),
                    elevator: vBool('swal-elevator'),
                    gym_pool_clubhouse: vBool('swal-gym'),
                    security_features: v('swal-security'),
                    garden_park_access: vBool('swal-garden'),
                    internet_provider: v('swal-internet-provider'),
                    owner_name: v('swal-owner-name'),
                    owner_contact: v('swal-owner-contact'),
                    listing_date: v('swal-listing-date') ? v('swal-listing-date') : null,
                    lease_terms_default: v('swal-lease-terms')
                };
            }
        });
        if (formValues) {
            try {
                await API.createProperty(formValues);
                Swal.fire('Success', 'Property added successfully!', 'success');
                // Refresh UI cache and any tables
                await Properties.loadProperties();
            } catch (error) {
                console.error('Failed to add property', error);
                Swal.fire('Error', (error && error.message) || 'Unable to add property. Please try again later.', 'error');
            }
        }
    }

    static async promptEditProperty() {
        await Properties.ensureProperties();
        console.log('DEBUG: Properties._cache', Properties._cache);
        console.log('DEBUG: Properties._propertiesOptionsHtml()', Properties._propertiesOptionsHtml());
        const { value: selection } = await Swal.fire({
            title: 'Select Property to Edit',
            html: `<select id="swal-prop" class="form-select">${Properties._propertiesOptionsHtml()}</select>`,
            focusConfirm: false,
            showCancelButton: true,
            preConfirm: () => document.getElementById('swal-prop').value
        });
        if (!selection) return;
        const prop = (Properties._cache.properties || []).find(p => String(p.id) === String(selection));
        console.log('DEBUG: Selected property', prop);
        if (!prop) return;
        // reuse add modal with prefill-like simple fields
                const { value: formValues } = await Swal.fire({
            title: '<span style="color: #3b82f6;">Edit Property</span>',
            html: `
                <div style="text-align: left; font-family: Arial, sans-serif;">
                    <div class="row g-2 text-start">
                      <div class="col-12">
                          <label for="swal-title" style="font-weight: bold;">Property Title</label>
                          <input id="swal-title" class="form-control" placeholder="Title" value="${(prop.title||'').replace(/\"/g,'&quot;')}" style="border: 1px solid #ddd; border-radius: 5px;" />
                      </div>
                      <div class="col-12">
                          <label for="swal-address" style="font-weight: bold;">Address</label>
                          <input id="swal-address" class="form-control" placeholder="Address" value="${(prop.address||'').replace(/\"/g,'&quot;')}" style="border: 1px solid #ddd; border-radius: 5px;" />
                      </div>
                      <div class="col-6">
                          <label for="swal-type" style="font-weight: bold;">Property Type</label>
                          <select id="swal-type" class="form-select" style="border: 1px solid #ddd; border-radius: 5px;">
                              ${['Flat','House','Room','Apartment','Studio','Villa','Commercial'].map(t=>`<option value="${t}" ${String(prop.property_type)===t?'selected':''}>${t}</option>`).join('')}
                          </select>
                      </div>
                      <div class="col-3">
                          <label for="swal-bed" style="font-weight: bold;">Bedrooms</label>
                          <select id="swal-bed" class="form-select" style="border: 1px solid #ddd; border-radius: 5px;">
                              ${Array.from({length:11},(_,i)=>`<option value="${i}" ${Number(prop.bedrooms)===i?'selected':''}>${i}</option>`).join('')}
                          </select>
                      </div>
                      <div class="col-3">
                          <label for="swal-bath" style="font-weight: bold;">Bathrooms</label>
                          <select id="swal-bath" class="form-select" style="border: 1px solid #ddd; border-radius: 5px;">
                              ${Array.from({length:11},(_,i)=>`<option value="${i}" ${Number(prop.bathrooms)===i?'selected':''}>${i}</option>`).join('')}
                          </select>
                      </div>
                  <div class="col-6"><input id="swal-area" type="number" step="0.01" class="form-control" placeholder="Area" value="${prop.area||0}" /></div>
                  <div class="col-6"><input id="swal-rent" type="number" step="0.01" class="form-control" placeholder="Rent" value="${prop.rent_amount||0}" /></div>
                  <div class="col-6"><input id="swal-deposit" type="number" step="0.01" class="form-control" placeholder="Deposit" value="${prop.deposit_amount??''}" /></div>
                                    <div class="col-6">
                                        <select id="swal-status" class="form-select">
                                            ${['vacant','rented','maintenance'].map(s=>{
                                                const label = (s==='vacant') ? 'Available' : (s.charAt(0).toUpperCase()+s.slice(1));
                                                return `<option value="${s}" ${String(prop.status||'vacant').toLowerCase()===s?'selected':''}>${label}</option>`;
                                            }).join('')}
                                        </select>
                                    </div>
                  <div class="col-12"><textarea id="swal-desc" class="form-control" placeholder="Description">${(prop.description||'')}</textarea></div>
                </div>
            `,
            focusConfirm: false,
            showCancelButton: true,
            preConfirm: () => {
                const v = (id) => document.getElementById(id).value.trim();
                return {
                    title: v('swal-title'),
                    address: v('swal-address'),
                    property_type: v('swal-type'),
                    bedrooms: parseInt(v('swal-bed') || '0'),
                    bathrooms: parseInt(v('swal-bath') || '0'),
                    area: parseFloat(v('swal-area') || '0'),
                    rent_amount: parseFloat(v('swal-rent') || '0'),
                    deposit_amount: v('swal-deposit') ? parseFloat(v('swal-deposit')) : null,
                    description: v('swal-desc'),
                    status: v('swal-status') || 'vacant',
                };
            }
        });
        if (!formValues) return;
        try {
            await API.updateProperty(prop.id, formValues);
            Swal.fire('Updated', 'Property updated successfully', 'success');
            await Properties.loadProperties();
        } catch (e) {
            Swal.fire('Error', e.message || 'Failed to update', 'error');
        }
    }

    static async promptSetRentDeposit() {
        await Properties.ensureProperties();
        const { value: selection } = await Swal.fire({
            title: 'Select Property',
            html: `<select id="swal-prop" class="form-select">${Properties._propertiesOptionsHtml()}</select>`,
            showCancelButton: true,
            preConfirm: () => document.getElementById('swal-prop').value
        });
        if (!selection) return;
        const prop = (Properties._cache.properties || []).find(p => String(p.id) === String(selection));
        const { value: formValues } = await Swal.fire({
            title: 'Set Rent & Deposit',
            html: `
                <div class="row g-2 text-start">
                  <div class="col-6"><input id="swal-rent" type="number" step="0.01" class="form-control" placeholder="Rent" value="${prop?.rent_amount||0}" /></div>
                  <div class="col-6"><input id="swal-deposit" type="number" step="0.01" class="form-control" placeholder="Deposit (optional)" value="${prop?.deposit_amount??''}" /></div>
                </div>
            `,
            showCancelButton: true,
            preConfirm: () => ({
                rent_amount: parseFloat(document.getElementById('swal-rent').value || '0'),
                deposit_amount: document.getElementById('swal-deposit').value ? parseFloat(document.getElementById('swal-deposit').value) : null,
            })
        });
        if (!formValues) return;
        try {
            await API.updateProperty(prop.id, { ...prop, ...formValues });
            Swal.fire('Saved', 'Rates updated', 'success');
            await Properties.loadProperties();
        } catch (e) {
            Swal.fire('Error', e.message || 'Failed to save', 'error');
        }
    }

    static async promptUploadDocuments() {
        await Properties.ensureProperties();
        const { value: selection } = await Swal.fire({
            title: 'Select Property',
            html: `<select id="swal-prop" class="form-select">${Properties._propertiesOptionsHtml()}</select>`,
            showCancelButton: true,
            preConfirm: () => document.getElementById('swal-prop').value
        });
        if (!selection) return;
        const propId = selection;
        const { value: files } = await Swal.fire({
            title: 'Upload Photos & Documents',
            html: `<input id="swal-files" type="file" class="form-control" multiple />`,
            showCancelButton: true,
            preConfirm: () => {
                const input = document.getElementById('swal-files');
                return input.files;
            }
        });
        if (!files || files.length === 0) return;
        try {
            const fd = new FormData();
            for (const f of files) fd.append('files', f);
            await API.request(`/properties/${propId}/documents`, { method: 'POST', body: fd });
            Swal.fire('Uploaded', 'Files uploaded successfully', 'success');
        } catch (e) {
            Swal.fire('Error', e.message || 'Upload failed', 'error');
        }
    }

    static async promptChangeStatus() {
        await Properties.ensureProperties();
        const { value: selection } = await Swal.fire({
            title: 'Select Property',
            html: `<select id="swal-prop" class="form-select">${Properties._propertiesOptionsHtml()}</select>`,
            showCancelButton: true,
            preConfirm: () => document.getElementById('swal-prop').value
        });
        if (!selection) return;
        const prop = (Properties._cache.properties || []).find(p => String(p.id) === String(selection));
        const { value: status } = await Swal.fire({
            title: 'Change Availability',
            input: 'select',
            inputOptions: { vacant: 'Available', rented: 'Rented', maintenance: 'Maintenance' },
            inputValue: (prop?.status || 'vacant'),
            showCancelButton: true
        });
        if (!status) return;
        try {
            await API.updateProperty(prop.id, { ...prop, status });
            Swal.fire('Updated', 'Status changed', 'success');
            await Properties.loadProperties();
        } catch (e) {
            Swal.fire('Error', e.message || 'Failed to update status', 'error');
        }
    }

    static async ensureProperties() {
        if (!this._cache || !Array.isArray(this._cache.properties)) {
            await this.loadProperties();
        }
    }

    static showAddPropertyModal() {
        Properties.openPropertyModal();
    }

    static showManagePropertiesModal() {
        Properties.loadProperties();
        document.getElementById('owner-properties-table').scrollIntoView({ behavior: 'smooth' });
    }

    static openPropertyModal(property = null) {
        document.getElementById('property-modal').style.display = 'block';
        document.getElementById('property-modal-title').textContent = property ? 'Edit Property' : 'Add Property';
        // Fill form if editing
        document.getElementById('property-form').reset();
        if (property) {
            document.getElementById('property-id').value = property.id;
            document.getElementById('property-title').value = property.title;
            document.getElementById('property-address').value = property.address;
            document.getElementById('property-type').value = property.property_type;
            document.getElementById('property-bedrooms').value = property.bedrooms;
            document.getElementById('property-bathrooms').value = property.bathrooms;
            document.getElementById('property-area').value = property.area;
            document.getElementById('property-rent').value = property.rent_amount;
            const dep = document.getElementById('property-deposit');
            if (dep) dep.value = property.deposit_amount ?? '';
            document.getElementById('property-description').value = property.description;
            document.getElementById('property-status').value = property.status;
        }
    }

    static closePropertyModal() {
        document.getElementById('property-modal').style.display = 'none';
    }

    static async saveProperty(e) {
        e.preventDefault();
        const id = document.getElementById('property-id').value;
        const data = {
            title: document.getElementById('property-title').value,
            address: document.getElementById('property-address').value,
            property_type: document.getElementById('property-type').value,
            bedrooms: parseInt(document.getElementById('property-bedrooms').value),
            bathrooms: parseInt(document.getElementById('property-bathrooms').value),
            area: parseFloat(document.getElementById('property-area').value),
            rent_amount: parseFloat(document.getElementById('property-rent').value),
            deposit_amount: parseFloat(document.getElementById('property-deposit')?.value || '0') || null,
            description: document.getElementById('property-description').value,
            status: document.getElementById('property-status').value
        };
        try {
            if (id) {
                await API.updateProperty(id, data);
                Swal.fire('Success', 'Property updated!', 'success');
            } else {
                await API.createProperty(data);
                Swal.fire('Success', 'Property added!', 'success');
            }
            Properties.closePropertyModal();
            Properties.loadProperties();
        } catch (err) {
            Swal.fire('Error', err.message, 'error');
        }
    }

    static async deleteProperty(id) {
        if (!confirm('Delete this property?')) return;
        try {
            await API.deleteProperty(id);
            Swal.fire('Deleted', 'Property deleted.', 'success');
            Properties.loadProperties();
        } catch (err) {
            Swal.fire('Error', err.message, 'error');
        }
    }

    static renderPropertiesTable(properties) {
        const tbody = document.querySelector('#owner-properties-table tbody');
        tbody.innerHTML = '';
        properties.forEach(p => {
            const tr = document.createElement('tr');
            tr.innerHTML = `
                <td>${p.title}</td>
                <td>${p.address}</td>
                <td>${p.property_type}</td>
                <td>${p.bedrooms}</td>
                <td>${Util.formatCurrency(p.rent_amount)}</td>
                <td>${p.deposit_amount ? Util.formatCurrency(p.deposit_amount) : '-'}</td>
                <td>${p.status}</td>
                <td>
                    <button onclick="Properties.openPropertyModal(${JSON.stringify(p).replace(/"/g, '&quot;')})">Edit</button>
                    <button onclick="Properties.deleteProperty(${p.id})">Delete</button>
                </td>
            `;
            tbody.appendChild(tr);
        });
    }

    static async showAllProperties() {
        try {
            // Use cached properties if available
            await Properties.ensureProperties();
            const properties = (this._cache && this._cache.properties) ? this._cache.properties : await API.getProperties();

            if (!properties || properties.length === 0) {
                return Swal.fire({
                    icon: 'info',
                    title: 'No Properties Found',
                    text: 'You have not added any properties yet.',
                    confirmButtonText: 'OK'
                });
            }

            const esc = (s) => String(s ?? '')
                .replace(/&/g, '&amp;')
                .replace(/</g, '&lt;')
                .replace(/>/g, '&gt;')
                .replace(/"/g, '&quot;')
                .replace(/'/g, '&#39;');

            const cards = properties.map(p => `
                <div class="col-12 col-md-6 col-lg-4 mb-3">
                    <div class="card h-100 shadow-sm border-0">
                        <div class="card-body">
                            <h6 class="card-title mb-1">${esc(p.title)}</h6>
                            <div class="text-muted small mb-2">${esc(p.address)}</div>
                            <div class="d-flex flex-wrap gap-2 small mb-2">
                                <span class="badge bg-secondary">${esc(p.property_type)}</span>
                                <span class="badge bg-light text-dark">${Number(p.bedrooms) || 0} bed</span>
                                <span class="badge bg-light text-dark">${Number(p.bathrooms) || 0} bath</span>
                                <span class="badge bg-${String(p.status).toLowerCase()==='rented'?'success':(String(p.status).toLowerCase()==='maintenance'?'warning':'primary')}">${esc((String(p.status||'').toLowerCase()==='vacant')?'Available':(p.status||'Available'))}</span>
                            </div>
                            <div class="fw-semibold mb-2">${Util.formatCurrency(p.rent_amount || 0)} / mo</div>
                            <div class="d-flex gap-2">
                                <button class="btn btn-sm btn-outline-primary" onclick='Properties.openPropertyModal(${JSON.stringify({
                                    id: null
                                })})'>Details</button>
                            </div>
                        </div>
                    </div>
                </div>
            `).join('');

            const html = `
                <div style="text-align:left;">
                    <div class="row">${cards}</div>
                </div>`;

            await Swal.fire({
                title: '<span style="color:#00bfa5;">All Properties</span>',
                html,
                width: '900px',
                showConfirmButton: true,
                confirmButtonText: 'Close'
            });
        } catch (error) {
            console.error('Failed to fetch all properties', error);
            Swal.fire('Error', 'Unable to fetch properties. Please try again later.', 'error');
        }
    }

    // Tenant Management Functions
    static async promptAssignProperty() {
        // Require authentication and owner role
        const token = localStorage.getItem(CONFIG.TOKEN_KEY);
        if (!token) {
            return Swal.fire({
                icon: 'warning',
                title: 'Login Required',
                text: 'Please login as an owner to assign a renter to a property.',
                confirmButtonText: 'OK'
            });
        }
        let payload = {};
        try { payload = (window.Util && Util.decodeJWT) ? (Util.decodeJWT(token) || {}) : {}; } catch {}
        // Only block if we can positively identify the role as not 'owner'.
        if (payload && payload.role && String(payload.role).toLowerCase() !== 'owner') {
            return Swal.fire({
                icon: 'error',
                title: 'Owner Access Only',
                text: 'You must be logged in as an owner to assign renters.',
                confirmButtonText: 'OK'
            });
        }

        // If role is not present in token (or decode failed), try backend to confirm role.
        if (!payload || !payload.role) {
            try {
                const profile = await API.getCurrentUser();
                if (profile && String(profile.role).toLowerCase() !== 'owner') {
                    return Swal.fire({
                        icon: 'error',
                        title: 'Owner Access Only',
                        text: 'You must be logged in as an owner to assign renters.',
                        confirmButtonText: 'OK'
                    });
                }
            } catch (e) {
                // If the check fails (e.g., network), proceed; backend will enforce authorization on submit
            }
        }

        // Load data for renters and properties
        const [rentersResp, properties] = await Promise.all([
            API.getAllRenters().catch(() => []),
            API.getProperties().catch(() => [])
        ]);

        // Normalise renters response: it may be an object { tenants: [...] } or already an array
        const renters = Array.isArray(rentersResp) ? rentersResp : (rentersResp && Array.isArray(rentersResp.tenants) ? rentersResp.tenants : []);

        // Only allow assigning VACANT properties
    const vacantProps = (properties || []).filter(p => ['vacant','available'].includes(String(p.status || '').toLowerCase()));
        if (!vacantProps.length) {
            return Swal.fire({
                icon: 'info',
                title: 'No Available Properties',
                text: 'You currently have no properties with status Available to assign.',
                confirmButtonText: 'OK'
            });
        }
        const propertyOptions = vacantProps.map(p => `<option value="${p.id}">${p.title} — ${p.address}</option>`).join('');

        const { value: formValues } = await Swal.fire({
            title: '<span style="color: #3b82f6;">Assign Property to Tenant</span>',
            html: `
                <div style="text-align: left; font-family: Arial, sans-serif;">
                    <div class="mt-2">
                        <label class="form-label" for="swal-renter" style="font-weight: bold;">Select Tenant</label>
                        <select id="swal-renter" class="form-select" style="border: 1px solid #ddd; border-radius: 5px;" required>
                            ${renters.map(r => `<option value="${r.id}">${(r.full_name || r.name || 'Unnamed')}</option>`).join('') || '<option value="">No tenants found</option>'}
                        </select>
                    </div>
                    <label for="swal-property" class="mt-3" style="font-weight: bold;">Select Property (Available Only)</label>
                    <select id="swal-property" class="form-select" style="border: 1px solid #ddd; border-radius: 5px;">
                        ${propertyOptions}
                    </select>
                    <div class="row mt-3">
                        <div class="col-6">
                            <label for="swal-start" style="font-weight: bold;">Start Date</label>
                            <input id="swal-start" type="date" class="form-control" />
                        </div>
                        <div class="col-6">
                            <label for="swal-end" style="font-weight: bold;">End Date (optional)</label>
                            <input id="swal-end" type="date" class="form-control" />
                        </div>
                        <div class="col-6 mt-2">
                            <label for="swal-rent" style="font-weight: bold;">Monthly Rent</label>
                            <input id="swal-rent" type="number" class="form-control" />
                        </div>
                        <div class="col-6 mt-2">
                            <label for="swal-deposit" style="font-weight: bold;">Deposit (optional)</label>
                            <input id="swal-deposit" type="number" class="form-control" />
                        </div>
                    </div>
                </div>
            `,
            focusConfirm: false,
            showCancelButton: true,
            preConfirm: () => {
                const renterId = document.getElementById('swal-renter').value;
                const propertyId = document.getElementById('swal-property').value;
                const startDate = document.getElementById('swal-start').value;
                const rentAmount = document.getElementById('swal-rent').value;

                if (!renterId || !propertyId || !startDate || !rentAmount) {
                    Swal.showValidationMessage('Please select a Tenant, Property, Start Date and Rent Amount');
                    return false;
                }
                return { renterId, propertyId, startDate, rentAmount };
            }
        });

        if (formValues) {
            try {
                await API.assignPropertyToTenant(parseInt(formValues.propertyId), {
                    renter_id: parseInt(formValues.renterId),
                    start_date: formValues.startDate,
                    rent_amount: parseFloat(formValues.rentAmount),
                    deposit_amount: document.getElementById('swal-deposit').value || null
                });
                Swal.fire('Invitation Sent', 'A lease invitation has been sent to the renter. The lease will be created once the renter approves.', 'success');
            } catch (error) {
                console.error('Failed to send invitation', error);
                const detail = (error && (error.body?.detail || error.message)) || 'Unable to send lease invitation. Please try again later.';
                Swal.fire('Error', detail, 'error');
            }
        }
    }

    static async showTenantList() {
        try {
            const response = await API.getAllRenters();
            
            // Handle both formats: plain array or { tenants: [...] }
            const tenants = Array.isArray(response) ? response : (response.tenants || []);
            
            if (!Array.isArray(response) && response.status === 'empty') {
                return Swal.fire({
                    icon: 'info',
                    title: 'No Tenants Found',
                    text: response.message || 'There are no registered tenants in the system.',
                    confirmButtonText: 'OK'
                });
            }

            if (!tenants || tenants.length === 0) {
                return Swal.fire({
                    icon: 'info',
                    title: 'No Tenants Found',
                    text: 'There are no registered tenants in the system.',
                    confirmButtonText: 'OK'
                });
            }

            const esc = (s) => String(s ?? '')
                .replace(/&/g, '&amp;')
                .replace(/</g, '&lt;')
                .replace(/>/g, '&gt;')
                .replace(/"/g, '&quot;')
                .replace(/'/g, '&#39;');

            const rows = tenants.map(t => `
                <tr>
                    <td>${esc(t.full_name)}</td>
                    <td>${esc(t.email)}</td>
                    <td>${esc(t.phone || '-')}</td>
                    <td>${t.lease_start ? new Date(t.lease_start).toLocaleDateString() : '-'}</td>
                </tr>
            `).join('');

            const html = `
                <div style="text-align:left;">
                    <table class="table table-striped">
                        <thead>
                            <tr>
                                <th>Name</th>
                                <th>Email</th>
                                <th>Phone</th>
                                <th>Lease Start</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${rows}
                        </tbody>
                    </table>
                </div>`;

            await Swal.fire({
                title: '<span style="color:#00bfa5;">All Tenants</span>',
                html,
                width: '800px',
                showConfirmButton: true,
                confirmButtonText: 'Close'
            });
        } catch (error) {
            console.error('Failed to fetch tenants', error);
            const errorMessage = error.body?.detail || error.message || 'Unable to fetch tenant list. Please try again later.';
            Swal.fire('Error', errorMessage, 'error');
        }
    }

    static async promptManageLease() {
        try {
            const [leases, tenantsResp, properties] = await Promise.all([
                API.getAllLeases(),
                API.getAllRenters(),
                API.getProperties()
            ]);

            const tenants = Array.isArray(tenantsResp) ? tenantsResp : (tenantsResp && Array.isArray(tenantsResp.tenants) ? tenantsResp.tenants : []);

            if (!leases || leases.length === 0) {
                return Swal.fire({
                    icon: 'info',
                    title: 'No Leases Found',
                    text: 'There are no active leases in the system.',
                    confirmButtonText: 'OK'
                });
            }

            const esc = (s) => String(s ?? '')
                .replace(/&/g, '&amp;')
                .replace(/</g, '&lt;')
                .replace(/>/g, '&gt;')
                .replace(/"/g, '&quot;')
                .replace(/'/g, '&#39;');

            const tenantMap = Object.fromEntries(tenants.map(t => [t.id, t]));
            const propertyMap = Object.fromEntries(properties.map(p => [p.id, p]));

            const rows = leases.map(l => {
                const tenant = tenantMap[l.tenant_id] || {};
                const property = propertyMap[l.property_id] || {};
                return `
                    <tr>
                        <td>${esc(property.title || '-')}</td>
                        <td>${esc(tenant.full_name || tenant.name || '-')}</td>
                        <td>${new Date(l.start_date).toLocaleDateString()}</td>
                        <td>${l.end_date ? new Date(l.end_date).toLocaleDateString() : 'Ongoing'}</td>
                        <td>${Util.formatCurrency(l.rent_amount)}</td>
                        <td>${esc(l.status)}</td>
                        <td>
                            <button class="btn btn-sm btn-primary" data-edit-lease="${l.id}">Edit</button>
                            <button class="btn btn-sm btn-danger" data-term-lease="${l.id}" style="margin-left:6px;">Terminate</button>
                        </td>
                    </tr>
                `;
            }).join('');

            const html = `
                <div style="text-align:left;">
                    <table class="table table-striped">
                        <thead>
                            <tr>
                                <th>Property</th>
                                <th>Tenant</th>
                                <th>Start Date</th>
                                <th>End Date</th>
                                <th>Rent</th>
                                <th>Status</th>
                                <th>Action</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${rows}
                        </tbody>
                    </table>
                </div>`;

            await Swal.fire({
                title: '<span style="color:#00bfa5;">All Leases</span>',
                html,
                width: '900px',
                showConfirmButton: true,
                confirmButtonText: 'Close',
                didOpen: () => {
                    const container = Swal.getHtmlContainer();
                    if (!container) return;
                    container.addEventListener('click', async (e) => {
                        const editBtn = e.target.closest('[data-edit-lease]');
                        const termBtn = e.target.closest('[data-term-lease]');
                        if (editBtn) {
                            const leaseId = parseInt(editBtn.getAttribute('data-edit-lease'));
                            const lease = leases.find(x => x.id === leaseId);
                            if (!lease) return;
                            const editHtml = `
                                <div class="form-grid">
                                    <label>Start Date</label>
                                    <input id="lease-start" type="date" value="${lease.start_date ? new Date(lease.start_date).toISOString().slice(0,10) : ''}" />
                                    <label>End Date</label>
                                    <input id="lease-end" type="date" value="${lease.end_date ? new Date(lease.end_date).toISOString().slice(0,10) : ''}" />
                                    <label>Rent Amount</label>
                                    <input id="lease-rent" type="number" step="0.01" value="${lease.rent_amount ?? ''}" />
                                    <label>Deposit Amount</label>
                                    <input id="lease-deposit" type="number" step="0.01" value="${lease.deposit_amount ?? ''}" />
                                    <label>Status</label>
                                    <select id="lease-status">
                                        ${['active','terminated','expired'].map(s => `<option value="${s}" ${String(lease.status).toLowerCase()===s?'selected':''}>${s}</option>`).join('')}
                                    </select>
                                </div>`;
                            const res = await Swal.fire({
                                title: 'Edit Lease',
                                html: editHtml,
                                focusConfirm: false,
                                showCancelButton: true,
                                confirmButtonText: 'Save',
                                preConfirm: () => {
                                    const start = document.getElementById('lease-start').value || null;
                                    const end = document.getElementById('lease-end').value || null;
                                    const rent = document.getElementById('lease-rent').value;
                                    const deposit = document.getElementById('lease-deposit').value;
                                    const status = document.getElementById('lease-status').value;
                                    const payload = {
                                        start_date: start || undefined,
                                        end_date: end || undefined,
                                        rent_amount: rent ? parseFloat(rent) : undefined,
        
                                        deposit_amount: deposit ? parseFloat(deposit) : undefined,
                                        status: status || undefined
                                    };
                                    return payload;
                                }
                            });
                            if (res.isConfirmed) {
                                try {
                                    const payload = res.value || {};
                                    await API.updateLease(leaseId, payload);
                                    await Swal.fire('Success', 'Lease updated successfully.', 'success');
                                    await Properties.promptManageLease();
                                } catch (err) {
                                    const msg = err.body?.detail || err.message || 'Failed to update lease';
                                    Swal.fire('Error', msg, 'error');
                                }
                            }
                        } else if (termBtn) {
                            const leaseId = parseInt(termBtn.getAttribute('data-term-lease'));
                            const confirm = await Swal.fire({
                                icon: 'warning',
                                title: 'Terminate Lease?',
                                text: 'This will end the lease and mark the property as available.',
                                showCancelButton: true,
                                confirmButtonText: 'Yes, terminate',
                                cancelButtonText: 'Cancel'
                            });
                            if (confirm.isConfirmed) {
                                try {
                                    await API.terminateLease(leaseId);
                                    await Swal.fire('Terminated', 'Lease terminated successfully.', 'success');
                                    await Properties.promptManageLease();
                                } catch (err) {
                                    const msg = err.body?.detail || err.message || 'Failed to terminate lease';
                                    Swal.fire('Error', msg, 'error');
                                }
                            }
                        }
                    });
                }
            });
        } catch (error) {
            console.error('Failed to fetch leases', error);
            Swal.fire('Error', 'Unable to fetch lease information. Please try again later.', 'error');
        }
    }

    static async promptTerminateLease() {
        try {
            const [leases, tenantsResp, properties] = await Promise.all([
                API.getAllLeases(),
                API.getAllRenters(),
                API.getProperties()
            ]);

            if (!leases || leases.length === 0) {
                return Swal.fire({ icon: 'info', title: 'No Leases', text: 'No leases available to terminate.' });
            }

            const tenants = Array.isArray(tenantsResp) ? tenantsResp : (tenantsResp && Array.isArray(tenantsResp.tenants) ? tenantsResp.tenants : []);
            const tenantMap = Object.fromEntries(tenants.map(t => [t.id, t]));
            const propertyMap = Object.fromEntries(properties.map(p => [p.id, p]));
            const esc = (s) => String(s ?? '').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;').replace(/'/g,'&#39;');

            const options = leases.map(l => {
                const t = tenantMap[l.tenant_id] || {}; const p = propertyMap[l.property_id] || {};
                const label = `${p.title || 'Property'} - ${t.full_name || t.name || 'Tenant'} - ${new Date(l.start_date).toLocaleDateString()}`;
                return `<option value="${l.id}">${esc(label)}</option>`;
            }).join('');

            const html = `<div style="text-align:left;">
                <label>Select Lease to Terminate</label>
                <select id="lease-select" class="swal2-select" style="width:100%;">${options}</select>
            </div>`;

            const res = await Swal.fire({
                title: 'Terminate Lease',
                html,
                showCancelButton: true,
                confirmButtonText: 'Terminate',
                preConfirm: () => parseInt(document.getElementById('lease-select').value)
            });
            if (!res.isConfirmed) return;

            const leaseId = res.value;
            const confirm = await Swal.fire({
                icon: 'warning',
                title: 'Are you sure?',
                text: 'This action will end the lease and set the property to available.',
                showCancelButton: true,
                confirmButtonText: 'Yes, terminate'
            });
            if (!confirm.isConfirmed) return;

            await API.terminateLease(leaseId);
            await Swal.fire('Terminated', 'Lease terminated successfully.', 'success');
        } catch (error) {
            console.error('Terminate lease failed', error);
            const msg = error.body?.detail || error.message || 'Failed to terminate lease';
            Swal.fire('Error', msg, 'error');
        }
    }
}
