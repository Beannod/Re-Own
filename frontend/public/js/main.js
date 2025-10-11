document.addEventListener('DOMContentLoaded', () => {
    // Only run landing page logic if elements exist
    const home = document.getElementById('homepage-details');
    const auth = document.getElementById('auth-container');
    const loginBtn = document.getElementById('homepage-login-btn');
    if (home && auth) {
        home.style.display = 'block';
        auth.style.display = 'none';
    }
    if (loginBtn) {
        loginBtn.addEventListener('click', () => {
            if (home && auth) {
                home.style.display = 'none';
                auth.style.display = 'block';
            }
            if (typeof Auth !== 'undefined') {
                try { Auth.init(); } catch (e) { console.warn('Auth.init failed', e); }
            }
        });
    }

    // Handle network errors globally
    window.addEventListener('unhandledrejection', event => {
        console.error('Unhandled promise rejection:', event.reason);
        Swal.fire({
            icon: 'error',
            title: 'Network Error',
            text: 'Please check your internet connection and try again.'
        });
    });

    // Add global error handling
    window.onerror = function(msg, url, lineNo, columnNo, error) {
        console.error('Global error:', error);
        Swal.fire({
            icon: 'error',
            title: 'Something went wrong',
            text: 'Please refresh the page and try again.'
        });
        return false;
    };
});
