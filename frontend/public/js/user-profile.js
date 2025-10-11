/**
 * User Profile Management
 * Handles loading and displaying user profile information
 */
class UserProfile {
    static async init() {
        await this.loadUserProfile();
        await this.loadUserPreferences();
    }

    static async loadUserProfile() {
        try {
            // Get current user information
            const userInfo = await API.getCurrentUser();
            
            if (userInfo) {
                this.updateProfileDisplay(userInfo);
            }
        } catch (error) {
            console.error('Error loading user profile:', error);
            this.showProfileError();
        }
    }

    static updateProfileDisplay(userInfo) {
        // Update full name
        const fullNameElement = document.getElementById('user-full-name');
        if (fullNameElement) {
            const fullName = this.getFullName(userInfo);
            fullNameElement.textContent = fullName;
        }

        // Update user ID
        const userIdElement = document.getElementById('user-id');
        if (userIdElement) {
            userIdElement.textContent = userInfo.id || userInfo.user_id || 'N/A';
        }

        // Update location
        const locationElement = document.getElementById('user-location');
        if (locationElement) {
            const location = this.getUserLocation(userInfo);
            locationElement.textContent = location;
        }

        // Update last login
        const lastLoginElement = document.getElementById('last-login');
        if (lastLoginElement) {
            const lastLogin = this.formatLastLogin(userInfo.last_login);
            lastLoginElement.textContent = lastLogin;
        }
    }

    static getFullName(userInfo) {
        // Try different combinations to get full name
        if (userInfo.first_name && userInfo.last_name) {
            return `${userInfo.first_name} ${userInfo.last_name}`;
        } else if (userInfo.full_name) {
            return userInfo.full_name;
        } else if (userInfo.username) {
            return userInfo.username;
        } else if (userInfo.email) {
            return userInfo.email.split('@')[0];
        }
        return 'User';
    }

    static getUserLocation(userInfo) {
        // Get location from profile or address
        if (userInfo.profile && userInfo.profile.address) {
            return this.formatAddress(userInfo.profile.address);
        } else if (userInfo.address) {
            return this.formatAddress(userInfo.address);
        } else if (userInfo.timezone) {
            return `Timezone: ${userInfo.timezone}`;
        }
        return 'Location not set';
    }

    static formatAddress(address) {
        // Format address for display (extract city/state if possible)
        if (!address) return 'Location not set';
        
        // If it's a full address, try to extract city/state
        const parts = address.split(',');
        if (parts.length >= 2) {
            // Take last 2 parts for city, state
            return parts.slice(-2).join(',').trim();
        }
        
        // Return first 30 characters if too long
        return address.length > 30 ? address.substring(0, 30) + '...' : address;
    }

    static formatLastLogin(lastLogin) {
        if (!lastLogin) return 'Never';
        
        try {
            const date = new Date(lastLogin);
            const now = new Date();
            const diffTime = Math.abs(now - date);
            const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
            
            if (diffDays === 1) {
                return 'Yesterday';
            } else if (diffDays <= 7) {
                return `${diffDays} days ago`;
            } else {
                return date.toLocaleDateString();
            }
        } catch (error) {
            return 'Unknown';
        }
    }

    static showProfileError() {
        // Show error state in profile elements
        const elements = ['user-full-name', 'user-id', 'user-location', 'last-login'];
        elements.forEach(id => {
            const element = document.getElementById(id);
            if (element) {
                element.textContent = 'Error loading';
                element.classList.add('text-danger');
            }
        });
    }

    static async refreshProfile() {
        // Refresh profile information
        await this.loadUserProfile();
        await this.loadUserPreferences();
    }

    static async loadUserPreferences() {
        try {
            console.log('Loading user preferences...');
            const preferences = await API.request('/auth/user-preferences');
            
            if (preferences) {
                this.updatePreferencesDisplay(preferences);
            }
        } catch (error) {
            console.error('Error loading user preferences:', error);
            // Don't show error for preferences as it's not critical
        }
    }

    static updatePreferencesDisplay(preferences) {
        // Update dark mode toggle state to match database
        const darkModeToggles = document.querySelectorAll('#darkModeToggle');
        darkModeToggles.forEach(toggle => {
            toggle.checked = preferences.dark_mode || false;
        });

        // Apply dark mode if it's enabled in database
        if (preferences.dark_mode) {
            if (!document.body.classList.contains('dark-mode')) {
                document.body.classList.add('dark-mode');
                console.log('Applied dark mode from database preferences');
            }
        } else {
            if (document.body.classList.contains('dark-mode')) {
                document.body.classList.remove('dark-mode');
                console.log('Removed dark mode from database preferences');
            }
        }

        // Update localStorage to match database
        localStorage.setItem('darkMode', preferences.dark_mode || false);
        
        console.log('User preferences loaded and applied:', preferences);
    }
}

// Auto-initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    UserProfile.init();
});