class Dashboard {
    static init() {
        console.log('Dashboard.init() called');
        this.bindEvents();
        this.updateDashboardStats().catch(err => console.error('Dashboard stats error:', err));
        
        try {
            Properties.init();
        } catch (err) {
            console.warn('Properties.init() error:', err);
        }
        
        try {
            Payments.init();
        } catch (err) {
            console.warn('Payments.init() error:', err);
        }
        
        try {
            Utilities.init();
        } catch (err) {
            console.warn('Utilities.init() error:', err);
        }
        
        // Initialize renter-specific functionality if available
        if (typeof RenterProperties !== 'undefined') {
            try {
                RenterProperties.init();
            } catch (err) {
                console.warn('RenterProperties.init() error:', err);
            }
        }
        console.log('Dashboard.init() completed');
    }

    static bindEvents() {
        // Handle navigation
        document.querySelectorAll('.nav-item').forEach(item => {
            item.addEventListener('click', () => this.handleNavigation(item.dataset.page));
        });
        
        // Handle logout buttons
        document.querySelectorAll('.logout-btn').forEach(btn => {
            btn.addEventListener('click', () => this.handleLogout());
        });
    }
    
    static async handleLogout() {
        console.log('[Logout] Initiating logout sequence');
        // First attempt API logout while token still present to avoid 401 noise
        try {
            await API.logout();
            console.log('[Logout] API logout request sent successfully');
        } catch (e) {
            console.warn('[Logout] API logout failed (non-blocking):', e);
        }
        // Now clear possible token/session keys (support legacy names)
        const tokenKeys = [CONFIG.TOKEN_KEY, 'reown_session_id', 'reown_session_token', 'auth_token'];
        tokenKeys.forEach(k => { try { localStorage.removeItem(k); } catch(_){} });
        // Defensive: clear sessionStorage variants
        ['re-own_auth_token','auth_token','reown_session_id'].forEach(k => { try { sessionStorage.removeItem(k); } catch(_){} });
        console.log('[Logout] Local/session tokens cleared');
        // Primary redirect
        try {
            window.location.replace('login.html#login');
            console.log('[Logout] Redirecting via location.replace');
        } catch (e) {
            console.warn('[Logout] location.replace failed, falling back to href', e);
            window.location.href = 'login.html#login';
        }
        // Fallback: force navigation if still on owner page after 700ms
        setTimeout(() => {
            try {
                const stillHasToken = !!localStorage.getItem(CONFIG.TOKEN_KEY);
                if (stillHasToken || /owner\.html/i.test(window.location.pathname)) {
                    console.warn('[Logout] Fallback redirect engaged');
                    window.location.href = 'login.html#login';
                }
            } catch(_){}
        }, 700);
    }

    static async updateDashboardStats() {
        try {
            console.log('Fetching dashboard KPIs...');
            
            // Fetch comprehensive owner analytics
            const analytics = await API.request(ENDPOINTS.AUTH.OWNER_ANALYTICS, {
                method: 'GET'
            });
            
            console.log('Owner Analytics:', analytics);
            
            // Update primary KPI cards
            const kpiTotalProps = document.getElementById('kpi-total-properties');
            const kpiActiveTenants = document.getElementById('kpi-active-tenants');
            const kpiMonthlyRevenue = document.getElementById('kpi-monthly-revenue');
            const kpiOccupancyRate = document.getElementById('kpi-occupancy-rate');
            
            if (kpiTotalProps) kpiTotalProps.textContent = analytics.totalProperties || 0;
            if (kpiActiveTenants) kpiActiveTenants.textContent = analytics.activeTenants || 0;
            if (kpiMonthlyRevenue) {
                kpiMonthlyRevenue.textContent = new Intl.NumberFormat('en-US', { 
                    style: 'currency', 
                    currency: 'USD',
                    minimumFractionDigits: 0,
                    maximumFractionDigits: 0
                }).format(analytics.monthlyRevenue || 0);
            }
            if (kpiOccupancyRate) kpiOccupancyRate.textContent = `${Math.round(analytics.occupancyRate || 0)}%`;
            
            // Update secondary metrics
            const kpiPendingPayments = document.getElementById('kpi-pending-payments');
            const kpiAvailableProps = document.getElementById('kpi-available-properties');
            const kpiCollectionRate = document.getElementById('kpi-collection-rate');
            
            if (kpiPendingPayments) {
                kpiPendingPayments.textContent = new Intl.NumberFormat('en-US', { 
                    style: 'currency', 
                    currency: 'USD',
                    minimumFractionDigits: 0,
                    maximumFractionDigits: 0
                }).format(analytics.pendingAmount || 0);
            }
            if (kpiAvailableProps) kpiAvailableProps.textContent = analytics.availableProperties || 0;
            if (kpiCollectionRate) kpiCollectionRate.textContent = `${Math.round(analytics.collectionRate || 0)}%`;
            
            console.log('Dashboard KPIs updated successfully');
        } catch (error) {
            console.error('Error updating dashboard stats:', error);
            // Set default values on error
            const defaultElements = [
                'kpi-total-properties', 'kpi-active-tenants', 'kpi-available-properties'
            ];
            defaultElements.forEach(id => {
                const el = document.getElementById(id);
                if (el) el.textContent = '0';
            });
            
            const currencyElements = ['kpi-monthly-revenue', 'kpi-pending-payments'];
            currencyElements.forEach(id => {
                const el = document.getElementById(id);
                if (el) el.textContent = '$0';
            });
            
            const percentElements = ['kpi-occupancy-rate', 'kpi-collection-rate'];
            percentElements.forEach(id => {
                const el = document.getElementById(id);
                if (el) el.textContent = '0%';
            });
        }
    }

    static handleNavigation(page) {
        // Hide all content containers
        document.querySelectorAll('[id$="-container"]').forEach(container => {
            container.style.display = 'none';
        });

        // Show selected content
        const container = document.getElementById(`${page}-container`);
        if (container) {
            container.style.display = 'block';
        }

        // Update active nav item
        document.querySelectorAll('.nav-item').forEach(item => {
            item.classList.toggle('active', item.dataset.page === page);
        });

        // Initialize the respective module
        switch (page) {
            case 'dashboard':
                this.updateDashboardStats();
                break;
            case 'properties':
                Properties.init();
                break;
            case 'tenants':
                Tenants.init();
                break;
            case 'payments':
                Payments.init();
                break;
            case 'utilities':
                Utilities.init();
                break;
            case 'reports':
                Reports.init();
                break;
        }
    }
}

// Initialize dashboard (and Properties/Payments/Utilities) when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    try {
        // Client-side guard: require an authenticated owner to view this page.
        // If no token or token role is not 'owner', redirect to login.
        try {
            const token = Auth.getAuthToken();
            if (!token) {
                console.warn('No auth token found - redirecting to login');
                window.location.href = 'login.html';
                return;
            }
            const payload = Util.decodeJWT(token) || {};
            if (!payload.role || payload.role !== 'owner') {
                console.warn('User is not an owner or role missing - redirecting to login');
                window.location.href = 'login.html';
                return;
            }
        } catch (guardErr) {
            console.error('Auth guard error:', guardErr);
            window.location.href = 'login.html';
            return;
        }

        Dashboard.init();
    } catch (e) { console.warn('Dashboard.init failed', e); }
});
