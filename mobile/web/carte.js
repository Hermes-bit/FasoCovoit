// FasoCovoit : carte Google Maps (Maps JavaScript API) au style clair et
// coloré, proche de Plans et de Google Maps, et recherche d'adresses dans la
// base de Google Maps (Places API, nouvelle version).
//
// Appelé depuis Flutter (lib/carte_web.dart). Les résultats sont renvoyés en
// JSON. En cas d'erreur (clé absente, API non activée, réseau), Flutter
// affiche la carte dessinée et la liste de lieux de l'application.
(function () {
  'use strict';

  // Style clair : terrain crème, routes blanches, grands axes jaunes, parcs
  // verts, eau bleue, lieux en couleur.
  const STYLE = [
    { elementType: 'geometry', stylers: [{ color: '#f6f3ee' }] },
    { elementType: 'labels.text.fill', stylers: [{ color: '#4f5864' }] },
    { elementType: 'labels.text.stroke', stylers: [{ color: '#ffffff' }, { weight: 3 }] },
    { featureType: 'administrative', elementType: 'geometry.stroke', stylers: [{ color: '#cfc8bc' }] },
    { featureType: 'administrative.land_parcel', stylers: [{ visibility: 'off' }] },
    { featureType: 'administrative.locality', elementType: 'labels.text.fill', stylers: [{ color: '#2c3440' }] },
    { featureType: 'administrative.neighborhood', elementType: 'labels.text.fill', stylers: [{ color: '#7b8490' }] },
    { featureType: 'landscape.man_made', elementType: 'geometry', stylers: [{ color: '#efebe3' }] },
    { featureType: 'landscape.natural', elementType: 'geometry', stylers: [{ color: '#f3efe5' }] },
    { featureType: 'poi', elementType: 'geometry', stylers: [{ color: '#ece7dd' }] },
    { featureType: 'poi.park', elementType: 'geometry', stylers: [{ color: '#c8e8b6' }] },
    { featureType: 'poi.park', elementType: 'labels.text.fill', stylers: [{ color: '#3b7a35' }] },
    { featureType: 'poi.sports_complex', elementType: 'geometry', stylers: [{ color: '#d3ecc4' }] },
    { featureType: 'poi.medical', elementType: 'geometry', stylers: [{ color: '#fbe1e1' }] },
    { featureType: 'poi.school', elementType: 'geometry', stylers: [{ color: '#f6e9c8' }] },
    { featureType: 'poi.business', elementType: 'labels.text.fill', stylers: [{ color: '#8a6a3a' }] },
    { featureType: 'road', elementType: 'geometry.fill', stylers: [{ color: '#ffffff' }] },
    { featureType: 'road', elementType: 'geometry.stroke', stylers: [{ color: '#e4ddd1' }] },
    { featureType: 'road', elementType: 'labels.text.fill', stylers: [{ color: '#6d7580' }] },
    { featureType: 'road.highway', elementType: 'geometry.fill', stylers: [{ color: '#fde49a' }] },
    { featureType: 'road.highway', elementType: 'geometry.stroke', stylers: [{ color: '#f1c75a' }] },
    { featureType: 'road.highway', elementType: 'labels.text.fill', stylers: [{ color: '#7a5a10' }] },
    { featureType: 'road.arterial', elementType: 'geometry.fill', stylers: [{ color: '#ffffff' }] },
    { featureType: 'road.local', elementType: 'labels.text.fill', stylers: [{ color: '#8b929b' }] },
    { featureType: 'transit.line', elementType: 'geometry', stylers: [{ color: '#d9d4ec' }] },
    { featureType: 'transit.station.airport', elementType: 'geometry', stylers: [{ color: '#e6e3f4' }] },
    { featureType: 'water', elementType: 'geometry', stylers: [{ color: '#9fd3f5' }] },
    { featureType: 'water', elementType: 'labels.text.fill', stylers: [{ color: '#33739f' }] },
  ];

  const ROUTE_BORD = '#1a5fd0';
  const ROUTE = '#3d8bfd';
  const ROUTE_FAITE = '#a9c4f2';
  const VERT = '#0e7a3e';
  const LATERITE = '#b5532a';

  let chargement = null;
  const ecouteursErreur = new Set();

  function charger(cle) {
    if (!cle) return Promise.reject(new Error('Clé Google Maps absente'));
    if (chargement) return chargement;
    chargement = new Promise((resolve, reject) => {
      // Appelé par Google si la clé est refusée (API non activée, site non autorisé…).
      window.gm_authFailure = () => {
        ecouteursErreur.forEach((f) => {
          try { f(); } catch (_) { /* rien */ }
        });
      };
      window.__fasoCarteInit = () => resolve();
      const p = new URLSearchParams({
        key: cle,
        v: 'weekly',
        loading: 'async',
        callback: '__fasoCarteInit',
        language: 'fr',
        region: 'BF',
      });
      const s = document.createElement('script');
      s.src = 'https://maps.googleapis.com/maps/api/js?' + p.toString();
      s.async = true;
      s.onerror = () => {
        chargement = null;
        reject(new Error('Google Maps ne se charge pas'));
      };
      document.head.appendChild(s);
    });
    return chargement;
  }

  // La carte a besoin d'un conteneur affiché et dimensionné.
  function attendreAffichage(div) {
    return new Promise((resolve) => {
      const debut = performance.now();
      (function verifier() {
        if ((div.isConnected && div.offsetWidth > 0 && div.offsetHeight > 0) || performance.now() - debut > 5000) {
          resolve();
        } else {
          requestAnimationFrame(verifier);
        }
      })();
    });
  }

  const latLng = (p) => ({
    lat: typeof p.lat === 'function' ? p.lat() : p.lat,
    lng: typeof p.lng === 'function' ? p.lng() : p.lng,
  });

  // Itinéraire en voiture : Routes (nouvelle API), sinon Directions, sinon
  // ligne droite. Mis en cache pour ne pas refaire la même demande.
  const itineraires = new Map();
  async function itineraire(a, b) {
    const cleCache = [a.lat, a.lng, b.lat, b.lng].map((x) => x.toFixed(5)).join(',');
    if (itineraires.has(cleCache)) return itineraires.get(cleCache);
    let chemin = null;
    try {
      const routes = await google.maps.importLibrary('routes');
      if (routes.Route && typeof routes.Route.computeRoutes === 'function') {
        const r = await routes.Route.computeRoutes({
          origin: a,
          destination: b,
          travelMode: 'DRIVING',
          fields: ['path'],
        });
        const route = r && r.routes && r.routes[0];
        if (route && route.path && route.path.length > 1) chemin = route.path.map(latLng);
      }
      if (!chemin && routes.DirectionsService) {
        const r = await new routes.DirectionsService().route({ origin: a, destination: b, travelMode: 'DRIVING' });
        const route = r && r.routes && r.routes[0];
        if (route && route.overview_path && route.overview_path.length > 1) chemin = route.overview_path.map(latLng);
      }
    } catch (_) {
      chemin = null;
    }
    if (!chemin) chemin = [a, b];
    itineraires.set(cleCache, chemin);
    return chemin;
  }

  // Point où l'on est arrivé après une fraction [t] de la longueur du chemin.
  function couper(chemin, t) {
    const d = (p, q) => Math.hypot(p.lat - q.lat, (p.lng - q.lng) * Math.cos((p.lat * Math.PI) / 180));
    let total = 0;
    for (let i = 1; i < chemin.length; i++) total += d(chemin[i - 1], chemin[i]);
    let reste = total * Math.min(Math.max(t, 0), 1);
    const fait = [chemin[0]];
    for (let i = 1; i < chemin.length; i++) {
      const l = d(chemin[i - 1], chemin[i]);
      if (reste <= l) {
        const k = l === 0 ? 0 : reste / l;
        const p = {
          lat: chemin[i - 1].lat + (chemin[i].lat - chemin[i - 1].lat) * k,
          lng: chemin[i - 1].lng + (chemin[i].lng - chemin[i - 1].lng) * k,
        };
        fait.push(p);
        return { fait, position: p };
      }
      reste -= l;
      fait.push(chemin[i]);
    }
    return { fait, position: chemin[chemin.length - 1] };
  }

  async function afficher(div, cle, optionsJson, surErreur) {
    const o = JSON.parse(optionsJson);
    const erreur = () => {
      try { surErreur(); } catch (_) { /* rien */ }
    };
    ecouteursErreur.add(erreur);
    try {
      await charger(cle);
      await attendreAffichage(div);
      const { Map, Polyline } = await google.maps.importLibrary('maps');
      const { LatLngBounds, SymbolPath } = await google.maps.importLibrary('core');
      const a = { lat: o.depart.lat, lng: o.depart.lng };
      const b = { lat: o.arrivee.lat, lng: o.arrivee.lng };
      const carte = new Map(div, {
        center: { lat: (a.lat + b.lat) / 2, lng: (a.lng + b.lng) / 2 },
        zoom: 12,
        styles: STYLE,
        backgroundColor: '#f6f3ee',
        disableDefaultUI: true,
        zoomControl: !!o.interactif,
        clickableIcons: false,
        keyboardShortcuts: false,
        gestureHandling: o.interactif ? 'greedy' : 'cooperative',
      });
      const chemin = await itineraire(a, b);
      const rond = (couleur, taille) => ({
        path: SymbolPath.CIRCLE,
        scale: taille,
        fillColor: couleur,
        fillOpacity: 1,
        strokeColor: '#ffffff',
        strokeWeight: 3,
      });
      new Polyline({ map: carte, path: chemin, strokeColor: ROUTE_BORD, strokeWeight: 10, strokeOpacity: 1, zIndex: 1 });
      new Polyline({ map: carte, path: chemin, strokeColor: ROUTE, strokeWeight: 6, strokeOpacity: 1, zIndex: 2 });
      if (typeof o.progression === 'number') {
        const { fait, position } = couper(chemin, o.progression);
        new Polyline({ map: carte, path: fait, strokeColor: ROUTE_FAITE, strokeWeight: 6, strokeOpacity: 1, zIndex: 3 });
        // Halo puis point bleu : la voiture.
        new Polyline({
          map: carte, path: [position, position], strokeOpacity: 0, zIndex: 6,
          icons: [{ icon: { path: SymbolPath.CIRCLE, scale: 18, fillColor: ROUTE, fillOpacity: 0.22, strokeOpacity: 0 }, offset: '0%' }],
        });
        new Polyline({
          map: carte, path: [position, position], strokeOpacity: 0, zIndex: 7,
          icons: [{ icon: rond(ROUTE, 8), offset: '0%' }],
        });
      }
      // Départ (vert) et destination (latérite).
      new Polyline({
        map: carte, path: chemin, strokeOpacity: 0, zIndex: 5,
        icons: [
          { icon: rond(VERT, 7), offset: '0%' },
          { icon: rond(LATERITE, 9), offset: '100%' },
        ],
      });
      const limites = new LatLngBounds();
      chemin.forEach((p) => limites.extend(p));
      const m = o.marges || {};
      carte.fitBounds(limites, { top: m.haut || 48, bottom: m.bas || 48, left: 40, right: 40 });
    } catch (e) {
      erreur();
    }
  }

  // Recherche d'adresses : suggestions limitées au Burkina Faso.
  let jeton = null;
  const predictions = new Map();

  async function suggestions(cle, texte) {
    await charger(cle);
    const { AutocompleteSuggestion, AutocompleteSessionToken } = await google.maps.importLibrary('places');
    if (!jeton) jeton = new AutocompleteSessionToken();
    const { suggestions: liste } = await AutocompleteSuggestion.fetchAutocompleteSuggestions({
      input: texte,
      includedRegionCodes: ['bf'],
      language: 'fr',
      region: 'bf',
      sessionToken: jeton,
    });
    const resultat = [];
    for (const s of liste || []) {
      const p = s.placePrediction;
      if (!p) continue;
      predictions.set(p.placeId, p);
      resultat.push({
        id: p.placeId,
        principal: p.mainText ? p.mainText.text : p.text.text,
        secondaire: p.secondaryText ? p.secondaryText.text : '',
      });
      if (resultat.length >= 6) break;
    }
    return JSON.stringify(resultat);
  }

  async function details(cle, id) {
    await charger(cle);
    const { Place } = await google.maps.importLibrary('places');
    const prediction = predictions.get(id);
    const lieu = prediction ? prediction.toPlace() : new Place({ id: id, requestedLanguage: 'fr' });
    await lieu.fetchFields({ fields: ['displayName', 'formattedAddress', 'location', 'addressComponents'] });
    jeton = null; // la session de recherche se termine avec le choix
    const composants = lieu.addressComponents || [];
    const trouver = (...types) => {
      const c = composants.find((x) => types.some((t) => (x.types || []).includes(t)));
      return c ? c.longText : '';
    };
    return JSON.stringify({
      lat: lieu.location ? lieu.location.lat() : null,
      lng: lieu.location ? lieu.location.lng() : null,
      nom: lieu.displayName || '',
      adresse: lieu.formattedAddress || '',
      ville: trouver('locality', 'administrative_area_level_3', 'administrative_area_level_2'),
      quartier: trouver('sublocality_level_1', 'sublocality', 'neighborhood'),
    });
  }

  window.fasoCarte = { afficher, suggestions, details };
})();
