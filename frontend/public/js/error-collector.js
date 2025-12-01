(function(){
  // Minimal, resilient frontend error collector
  // Ensure absolute backend host (avoid relative hitting 8080 static server)
  const BACKEND_BASE = (window.CONFIG && CONFIG.API_BASE_URL ? CONFIG.API_BASE_URL.replace(/\/api\/?$/, '') : 'http://127.0.0.1:8000');
  const ENDPOINT = BACKEND_BASE + '/log_frontend_error';
  const BATCH_INTERVAL = 3000; // ms
  const MAX_BATCH = 10;
  let queue = [];

  function sendBatch(){
    if (!queue.length) return;
    const payload = queue.slice();
    queue = [];
    try {
      navigator.sendBeacon && typeof navigator.sendBeacon === 'function' && navigator.sendBeacon(ENDPOINT, JSON.stringify({errors: payload})) ||
      fetch(ENDPOINT, { method: 'POST', headers: {'Content-Type': 'application/json'}, body: JSON.stringify({errors: payload}) }).catch(()=>{});
    } catch (e) {
      try { console.warn('ErrorCollector send failed', e); } catch(_){}
    }
  }

  setInterval(sendBatch, BATCH_INTERVAL);

  function enqueue(item){
    try {
      queue.push(Object.assign({timestamp: new Date().toISOString(), userAgent: navigator.userAgent}, item));
      if (queue.length >= MAX_BATCH) sendBatch();
    } catch(e){}
  }

  // Capture console.error
  const origConsoleError = console.error.bind(console);
  console.error = function(...args){
    try { enqueue({type: 'console_error', message: args.map(a=>String(a)).join(' '), raw: args}); } catch(e){}
    origConsoleError(...args);
  };

  // window.onerror
  window.onerror = function(msg, url, lineNo, columnNo, error){
    enqueue({type: 'error', message: msg, url, line: lineNo, column: columnNo, stack: error && error.stack ? error.stack : ''});
    return false;
  };

  // unhandledrejection
  window.addEventListener('unhandledrejection', event => {
    enqueue({type: 'unhandledrejection', message: event.reason && event.reason.toString ? event.reason.toString() : String(event.reason), raw: event.reason});
  });

  // Wrap fetch to detect network failures
  if (window.fetch) {
    const origFetch = window.fetch.bind(window);
    window.fetch = function(...args){
      return origFetch(...args).then(resp => {
        if (!resp.ok) {
          enqueue({type: 'network_http_error', url: resp.url, status: resp.status, statusText: resp.statusText});
        }
        return resp;
      }).catch(err => {
        enqueue({type: 'network_error', url: args && args[0], message: err && err.message});
        throw err;
      });
    };
  }

  // XHR
  (function(){
    const OrigXHR = window.XMLHttpRequest;
    function NewXHR(){
      const xhr = new OrigXHR();
      const origOpen = xhr.open;
      xhr.open = function(method, url){
        this._url = url;
        return origOpen.apply(this, arguments);
      };
      xhr.addEventListener('load', function(){
        if (this.status && this.status >= 400) {
          enqueue({type: 'network_http_error', url: this._url, status: this.status, statusText: this.statusText});
        }
      });
      xhr.addEventListener('error', function(){
        enqueue({type: 'network_error', url: this._url});
      });
      return xhr;
    }
    try { window.XMLHttpRequest = NewXHR; } catch(e){}
  })();

  // Expose manual reporter
  window.reportFrontendError = function(obj){ enqueue(Object.assign({type: 'manual'}, obj)); };

  // Flush before unload
  window.addEventListener('beforeunload', sendBatch);
})();