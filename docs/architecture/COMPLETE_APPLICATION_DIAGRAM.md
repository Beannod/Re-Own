# Re-Own Property Management System - Complete Application Architecture

## 🏗️ High-Level Architecture Overview

```mermaid
graph TB
    subgraph "Client Layer"
        WEB[Web Browser<br/>Static HTML/JS/CSS]
        MOBILE[Mobile App<br/>React Native]
    end
    
    subgraph "Web Frontend"
        LANDING[Landing Page<br/>landing.html]
        AUTH[Authentication<br/>login.html]
        OWNER[Owner Dashboard<br/>owner.html]
        RENTER[Renter Dashboard<br/>renter.html]
    end
    
    subgraph "Frontend JavaScript Architecture"
        CONFIG[config.js<br/>API Configuration]
        API_JS[api.js<br/>HTTP Client]
        AUTH_JS[auth.js<br/>Authentication Logic]
        SITE[site.js<br/>Common Functions]
        PROPERTIES[properties.js<br/>Property Management]
        PAYMENTS[payments.js<br/>Payment Logic]
        UTILITIES[utilities.js<br/>Utility Management]
        PROFILE[user-profile.js<br/>User Management]
    end
    
    subgraph "Backend API Layer"
        FASTAPI[FastAPI Application<br/>main.py]
        
        subgraph "API Routers"
            AUTH_R[auth.py<br/>Authentication]
            PROP_R[properties.py<br/>Properties]
            TENANT_R[tenants.py<br/>Tenant Mgmt]
            PAY_R[payments.py<br/>Payments]
            UTIL_R[utilities.py<br/>Utilities]
            LEASE_R[leases.py<br/>Leases]
            MAINT_R[maintenance.py<br/>Maintenance]
            REP_R[reports.py<br/>Reports]
        end
    end
    
    subgraph "Core Backend Services"
        DB_SERVICE[database.py<br/>Database Layer]
        SECURITY[security.py<br/>JWT & Security]
        DEPS[dependencies.py<br/>Dependency Injection]
        ERROR_TRACK[ai_error_tracker.py<br/>Error Tracking]
    end
    
    subgraph "Database Layer"
        SQLSERVER[(SQL Server Database<br/>property_manager_db)]
        
        subgraph "Database Tables"
            USERS_T[users]
            PROPERTIES_T[properties]
            UNITS_T[units]
            LEASES_T[leases]
            PAYMENTS_T[payments]
            UTILITIES_T[utilities]
            MAINT_T[maintenance_requests]
            SESSIONS_T[sessions]
        end
        
        subgraph "Stored Procedures"
            SP_USER[User Management SPs]
            SP_PROP[Property Management SPs]
            SP_LEASE[Lease Management SPs]
            SP_PAY[Payment Processing SPs]
            SP_UTIL[Utility Management SPs]
        end
    end
    
    subgraph "File Storage"
        UPLOADS[uploads/<br/>Property Documents]
        LOGS[Logs<br/>ai_error_log.json<br/>sql_error_log.json]
    end
    
    %% Connections
    WEB --> LANDING
    WEB --> AUTH
    WEB --> OWNER
    WEB --> RENTER
    
    LANDING --> CONFIG
    AUTH --> AUTH_JS
    OWNER --> PROPERTIES
    RENTER --> PROFILE
    
    CONFIG --> API_JS
    AUTH_JS --> API_JS
    PROPERTIES --> API_JS
    PAYMENTS --> API_JS
    UTILITIES --> API_JS
    PROFILE --> API_JS
    
    API_JS -.->|HTTP/JSON| FASTAPI
    MOBILE -.->|HTTP/JSON| FASTAPI
    
    FASTAPI --> AUTH_R
    FASTAPI --> PROP_R
    FASTAPI --> TENANT_R
    FASTAPI --> PAY_R
    FASTAPI --> UTIL_R
    FASTAPI --> LEASE_R
    
    AUTH_R --> DB_SERVICE
    PROP_R --> DB_SERVICE
    TENANT_R --> DB_SERVICE
    PAY_R --> DB_SERVICE
    
    DB_SERVICE --> SQLSERVER
    SECURITY --> SESSIONS_T
    ERROR_TRACK --> LOGS
    
    SQLSERVER --> USERS_T
    SQLSERVER --> PROPERTIES_T
    SQLSERVER --> LEASES_T
    SQLSERVER --> PAYMENTS_T
    
    SP_USER -.-> USERS_T
    SP_PROP -.-> PROPERTIES_T
    SP_LEASE -.-> LEASES_T
    SP_PAY -.-> PAYMENTS_T
```

## 🎯 Application Flow & Component Interaction

### 1. Authentication Flow
```mermaid
sequenceDiagram
    participant User
    participant Frontend as Frontend (HTML/JS)
    participant API as FastAPI Backend
    participant DB as SQL Server
    participant Session as Session Store

    User->>Frontend: Enter credentials
    Frontend->>API: POST /api/auth/login
    API->>DB: sp_GetUserByEmail()
    DB-->>API: User data + password hash
    API->>API: Verify password
    API->>Session: Create session
    API-->>Frontend: JWT token + session_id
    Frontend->>Frontend: Store token in localStorage
    Frontend->>API: GET /api/auth/me (with Bearer token)
    API->>Session: Validate session
    API-->>Frontend: User profile data
```

### 2. Property Management Flow
```mermaid
sequenceDiagram
    participant Owner
    participant OwnerUI as Owner Dashboard
    participant API as FastAPI Backend
    participant DB as SQL Server

    Owner->>OwnerUI: Click "View Properties"
    OwnerUI->>API: GET /api/properties
    API->>DB: sp_GetPropertiesByOwner()
    DB-->>API: Properties list
    API-->>OwnerUI: JSON properties data
    OwnerUI->>OwnerUI: Render properties grid
    
    Owner->>OwnerUI: Click "Add Property"
    OwnerUI->>API: POST /api/properties
    API->>DB: sp_CreateProperty()
    DB-->>API: New property ID
    API-->>OwnerUI: Success response
    OwnerUI->>OwnerUI: Refresh properties list
```

### 3. Tenant Management Flow
```mermaid
sequenceDiagram
    participant Renter
    participant RenterUI as Renter Dashboard
    participant API as FastAPI Backend
    participant DB as SQL Server

    Renter->>RenterUI: Click "View Property Details"
    RenterUI->>API: GET /api/leases/current
    API->>DB: sp_GetCurrentLease()
    DB-->>API: Lease + Property + Owner data
    API-->>RenterUI: JSON lease data
    RenterUI->>RenterUI: Display property details modal
    
    Renter->>RenterUI: Click "Update Contact Info"
    RenterUI->>API: PUT /api/users/profile
    API->>DB: sp_UpdateUserProfile()
    DB-->>API: Updated profile
    API-->>RenterUI: Success response
```

## 🏛️ Database Schema Architecture

```mermaid
erDiagram
    USERS {
        int id PK
        string email UK
        string username UK
        string hashed_password
        string full_name
        string role
        string phone
        string address
        datetime created_at
        datetime updated_at
        boolean dark_mode
        json notification_preferences
    }
    
    PROPERTIES {
        int id PK
        int owner_id FK
        string title
        string address
        string property_type
        int bedrooms
        int bathrooms
        float area
        text description
        string status
        datetime created_at
        datetime updated_at
    }
    
    UNITS {
        int id PK
        int property_id FK
        string unit_number
        string unit_type
        string status
        datetime created_at
        datetime updated_at
    }
    
    LEASES {
        int id PK
        int tenant_id FK
        int unit_id FK
        date start_date
        date end_date
        float rent_amount
        float deposit_amount
        string status
        datetime created_at
        datetime updated_at
    }
    
    PAYMENTS {
        int id PK
        int lease_id FK
        float amount
        date payment_date
        string payment_method
        string status
        datetime created_at
    }
    
    UTILITIES {
        int id PK
        int unit_id FK
        string utility_type
        float reading
        date reading_date
        float amount
        datetime created_at
    }
    
    MAINTENANCE_REQUESTS {
        int id PK
        int unit_id FK
        int tenant_id FK
        string title
        text description
        string status
        string priority
        datetime created_at
        datetime updated_at
    }
    
    SESSIONS {
        string session_id PK
        int user_id FK
        datetime expires_at
        datetime last_seen
        boolean revoked
        datetime created_at
    }
    
    EMERGENCY_CONTACTS {
        int id PK
        int user_id FK
        string name
        string relationship
        string phone
        string email
        datetime created_at
    }

    USERS ||--o{ PROPERTIES : owns
    USERS ||--o{ LEASES : rents
    USERS ||--o{ SESSIONS : has
    USERS ||--o{ EMERGENCY_CONTACTS : has
    PROPERTIES ||--o{ UNITS : contains
    UNITS ||--o{ LEASES : leased_as
    UNITS ||--o{ UTILITIES : consumes
    UNITS ||--o{ MAINTENANCE_REQUESTS : requires
    LEASES ||--o{ PAYMENTS : generates
```

## 📁 File Structure & Organization

```
Re-Own/
├── 📱 Mobile App (React Native)
│   ├── src/
│   │   ├── components/     # Reusable UI components
│   │   ├── navigation/     # Stack & Tab navigators
│   │   ├── screens/        # App screens (Login, Dashboard, etc.)
│   │   ├── services/       # API service layer
│   │   ├── types/          # TypeScript definitions
│   │   └── utils/          # Auth context & utilities
│   ├── android/           # Android-specific configs
│   └── package.json       # Dependencies & scripts
│
├── 🌐 Frontend (Static Web)
│   └── public/
│       ├── 📄 HTML Pages
│       │   ├── landing.html    # Landing/Marketing page
│       │   ├── login.html      # Authentication page
│       │   ├── owner.html      # Owner dashboard
│       │   └── renter.html     # Renter dashboard
│       ├── 🎨 CSS Styles
│       │   ├── style.css       # Global styles & dark mode
│       │   ├── owner.css       # Owner-specific styles
│       │   ├── renter.css      # Renter-specific styles
│       │   └── landing.css     # Landing page styles
│       └── ⚡ JavaScript
│           ├── config.js          # API configuration
│           ├── api.js             # HTTP client & endpoints
│           ├── auth.js            # Authentication logic
│           ├── site.js            # Dark mode & common functions
│           ├── user-profile.js    # User profile management
│           ├── properties.js      # Property management
│           ├── renter-properties.js # Renter property views
│           ├── payments.js        # Payment processing
│           └── utilities.js       # Utility management
│
├── 🔧 Backend (FastAPI)
│   └── app/
│       ├── 🛣️ Routers
│       │   ├── auth.py           # Authentication endpoints
│       │   ├── properties.py     # Property CRUD operations
│       │   ├── tenants.py        # Tenant management
│       │   ├── leases.py         # Lease management
│       │   ├── payments.py       # Payment processing
│       │   ├── utilities.py      # Utility management
│       │   ├── maintenance.py    # Maintenance requests
│       │   └── reports.py        # Analytics & reporting
│       ├── 🏗️ Core
│       │   ├── dependencies.py   # Dependency injection
│       │   └── security.py       # JWT & password handling
│       ├── 📊 Models
│       │   ├── user.py          # User data models
│       │   ├── property.py      # Property data models
│       │   ├── payment.py       # Payment data models
│       │   └── utility.py       # Utility data models
│       ├── 📝 Schemas
│       │   ├── user.py          # Pydantic user schemas
│       │   ├── property.py      # Pydantic property schemas
│       │   ├── payment.py       # Pydantic payment schemas
│       │   └── utility.py       # Pydantic utility schemas
│       ├── database.py          # Database connection & SP execution
│       ├── ai_error_tracker.py  # AI-powered error tracking
│       └── main.py              # FastAPI application entry
│
├── 🗄️ Database
│   ├── database.sql          # Table creation scripts
│   ├── init_database.sql     # Database initialization
│   └── stored_procedures.sql # Stored procedure definitions
│
├── 📚 Documentation
│   └── architecture/
│       ├── system-architecture.md    # System overview
│       ├── sequence-diagrams.md      # Flow diagrams
│       └── COMPLETE_APPLICATION_DIAGRAM.md # This file
│
├── 📁 Uploads
│   └── property_docs/       # Property documents & images
│
├── 🚀 Deployment
│   ├── run.py              # Development server launcher
│   ├── restart.bat         # Windows restart script
│   └── requirements.txt    # Python dependencies
│
└── 📋 Project Files
    ├── README.md           # Project documentation
    ├── reown_pids.json     # Process ID tracking
    ├── ai_error_log.json   # AI error analysis logs
    └── sql_error_log.json  # SQL error logs
```

## 🔄 Data Flow Architecture

### Frontend → Backend Communication
```mermaid
graph LR
    subgraph "Frontend Layer"
        HTML[HTML Pages]
        JS[JavaScript Classes]
        CSS[CSS Styling]
    end
    
    subgraph "API Communication"
        CONFIG[config.js<br/>API_BASE_URL]
        API_CLASS[api.js<br/>HTTP Client]
        AUTH_TOKEN[localStorage<br/>JWT Token]
    end
    
    subgraph "Backend Processing"
        FASTAPI_MAIN[main.py<br/>FastAPI App]
        ROUTERS[API Routers]
        DB_LAYER[database.py<br/>Stored Procedures]
    end
    
    subgraph "Data Storage"
        SQLSERVER[(SQL Server)]
        FILES[File System]
    end
    
    HTML --> JS
    JS --> CONFIG
    CONFIG --> API_CLASS
    API_CLASS --> AUTH_TOKEN
    API_CLASS -.->|HTTP/JSON| FASTAPI_MAIN
    FASTAPI_MAIN --> ROUTERS
    ROUTERS --> DB_LAYER
    DB_LAYER --> SQLSERVER
    ROUTERS --> FILES
```

## 🎨 Frontend Architecture Breakdown

### JavaScript Class Structure
```mermaid
classDiagram
    class API {
        +request(endpoint, options)
        +login(credentials)
        +getCurrentUser()
        +getProperties()
        +createProperty(data)
        +getPayments()
        +createPayment(data)
        +getUserProfile()
        +updateUserProfile(data)
    }
    
    class UserProfile {
        +init()
        +loadUserProfile()
        +displayUserInfo()
        +handleProfileUpdate()
        +loadDarkModePreference()
    }
    
    class Properties {
        +init()
        +loadProperties()
        +showCreatePropertyModal()
        +handlePropertyCreate()
        +showEditPropertyModal()
        +deleteProperty(id)
    }
    
    class RenterProperties {
        +init()
        +bindPropertyActions()
        +bindTenantManagementActions()
        +showPropertyDetails()
        +showTenantProfile()
        +manageEmergencyContacts()
    }
    
    class Payments {
        +init()
        +loadPayments()
        +showCreatePaymentModal()
        +processPayment(data)
        +downloadReceipt(id)
    }
    
    UserProfile --> API
    Properties --> API
    RenterProperties --> API
    Payments --> API
```

### CSS Architecture
```mermaid
graph TD
    STYLE_CSS[style.css<br/>Global Styles]
    
    subgraph "Global Styling"
        COLORS[Color Variables<br/>Primary: #00bfa5]
        DARK_MODE[Dark Mode Support<br/>CSS Variables]
        TYPOGRAPHY[Typography<br/>Inter, Poppins]
        COMPONENTS[Bootstrap 5 Integration]
    end
    
    subgraph "Page-Specific Styles"
        OWNER_CSS[owner.css<br/>Dashboard Modules]
        RENTER_CSS[renter.css<br/>Action Buttons]
        LANDING_CSS[landing.css<br/>Marketing Styles]
    end
    
    subgraph "Module Styling"
        ACTION_BUTTONS[Gradient Action Buttons]
        CARD_STYLES[Card Hover Effects]
        RESPONSIVE[Mobile Responsive]
    end
    
    STYLE_CSS --> COLORS
    STYLE_CSS --> DARK_MODE
    STYLE_CSS --> TYPOGRAPHY
    STYLE_CSS --> COMPONENTS
    
    OWNER_CSS --> ACTION_BUTTONS
    RENTER_CSS --> ACTION_BUTTONS
    LANDING_CSS --> CARD_STYLES
    
    ACTION_BUTTONS --> RESPONSIVE
```

## ⚙️ Backend Architecture Breakdown

### FastAPI Router Structure
```mermaid
graph TB
    subgraph "FastAPI Main Application"
        MAIN[main.py<br/>FastAPI Instance]
        CORS[CORS Middleware]
        ERROR_HANDLER[Global Exception Handler]
        LOGGING[Request Logging]
    end
    
    subgraph "API Routers"
        AUTH_ROUTER[auth.py<br/>/api/auth/*]
        PROP_ROUTER[properties.py<br/>/api/properties/*]
        TENANT_ROUTER[tenants.py<br/>/api/tenants/*]
        PAYMENT_ROUTER[payments.py<br/>/api/payments/*]
        LEASE_ROUTER[leases.py<br/>/api/leases/*]
        UTIL_ROUTER[utilities.py<br/>/api/utilities/*]
        MAINT_ROUTER[maintenance.py<br/>/api/maintenance/*]
        REPORT_ROUTER[reports.py<br/>/api/reports/*]
    end
    
    subgraph "Core Services"
        DB_SERVICE[database.py<br/>StoredProcedures Class]
        SECURITY_SERVICE[security.py<br/>JWT & Password Hashing]
        DEPS[dependencies.py<br/>Authentication Dependencies]
        AI_TRACKER[ai_error_tracker.py<br/>Error Analysis]
    end
    
    MAIN --> CORS
    MAIN --> ERROR_HANDLER
    MAIN --> LOGGING
    MAIN --> AUTH_ROUTER
    MAIN --> PROP_ROUTER
    MAIN --> TENANT_ROUTER
    MAIN --> PAYMENT_ROUTER
    
    AUTH_ROUTER --> DB_SERVICE
    AUTH_ROUTER --> SECURITY_SERVICE
    PROP_ROUTER --> DB_SERVICE
    TENANT_ROUTER --> DB_SERVICE
    
    ERROR_HANDLER --> AI_TRACKER
    DB_SERVICE --> AI_TRACKER
```

### Database Connection Architecture
```mermaid
graph TB
    subgraph "Database Configuration"
        ENV_VARS[Environment Variables<br/>DB_SERVER, DB_NAME, etc.]
        CONN_STR[Connection String Builder]
        ODBC_DRIVER[ODBC Driver 17]
    end
    
    subgraph "Connection Management"
        STORED_PROCS[StoredProcedures Class]
        CONN_POOL[Connection Pooling]
        ERROR_HANDLING[SQL Error Handling]
        FALLBACK[Server Fallback Logic]
    end
    
    subgraph "SQL Server Instance"
        SQLEXPRESS[SQL Server Express<br/>.\SQLEXPRESS]
        PROPERTY_DB[(property_manager_db)]
        TABLES[Database Tables]
        SPS[Stored Procedures]
    end
    
    ENV_VARS --> CONN_STR
    CONN_STR --> ODBC_DRIVER
    ODBC_DRIVER --> STORED_PROCS
    STORED_PROCS --> CONN_POOL
    CONN_POOL --> ERROR_HANDLING
    ERROR_HANDLING --> FALLBACK
    
    FALLBACK --> SQLEXPRESS
    SQLEXPRESS --> PROPERTY_DB
    PROPERTY_DB --> TABLES
    PROPERTY_DB --> SPS
```

## 🔐 Security Architecture

```mermaid
graph TB
    subgraph "Authentication Layer"
        LOGIN[Login Form]
        JWT_TOKEN[JWT Token Generation]
        TOKEN_STORAGE[localStorage Storage]
        SESSION_DB[Database Sessions]
    end
    
    subgraph "Authorization Layer"
        BEARER_TOKEN[Bearer Token Validation]
        ROLE_CHECK[Role-Based Access Control]
        SESSION_VALIDATION[Session Expiry Check]
        MIDDLEWARE[Authentication Middleware]
    end
    
    subgraph "Security Features"
        PASSWORD_HASH[bcrypt Password Hashing]
        CORS_CONFIG[CORS Configuration]
        HTTPS_READY[HTTPS Ready]
        SESSION_MANAGEMENT[Session Revocation]
    end
    
    LOGIN --> JWT_TOKEN
    JWT_TOKEN --> TOKEN_STORAGE
    JWT_TOKEN --> SESSION_DB
    
    TOKEN_STORAGE --> BEARER_TOKEN
    BEARER_TOKEN --> ROLE_CHECK
    ROLE_CHECK --> SESSION_VALIDATION
    SESSION_VALIDATION --> MIDDLEWARE
    
    MIDDLEWARE --> PASSWORD_HASH
    MIDDLEWARE --> CORS_CONFIG
    MIDDLEWARE --> SESSION_MANAGEMENT
```

## 📱 Mobile App Architecture

```mermaid
graph TB
    subgraph "React Native App"
        APP_TSX[App.tsx<br/>Main Component]
        AUTH_CONTEXT[AuthContext<br/>Global State]
        NAVIGATION[AppNavigator<br/>Stack & Tab Navigation]
    end
    
    subgraph "Screen Components"
        LOGIN_SCREEN[LoginScreen.tsx]
        DASHBOARD_SCREEN[DashboardScreen.tsx]
        PROPERTIES_SCREEN[PropertiesScreen.tsx]
        PAYMENTS_SCREEN[PaymentsScreen.tsx]
        PROFILE_SCREEN[ProfileScreen.tsx]
    end
    
    subgraph "Services & Utils"
        API_SERVICE[ApiService.ts<br/>HTTP Client]
        TYPE_DEFS[types/index.ts<br/>TypeScript Types]
        ASYNC_STORAGE[AsyncStorage<br/>Token Persistence]
    end
    
    APP_TSX --> AUTH_CONTEXT
    APP_TSX --> NAVIGATION
    NAVIGATION --> LOGIN_SCREEN
    NAVIGATION --> DASHBOARD_SCREEN
    NAVIGATION --> PROPERTIES_SCREEN
    
    LOGIN_SCREEN --> API_SERVICE
    DASHBOARD_SCREEN --> API_SERVICE
    PROPERTIES_SCREEN --> API_SERVICE
    
    API_SERVICE --> TYPE_DEFS
    AUTH_CONTEXT --> ASYNC_STORAGE
```

## 🚀 Deployment & Development Architecture

```mermaid
graph TB
    subgraph "Development Environment"
        RUN_PY[run.py<br/>Dev Server Launcher]
        BACKEND_DEV[Uvicorn FastAPI Server<br/>Port 8000]
        FRONTEND_DEV[Python HTTP Server<br/>Port 8080]
        PID_TRACKING[reown_pids.json<br/>Process Management]
    end
    
    subgraph "Error Tracking & Monitoring"
        AI_ERROR_LOG[ai_error_log.json<br/>AI Error Analysis]
        SQL_ERROR_LOG[sql_error_log.json<br/>SQL Error Tracking]
        DEBUG_ENDPOINTS[/debug/errors<br/>/debug/sql-errors]
    end
    
    subgraph "Database Management"
        INIT_SCRIPTS[Database Initialization<br/>database.sql]
        STORED_PROC_SCRIPTS[Stored Procedures<br/>stored_procedures.sql]
        DB_CONNECTION_TEST[Connection Health Check]
    end
    
    RUN_PY --> BACKEND_DEV
    RUN_PY --> FRONTEND_DEV
    RUN_PY --> PID_TRACKING
    
    BACKEND_DEV --> AI_ERROR_LOG
    BACKEND_DEV --> SQL_ERROR_LOG
    BACKEND_DEV --> DEBUG_ENDPOINTS
    
    BACKEND_DEV --> INIT_SCRIPTS
    BACKEND_DEV --> STORED_PROC_SCRIPTS
    BACKEND_DEV --> DB_CONNECTION_TEST
```

## 🔗 Integration Points & API Contracts

### Key API Endpoints
```
Authentication:
├── POST /api/auth/login           # User login
├── POST /api/auth/register        # User registration
├── POST /api/auth/logout          # User logout
└── GET  /api/auth/me              # Current user info

Properties:
├── GET    /api/properties         # List properties
├── POST   /api/properties         # Create property
├── PUT    /api/properties/:id     # Update property
└── DELETE /api/properties/:id     # Delete property

Tenant Management:
├── GET  /api/leases/current       # Current lease info
├── POST /api/leases/assign        # Assign property to tenant
├── GET  /api/users/profile        # User profile
├── PUT  /api/users/profile        # Update profile
├── GET  /api/users/emergency-contacts  # Emergency contacts
└── POST /api/users/emergency-contacts  # Add emergency contact

Utilities & Payments:
├── GET  /api/payments             # Payment history
├── POST /api/payments             # Create payment
├── GET  /api/utilities            # Utility readings
└── POST /api/utilities            # Add utility reading
```

## 📈 Data Flow Summary

1. **User Access**: Browser loads static HTML/CSS/JS from port 8080
2. **Authentication**: JavaScript sends credentials to FastAPI on port 8000
3. **Session Management**: JWT tokens stored in localStorage, sessions in SQL Server
4. **Data Operations**: JavaScript classes make API calls to FastAPI routers
5. **Database Interaction**: FastAPI uses StoredProcedures class to execute SQL procedures
6. **Response Handling**: JSON responses processed by frontend and displayed to user
7. **Error Tracking**: All errors logged and analyzed by AI error tracking system
8. **File Management**: Property documents stored in uploads/ directory
9. **Mobile Access**: React Native app connects to same FastAPI backend
10. **Dark Mode**: User preferences stored in database and synchronized across sessions

This architecture provides a scalable, maintainable, and feature-rich property management system with comprehensive user interfaces for both owners and renters, robust backend APIs, and proper security implementations.