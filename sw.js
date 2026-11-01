/* Service worker: serve a rendere l'app installabile e ad aprirla in fretta.
   Regola di fondo: la pagina viene SEMPRE cercata prima in rete, cosi' dopo un
   push vedi subito la versione nuova; la copia in cache e' solo la rete di
   sicurezza per quando sei senza linea. I dati di Supabase non si toccano. */

var VERSIONE = 'schede-v17';
var GUSCIO = [
  './',
  './index.html',
  './config.js',
  './icon-192.png',
  './logo.png',
  './icon-512.png',
  './manifest.webmanifest'
];

self.addEventListener('install', function (e) {
  e.waitUntil(
    caches.open(VERSIONE)
      .then(function (c) { return c.addAll(GUSCIO); })
      .catch(function () { /* se un file manca, l'installazione non deve fallire */ })
      .then(function () { return self.skipWaiting(); })
  );
});

self.addEventListener('activate', function (e) {
  e.waitUntil(
    caches.keys().then(function (chiavi) {
      return Promise.all(chiavi.map(function (k) {
        if (k !== VERSIONE) return caches.delete(k);
      }));
    }).then(function () { return self.clients.claim(); })
  );
});

self.addEventListener('fetch', function (e) {
  var req = e.request;
  if (req.method !== 'GET') return;

  var url = new URL(req.url);

  /* Supabase e qualunque altra chiamata a un altro dominio che non sia
     una libreria: sempre in rete, mai in cache. */
  var stessaOrigine = url.origin === self.location.origin;
  var libreria = /cdn\.jsdelivr\.net|fonts\.googleapis\.com|fonts\.gstatic\.com/.test(url.host);
  if (!stessaOrigine && !libreria) return;

  /* La pagina: prima la rete, poi la cache. */
  if (req.mode === 'navigate') {
    e.respondWith(
      fetch(req).then(function (r) {
        var copia = r.clone();
        caches.open(VERSIONE).then(function (c) { c.put('./index.html', copia); });
        return r;
      }).catch(function () {
        return caches.match('./index.html').then(function (r) {
          return r || new Response('Non raggiungibile e non in memoria.',
            { status: 503, headers: { 'Content-Type': 'text/plain; charset=utf-8' } });
        });
      })
    );
    return;
  }

  /* Il resto (script, icone, font): prima la cache, e intanto si aggiorna. */
  e.respondWith(
    caches.match(req).then(function (inCache) {
      var dallaRete = fetch(req).then(function (r) {
        if (r && (r.status === 200 || r.type === 'opaque')) {
          var copia = r.clone();
          caches.open(VERSIONE).then(function (c) { c.put(req, copia); });
        }
        return r;
      }).catch(function () { return inCache; });
      return inCache || dallaRete;
    })
  );
});
