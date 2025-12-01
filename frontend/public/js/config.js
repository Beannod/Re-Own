const CONFIG = {
    API_BASE_URL: 'http://127.0.0.1:8000/api',
    TOKEN_KEY: 're-own_auth_token',
};

// API Endpoints
const ENDPOINTS = {
    AUTH: {
        LOGIN: '/auth/login',
        REGISTER: '/auth/register',
        LOGOUT: '/auth/logout',
        OWNER_ANALYTICS: '/auth/owner-analytics'
    },
    PROPERTIES: {
        LIST: '/properties',
        CREATE: '/properties',
        UPDATE: '/properties/:id',
        DELETE: '/properties/:id',
    },
    LOOKUPS: {
        PROPERTY_TYPES: '/lookups/property-types'
    },
    TENANTS: {
        LIST: '/tenants',
        CREATE: '/tenants',
        UPDATE: '/tenants/:id',
        DELETE: '/tenants/:id',
    },
    PAYMENTS: {
        LIST: '/payments',
        CREATE: '/payments',
        UPDATE: '/payments/:id',
    },
    UTILITIES: {
        LIST: '/utilities',
        CREATE: '/utilities',
        UPDATE: '/utilities/:id',
    },
    REPORTS: {
        OCCUPANCY: '/reports/occupancy',
        PAYMENTS: '/reports/payments',
        UTILITIES: '/reports/utilities',
    },
};
