/**
 * Comprehensive Error Logger
 * Logs all errors to browser console and sends to backend for persistent storage
 */

class ErrorLogger {
    static LOG_FILE = 'frontend_errors.log';
    static MAX_LOCAL_ERRORS = 100;
    static STORAGE_KEY = 'app_error_log';
    
    static init() {
        console.log('ErrorLogger initializing...');
        
        // Log all console errors
        window.addEventListener('error', (event) => {
            this.logError('Uncaught Error', {
                message: event.message,
                filename: event.filename,
                lineno: event.lineno,
                colno: event.colno,
                stack: event.error?.stack
            });
        });

        // Log unhandled promise rejections
        window.addEventListener('unhandledrejection', (event) => {
            this.logError('Unhandled Promise Rejection', {
                reason: event.reason?.message || event.reason,
                stack: event.reason?.stack
            });
        });

        // Override console.error to capture all errors
        const originalError = console.error;
        console.error = function(...args) {
            originalError.apply(console, args);
            ErrorLogger.logError('console.error', {
                args: args.map(arg => 
                    typeof arg === 'object' ? JSON.stringify(arg) : String(arg)
                )
            });
        };

        // Override console.warn for warnings
        const originalWarn = console.warn;
        console.warn = function(...args) {
            originalWarn.apply(console, args);
            ErrorLogger.logWarning('console.warn', {
                args: args.map(arg => 
                    typeof arg === 'object' ? JSON.stringify(arg) : String(arg)
                )
            });
        };

        console.log('ErrorLogger initialized');
    }

    static logError(title, details = {}) {
        const timestamp = new Date().toISOString();
        const errorEntry = {
            timestamp,
            level: 'ERROR',
            title,
            ...details,
            url: window.location.href,
            userAgent: navigator.userAgent
        };

        // Log to console
        console.group(`🔴 ${title}`);
        console.log('Timestamp:', timestamp);
        Object.entries(details).forEach(([key, value]) => {
            console.log(key + ':', value);
        });
        console.groupEnd();

        // Store locally
        this.storeError(errorEntry);

        // Try to send to backend
        this.sendToBackend(errorEntry);

        return errorEntry;
    }

    static logWarning(title, details = {}) {
        const timestamp = new Date().toISOString();
        const warningEntry = {
            timestamp,
            level: 'WARNING',
            title,
            ...details,
            url: window.location.href,
            userAgent: navigator.userAgent
        };

        // Log to console
        console.group(`⚠️ ${title}`);
        console.log('Timestamp:', timestamp);
        Object.entries(details).forEach(([key, value]) => {
            console.log(key + ':', value);
        });
        console.groupEnd();

        // Store locally
        this.storeError(warningEntry);

        return warningEntry;
    }

    static logInfo(title, details = {}) {
        const timestamp = new Date().toISOString();
        const infoEntry = {
            timestamp,
            level: 'INFO',
            title,
            ...details,
            url: window.location.href
        };

        console.group(`ℹ️ ${title}`);
        console.log('Timestamp:', timestamp);
        Object.entries(details).forEach(([key, value]) => {
            console.log(key + ':', value);
        });
        console.groupEnd();

        // Store locally
        this.storeError(infoEntry);

        return infoEntry;
    }

    static storeError(errorEntry) {
        try {
            const errors = JSON.parse(localStorage.getItem(this.STORAGE_KEY) || '[]');
            errors.push(errorEntry);

            // Keep only recent errors
            if (errors.length > this.MAX_LOCAL_ERRORS) {
                errors.splice(0, errors.length - this.MAX_LOCAL_ERRORS);
            }

            localStorage.setItem(this.STORAGE_KEY, JSON.stringify(errors));
        } catch (e) {
            console.error('Failed to store error locally:', e);
        }
    }

    static async sendToBackend(errorEntry) {
        try {
            const base = (typeof CONFIG !== 'undefined' && CONFIG.API_BASE_URL) ? CONFIG.API_BASE_URL : 'http://127.0.0.1:8000/api';
            const url = base.replace(/\/$/, '') + '/logs/error';
            await fetch(url, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(errorEntry)
            });
        } catch (e) {
            try { console.warn('ErrorLogger backend send failed (non-blocking)', e); } catch(_){}
        }
    }

    static getStoredErrors() {
        try {
            return JSON.parse(localStorage.getItem(this.STORAGE_KEY) || '[]');
        } catch (e) {
            return [];
        }
    }

    static getErrorsAsText() {
        const errors = this.getStoredErrors();
        return errors.map(err => {
            let text = `[${err.timestamp}] ${err.level} - ${err.title}\n`;
            Object.entries(err).forEach(([key, value]) => {
                if (key !== 'timestamp' && key !== 'level' && key !== 'title') {
                    if (typeof value === 'object') {
                        text += `  ${key}: ${JSON.stringify(value)}\n`;
                    } else {
                        text += `  ${key}: ${value}\n`;
                    }
                }
            });
            text += '\n';
            return text;
        }).join('---\n');
    }

    static downloadErrorLog() {
        const errorText = this.getErrorsAsText();
        const blob = new Blob([errorText], { type: 'text/plain' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `error-log-${new Date().toISOString().split('T')[0]}.txt`;
        a.click();
        URL.revokeObjectURL(url);
    }

    static clearErrors() {
        try {
            localStorage.removeItem(this.STORAGE_KEY);
            console.log('Error log cleared');
        } catch (e) {
            console.error('Failed to clear error log:', e);
        }
    }

    static displayErrorPanel() {
        const errors = this.getStoredErrors();
        const panel = document.createElement('div');
        panel.id = 'error-panel';
        panel.style.cssText = `
            position: fixed;
            bottom: 20px;
            right: 20px;
            background: #fff;
            border: 2px solid #dc3545;
            border-radius: 8px;
            padding: 16px;
            max-width: 400px;
            max-height: 300px;
            overflow-y: auto;
            box-shadow: 0 4px 12px rgba(0,0,0,0.15);
            z-index: 9999;
            font-family: monospace;
            font-size: 12px;
        `;

        let html = `<div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px;">
            <strong style="color: #dc3545;">⚠️ Errors (${errors.length})</strong>
            <button onclick="document.getElementById('error-panel').remove()" style="background: none; border: none; cursor: pointer; font-size: 16px;">×</button>
        </div>`;

        if (errors.length === 0) {
            html += '<div style="color: #28a745;">✓ No errors logged</div>';
        } else {
            errors.slice(-10).forEach(err => {
                html += `<div style="margin-bottom: 8px; padding: 8px; background: #f8f9fa; border-left: 3px solid #dc3545;">
                    <strong>${err.title}</strong><br>
                    <small style="color: #666;">${err.timestamp}</small><br>
                    ${err.message ? `<small>${err.message}</small>` : ''}
                </div>`;
            });
        }

        html += `<div style="margin-top: 12px; border-top: 1px solid #ddd; padding-top: 12px;">
            <button onclick="ErrorLogger.downloadErrorLog()" style="
                background: #0d6efd;
                color: white;
                border: none;
                padding: 6px 12px;
                border-radius: 4px;
                cursor: pointer;
                width: 100%;
                margin-bottom: 6px;
            ">Download Log</button>
            <button onclick="ErrorLogger.clearErrors(); location.reload()" style="
                background: #6c757d;
                color: white;
                border: none;
                padding: 6px 12px;
                border-radius: 4px;
                cursor: pointer;
                width: 100%;
            ">Clear & Reload</button>
        </div>`;

        panel.innerHTML = html;
        document.body.appendChild(panel);
    }
}

// Initialize on page load
document.addEventListener('DOMContentLoaded', () => {
    ErrorLogger.init();
});

// Also initialize immediately if DOM is already loaded
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
        ErrorLogger.init();
    });
} else {
    ErrorLogger.init();
}
