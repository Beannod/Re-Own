(function(){
  const nav = document.getElementById('nav');
  function onScroll(){
    if(!nav) return;
    if (window.scrollY > 10) nav.classList.add('scrolled');
    else nav.classList.remove('scrolled');
  }
  window.addEventListener('scroll', onScroll);
  document.addEventListener('DOMContentLoaded', onScroll);

  // Smooth scroll for internal links
  document.addEventListener('click', (e) => {
    const target = e.target.closest('a[href^="#"]');
    if(!target) return;
    const id = target.getAttribute('href').slice(1);
    const el = document.getElementById(id);
    if(el){
      e.preventDefault();
      window.scrollTo({ top: el.offsetTop - 80, behavior: 'smooth' });
    }
  });
})();
