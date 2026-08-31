const CACHE_NAME = 'sabeel-v2';
const SHELL = [
  './',
  './Sabeel.html',
  './icon.svg'
];

self.addEventListener('install', e=>{
  e.waitUntil(
    caches.open(CACHE_NAME)
      .then(c=> c.addAll(SHELL))
      .then(()=> self.skipWaiting())
      .catch(()=> self.skipWaiting())
  );
});

self.addEventListener('activate', e=>{
  e.waitUntil(
    caches.keys().then(keys=>
      Promise.all(keys.filter(k=> k!==CACHE_NAME).map(k=> caches.delete(k)))
    ).then(()=> self.clients.claim())
  );
});

self.addEventListener('fetch', e=>{
  const url = new URL(e.request.url);

  if(e.request.method !== 'GET') return;

  /* App shell: cache-first, fallback to network */
  if(url.origin === self.location.origin){
    e.respondWith(
      caches.match(e.request).then(cached=>{
        if(cached) return cached;
        return fetch(e.request).then(resp=>{
          if(resp && resp.status === 200){
            const clone = resp.clone();
            caches.open(CACHE_NAME).then(c=> c.put(e.request, clone));
          }
          return resp;
        }).catch(()=> new Response('Offline', {status: 503, statusText: 'Offline'}));
      })
    );
    return;
  }

  /* CDN audio + API: stale-while-revalidate for speed */
  if(url.hostname.includes('cdn.islamic.network') || url.hostname.includes('everyayah.com') || url.hostname.includes('api.quran.com')){
    e.respondWith(
      caches.match(e.request).then(cached=>{
        const fetched = fetch(e.request).then(resp=>{
          if(resp && resp.status === 200){
            const clone = resp.clone();
            caches.open(CACHE_NAME).then(c=> c.put(e.request, clone));
          }
          return resp;
        }).catch(()=> cached);
        return cached || fetched;
      })
    );
    return;
  }

  /* External audio (hisnmuslim, salafiaudio): cache-first for offline */
  if(url.hostname.includes('hisnmuslim.com') || url.hostname.includes('salafiaudio.files.wordpress.com')){
    e.respondWith(
      caches.match(e.request).then(cached=>{
        if(cached) return cached;
        return fetch(e.request).then(resp=>{
          if(resp && resp.status === 200){
            const clone = resp.clone();
            caches.open(CACHE_NAME).then(c=> c.put(e.request, clone));
          }
          return resp;
        });
      })
    );
    return;
  }

  /* Everything else: network-first */
  e.respondWith(
    fetch(e.request).catch(()=> caches.match(e.request))
  );
});
