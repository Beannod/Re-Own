class Auth {
    static init() {
        this.bindEvents();
        this.checkAuthStatus();
    }

    static bindEvents() {
        // Switch between login and register forms
        document.querySelectorAll('.auth-tab').forEach(tab => {
            tab.addEventListener('click', () => this.switchAuthForm(tab.dataset.tab));
        });

        // Handle form submissions
        document.getElementById('login-form').addEventListener('submit', (e) => this.handleLogin(e));
        document.getElementById('register-form').addEventListener('submit', (e) => this.handleRegister(e));

        // Handle logout
        document.querySelector('.logout-btn').addEventListener('click', () => this.handleLogout());
    }

    static switchAuthForm(tab) {
        // Update active tab
        document.querySelectorAll('.auth-tab').forEach(t => {
            t.classList.toggle('active', t.dataset.tab === tab);
        });

        // Show selected form
        document.getElementById('login-form').style.display = tab === 'login' ? 'block' : 'none';
        document.getElementById('register-form').style.display = tab === 'register' ? 'block' : 'none';
    }

    static async handleLogin(e) {
        e.preventDefault();
        
        const email = document.getElementById('login-email').value.trim();
        const password = document.getElementById('login-password').value;

        // Basic validation
        if (!email || !password) {
            return Swal.fire({
                icon: 'warning',
                title: 'Missing information',
                text: 'Please enter both email and password.'
            });
        }

        try {
            const response = await API.login({ email, password });
            const token = response.access_token;
            this.setAuthToken(token);

            // Try to read role from token
            const payload = Util.decodeJWT(token);
            let role = payload && payload.role ? payload.role : null;
            // Store session id if present
            if (payload && payload.sid) {
                localStorage.setItem('reown_session_id', payload.sid);
            }

            // If token doesn't include role, try to fetch current user from API
            if (!role) {
                try {
                    const profile = await API.request('/auth/me');
                    role = profile.role;
                } catch (err) {
                    console.warn('Could not fetch profile:', err);
                }
            }

            // Redirect to appropriate page
            if (role === 'owner') {
                window.location.href = 'owner.html';
            } else {
                window.location.href = 'renter.html';
            }

            Swal.fire({
                icon: 'success',
                title: 'Welcome back!',
                showConfirmButton: false,
                timer: 1200
            });
        } catch (error) {
            // Map backend error codes/statuses to friendly messages
            let title = 'Login Failed';
            let text = error.message || 'Please try again.';
            switch (error.errorCode) {
                case 'EMAIL_NOT_FOUND':
                    text = 'Email address not found. Please check or register a new account.';
                    break;
                case 'INVALID_PASSWORD':
                    text = 'Invalid password. Please try again.';
                    break;
                case 'NETWORK_ERROR':
                    title = 'Network Error';
                    text = 'Unable to reach the server. Please check your connection and try again.';
                    break;
                default:
                    // Fallbacks based on status
                    if (error.status === 404) text = 'Email address not found.';
                    else if (error.status === 401) text = 'Incorrect email or password.';
                    break;
            }
            Swal.fire({ icon: 'error', title, text });
        }
    }

    static async handleRegister(e) {
        e.preventDefault();
        
        const email = document.getElementById('register-email').value.trim();
        const username = document.getElementById('register-username').value.trim();
        const full_name = document.getElementById('register-fullname').value.trim();
        const role = document.getElementById('register-role').value;
        const password = document.getElementById('register-password').value;

        if (!email || !username || !full_name || !role || !password) {
            return Swal.fire({
                icon: 'warning',
                title: 'Missing information',
                text: 'Please fill in all required fields.'
            });
        }

        const userData = { email, username, full_name, role, password };

        try {
            await API.register(userData);
            // Redirect user to login page after successful registration
            window.location.href = 'login.html';
            Swal.fire({
                icon: 'success',
                title: 'Registration Successful',
                text: 'Please login with your credentials'
            });
        } catch (error) {
            // Friendly messages for common registration errors
            let title = 'Registration Failed';
            let text = error.message || 'Please fix the errors and try again.';
            switch (error.errorCode) {
                case 'EMAIL_EXISTS':
                    text = 'That email is already registered. Try logging in or use a different email.';
                    break;
                case 'USERNAME_EXISTS':
                    text = 'That username is already taken. Please choose another one.';
                    break;
                case 'CREATE_USER_FAILED':
                    text = 'Could not create the account at this time. Please try again later.';
                    break;
                case 'NETWORK_ERROR':
                    title = 'Network Error';
                    text = 'Unable to reach the server. Please check your connection and try again.';
                    break;
                default:
                    if (error.status === 409) text = 'Email or username already exists.';
                    break;
            }
            Swal.fire({ icon: 'error', title, text });
        }
    }

    static handleLogout() {
        // Attempt API logout; fall back to local clear
        (async () => {
            try { await API.logout(); } catch (e) { /* ignore */ }
            localStorage.removeItem(CONFIG.TOKEN_KEY);
            localStorage.removeItem('reown_session_id');
            window.location.href = 'login.html#login';
        })();
    }

    static setAuthToken(token) {
        localStorage.setItem(CONFIG.TOKEN_KEY, token);
    }

    static getAuthToken() {
        return localStorage.getItem(CONFIG.TOKEN_KEY);
    }

    static isAuthenticated() {
        return !!this.getAuthToken();
    }

    static checkAuthStatus() {
        if (this.isAuthenticated()) {
            const token = this.getAuthToken();
            const payload = Util.decodeJWT(token);
            const role = payload && payload.role ? payload.role : null;
            
            if (role) {
                // Show message and redirect to appropriate dashboard
                if (window.Swal) {
                    Swal.fire({
                        icon: 'info',
                        title: 'Already Signed In',
                        text: 'You are already logged in. What would you like to do?',
                        showCancelButton: true,
                        showDenyButton: true,
                        confirmButtonText: 'Show Dashboard',
                        denyButtonText: 'Sign Out',
                        cancelButtonText: 'Stay Here'
                    }).then((result) => {
                        if (result.isConfirmed) {
                            if (role === 'owner') {
                                window.location.href = 'owner.html';
                            } else {
                                window.location.href = 'renter.html';
                            }
                        } else if (result.isDenied) {
                            // Sign out user
                            localStorage.removeItem(CONFIG.TOKEN_KEY);
                            localStorage.removeItem('reown_session_id');
                            Swal.fire({
                                icon: 'success',
                                title: 'Signed Out',
                                text: 'You have been signed out successfully.',
                                timer: 1500,
                                showConfirmButton: false
                            });
                        }
                    });
                } else {
                    // Fallback without SweetAlert
                    const choice = prompt('You are already signed in. Choose:\n1. Go to Dashboard\n2. Sign Out\n3. Stay Here\n\nEnter 1, 2, or 3:');
                    if (choice === '1') {
                        if (role === 'owner') {
                            window.location.href = 'owner.html';
                        } else {
                            window.location.href = 'renter.html';
                        }
                    } else if (choice === '2') {
                        localStorage.removeItem(CONFIG.TOKEN_KEY);
                        localStorage.removeItem('reown_session_id');
                        alert('You have been signed out successfully.');
                    }
                }
            }
        }
    }

    static showDashboard() {
        // Not used in multi-page flow
    }

    static showAuthForms() {
        // Not used in multi-page flow
    }
}
