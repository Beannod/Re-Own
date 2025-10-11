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
