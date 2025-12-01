class Util {
    static decodeJWT(token) {
        if (!token) return null;
        try {
            const parts = token.split('.');
            if (parts.length < 2) return null;
            let payload = parts[1].replace(/-/g, '+').replace(/_/g, '/');
            // Add padding if missing
            const pad = payload.length % 4;
            if (pad === 2) payload += '==';
            else if (pad === 3) payload += '=';
            else if (pad !== 0) {
                // If padding length is invalid, bail out safely
                return null;
            }
            const decoded = atob(payload);
            // decodeURIComponent(escape()) handles UTF-8 in older browsers; safe fallback
            try {
                return JSON.parse(decodeURIComponent(escape(decoded)));
            } catch {
                return JSON.parse(decoded);
            }
        } catch (e) {
            console.warn('Failed to decode JWT', e);
            return null;
        }
    }

    static formatCurrency(amount) {
        return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(amount || 0);
    }
}

// Global dark mode toggle with backend persistence when authenticated
async function toggleDarkMode() {
    try {
        const isDark = !document.body.classList.contains('dark-mode');
        document.body.classList.toggle('dark-mode', isDark);
        try {
            localStorage.setItem('darkMode', JSON.stringify(isDark));
        } catch(_) {}
        // Reflect UI toggle states
        document.querySelectorAll('#darkModeToggle').forEach(el => { try { el.checked = isDark; } catch(_){} });

        // Persist preference to backend if logged in
        try {
            const token = localStorage.getItem(CONFIG.TOKEN_KEY);
            if (token && typeof API !== 'undefined') {
                await API.request('/auth/user-preferences', {
                    method: 'PUT',
                    body: JSON.stringify({ dark_mode: isDark })
                });
            }
        } catch (e) {
            console.warn('Backend dark mode update failed (non-blocking):', e);
        }
        return isDark;
    } catch (e) {
        console.error('toggleDarkMode failed:', e);
        return document.body.classList.contains('dark-mode');
    }
}

// Apply saved dark mode on load
document.addEventListener('DOMContentLoaded', async () => {
    try {
        let isDark = false;
        // Prefer backend preference if logged in
        const token = localStorage.getItem(CONFIG.TOKEN_KEY);
        if (token && typeof API !== 'undefined') {
            try {
                const prefs = await API.request('/auth/user-preferences');
                if (typeof prefs.dark_mode === 'boolean') {
                    isDark = !!prefs.dark_mode;
                }
            } catch (e) {
                // Fallback to local
                const local = localStorage.getItem('darkMode');
                if (local !== null) isDark = JSON.parse(local);
            }
        } else {
            const local = localStorage.getItem('darkMode');
            if (local !== null) isDark = JSON.parse(local);
        }
        document.body.classList.toggle('dark-mode', !!isDark);
        document.querySelectorAll('#darkModeToggle').forEach(el => { try { el.checked = !!isDark; } catch(_){} });
    } catch (e) {
        console.warn('Failed to apply saved dark mode:', e);
    }
});

// Clear browser localStorage and sessionStorage
function clearBrowserStorage() {
    localStorage.clear();
    sessionStorage.clear();
    console.log('localStorage and sessionStorage cleared');
}

// Optionally, call this on logout or add a button:
// clearBrowserStorage();

// Set password to user's own email
function setPasswordToEmail(emailInputId, passwordInputId) {
    var email = document.getElementById(emailInputId).value.trim();
    document.getElementById(passwordInputId).value = email;
}

// Example usage:
// setPasswordToEmail('login-email', 'login-password');
// You can call this on a button click or form event.
