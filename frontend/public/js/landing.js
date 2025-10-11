(function(){
  function checkAuthAndRedirectToLogin() {
    // Check if user is already authenticated and trying to access login
    const token = localStorage.getItem(CONFIG.TOKEN_KEY);
    if (token) {
      // Try to decode token to get role
      const payload = Util.decodeJWT(token);
      if (payload && payload.role) {
        const role = payload.role;
        
        // Show message and redirect based on role
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
        return true;
      } else {
        // Token is invalid, remove it
        localStorage.removeItem(CONFIG.TOKEN_KEY);
      }
    }
    return false;
  }

  function interceptLoginLinks() {
    // Intercept clicks on login/signup buttons for authenticated users
    const loginButtons = document.querySelectorAll('a[href*="login.html"], a[href*="#register"]');
    loginButtons.forEach(button => {
      button.addEventListener('click', (e) => {
        if (checkAuthAndRedirectToLogin()) {
          e.preventDefault();
        }
      });
    });
  }

  // Handle dark mode toggle for landing page
  function handleDarkModeToggle() {
    console.log('Dark mode toggle clicked');
    
    if (typeof toggleDarkMode === 'function') {
      console.log('Using async toggleDarkMode function');
      toggleDarkMode().catch(console.error);
    } else {
      // Fallback for simple dark mode toggle
      console.log('Using fallback dark mode toggle');
      const isDarkMode = document.body.classList.toggle('dark-mode');
      console.log('Dark mode is now:', isDarkMode);
      console.log('Body classes:', document.body.className);
      localStorage.setItem('darkMode', isDarkMode);
      
      // Update all dark mode toggles on the page
      document.querySelectorAll('#darkModeToggle').forEach(toggle => {
        toggle.checked = isDarkMode;
      });
    }
  }

  // Make function globally available
  window.handleDarkModeToggle = handleDarkModeToggle;

  function setText(id, value){
    const el = document.getElementById(id);
    if (el) el.textContent = value;
  }

  function formatCurrency(amount){
    return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(amount || 0);
  }

  function renderCollectionsChart(containerId, data){
    const el = document.getElementById(containerId);
    if(!el) return;
    el.innerHTML = '';

    if(!data || data.length === 0){
      el.innerHTML = '<div class="text-muted">No data available</div>';
      return;
    }

    // Simple bar chart using divs
    const max = Math.max(...data.map(d => d.amount), 1);
    const barWrap = document.createElement('div');
    barWrap.style.display = 'flex';
    barWrap.style.alignItems = 'flex-end';
    barWrap.style.gap = '8px';
    barWrap.style.height = '160px';

    data.forEach(d => {
      const col = document.createElement('div');
      col.style.flex = '1 1 auto';
      col.style.display = 'flex';
      col.style.flexDirection = 'column';
      col.style.alignItems = 'center';

      const bar = document.createElement('div');
      const h = Math.max(8, Math.round((d.amount / max) * 120));
      bar.style.height = h + 'px';
      bar.style.width = '100%';
      bar.style.background = '#0d6efd';
      bar.style.borderRadius = '4px 4px 0 0';

      const label = document.createElement('div');
      label.style.marginTop = '6px';
      label.style.fontSize = '12px';
      label.style.color = '#6c757d';
      label.textContent = d.month;

      col.appendChild(bar);
      col.appendChild(label);
      col.title = `${d.month}: ${formatCurrency(d.amount)}`;
      barWrap.appendChild(col);
    });

    el.appendChild(barWrap);
  }

  function renderRecentProperties(containerId, items){
    const el = document.getElementById(containerId);
    if(!el) return;
    el.innerHTML = '';
    if(!items || items.length === 0){
      el.innerHTML = '<div class="text-muted">No recent properties found</div>';
      return;
    }

    items.forEach(p => {
      const a = document.createElement('a');
      a.className = 'list-group-item list-group-item-action';
      a.href = 'login.html';
      const title = document.createElement('div');
      title.className = 'd-flex w-100 justify-content-between';
      const h6 = document.createElement('h6');
      h6.className = 'mb-1';
      h6.textContent = p.title || 'Untitled property';
      const small = document.createElement('small');
      small.className = 'text-muted';
      small.textContent = p.property_type || '—';
      title.appendChild(h6);
      title.appendChild(small);

      const addr = document.createElement('p');
      addr.className = 'mb-1 text-muted';
      addr.textContent = p.address || '';

      const meta = document.createElement('small');
      const owner = p.owner_name ? ` by ${p.owner_name}` : '';
      const rent = (p.rent_amount != null) ? ` • ${formatCurrency(p.rent_amount)}` : '';
      meta.textContent = (p.status || 'available') + owner + rent;

      a.appendChild(title);
      a.appendChild(addr);
      a.appendChild(meta);
      el.appendChild(a);
    });
  }

  function renderAvailableProperties(containerId, items){
    const el = document.getElementById(containerId);
    if(!el) return;
    el.innerHTML = '';

    if(!items || items.length === 0){
      el.innerHTML = '<div class="col-12 text-muted">No properties are currently available. Please check back later.</div>';
      return;
    }

    items.forEach(p => {
      const col = document.createElement('div');
      col.className = 'col-12 col-sm-6 col-lg-4';

      const card = document.createElement('div');
      card.className = 'card h-100 shadow-sm';

      const img = document.createElement('div');
      img.className = 'ratio ratio-16x9 bg-light';
      img.style.backgroundImage = 'url(assets/placeholder-property.jpg)';
      img.style.backgroundSize = 'cover';
      img.style.backgroundPosition = 'center';

      const body = document.createElement('div');
      body.className = 'card-body';

      const title = document.createElement('h6');
      title.className = 'card-title mb-1';
      title.textContent = p.title || 'Untitled property';

      const meta = document.createElement('div');
      meta.className = 'text-muted small mb-2';
      const parts = [];
      if (p.property_type) parts.push(p.property_type);
      if (p.bedrooms != null) parts.push(`${p.bedrooms} BR`);
      if (p.bathrooms != null) parts.push(`${p.bathrooms} BA`);
      if (p.area != null) parts.push(`${p.area} sqft`);
      meta.textContent = parts.join(' • ');

      const addr = document.createElement('div');
      addr.className = 'small';
      addr.textContent = p.address || '';

      const price = document.createElement('div');
      price.className = 'fw-semibold mt-2';
      price.textContent = (p.rent_amount != null) ? formatCurrency(p.rent_amount) + ' / mo' : '';

      const cta = document.createElement('a');
      cta.href = 'login.html#register';
      cta.className = 'btn btn-sm btn-brand mt-3';
      cta.textContent = 'I’m Interested';

      body.appendChild(title);
      body.appendChild(meta);
      body.appendChild(addr);
      body.appendChild(price);
      body.appendChild(cta);

      card.appendChild(img);
      card.appendChild(body);
      col.appendChild(card);
      el.appendChild(col);
    });
  }

  async function load(){
    try{
      const data = await API.request('/public/summary');
      const st = data.stats || {};
      setText('stat-properties', st.total_properties ?? '-');
      setText('stat-owners', st.active_owners ?? '-');
      setText('stat-renters', st.active_renters ?? '-');
      setText('stat-payments', st.total_payments ?? '-');

      const monthly = data.monthly_collections || [];
      const subtitle = document.getElementById('collections-subtitle');
      if (subtitle && monthly.length){
        subtitle.textContent = `${monthly[0].month} – ${monthly[monthly.length - 1].month}`;
      }
      renderCollectionsChart('collections-chart', monthly);

      renderRecentProperties('recent-properties', data.recent_properties || []);

      // Load available properties in parallel (non-blocking for summary)
      API.request('/public/available?limit=12')
        .then(res => renderAvailableProperties('available-properties', (res && res.items) || []))
        .catch(err => {
          console.warn('Failed to load available properties', err);
          const el = document.getElementById('available-properties');
          if (el) el.innerHTML = '<div class="col-12 text-muted">Unable to load available properties right now.</div>';
        });
    } catch (e) {
      console.error('Failed to load landing summary', e);
      if (window.Swal) {
        Swal.fire({
          icon: 'warning',
          title: 'Live data unavailable',
          text: 'We could not fetch live stats right now. You can still browse and log in.'
        });
      }
    }
  }

  document.addEventListener('DOMContentLoaded', () => {
    // Set up login link interception for authenticated users
    interceptLoginLinks();
    
    // Initialize dark mode
    if (typeof initializeDarkMode === 'function') {
      console.log('Using async initializeDarkMode function');
      initializeDarkMode().catch(console.error);
    } else {
      // Fallback for simple dark mode initialization
      console.log('Using fallback dark mode initialization');
      const savedDarkMode = localStorage.getItem('darkMode') === 'true';
      
      if (savedDarkMode) {
        document.body.classList.add('dark-mode');
      }
      
      // Set the toggle state
      document.querySelectorAll('#darkModeToggle').forEach(toggle => {
        toggle.checked = savedDarkMode;
      });
    }
    
    // Load landing page content
    load();
  });
})();
