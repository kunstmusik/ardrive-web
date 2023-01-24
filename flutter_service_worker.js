'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';
const RESOURCES = {
  "worker.js": "f916974921b8b3d98f9fdfc4b68e5432",
"flutter.js": "f85e6fb278b0fd20c349186fb46ae36d",
"sql-wasm.wasm": "8b3b3fe7c9c611db53b9e43661bf38dd",
"index.html": "293ba1fe4aaf594c2f13ad183e16e1ac",
"/": "293ba1fe4aaf594c2f13ad183e16e1ac",
"sqlite3.wasm": "fbf9815a14460df0b4ee8b746ae9b95b",
"main.dart.js": "3d495d59039d7d7b74636b08b4d0f905",
"manifest.json": "a610c0950a2012e01119d0e8a57e3585",
"ardrive-http.js": "0b50ed9f28bbaaabe4519526b881f902",
"favicon.png": "167c77d2168cfdb31c240d2d3d5e9601",
"icons/Icon-512.png": "92dc660f505d120ed1d92db8ec74943d",
"icons/Icon-192.png": "59fd8ea25636b975179f03f82cc7b19e",
"assets/FontManifest.json": "7b2a36307916a9721811788013e65289",
"assets/NOTICES": "8edc47b31e11d6b00bc36f07900bf20b",
"assets/fonts/MaterialIcons-Regular.otf": "95db9098c58fd6db106f1116bae85a0b",
"assets/shaders/ink_sparkle.frag": "83c076d55fdbf5e6f73f29c79926992c",
"assets/assets/config/prod.json": "3d6c5819f04179660960f51274c830aa",
"assets/assets/config/dev.json": "3d6c5819f04179660960f51274c830aa",
"assets/assets/images/inferno/fire_icon.png": "29087f1ccf20dcb0d824e22af76b357e",
"assets/assets/images/brand/ArDrive-Logo-Wordmark-Dark.png": "1a5609738e95b5ebe84e8165f1ad46c8",
"assets/assets/images/brand/ArDrive-Logo-Wordmark-Light.png": "b11193d644585ac01361cfdce7b6b9cb",
"assets/assets/images/brand/launch_icon.png": "8d40188cdbfdbe3e48686a7eaa8a78de",
"assets/assets/images/profile/profile_new_user_upload.png": "6eb625030efb33a901a7be4531e015da",
"assets/assets/images/profile/profile_new_user_delete.png": "6eb625030efb33a901a7be4531e015da",
"assets/assets/images/profile/profile_new_user_permanent.png": "19cef59765533319b5ab58d665200762",
"assets/assets/images/profile/profile_new_user_private.png": "bb761b58972221c0bb8a330c1be86f3a",
"assets/assets/images/profile/profile_unlock.png": "bb761b58972221c0bb8a330c1be86f3a",
"assets/assets/images/profile/profile_welcome.png": "8ce2b109cbe2aa3155d501be5bc47dba",
"assets/assets/images/profile/profile_add.png": "bb761b58972221c0bb8a330c1be86f3a",
"assets/assets/images/profile/profile_new_user_payment.png": "968d2e6cb2304669cd61d8f614b960a4",
"assets/assets/images/profile/profile_permahills_bg.svg": "b03d4d69db506598a66e3ae1b19b5252",
"assets/assets/images/profile/profile_permahills_bg.png": "b4d8f83b6bd7750a64cb305bcf1dd1a0",
"assets/assets/fonts/Montserrat-Light.ttf": "409c7f79a42e56c785f50ed37535f0be",
"assets/assets/fonts/OpenSans-Regular.ttf": "3ed9575dcc488c3e3a5bd66620bdf5a4",
"assets/assets/fonts/OpenSans-Bold.ttf": "1025a6e0fb0fa86f17f57cc82a6b9756",
"assets/assets/fonts/Montserrat-Regular.ttf": "ee6539921d713482b8ccd4d0d23961bb",
"assets/packages/flutter_dropzone_web/assets/flutter_dropzone.js": "0266ef445553f45f6e45344556cfd6fd",
"assets/AssetManifest.json": "f5033e81ecc8a17dcde4617b104dace3",
"canvaskit/canvaskit.wasm": "bf50631470eb967688cca13ee181af62",
"canvaskit/canvaskit.js": "2bc454a691c631b07a9307ac4ca47797",
"canvaskit/profiling/canvaskit.wasm": "95a45378b69e77af5ed2bc72b2209b94",
"canvaskit/profiling/canvaskit.js": "38164e5a72bdad0faa4ce740c9b8e564",
"js/pst.min.js": "353b22b2121953178e78dfe6bce00b6d",
"js/arconnect.js": "fcf3565603d187e5050b091f013c4d45",
"js/sql-wasm.js": "88a2d15fe24a12bed48ade5c89689065",
"version.json": "52321b5a0487cf8ed9d0820b52074af2"
};

// The application shell files that are downloaded before a service worker can
// start.
const CORE = [
  "main.dart.js",
"index.html",
"assets/AssetManifest.json",
"assets/FontManifest.json"];
// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});

// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});

// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});

self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});

// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}

// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
