// Cross-link owner <-> renter dashboards using domain IDs in query params
(function(){
  const CANON = {
    renterid: 'tenantId', renter_id: 'tenantId', tenantid: 'tenantId', tenant_id: 'tenantId',
    ownerid: 'ownerId', owner_id: 'ownerId',
    propertyid: 'propertyId', property_id: 'propertyId',
    unitid: 'unitId', unit_id: 'unitId', flatid: 'unitId', flat_id: 'unitId',
    leaseid: 'leaseId', lease_id: 'leaseId',
    invoiceid: 'invoiceId', invoice_id: 'invoiceId',
    transactionid: 'transactionId', transaction_id: 'transactionId',
    maintenanceid: 'maintenanceId', maintenance_id: 'maintenanceId', requestid: 'maintenanceId',
    utilitymeterid: 'meterId', utility_meter_id: 'meterId', meterid: 'meterId', meter_id: 'meterId'
  };

  function parseParams(){
    const raw = new URLSearchParams(window.location.search);
    const out = {};
    raw.forEach((v, k) => {
      const key = (CANON[k.toLowerCase()] || k).trim();
      if (v != null && v !== '') out[key] = v;
    });
    return out;
  }

  function withParams(base, params){
    const url = new URL(base, window.location.origin);
    Object.entries(params).forEach(([k,v]) => url.searchParams.set(k, v));
    return url.pathname + url.search + url.hash;
  }

  function ensureAnchor(anchor){
    if(!anchor) return;
    const el = document.querySelector(anchor);
    if (el) {
      const offset = 80;
      const top = el.getBoundingClientRect().top + window.pageYOffset - offset;
      window.scrollTo({ top, behavior: 'smooth' });
    }
  }

  function pickOwnerAnchor(p){
    if (p.tenantId) return '#owner-tenant';
    if (p.propertyId || p.unitId) return '#owner-property';
    if (p.meterId) return '#owner-utilities';
    if (p.invoiceId || p.transactionId) return '#owner-payments';
    if (p.maintenanceId) return '#owner-notify';
    return '#owner-dashboard-container';
  }

  function pickRenterAnchor(p){
    if (p.propertyId || p.unitId) return '#renter-property';
    if (p.meterId) return '#renter-utilities';
    if (p.invoiceId || p.transactionId) return '#renter-payments';
    if (p.maintenanceId) return '#renter-maintenance';
    if (p.tenantId) return '#renter-property';
    return '#renter-dashboard-container';
  }

  function bannerList(params){
    const labels = [];
    if (params.tenantId) labels.push(`<span><strong>Renter ID:</strong> <span class="font-monospace">${params.tenantId}</span></span>`);
    if (params.ownerId) labels.push(`<span><strong>Owner ID:</strong> <span class="font-monospace">${params.ownerId}</span></span>`);
    if (params.propertyId) labels.push(`<span><strong>Property ID:</strong> <span class="font-monospace">${params.propertyId}</span></span>`);
    if (params.unitId) labels.push(`<span><strong>Unit ID:</strong> <span class="font-monospace">${params.unitId}</span></span>`);
    if (params.leaseId) labels.push(`<span><strong>Lease ID:</strong> <span class="font-monospace">${params.leaseId}</span></span>`);
    if (params.invoiceId) labels.push(`<span><strong>Invoice ID:</strong> <span class="font-monospace">${params.invoiceId}</span></span>`);
  if (params.transactionId) labels.push(`<span><strong>Transaction ID:</strong> <span class="font-monospace">${params.transactionId}</span></span>`);
  if (params.meterId) labels.push(`<span><strong>Meter ID:</strong> <span class="font-monospace">${params.meterId}</span></span>`);
    if (params.maintenanceId) labels.push(`<span><strong>Maintenance ID:</strong> <span class="font-monospace">${params.maintenanceId}</span></span>`);
    return labels.join(' · ');
  }

  function copyLink(){
    const href = location.href;
    navigator.clipboard?.writeText(href).then(() => {
      // Optional toast could be added here
    });
  }

  document.addEventListener('DOMContentLoaded', function(){
    const params = parseParams();
    const isOwner = /owner\.html$/i.test(location.pathname);
    const isRenter = /renter\.html$/i.test(location.pathname);

    if (isOwner) {
      const header = document.querySelector('#owner-dashboard-container .container > .mb-4');
      if (header && Object.keys(params).length) {
        const info = document.createElement('div');
        info.className = 'alert alert-info d-flex align-items-center justify-content-between flex-wrap gap-2';
        const labels = bannerList(params) || '<em>No IDs in context</em>';
        const toRenter = withParams('renter.html', params) + pickRenterAnchor(params);
        info.innerHTML = `
          <div class="me-2">${labels}</div>
          <div class="d-flex gap-2 ms-auto">
            <a class="btn btn-sm btn-outline-secondary" href="#" data-action="copy-link">Copy link</a>
            <a class="btn btn-sm btn-outline-primary" href="${toRenter}">Open Renter</a>
          </div>`;
        header.insertAdjacentElement('afterend', info);
        ensureAnchor(pickOwnerAnchor(params));
      }

      document.addEventListener('click', function(e){
        const copyBtn = e.target.closest('[data-action="copy-link"]');
        if (copyBtn) { e.preventDefault(); copyLink(); return; }

        const btn = e.target.closest('[data-link="renter"]');
        if(!btn) return;
        e.preventDefault();
        if (!params.tenantId) {
          const rid = prompt('Enter Renter ID to open their dashboard:');
          if (rid) params.tenantId = rid;
          else return;
        }
        const href = withParams('renter.html', params) + pickRenterAnchor(params);
        location.href = href;
      });
    }

    if (isRenter) {
      const header = document.querySelector('#renter-dashboard-container .container > .mb-4');
      if (header && (params.tenantId || Object.keys(params).length)) {
        const info = document.createElement('div');
        info.className = 'alert alert-info d-flex align-items-center justify-content-between flex-wrap gap-2';
        const labels = bannerList(params) || '<em>No IDs in context</em>';
        const toOwner = withParams('owner.html', params) + pickOwnerAnchor(params);
        info.innerHTML = `
          <div class="me-2">${labels}</div>
          <div class="d-flex gap-2 ms-auto">
            <a class="btn btn-sm btn-outline-secondary" href="#" data-action="copy-link">Copy link</a>
            <a class="btn btn-sm btn-outline-primary" href="${toOwner}">Open Owner</a>
          </div>`;
        header.insertAdjacentElement('afterend', info);
        ensureAnchor(pickRenterAnchor(params));
      }

      document.addEventListener('click', function(e){
        const copyBtn = e.target.closest('[data-action="copy-link"]');
        if (copyBtn) { e.preventDefault(); copyLink(); return; }

        const btn = e.target.closest('[data-link="owner"]');
        if(!btn) return;
        e.preventDefault();
        if (!params.tenantId) {
          const rid = prompt('Enter your Renter ID to open Owner dashboard:');
          if (rid) params.tenantId = rid;
          else return;
        }
        const href = withParams('owner.html', params) + pickOwnerAnchor(params);
        location.href = href;
      });
    }
  });
})();
