window.ErrorUI = {
  show(err, context) {
    try {
      const code = err?.errorCode || err?.body?.error_code || null;
      const status = err?.status;
      const detail = (err?.body && (err.body.detail || err.body.error || err.body.message)) || err?.message || 'Request failed';
      let title = 'Action Failed';
      let text = detail;

      switch (code) {
        case 'EMAIL_NOT_FOUND':
          title = 'Email not found';
          text = 'Please check the email and try again.';
          break;
        case 'INVALID_PASSWORD':
          title = 'Invalid password';
          text = 'Please re-enter your password.';
          break;
        case 'CREATE_USER_FAILED':
          title = 'Could not create user';
          break;
        default:
          // Map by status when no code
          if (status === 400) {
            title = 'Invalid input';
          } else if (status === 401) {
            title = 'Not authorized';
            text = 'Your session may have expired. Please log in again.';
            // auto logout prompt
            if (window.Swal) {
              Swal.fire({
                icon: 'warning',
                title: 'Session expired',
                text: 'Please log in again to continue.',
                confirmButtonText: 'Go to Login'
              }).then(() => {
                try { localStorage.removeItem(CONFIG.TOKEN_KEY); localStorage.removeItem('reown_session_id'); } catch (e) {}
                window.location.href = 'login.html#login';
              });
              return; // already handled
            }
          } else if (status === 404) {
            title = 'Not found';
          } else if (status === 409) {
            title = 'Conflict';
          } else if (status === 422) {
            title = 'Validation error';
          } else if (status >= 500) {
            title = 'Server error';
            text = 'Something went wrong on the server. Please try again later.';
          }
          break;
      }

      // Prefer SweetAlert if available
      if (window.Swal && typeof Swal.fire === 'function') {
        Swal.fire({ icon: 'error', title, text, footer: context ? String(context) : undefined });
      } else {
        alert(`${title}: ${text}`);
      }
    } catch (e) {
      try { console.error('ErrorUI failed to show error:', e, err); } catch (_) {}
      if (window.Swal) Swal.fire({ icon: 'error', title: 'Error', text: err?.message || 'An error occurred' });
    }
  }
};
