// Small site-wide JS helpers
document.addEventListener('DOMContentLoaded', () => {
    // Smooth scroll for anchor links
    document.querySelectorAll('a[href^="#"]').forEach(a => {
        a.addEventListener('click', function (e) {
            e.preventDefault();
            const target = document.querySelector(this.getAttribute('href'));
            if (target) target.scrollIntoView({ behavior: 'smooth' });
        });
    });

    // Mobile sidebar toggle (if present)
    const toggle = document.querySelector('.sidebar-toggle');
    if (toggle) {
        toggle.addEventListener('click', () => {
            document.querySelector('.sidebar').classList.toggle('collapsed');
        });
    }

    // Global logout handler for pages with a logout button
    document.querySelectorAll('.logout-btn').forEach(btn => {
        btn.addEventListener('click', async (e) => {
            e.preventDefault();
            try {
                await API.logout({ suppressErrorUI: true });
            } catch (e) {
                // ignore API errors on logout, we'll clear local state regardless
            }
            try {
                localStorage.removeItem(CONFIG.TOKEN_KEY);
                localStorage.removeItem('reown_session_id');
            } catch (e) {}
            if (window.Swal && typeof Swal.fire === 'function') {
                await Swal.fire({ icon: 'success', title: 'Logged out', showConfirmButton: false, timer: 800 });
            }
            window.location.href = 'login.html#login';
        });
    });

    // Initialize dark mode on page load
    initializeDarkMode();
});

// Dark Mode Functions
async function toggleDarkMode() {
    const isDarkMode = document.body.classList.toggle('dark-mode');
    
    // Update all dark mode toggles on the page
    document.querySelectorAll('#darkModeToggle').forEach(toggle => {
        toggle.checked = isDarkMode;
    });
    
    // Store preference
    await saveDarkModePreference(isDarkMode);
}

async function saveDarkModePreference(isDarkMode) {
    // Always store in localStorage for immediate use
    localStorage.setItem('darkMode', isDarkMode);
    console.log('Dark mode preference saved to localStorage:', isDarkMode);
    
    // If user is authenticated, also store in database
    const token = localStorage.getItem(CONFIG?.TOKEN_KEY || 're-own_auth_token');
    if (token && typeof API !== 'undefined') {
        try {
            console.log('Saving dark mode preference to database...');
            const response = await API.request('/auth/user-preferences', {
                method: 'PUT',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({
                    dark_mode: isDarkMode
                })
            });
            console.log('Dark mode preference saved to database successfully:', response);
        } catch (error) {
            console.warn('Failed to save dark mode preference to database:', error);
            // Show user a notification about the failure but don't prevent the UI change
            if (window.Swal && typeof Swal.fire === 'function') {
                Swal.fire({
                    icon: 'warning',
                    title: 'Settings Not Synced',
                    text: 'Your dark mode preference was saved locally but could not be synced to your account.',
                    timer: 3000,
                    showConfirmButton: false
                });
            }
        }
    } else {
        console.log('User not authenticated, dark mode preference saved locally only');
    }
}

async function loadDarkModePreference() {
    let isDarkMode = false;
    
    // Try to load from database if user is authenticated
    const token = localStorage.getItem(CONFIG?.TOKEN_KEY || 're-own_auth_token');
    if (token && typeof API !== 'undefined') {
        try {
            console.log('Loading dark mode preference from database...');
            const preferences = await API.request('/auth/user-preferences');
            if (preferences && typeof preferences.dark_mode === 'boolean') {
                isDarkMode = preferences.dark_mode;
                // Update localStorage to match database
                localStorage.setItem('darkMode', isDarkMode);
                console.log('Dark mode preference loaded from database:', isDarkMode);
            } else {
                console.log('No dark mode preference found in database, using localStorage');
                // Fallback to localStorage
                isDarkMode = localStorage.getItem('darkMode') === 'true';
            }
        } catch (error) {
            console.warn('Failed to load preferences from database, using localStorage:', error);
            // Fallback to localStorage
            isDarkMode = localStorage.getItem('darkMode') === 'true';
        }
    } else {
        console.log('User not authenticated, using localStorage for dark mode');
        // Not authenticated, use localStorage
        isDarkMode = localStorage.getItem('darkMode') === 'true';
    }
    
    return isDarkMode;
}

async function initializeDarkMode() {
    const isDarkMode = await loadDarkModePreference();
    
    if (isDarkMode) {
        document.body.classList.add('dark-mode');
    }
    
    // Set the toggle state
    document.querySelectorAll('#darkModeToggle').forEach(toggle => {
        toggle.checked = isDarkMode;
    });
}
