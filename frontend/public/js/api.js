class API {
    static async request(endpoint, options = {}) {
        const token = localStorage.getItem(CONFIG.TOKEN_KEY);
        
        const defaultHeaders = {};

        if (token) {
            defaultHeaders['Authorization'] = `Bearer ${token}`;
        }

        const isFormData = options && options.body instanceof FormData;
        const config = {
            ...options,
            headers: {
                ...defaultHeaders,
                ...options.headers,
            },
        };
        if (!isFormData) {
            config.headers['Content-Type'] = config.headers['Content-Type'] || 'application/json';
        }

        const requestId = Math.random().toString(36).substr(2, 9);
        const logPrefix = `[API-${requestId}]`;
        
        try {
            console.log(`${logPrefix} ${config.method || 'GET'} ${CONFIG.API_BASE_URL}${endpoint}`);
            console.log(`${logPrefix} Request config:`, config);
            
            const response = await fetch(`${CONFIG.API_BASE_URL}${endpoint}`, config);

            const contentType = response.headers.get('content-type') || '';
            const isJson = contentType.includes('application/json');
            const body = isJson ? await response.json().catch(() => ({})) : await response.text();

            console.log(`${logPrefix} Response status: ${response.status} ${response.statusText}`);
            console.log(`${logPrefix} Response body:`, body);

            if (!response.ok) {
                const detail = isJson ? (body.detail || JSON.stringify(body)) : body;
                const debugInfo = body.debug_info || {};
                const errorCode = response.headers.get('X-Error-Code') || (isJson ? body.error_code : null) || null;
                
                console.error(`${logPrefix} API Error Details:`, {
                    status: response.status,
                    statusText: response.statusText,
                    detail,
                    debugInfo,
                    errorCode,
                    endpoint,
                    requestConfig: config
                });
                
                // Build structured error to allow UI mapping
                const err = new Error(detail || 'Request failed');
                err.status = response.status;
                err.statusText = response.statusText;
                err.errorCode = errorCode;
                err.body = body;
                throw err;
            }

            return isJson ? body : { raw: body };
        } catch (error) {
            // Network or CORS errors surface here
            console.error(`${logPrefix} Network/Fetch Error:`, {
                message: error.message,
                endpoint,
                config,
                stack: error.stack
            });
            
            // Store error for debugging
            this.logError(error, endpoint, config);
            
            // Rethrow preserving structured fields when present
            if (error.message && error.message.includes('Failed to fetch')) {
                const netErr = new Error('Network error: unable to reach API');
                netErr.errorCode = 'NETWORK_ERROR';
                if (window.ErrorUI) ErrorUI.show(netErr, endpoint);
                throw netErr;
            }
            if (window.ErrorUI) ErrorUI.show(error, endpoint);
            throw error;
        }
    }

    static logError(error, endpoint, config) {
        const errorLog = {
            timestamp: new Date().toISOString(),
            error: error.message,
            stack: error.stack,
            endpoint,
            config,
            userAgent: navigator.userAgent,
            url: window.location.href
        };
        
        // Store in localStorage for debugging
        const existingLogs = JSON.parse(localStorage.getItem('api_error_logs') || '[]');
        existingLogs.push(errorLog);
        
        // Keep only last 50 errors
        if (existingLogs.length > 50) {
            existingLogs.splice(0, existingLogs.length - 50);
        }
        
        localStorage.setItem('api_error_logs', JSON.stringify(existingLogs));
        console.error('Error logged to localStorage:', errorLog);
    }

    static getErrorLogs() {
        return JSON.parse(localStorage.getItem('api_error_logs') || '[]');
    }

    static clearErrorLogs() {
        localStorage.removeItem('api_error_logs');
        console.log('Error logs cleared');
    }

    // Authentication
    static async login(credentials) {
        return await this.request(ENDPOINTS.AUTH.LOGIN, {
            method: 'POST',
            body: JSON.stringify(credentials),
        });
    }

    static async register(userData) {
        return await this.request(ENDPOINTS.AUTH.REGISTER, {
            method: 'POST',
            body: JSON.stringify(userData),
        });
    }

    static async logout(options = {}) {
        try {
            return await this.request(ENDPOINTS.AUTH.LOGOUT, {
                method: 'POST',
            });
        } catch (e) {
            if (options.suppressErrorUI) {
                // swallow to allow forced local logout
                return { ok: false };
            }
            throw e;
        }
    }

    // Properties
    static async getProperties(options = {}) {
        // Attempt lightweight summary endpoint unless full detail explicitly requested
        if (!options.full) {
            try {
                const summary = await this.request('/properties/summary');
                // Normalize to array of property-like objects for existing callers
                if (summary && Array.isArray(summary.items)) {
                    return summary.items;
                }
            } catch (e) {
                // Fallback silently to full list
                console.warn('Summary properties fetch failed, falling back to full list:', e.message);
            }
        }
        return await this.request(ENDPOINTS.PROPERTIES.LIST);
    }

    static async createProperty(propertyData) {
        return await this.request(ENDPOINTS.PROPERTIES.CREATE, {
            method: 'POST',
            body: JSON.stringify(propertyData),
        });
    }

    static async updateProperty(id, propertyData) {
        const endpoint = ENDPOINTS.PROPERTIES.UPDATE.replace(':id', id);
        return await this.request(endpoint, {
            method: 'PUT',
            body: JSON.stringify(propertyData),
        });
    }

    static async deleteProperty(id) {
        const endpoint = ENDPOINTS.PROPERTIES.DELETE.replace(':id', id);
        return await this.request(endpoint, {
            method: 'DELETE',
        });
    }

    // Payments
    static async getPayments() {
        return await this.request(ENDPOINTS.PAYMENTS.LIST);
    }

    static async createPayment(paymentData) {
        return await this.request(ENDPOINTS.PAYMENTS.CREATE, {
            method: 'POST',
            body: JSON.stringify(paymentData),
        });
    }

    static async updatePayment(id, paymentData) {
        const endpoint = ENDPOINTS.PAYMENTS.UPDATE.replace(':id', id);
        return await this.request(endpoint, {
            method: 'PUT',
            body: JSON.stringify(paymentData),
        });
    }

    // Tenants/Renters
    static async getTenants() {
        return await this.request(ENDPOINTS.TENANTS.LIST);
    }

    // Utilities
    static async getUtilities() {
        return await this.request(ENDPOINTS.UTILITIES.LIST);
    }

    static async createUtility(utilityData) {
        return await this.request(ENDPOINTS.UTILITIES.CREATE, {
            method: 'POST',
            body: JSON.stringify(utilityData),
        });
    }

    static async updateUtility(id, utilityData) {
        const endpoint = ENDPOINTS.UTILITIES.UPDATE.replace(':id', id);
        return await this.request(endpoint, {
            method: 'PUT',
            body: JSON.stringify(utilityData),
        });
    }

    // Reports
    static async getOccupancyReport() {
        return await this.request(ENDPOINTS.REPORTS.OCCUPANCY);
    }

    static async getPaymentsReport() {
        return await this.request(ENDPOINTS.REPORTS.PAYMENTS);
    }

    static async getUtilitiesReport() {
        return await this.request(ENDPOINTS.REPORTS.UTILITIES);
    }

    // Renter-specific methods
    static async getCurrentLease() {
        return await this.request('/leases/current');
    }

    static async getUtilitiesByTenant(tenantId) {
        return await this.request(`/utilities?tenant_id=${tenantId}`);
    }

    static async getPaymentsByTenant(tenantId) {
        return await this.request(`/payments?tenant_id=${tenantId}`);
    }

    static async downloadLeaseAgreement(leaseId) {
        const response = await fetch(`${CONFIG.API_BASE_URL}/leases/${leaseId}/agreement`, {
            method: 'GET',
            headers: {
                'Authorization': `Bearer ${localStorage.getItem(CONFIG.TOKEN_KEY)}`
            }
        });
        
        if (!response.ok) {
            throw new Error('Failed to download agreement');
        }
        const blob = await response.blob();
        return { blob, contentType: response.headers.get('content-type') || 'application/octet-stream' };
    }

    static async getPropertyDocuments(propertyId) {
        return await this.request(`/properties/${propertyId}/documents`);
    }

    // Tenant Management methods
    static async createLease(leaseData) {
        return await this.request('/leases/', {
            method: 'POST',
            body: JSON.stringify({
                tenant_id: parseInt(leaseData.tenant_id),
                property_id: parseInt(leaseData.property_id),
                start_date: leaseData.start_date,
                rent_amount: parseFloat(leaseData.rent_amount)
            })
        });
    }

    static async assignPropertyToTenant(propertyId, leaseData) {
        // Use invite flow instead of immediate lease creation
        return await this.request('/leases/invite', {
            method: 'POST',
            body: JSON.stringify({
                property_id: parseInt(propertyId),
                renter_id: parseInt(leaseData.renter_id || leaseData.tenant_id),
                start_date: leaseData.start_date,
                rent_amount: parseFloat(leaseData.rent_amount),
                deposit_amount: leaseData.deposit_amount ? parseFloat(leaseData.deposit_amount) : null
            })
        });
    }

    static async getAllLeases() {
        return await this.request('/leases/all');
    }

    // Lease invitations
    static async listMyLeaseInvites() {
        return await this.request('/leases/invites');
    }

    static async approveLeaseInvite(invitationId) {
        return await this.request(`/leases/invites/${invitationId}/approve`, { method: 'POST' });
    }

    static async rejectLeaseInvite(invitationId) {
        return await this.request(`/leases/invites/${invitationId}/reject`, { method: 'POST' });
    }

    static async terminateLease(leaseId) {
        return await this.request(`/leases/${leaseId}/terminate`, {
            method: 'PUT'
        });
    }

    static async updateLease(leaseId, updates) {
        return await this.request(`/leases/${leaseId}`, {
            method: 'PUT',
            body: JSON.stringify(updates)
        });
    }

    // User Profile methods
    static async getCurrentUser() {
        return await this.request('/auth/me');
    }

    static async getUserById(userId) {
        return await this.request(`/users/${userId}`);
    }

    static async searchUsersByEmail(email) {
        return await this.request(`/users/search?email=${encodeURIComponent(email)}`);
    }

    static async searchUsersByName(name) {
        return await this.request(`/users/search?name=${encodeURIComponent(name)}`);
    }

    // Enhanced property assignment with renter ID support
    static async assignPropertyToTenantById(propertyId, leaseData) {
        return await this.request('/leases/assign-by-id', {
            method: 'POST',
            body: JSON.stringify({
                property_id: parseInt(propertyId),
                ...leaseData
            })
        });
    }

    static async getAllRenters() {
        try {
            // Use tenants router which returns all renters
            const response = await this.request('/tenants');
            
            // Handle errors in response
            if (response.detail) {
                throw new Error(response.detail);
            }
            
            return response;
        } catch (error) {
            console.error('Error fetching renters:', error);
            throw error;
        }
    }

    // Helper that guarantees an array of renters for convenience
    static async getAllRentersArray() {
        const resp = await this.getAllRenters();
        return Array.isArray(resp) ? resp : (resp && Array.isArray(resp.tenants) ? resp.tenants : []);
    }

    // Tenant Management API Methods
    static async getUserProfile() {
        return await this.request('/users/profile');
    }

    static async updateUserProfile(profileData) {
        return await this.request('/users/profile', {
            method: 'PUT',
            body: JSON.stringify(profileData)
        });
    }

    static async getEmergencyContacts() {
        return await this.request('/users/emergency-contacts');
    }

    static async addEmergencyContact(contactData) {
        return await this.request('/users/emergency-contacts', {
            method: 'POST',
            body: JSON.stringify(contactData)
        });
    }

    static async removeEmergencyContact(contactId) {
        return await this.request(`/users/emergency-contacts/${contactId}`, {
            method: 'DELETE'
        });
    }

    static async getCoTenants(leaseId) {
        return await this.request(`/leases/${leaseId}/co-tenants`);
    }

    static async getUserPreferences() {
        return await this.request('/users/preferences');
    }

    static async updateUserPreferences(preferences) {
        return await this.request('/users/preferences', {
            method: 'PUT',
            body: JSON.stringify(preferences)
        });
    }
}
