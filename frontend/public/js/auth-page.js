// Login/Register page helpers
(function(){
  function showPanel(which){
    const login = document.getElementById('login-panel');
    const register = document.getElementById('register-panel');
    if(!login || !register) return;
    if(which === 'register'){
      login.classList.add('d-none');
      register.classList.remove('d-none');
      window.location.hash = '#register';
    } else {
      register.classList.add('d-none');
      login.classList.remove('d-none');
      window.location.hash = '#login';
    }
  }

  function applyHash(){
    const hash = (window.location.hash || '').replace('#','');
    showPanel(hash === 'register' ? 'register' : 'login');
  }

  document.addEventListener('click', (e) => {
    const t = e.target.closest('.toggle-auth');
    if(!t) return;
    e.preventDefault();
    const which = t.getAttribute('data-switch');
    showPanel(which === 'register' ? 'register' : 'login');
  });

  document.addEventListener('click', (e) => {
    const btn = e.target.closest('.toggle-password');
    if(!btn) return;
    const sel = btn.getAttribute('data-target');
    const input = document.querySelector(sel);
    if(!input) return;
    const isPwd = input.getAttribute('type') === 'password';
    input.setAttribute('type', isPwd ? 'text' : 'password');
    const icon = btn.querySelector('i');
    if(icon){
      icon.classList.toggle('fa-eye');
      icon.classList.toggle('fa-eye-slash');
    }
  });

  window.addEventListener('hashchange', applyHash);
  document.addEventListener('DOMContentLoaded', () => {
    if (typeof Auth !== 'undefined' && Auth.bindEvents) {
      Auth.bindEvents();
    }
    applyHash();
  });
})();