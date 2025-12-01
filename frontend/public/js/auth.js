class Auth {
    static init() {
        this.bindEvents();
        this.applyHashPanel();
        window.addEventListener('hashchange', () => this.applyHashPanel());
        this.checkAuthStatus();
    }

    static bindEvents() {
        // Switch between login and register forms
        document.querySelectorAll('.auth-tab').forEach(tab => {
            tab.addEventListener('click', () => this.switchAuthForm(tab.dataset.tab));
        });

        // Support links with class .toggle-auth (present in login.html)
        document.querySelectorAll('.toggle-auth').forEach(link => {
            link.addEventListener('click', (e) => {
                e.preventDefault();
                const target = link.getAttribute('data-switch') || (link.href.includes('#register') ? 'register' : 'login');
                window.location.hash = `#${target}`;
                this.switchAuthForm(target);
            });
        });

        // Handle form submissions
        document.getElementById('login-form').addEventListener('submit', (e) => this.handleLogin(e));
        document.getElementById('register-form').addEventListener('submit', (e) => this.handleRegister(e));

        // Handle logout
        const logoutBtn = document.querySelector('.logout-btn');
        if (logoutBtn) {
            logoutBtn.addEventListener('click', () => this.handleLogout());
        }
    }

    static switchAuthForm(tab) {
        // Update active tab
        document.querySelectorAll('.auth-tab').forEach(t => {
            t.classList.toggle('active', t.dataset.tab === tab);
        });

        // Show selected form
        const lp = document.getElementById('login-panel');
        const rp = document.getElementById('register-panel');
        if (lp && rp) {
            if (tab === 'login') {
                lp.classList.remove('d-none');
                rp.classList.add('d-none');
            } else if (tab === 'register') {
                rp.classList.remove('d-none');
                lp.classList.add('d-none');
            }
        } else {
            // Fallback to form-only toggle
            const lf = document.getElementById('login-form');
            const rf = document.getElementById('register-form');
            if (lf && rf) {
                lf.style.display = tab === 'login' ? 'block' : 'none';
                rf.style.display = tab === 'register' ? 'block' : 'none';
            }
        }
    }

    static applyHashPanel() {
        const hash = (window.location.hash || '').toLowerCase();
        if (hash.includes('register')) {
            this.switchAuthForm('register');
        } else {
            this.switchAuthForm('login');
        }
    }

    static async handleLogin(e) {
        e.preventDefault();
        
        const email = document.getElementById('login-email').value.trim();
        const password = document.getElementById('login-password').value;

        // Log login attempt
        ErrorLogger.logInfo('Login Attempt', {
            email: email,
            timestamp: new Date().toISOString()
        });

        // Basic validation
        if (!email || !password) {
            ErrorLogger.logWarning('Login Validation Failed', {
                reason: 'Missing email or password'
            });
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
            console.log('Token payload:', payload);
            let role = payload && payload.role ? payload.role : null;
            console.log('Role from token:', role);
            
            ErrorLogger.logInfo('Login Successful', {
                email: email,
                role: role,
                hasToken: !!token
            });
            
            // Store session id if present
            if (payload && payload.sid) {
                localStorage.setItem('reown_session_id', payload.sid);
            }

            // If token doesn't include role, try to fetch current user from API
            if (!role) {
                try {
                    const profile = await API.request('/auth/me');
                    console.log('Profile from API:', profile);
                    role = profile.role;
                } catch (err) {
                    console.warn('Could not fetch profile:', err);
                    ErrorLogger.logWarning('Could not fetch profile from /auth/me', {
                        error: err.message
                    });
                    // Default to owner if we can't determine role
                    role = 'owner';
                }
            }

            console.log('Final role:', role);
            ErrorLogger.logInfo('Final Role Determined', { role: role });

            // Show success message then redirect
            await Swal.fire({
                icon: 'success',
                title: 'Welcome back!',
                showConfirmButton: false,
                timer: 1200
            });

            // Add small delay to ensure alert is dismissed
            await new Promise(resolve => setTimeout(resolve, 100));

            // Determine target page
            const targetPage = role === 'owner' ? 'owner.html' : 'renter.html';
            console.log('Loading:', targetPage);
            
            ErrorLogger.logInfo('Page Load Initiated', {
                targetPage: targetPage,
                currentUrl: window.location.href
            });
            
            // Navigate using a normal location change (avoid document.write duplication & parser-blocking warnings)
            try {
                ErrorLogger.logInfo('Navigating to page', { targetPage });
                // Use relative path instead of leading slash to avoid root mismatch in some static hosting contexts
                window.location.replace(targetPage);
            } catch (navErr) {
                console.warn('Primary navigation failed, fallback to href', navErr);
                window.location.href = targetPage;
            }
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

        const submitBtn = e.target.querySelector('button[type="submit"]');
        const originalBtnText = submitBtn ? submitBtn.textContent : null;
        if (submitBtn) {
            submitBtn.disabled = true;
            submitBtn.textContent = 'Creating...';
        }
        try {
            const result = await API.register(userData);
            ErrorLogger.logInfo('Registration Successful', { email, role, userId: result && result.id });
            // Show success feedback first, THEN redirect after short delay so user perceives success.
            await Swal.fire({
                icon: 'success',
                title: 'Account Created',
                text: 'You can now log in with your credentials.',
                timer: 1600,
                showConfirmButton: false
            });
            // Ensure panels reset to login hash for deep-link consistency
            try { window.location.replace('login.html#login'); } catch(_) { window.location.href = 'login.html#login'; }
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
        finally {
            if (submitBtn) {
                submitBtn.disabled = false;
                if (originalBtnText) submitBtn.textContent = originalBtnText;
            }
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

    static async checkAuthStatus() {
        if (this.isAuthenticated()) {
            const token = this.getAuthToken();
            const payload = Util.decodeJWT(token);
            const role = payload && payload.role ? payload.role : null;

            if (role) {
                // Show message and redirect to appropriate dashboard
                if (window.Swal) {
                    try {
                        const result = await Swal.fire({
                            icon: 'info',
                            title: 'Already Signed In',
                            // Use html so we can add a 'Switch Account' inline link
                            html: 'You are already logged in. What would you like to do?<br/><small class="text-muted">You can also <a href="#" id="sw-switch-account">switch account</a> to log in with a different user.</small>',
                            showCancelButton: true,
                            showDenyButton: true,
                            confirmButtonText: 'Go to Dashboard',
                            denyButtonText: 'Sign Out',
                            cancelButtonText: 'Stay Here',
                            willOpen: () => {
                                // Attach handler to the inline 'Switch Account' link
                                const el = document.getElementById('sw-switch-account');
                                if (el) {
                                    el.addEventListener('click', async (ev) => {
                                        ev.preventDefault();
                                        try { await API.logout(); } catch (e) { /* ignore */ }
                                        localStorage.removeItem(CONFIG.TOKEN_KEY);
                                        localStorage.removeItem('reown_session_id');
                                        // Navigate to login for switching accounts
                                        window.location.href = 'login.html#login';
                                    });
                                }
                            }
                        });

                        if (result && result.isConfirmed) {
                            if (role === 'owner') {
                                window.location.href = 'owner.html';
                            } else {
                                window.location.href = 'renter.html';
                            }
                        } else if (result && result.isDenied) {
                            try {
                                await API.logout();
                            } catch (e) {
                                console.warn('Logout API call failed:', e);
                            }
                            localStorage.removeItem(CONFIG.TOKEN_KEY);
                            localStorage.removeItem('reown_session_id');

                            await Swal.fire({
                                icon: 'success',
                                title: 'Signed Out',
                                text: 'You have been signed out successfully.',
                                timer: 1200,
                                showConfirmButton: false
                            });

                            // Reload the page to show login form
                            window.location.reload();
                        }
                    } catch (err) {
                        console.error('Already Signed In dialog failed:', err);
                    }
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
                        try {
                            await API.logout();
                        } catch (e) { /* ignore */ }
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
