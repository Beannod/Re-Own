// Debug utilities for tracking errors and app state
class Debug {
    static init() {
        // Global error handler
        window.addEventListener('error', (event) => {
            this.logError('JavaScript Error', {
                message: event.message,
                filename: event.filename,
                lineno: event.lineno,
                colno: event.colno,
                stack: event.error?.stack
            });
        });

        // Unhandled promise rejection handler
        window.addEventListener('unhandledrejection', (event) => {
            this.logError('Unhandled Promise Rejection', {
                reason: event.reason,
                stack: event.reason?.stack
            });
        });

        // Add debug panel to page
        this.createDebugPanel();
        
        console.log('Debug mode initialized');
    }

    static logError(type, details) {
        const errorLog = {
            timestamp: new Date().toISOString(),
            type,
            details,
            url: window.location.href,
            userAgent: navigator.userAgent
        };

        console.error(`[DEBUG] ${type}:`, errorLog);

        // Store in localStorage
        const existingLogs = JSON.parse(localStorage.getItem('debug_error_logs') || '[]');
        existingLogs.push(errorLog);

        // Keep only last 100 errors
        if (existingLogs.length > 100) {
            existingLogs.splice(0, existingLogs.length - 100);
        }

        localStorage.setItem('debug_error_logs', JSON.stringify(existingLogs));
    }

    static createDebugPanel() {
        // Only show debug panel if localStorage has debug flag
        if (!localStorage.getItem('debug_mode')) return;

        const panel = document.createElement('div');
        panel.id = 'debug-panel';
        panel.style.cssText = `
            position: fixed;
            top: 10px;
            right: 10px;
            width: 300px;
            background: rgba(0,0,0,0.9);
            color: white;
            padding: 10px;
            border-radius: 5px;
            font-family: monospace;
            font-size: 12px;
            z-index: 10000;
            max-height: 400px;
            overflow-y: auto;
        `;

        panel.innerHTML = `
            <div style="display: flex; justify-content: between; align-items: center; margin-bottom: 10px;">
                <strong>Debug Panel</strong>
                <button onclick="Debug.togglePanel()" style="margin-left: auto; padding: 2px 6px;">Hide</button>
            </div>
            <div id="debug-content">
                <button onclick="Debug.showErrorLogs()">Show Error Logs</button>
                <button onclick="Debug.showAPILogs()">Show API Logs</button>
                <button onclick="Debug.clearAllLogs()">Clear All Logs</button>
                <button onclick="Debug.testError()">Test Error</button>
            </div>
        `;

        document.body.appendChild(panel);
    }

    static togglePanel() {
        const panel = document.getElementById('debug-panel');
        if (panel) {
            panel.style.display = panel.style.display === 'none' ? 'block' : 'none';
        }
    }

    static showErrorLogs() {
        const logs = JSON.parse(localStorage.getItem('debug_error_logs') || '[]');
        console.group('Debug Error Logs');
        logs.forEach((log, i) => {
            console.log(`${i + 1}.`, log);
        });
        console.groupEnd();
        
        const content = document.getElementById('debug-content');
        if (content) {
            content.innerHTML += `<div>Error logs (${logs.length}) logged to console</div>`;
        }
    }

    static showAPILogs() {
        const logs = API.getErrorLogs();
        console.group('API Error Logs');
        logs.forEach((log, i) => {
            console.log(`${i + 1}.`, log);
        });
        console.groupEnd();
        
        const content = document.getElementById('debug-content');
        if (content) {
            content.innerHTML += `<div>API logs (${logs.length}) logged to console</div>`;
        }
    }

    static clearAllLogs() {
        localStorage.removeItem('debug_error_logs');
        API.clearErrorLogs();
        console.log('All logs cleared');
        
        const content = document.getElementById('debug-content');
        if (content) {
            content.innerHTML += `<div>All logs cleared</div>`;
        }
    }

    static testError() {
        throw new Error('This is a test error for debugging');
    }

    static enableDebugMode() {
        localStorage.setItem('debug_mode', 'true');
        location.reload();
    }

    static disableDebugMode() {
        localStorage.removeItem('debug_mode');
        location.reload();
    }
}

// Enable debug mode by default in development
if (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1') {
    localStorage.setItem('debug_mode', 'true');
}

// Initialize debug on page load
document.addEventListener('DOMContentLoaded', () => {
    Debug.init();
});

// Make Debug available globally
window.Debug = Debug;