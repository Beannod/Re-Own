class Dashboard {
    static init() {
        this.updateDashboardStats();
        this.bindEvents();
        Properties.init();
        Payments.init();
        Utilities.init();
        
        // Initialize renter-specific functionality if available
        if (typeof RenterProperties !== 'undefined') {
            RenterProperties.init();
        }
    }

    static bindEvents() {
        // Handle navigation
        document.querySelectorAll('.nav-item').forEach(item => {
            item.addEventListener('click', () => this.handleNavigation(item.dataset.page));
        });
    }

    static async updateDashboardStats() {
        try {
            // Get various reports
            const [properties, occupancyReport, paymentsReport] = await Promise.all([
                API.getProperties(),
                API.getOccupancyReport(),
                API.getPaymentsReport()
            ]);

            // Update UI
            document.getElementById('total-properties').textContent = properties.length;
            document.getElementById('total-tenants').textContent = occupancyReport.totalTenants;
            document.getElementById('monthly-revenue').textContent = 
                new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' })
                    .format(paymentsReport.monthlyRevenue);
            document.getElementById('occupancy-rate').textContent = 
                `${Math.round(occupancyReport.occupancyRate)}%`;

        } catch (error) {
            console.error('Error updating dashboard:', error);
            Swal.fire({
                icon: 'error',
                title: 'Dashboard Update Failed',
                text: 'Could not fetch latest statistics'
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
    try { Dashboard.init(); } catch (e) { console.warn('Dashboard.init failed', e); }
});
