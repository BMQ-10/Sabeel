const CACHE_NAME = 'sabeel-v4';
/* Audio lives in its own cache so app-shell updates (v-bumps) never wipe
   hours of downloaded recitations. Same-origin assets (app shell, segment
   .js files, local audio/ files) use the shell cache — they are re-served
   from disk anyway. */
const AUDIO_CACHE = 'sabeel-audio-v1';
const SHELL = [
  './',
  './Sabeel.html',
  './icon.svg'
];
/* Segment JSONs (~30MB for all reciters) and audio files are NOT pre-cached at
   install — that would punish first visits on mobile data. The fetch handlers
   below cache them on first use, so anything heard once works offline after. */

self.addEventListener('install', e=>{
  e.waitUntil(
    caches.open(CACHE_NAME)
      .then(c=> Promise.all(SHELL.map(u => c.add(u).catch(()=>{ /* optional asset — never block install */ }))))
      .then(()=> self.skipWaiting())
      .catch(()=> self.skipWaiting())
  );
});

self.addEventListener('activate', e=>{
  e.waitUntil(
    caches.keys().then(keys=>
      Promise.all(keys.filter(k=> k!==CACHE_NAME && k!==AUDIO_CACHE).map(k=> caches.delete(k)))
    ).then(()=> self.clients.claim())
  );
});

function isAudioHost(hostname){
  return hostname.includes('cdn.islamic.network')
      || hostname.includes('everyayah.com')
      || hostname.includes('hisnmuslim.com')
      || hostname.includes('salafiaudio.files.wordpress.com')
      || hostname.includes('verses.quran.com');
}

self.addEventListener('fetch', e=>{
  const url = new URL(e.request.url);

  if(e.request.method !== 'GET') return;

  /* Recitation audio (cross-origin CDNs): cache-FIRST in the audio cache.
     Audio files are immutable — a stale revalidation only wastes bandwidth,
     so unlike the API we prefer the cached copy outright. */
  if(isAudioHost(url.hostname)){
    e.respondWith(
      caches.open(AUDIO_CACHE).then(c=>
        c.match(e.request).then(cached=>{
          if(cached) return cached;
          const fetched = fetch(e.request).then(resp=>{
            if(resp && (resp.status === 200 || resp.type === 'opaque')){
              c.put(e.request, resp.clone());
            }
            return resp;
          }).catch(()=> cached);
          return fetched;
        })
      )
    );
    return;
  }

  /* App shell + same-origin (incl. segments/*.js and local ./audio/): cache-first */
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

  /* APIs: stale-while-revalidate for speed */
  if(url.hostname.includes('api.quran.com') || url.hostname.includes('api.alquran.cloud') || url.hostname.includes('geocoding-api.open-meteo.com')){
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

  /* Everything else: network-first */
  e.respondWith(
    fetch(e.request).catch(()=> caches.match(e.request))
  );
});
