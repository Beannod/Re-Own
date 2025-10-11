class RenterProperties {
    static init() {
        this.bindPropertyActions();
        this.bindTenantManagementActions();
        this.loadCurrentProperty();
        this.loadTenantProfile();

        // Bell icon in navbar opens invitations
        document.getElementById('nav-invitations')?.addEventListener('click', (e) => {
            e.preventDefault();
            RenterProperties.viewLeaseInvitations();
        });
    }

    static bindPropertyActions() {
        // Bind property detail buttons
        document.getElementById('btn-view-property')?.addEventListener('click', () => this.showPropertyDetails());
        document.getElementById('btn-view-rent-info')?.addEventListener('click', () => this.showRentInformation());
        document.getElementById('btn-download-agreement')?.addEventListener('click', () => this.downloadRentalAgreement());
        document.getElementById('btn-view-photos')?.addEventListener('click', () => this.showPropertyPhotos());
        document.getElementById('btn-owner-contact')?.addEventListener('click', () => this.showOwnerContact());
    }

    static bindTenantManagementActions() {
        // Bind tenant management buttons
        document.getElementById('action-view-tenant-profile')?.addEventListener('click', () => this.showTenantProfile());
        document.getElementById('action-update-contact-info')?.addEventListener('click', () => this.updateContactInformation());
        document.getElementById('action-view-lease-terms')?.addEventListener('click', () => this.viewLeaseTerms());
        document.getElementById('action-emergency-contacts')?.addEventListener('click', () => this.manageEmergencyContacts());
        document.getElementById('action-view-co-tenants')?.addEventListener('click', () => this.viewCoTenants());
        document.getElementById('action-view-invitations')?.addEventListener('click', () => this.viewLeaseInvitations());
    }

    static async loadCurrentProperty() {
        try {
            // Get current user info
            const token = localStorage.getItem(CONFIG.TOKEN_KEY);
            const payload = (window.Util && Util.decodeJWT) ? (Util.decodeJWT(token) || {}) : {};
            
            if (payload.role !== 'renter') {
                console.warn('User is not a renter');
                return;
            }

            // Load assigned property information
            const lease = await API.getCurrentLease();
            if (lease && lease.property) {
                this._currentProperty = lease.property;
                this._currentLease = lease;
                this._ownerInfo = lease.owner;
                
                // Update dashboard display
                const propertyEl = document.getElementById('renter-current-property');
                if (propertyEl) {
                    propertyEl.textContent = lease.property.title || 'Not Assigned';
                }
            } else {
                this._currentProperty = null;
                this._currentLease = null;
                this._ownerInfo = null;
            }
        } catch (error) {
            console.error('Failed to load current property:', error);
            this._currentProperty = null;
            this._currentLease = null;
            this._ownerInfo = null;
        }
    }

    static async showPropertyDetails() {
        if (!this._currentProperty) {
            return Swal.fire({
                icon: 'info',
                title: 'No Property Assigned',
                text: 'You do not have a property assigned to your account yet.',
                confirmButtonText: 'OK'
            });
        }

        const property = this._currentProperty;
        const lease = this._currentLease;

        await Swal.fire({
            title: 'Property Details',
            html: `
                <div class="text-start">
                    <div class="row g-3">
                        <div class="col-12">
                            <h6 class="text-primary"><i class="fas fa-home me-2"></i>Property Information</h6>
                            <div class="border rounded p-3">
                                <p class="mb-2"><strong>Title:</strong> ${property.title || 'N/A'}</p>
                                <p class="mb-2"><strong>Address:</strong> ${property.address || 'N/A'}</p>
                                <p class="mb-2"><strong>Type:</strong> ${property.property_type || 'N/A'}</p>
                                <p class="mb-2"><strong>Bedrooms:</strong> ${property.bedrooms || 'N/A'}</p>
                                <p class="mb-2"><strong>Bathrooms:</strong> ${property.bathrooms || 'N/A'}</p>
                                <p class="mb-2"><strong>Area:</strong> ${property.area || 'N/A'} sq ft</p>
                                <p class="mb-0"><strong>Status:</strong> <span class="badge bg-success">${property.status || 'N/A'}</span></p>
                            </div>
                        </div>
                        ${lease ? `
                        <div class="col-12">
                            <h6 class="text-success"><i class="fas fa-file-contract me-2"></i>Lease Information</h6>
                            <div class="border rounded p-3">
                                <p class="mb-2"><strong>Start Date:</strong> ${new Date(lease.start_date).toLocaleDateString()}</p>
                                <p class="mb-2"><strong>End Date:</strong> ${lease.end_date ? new Date(lease.end_date).toLocaleDateString() : 'Ongoing'}</p>
                                <p class="mb-0"><strong>Status:</strong> <span class="badge bg-info">${lease.status || 'Active'}</span></p>
                            </div>
                        </div>
                        ` : ''}
                        ${property.description ? `
                        <div class="col-12">
                            <h6 class="text-info"><i class="fas fa-info-circle me-2"></i>Description</h6>
                            <div class="border rounded p-3">
                                <p class="mb-0">${property.description}</p>
                            </div>
                        </div>
                        ` : ''}
                    </div>
                </div>
            `,
            width: '600px',
            confirmButtonText: 'Close'
        });
    }

    static async showRentInformation() {
        if (!this._currentLease) {
            return Swal.fire({
                icon: 'info',
                title: 'No Lease Information',
                text: 'No active lease found for your account.',
                confirmButtonText: 'OK'
            });
        }

        const lease = this._currentLease;
        const nextDueDate = this.calculateNextDueDate(lease.start_date);

        await Swal.fire({
            title: 'Rent & Financial Information',
            html: `
                <div class="text-start">
                    <div class="row g-3">
                        <div class="col-12">
                            <h6 class="text-success"><i class="fas fa-dollar-sign me-2"></i>Monthly Rent</h6>
                            <div class="border rounded p-3 bg-light">
                                <h4 class="text-primary mb-0">$${lease.rent_amount || 'N/A'}</h4>
                                <small class="text-muted">per month</small>
                            </div>
                        </div>
                        ${lease.deposit_amount ? `
                        <div class="col-12">
                            <h6 class="text-warning"><i class="fas fa-shield-alt me-2"></i>Security Deposit</h6>
                            <div class="border rounded p-3">
                                <h5 class="text-warning mb-0">$${lease.deposit_amount}</h5>
                                <small class="text-muted">Refundable upon lease termination</small>
                            </div>
                        </div>
                        ` : ''}
                        <div class="col-12">
                            <h6 class="text-danger"><i class="fas fa-calendar-alt me-2"></i>Next Due Date</h6>
                            <div class="border rounded p-3">
                                <h5 class="text-danger mb-1">${nextDueDate}</h5>
                                <small class="text-muted">Monthly rent is typically due on the same day each month</small>
                            </div>
                        </div>
                        <div class="col-12">
                            <h6 class="text-info"><i class="fas fa-info-circle me-2"></i>Payment Information</h6>
                            <div class="border rounded p-3">
                                <p class="mb-2"><strong>Lease Period:</strong> ${new Date(lease.start_date).toLocaleDateString()} - ${lease.end_date ? new Date(lease.end_date).toLocaleDateString() : 'Ongoing'}</p>
                                <p class="mb-0"><strong>Payment Status:</strong> <span class="badge bg-success">Current</span></p>
                            </div>
                        </div>
                    </div>
                </div>
            `,
            width: '500px',
            confirmButtonText: 'Close'
        });
    }

    static async downloadRentalAgreement() {
        if (!this._currentLease) {
            return Swal.fire({
                icon: 'info',
                title: 'No Lease Agreement',
                text: 'No active lease agreement found for your account.',
                confirmButtonText: 'OK'
            });
        }

        const { isConfirmed } = await Swal.fire({
            title: 'Download Rental Agreement',
            text: 'Would you like to download your rental agreement document?',
            icon: 'question',
            showCancelButton: true,
            confirmButtonText: 'Download',
            cancelButtonText: 'Cancel'
        });

        if (isConfirmed) {
            try {
                // Request rental agreement download
                const { blob, contentType } = await API.downloadLeaseAgreement(this._currentLease.id);
                
                // Create download link using the provided content type
                const url = window.URL.createObjectURL(blob);
                const a = document.createElement('a');
                a.href = url;
                const ext = (contentType && contentType.includes('text/plain')) ? 'txt' : 'pdf';
                a.download = `rental-agreement-${this._currentLease.id}.${ext}`;
                document.body.appendChild(a);
                a.click();
                window.URL.revokeObjectURL(url);
                document.body.removeChild(a);

                Swal.fire({
                    icon: 'success',
                    title: 'Download Started',
                    text: 'Your rental agreement is being downloaded.',
                    timer: 2000,
                    showConfirmButton: false
                });
            } catch (error) {
                Swal.fire({
                    icon: 'error',
                    title: 'Download Failed',
                    text: 'Unable to download rental agreement. Please contact your property manager.',
                    confirmButtonText: 'OK'
                });
            }
        }
    }

    static async showPropertyPhotos() {
        if (!this._currentProperty) {
            return Swal.fire({
                icon: 'info',
                title: 'No Property Assigned',
                text: 'You do not have a property assigned to view photos.',
                confirmButtonText: 'OK'
            });
        }

        try {
            const documents = await API.getPropertyDocuments(this._currentProperty.id);
            const photos = documents.filter(doc => doc.content_type && doc.content_type.startsWith('image/'));
            const nonPhotos = documents.filter(doc => !doc.content_type || !doc.content_type.startsWith('image/'));

            const photoGallery = photos.map(photo => `
                <div class="col-6 col-md-4 mb-3">
                    <img src="${photo.url}" class="img-fluid rounded" style="height: 150px; object-fit: cover; width: 100%;" alt="Property Photo">
                </div>
            `).join('');

            const docsList = nonPhotos.map(doc => `
                <a href="${doc.url}" target="_blank" class="list-group-item list-group-item-action">
                    <i class="fas fa-file me-2"></i>${doc.file_name}
                </a>
            `).join('');

            await Swal.fire({
                title: 'Property Photos & Documents',
                html: `
                    <div class="text-start">
                        ${photos.length ? `
                        <h6 class="text-primary mb-3"><i class="fas fa-images me-2"></i>Property Gallery</h6>
                        <div class="row">
                            ${photoGallery}
                        </div>
                        ` : `
                        <div class="text-center py-3 text-muted">
                            <i class="fas fa-image-slash" style="font-size:2rem;"></i>
                            <div class="mt-2">No photos available</div>
                        </div>
                        `}
                        ${nonPhotos.length ? `
                        <hr>
                        <h6 class="text-info mb-3"><i class="fas fa-file-alt me-2"></i>Documents</h6>
                        <div class="list-group">
                            ${docsList}
                        </div>
                        ` : ''}
                    </div>
                `,
                width: '700px',
                confirmButtonText: 'Close'
            });
        } catch (error) {
            Swal.fire({
                icon: 'error',
                title: 'Unable to Load Photos',
                text: 'Failed to load property photos and documents.',
                confirmButtonText: 'OK'
            });
        }
    }

    static async showOwnerContact() {
        if (!this._ownerInfo) {
            return Swal.fire({
                icon: 'info',
                title: 'Owner Contact Not Available',
                text: 'Owner contact information is not currently available.',
                confirmButtonText: 'OK'
            });
        }

        const owner = this._ownerInfo;

        await Swal.fire({
            title: 'Owner Contact Information',
            html: `
                <div class="text-start">
                    <div class="row g-3">
                        <div class="col-12">
                            <h6 class="text-primary"><i class="fas fa-user-tie me-2"></i>Property Owner</h6>
                            <div class="border rounded p-3">
                                <p class="mb-2"><strong>Name:</strong> ${owner.full_name || 'N/A'}</p>
                                <p class="mb-2"><strong>Email:</strong> 
                                    ${owner.email ? `<a href="mailto:${owner.email}">${owner.email}</a>` : 'N/A'}
                                </p>
                                ${owner.phone ? `<p class="mb-2"><strong>Phone:</strong> <a href="tel:${owner.phone}">${owner.phone}</a></p>` : ''}
                                ${owner.company ? `<p class="mb-2"><strong>Company:</strong> ${owner.company}</p>` : ''}
                                ${owner.address ? `<p class="mb-0"><strong>Address:</strong> ${owner.address}</p>` : ''}
                            </div>
                        </div>
                        <div class="col-12">
                            <h6 class="text-info"><i class="fas fa-info-circle me-2"></i>Contact Guidelines</h6>
                            <div class="border rounded p-3 bg-light">
                                <ul class="mb-0 small">
                                    <li>For maintenance requests, use the maintenance module</li>
                                    <li>For payment issues, contact during business hours</li>
                                    <li>For emergencies, call immediately</li>
                                    <li>Response time: typically within 24-48 hours</li>
                                </ul>
                            </div>
                        </div>
                    </div>
                </div>
            `,
            width: '500px',
            confirmButtonText: 'Close'
        });
    }

    static calculateNextDueDate(leaseStartDate) {
        const start = new Date(leaseStartDate);
        const today = new Date();
        const dayOfMonth = start.getDate();
        
        let nextDue = new Date(today.getFullYear(), today.getMonth(), dayOfMonth);
        
        if (nextDue <= today) {
            nextDue = new Date(today.getFullYear(), today.getMonth() + 1, dayOfMonth);
        }
        
        return nextDue.toLocaleDateString();
    }

    // Tenant Management Methods
    static async loadTenantProfile() {
        try {
            const token = localStorage.getItem(CONFIG.TOKEN_KEY);
            const payload = (window.Util && Util.decodeJWT) ? (Util.decodeJWT(token) || {}) : {};
            
            if (payload.role !== 'renter') return;

            // Load current user profile
            const userProfile = await API.getUserProfile();
            this._tenantProfile = userProfile;

            // Load emergency contacts
            const emergencyContacts = await API.getEmergencyContacts();
            this._emergencyContacts = emergencyContacts;

            // Load co-tenants if any
            if (this._currentLease) {
                const coTenants = await API.getCoTenants(this._currentLease.id);
                this._coTenants = coTenants;
            }

            // Optionally load pending invitations count for badge
            try {
                const invites = await API.listMyLeaseInvites();
                this._leaseInvites = invites;
                const badge = document.getElementById('badge-lease-invitations');
                if (badge) badge.textContent = (invites && invites.length) ? String(invites.length) : '';
            } catch {}
        } catch (error) {
            console.error('Failed to load tenant profile:', error);
            this._tenantProfile = null;
            this._emergencyContacts = [];
            this._coTenants = [];
        }
    }

    static async viewLeaseInvitations() {
        try {
            const invites = await API.listMyLeaseInvites();
            if (!invites || invites.length === 0) {
                return Swal.fire({ icon: 'info', title: 'No Invitations', text: 'You have no pending lease invitations.' });
            }
            const esc = (s) => String(s ?? '').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;').replace(/'/g,'&#39;');
            const rows = invites.map(inv => `
                <tr>
                    <td>${esc(inv.property_title || '')}</td>
                    <td>${esc(inv.property_address || '')}</td>
                    <td>${new Date(inv.start_date).toLocaleDateString()}</td>
                    <td>${esc(inv.rent_amount)}</td>
                    <td>
                        <button class="btn btn-sm btn-success" data-approve="${inv.id}">Approve</button>
                        <button class="btn btn-sm btn-outline-danger" data-reject="${inv.id}" style="margin-left:6px;">Reject</button>
                    </td>
                </tr>
            `).join('');

            const html = `
                <div class="text-start">
                    <table class="table table-striped">
                        <thead>
                            <tr>
                                <th>Property</th>
                                <th>Address</th>
                                <th>Start Date</th>
                                <th>Rent</th>
                                <th>Action</th>
                            </tr>
                        </thead>
                        <tbody>${rows}</tbody>
                    </table>
                </div>`;

            await Swal.fire({
                title: 'Lease Invitations',
                html,
                width: '800px',
                showConfirmButton: true,
                confirmButtonText: 'Close',
                didOpen: () => {
                    const container = Swal.getHtmlContainer();
                    if (!container) return;
                    container.addEventListener('click', async (e) => {
                        const a = e.target.closest('[data-approve]');
                        const r = e.target.closest('[data-reject]');
                        if (a) {
                            const id = parseInt(a.getAttribute('data-approve'));
                            try {
                                await API.approveLeaseInvite(id);
                                await Swal.fire('Approved', 'Lease invitation approved. Your lease has been created.', 'success');
                                await RenterProperties.loadCurrentProperty();
                                await RenterProperties.loadTenantProfile();
                            } catch (err) {
                                const msg = (err && (err.body?.detail || err.message)) || 'Failed to approve invitation';
                                Swal.fire('Error', msg, 'error');
                            }
                        } else if (r) {
                            const id = parseInt(r.getAttribute('data-reject'));
                            try {
                                await API.rejectLeaseInvite(id);
                                await Swal.fire('Rejected', 'Lease invitation rejected.', 'success');
                            } catch (err) {
                                const msg = (err && (err.body?.detail || err.message)) || 'Failed to reject invitation';
                                Swal.fire('Error', msg, 'error');
                            }
                        }
                    });
                }
            });
        } catch (error) {
            console.error('Failed to load invitations', error);
            Swal.fire('Error', 'Unable to load lease invitations.', 'error');
        }
    }

    static async showTenantProfile() {
        if (!this._tenantProfile) {
            await this.loadTenantProfile();
        }

        const profile = this._tenantProfile;
        const lease = this._currentLease;

        await Swal.fire({
            title: 'My Tenant Profile',
            html: `
                <div class="text-start">
                    <div class="row g-3">
                        <div class="col-12">
                            <h6 class="text-primary"><i class="fas fa-user-circle me-2"></i>Personal Information</h6>
                            <div class="border rounded p-3">
                                <p class="mb-2"><strong>Full Name:</strong> ${profile?.full_name || 'N/A'}</p>
                                <p class="mb-2"><strong>Email:</strong> ${profile?.email || 'N/A'}</p>
                                <p class="mb-2"><strong>Phone:</strong> ${profile?.phone || 'N/A'}</p>
                                <p class="mb-2"><strong>Date of Birth:</strong> ${profile?.date_of_birth ? new Date(profile.date_of_birth).toLocaleDateString() : 'N/A'}</p>
                                <p class="mb-0"><strong>Account Type:</strong> <span class="badge bg-info">Tenant</span></p>
                            </div>
                        </div>
                        ${lease ? `
                        <div class="col-12">
                            <h6 class="text-success"><i class="fas fa-file-contract me-2"></i>Current Lease Status</h6>
                            <div class="border rounded p-3">
                                <p class="mb-2"><strong>Property:</strong> ${this._currentProperty?.title || 'N/A'}</p>
                                <p class="mb-2"><strong>Lease Start:</strong> ${new Date(lease.start_date).toLocaleDateString()}</p>
                                <p class="mb-2"><strong>Lease End:</strong> ${lease.end_date ? new Date(lease.end_date).toLocaleDateString() : 'Ongoing'}</p>
                                <p class="mb-0"><strong>Status:</strong> <span class="badge bg-success">${lease.status || 'Active'}</span></p>
                            </div>
                        </div>
                        ` : ''}
                        <div class="col-12">
                            <h6 class="text-info"><i class="fas fa-clock me-2"></i>Account Information</h6>
                            <div class="border rounded p-3">
                                <p class="mb-2"><strong>Member Since:</strong> ${profile?.created_at ? new Date(profile.created_at).toLocaleDateString() : 'N/A'}</p>
                                <p class="mb-0"><strong>Account Status:</strong> <span class="badge bg-success">Active</span></p>
                            </div>
                        </div>
                    </div>
                </div>
            `,
            width: '600px',
            confirmButtonText: 'Close'
        });
    }

    static async updateContactInformation() {
        // Ensure we have the latest profile
        let profile = this._tenantProfile;
        if (!profile) {
            try { profile = await API.getUserProfile(); } catch (e) { profile = {}; }
        }

        const result = await Swal.fire({
            title: 'Update Contact Information',
            html: `
                <div class="text-start">
                    <div class="mb-3">
                        <label class="form-label">Phone</label>
                        <input id="tenant-phone" class="form-control" type="text" value="${(profile && profile.phone) ? String(profile.phone).replace(/"/g, '&quot;') : ''}" />
                    </div>
                    <div class="mb-3">
                        <label class="form-label">Address</label>
                        <input id="tenant-address" class="form-control" type="text" value="${(profile && profile.address) ? String(profile.address).replace(/"/g, '&quot;') : ''}" />
                    </div>
                </div>
            `,
            showCancelButton: true,
            confirmButtonText: 'Save',
            preConfirm: () => {
                const phone = document.getElementById('tenant-phone').value.trim();
                const address = document.getElementById('tenant-address').value.trim();
                return { phone, address };
            }
        });

        if (result && result.value) {
            try {
                await API.updateUserProfile(result.value);
                // refresh cached profile
                this._tenantProfile = await API.getUserProfile().catch(() => this._tenantProfile);
                await Swal.fire({ icon: 'success', title: 'Updated', text: 'Contact information updated.' });
            } catch (err) {
                await Swal.fire({ icon: 'error', title: 'Update Failed', text: (err && (err.body?.detail || err.message)) || 'Failed to update contact information.' });
            }
        }
    }

    static async viewLeaseTerms() {
        if (!this._currentLease) {
            return Swal.fire({
                icon: 'info',
                title: 'No Active Lease',
                text: 'No active lease found to display terms and conditions.',
                confirmButtonText: 'OK'
            });
        }

        const lease = this._currentLease;

        await Swal.fire({
            title: 'Lease Terms & Conditions',
            html: `
                <div class="text-start">
                    <div class="row g-3">
                        <div class="col-12">
                            <h6 class="text-primary"><i class="fas fa-file-contract me-2"></i>Lease Agreement Details</h6>
                            <div class="border rounded p-3">
                                <p class="mb-2"><strong>Lease Duration:</strong> ${new Date(lease.start_date).toLocaleDateString()} - ${lease.end_date ? new Date(lease.end_date).toLocaleDateString() : 'Month-to-Month'}</p>
                                <p class="mb-2"><strong>Monthly Rent:</strong> $${lease.rent_amount}</p>
                                <p class="mb-2"><strong>Security Deposit:</strong> $${lease.deposit_amount || 'N/A'}</p>
                                <p class="mb-0"><strong>Payment Due Date:</strong> ${this.calculateNextDueDate(lease.start_date)}</p>
                            </div>
                        </div>
                        <div class="col-12">
                            <h6 class="text-warning"><i class="fas fa-exclamation-triangle me-2"></i>Important Terms</h6>
                            <div class="border rounded p-3 bg-light">
                                <ul class="mb-0 small">
                                    <li><strong>Late Fees:</strong> $50 fee applied for payments received after the 5th of the month</li>
                                    <li><strong>Pet Policy:</strong> ${lease.pet_policy || 'No pets allowed without written consent'}</li>
                                    <li><strong>Smoking Policy:</strong> ${lease.smoking_policy || 'No smoking permitted on the premises'}</li>
                                    <li><strong>Noise Policy:</strong> Quiet hours between 10 PM and 7 AM</li>
                                    <li><strong>Maintenance:</strong> Report all maintenance issues within 24 hours</li>
                                    <li><strong>Notice Period:</strong> 30 days written notice required for lease termination</li>
                                </ul>
                            </div>
                        </div>
                        <div class="col-12">
                            <h6 class="text-info"><i class="fas fa-info-circle me-2"></i>Tenant Responsibilities</h6>
                            <div class="border rounded p-3">
                                <ul class="mb-0 small">
                                    <li>Keep the property clean and in good condition</li>
                                    <li>Pay rent on time each month</li>
                                    <li>Report maintenance issues promptly</li>
                                    <li>Comply with all lease terms and local laws</li>
                                    <li>Allow property inspections with proper notice</li>
                                </ul>
                            </div>
                        </div>
                    </div>
                </div>
            `,
            width: '700px',
            confirmButtonText: 'Close'
        });
    }

    static async manageEmergencyContacts() {
        const contacts = this._emergencyContacts || [];

        const { isConfirmed, value: action } = await Swal.fire({
            title: 'Emergency Contacts',
            html: `
                <div class="text-start">
                    ${contacts.length > 0 ? `
                    <h6 class="text-primary mb-3"><i class="fas fa-phone-alt me-2"></i>Current Emergency Contacts</h6>
                    <div class="list-group mb-3">
                        ${contacts.map(contact => `
                            <div class="list-group-item">
                                <div class="d-flex justify-content-between align-items-start">
                                    <div>
                                        <h6 class="mb-1">${contact.name}</h6>
                                        <p class="mb-1"><strong>Relationship:</strong> ${contact.relationship}</p>
                                        <p class="mb-1"><strong>Phone:</strong> ${contact.phone}</p>
                                        ${contact.email ? `<p class="mb-0"><strong>Email:</strong> ${contact.email}</p>` : ''}
                                    </div>
                                    <button class="btn btn-sm btn-outline-danger" onclick="RenterProperties.removeEmergencyContact(${contact.id})">
                                        <i class="fas fa-trash"></i>
                                    </button>
                                </div>
                            </div>
                        `).join('')}
                    </div>
                    ` : '<p class="text-muted mb-3">No emergency contacts added yet.</p>'}
                    <div class="d-grid gap-2">
                        <button class="btn btn-primary btn-sm" onclick="RenterProperties.addEmergencyContact()">
                            <i class="fas fa-plus me-2"></i>Add Emergency Contact
                        </button>
                    </div>
                </div>
            `,
            width: '600px',
            showConfirmButton: true,
            confirmButtonText: 'Close',
            allowOutsideClick: false
        });
    }

    static async addEmergencyContact() {
        const { value: formValues } = await Swal.fire({
            title: 'Add Emergency Contact',
            html: `
                <div class="text-start">
                    <div class="mb-3">
                        <label for="contact-name" class="form-label">Full Name *</label>
                        <input type="text" class="form-control" id="contact-name" required>
                    </div>
                    <div class="mb-3">
                        <label for="contact-relationship" class="form-label">Relationship *</label>
                        <select class="form-control" id="contact-relationship" required>
                            <option value="">Select relationship</option>
                            <option value="Parent">Parent</option>
                            <option value="Sibling">Sibling</option>
                            <option value="Spouse">Spouse</option>
                            <option value="Partner">Partner</option>
                            <option value="Friend">Friend</option>
                            <option value="Relative">Relative</option>
                            <option value="Other">Other</option>
                        </select>
                    </div>
                    <div class="mb-3">
                        <label for="contact-phone" class="form-label">Phone Number *</label>
                        <input type="tel" class="form-control" id="contact-phone" required>
                    </div>
                    <div class="mb-3">
                        <label for="contact-email" class="form-label">Email Address</label>
                        <input type="email" class="form-control" id="contact-email">
                    </div>
                </div>
            `,
            focusConfirm: false,
            showCancelButton: true,
            confirmButtonText: 'Add Contact',
            preConfirm: () => {
                const name = document.getElementById('contact-name').value;
                const relationship = document.getElementById('contact-relationship').value;
                const phone = document.getElementById('contact-phone').value;
                
                if (!name || !relationship || !phone) {
                    Swal.showValidationMessage('Please fill in all required fields');
                    return false;
                }
                
                return {
                    name: name,
                    relationship: relationship,
                    phone: phone,
                    email: document.getElementById('contact-email').value
                };
            }
        });

        if (formValues) {
            try {
                const newContact = await API.addEmergencyContact(formValues);
                this._emergencyContacts = this._emergencyContacts || [];
                this._emergencyContacts.push(newContact);
                
                Swal.fire({
                    icon: 'success',
                    title: 'Contact Added',
                    text: 'Emergency contact has been successfully added.',
                    timer: 2000
                });
                
                // Refresh the emergency contacts view
                setTimeout(() => this.manageEmergencyContacts(), 2000);
            } catch (error) {
                Swal.fire({
                    icon: 'error',
                    title: 'Failed to Add Contact',
                    text: 'Unable to add emergency contact. Please try again.',
                    confirmButtonText: 'OK'
                });
            }
        }
    }

    static async removeEmergencyContact(contactId) {
        const { isConfirmed } = await Swal.fire({
            title: 'Remove Emergency Contact',
            text: 'Are you sure you want to remove this emergency contact?',
            icon: 'warning',
            showCancelButton: true,
            confirmButtonText: 'Remove',
            cancelButtonText: 'Cancel'
        });

        if (isConfirmed) {
            try {
                await API.removeEmergencyContact(contactId);
                this._emergencyContacts = this._emergencyContacts.filter(c => c.id !== contactId);
                
                Swal.fire({
                    icon: 'success',
                    title: 'Contact Removed',
                    text: 'Emergency contact has been removed.',
                    timer: 2000
                });
                
                // Refresh the emergency contacts view
                setTimeout(() => this.manageEmergencyContacts(), 2000);
            } catch (error) {
                Swal.fire({
                    icon: 'error',
                    title: 'Failed to Remove Contact',
                    text: 'Unable to remove emergency contact. Please try again.',
                    confirmButtonText: 'OK'
                });
            }
        }
    }

    static async viewCoTenants() {
        if (!this._currentLease) {
            return Swal.fire({
                icon: 'info',
                title: 'No Active Lease',
                text: 'No active lease found to check for co-tenants.',
                confirmButtonText: 'OK'
            });
        }

        const coTenants = this._coTenants || [];

        await Swal.fire({
            title: 'Co-tenants Information',
            html: `
                <div class="text-start">
                    ${coTenants.length > 0 ? `
                    <h6 class="text-primary mb-3"><i class="fas fa-user-friends me-2"></i>Current Co-tenants</h6>
                    <div class="row g-3">
                        ${coTenants.map(tenant => `
                            <div class="col-12">
                                <div class="border rounded p-3">
                                    <h6 class="mb-2">${tenant.full_name}</h6>
                                    <p class="mb-1"><strong>Email:</strong> ${tenant.email}</p>
                                    <p class="mb-1"><strong>Phone:</strong> ${tenant.phone || 'N/A'}</p>
                                    <p class="mb-0"><strong>Lease Start:</strong> ${new Date(tenant.lease_start_date).toLocaleDateString()}</p>
                                </div>
                            </div>
                        `).join('')}
                    </div>
                    ` : `
                    <div class="text-center py-4">
                        <i class="fas fa-user text-muted" style="font-size: 3rem;"></i>
                        <h6 class="mt-3 text-muted">No Co-tenants</h6>
                        <p class="text-muted mb-0">You are the only tenant for this property.</p>
                    </div>
                    `}
                    <hr>
                    <div class="bg-light rounded p-3">
                        <h6 class="text-info"><i class="fas fa-info-circle me-2"></i>Co-tenant Guidelines</h6>
                        <ul class="mb-0 small">
                            <li>All tenants are jointly responsible for rent payments</li>
                            <li>Maintenance requests can be submitted by any tenant</li>
                            <li>Communication with the owner should involve all tenants</li>
                            <li>Any lease modifications require all tenants' agreement</li>
                        </ul>
                    </div>
                </div>
            `,
            width: '600px',
            confirmButtonText: 'Close'
        });
    }
}