const app = document.querySelector('#app');
const tomorrow = new Date();
tomorrow.setDate(tomorrow.getDate() + 1);
const localDate = date => `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`;
const demoDate = localDate(tomorrow);
const dateLabel = value => new Intl.DateTimeFormat('fr-FR', { weekday: 'short', day: 'numeric', month: 'short' }).format(new Date(`${value}T12:00:00`));
const money = value => `${new Intl.NumberFormat('fr-FR').format(value)} FCFA`;
const esc = value => String(value).replace(/[&<>"']/g, char => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[char]);
const norm = value => value.trim().normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase().replace(/^ouaga$/, 'ouagadougou');
const trips = [
  { id: 1, from: 'Ouagadougou', to: 'Bobo-Dioulasso', departure: '07:00', arrival: '11:30', date: demoDate, seats: 3, price: 5000, driver: 'Ibrahim O.', initials: 'IO', car: 'Toyota Corolla', fromPoint: 'Rond-point de Gounghin', toPoint: 'Place de la Nation', via: 'Boromo', color: '' },
  { id: 2, from: 'Ouagadougou', to: 'Koudougou', departure: '08:15', arrival: '10:00', date: demoDate, seats: 2, price: 2000, driver: 'Fatimata K.', initials: 'FK', car: 'Hyundai Tucson', fromPoint: 'Tampouy', toPoint: 'Centre-ville', via: '', color: 'blue' },
  { id: 3, from: 'Ouagadougou', to: 'Ouahigouya', departure: '14:00', arrival: '17:00', date: demoDate, seats: 1, price: 3500, driver: 'Souleymane B.', initials: 'SB', car: 'Mitsubishi Pajero', fromPoint: "Patte d’Oie", toPoint: 'Centre-ville', via: 'Yako', color: 'purple' }
];
let bookings = [];
let mode = 'intercity';
let selectedTrip = null;
let seats = 1;
let search = { from: '', to: '', date: demoDate, passengers: 1 };

function card(trip) {
  return `<button type="button" class="trip-card" data-trip="${trip.id}" aria-label="Voir le trajet ${esc(trip.from)} vers ${esc(trip.to)}">
    <div class="card-head"><span class="route-label">TRAJET ENTRE VILLES</span><span class="tag">${trip.seats} place${trip.seats > 1 ? 's' : ''}</span></div>
    <div class="route-line">${esc(trip.from === 'Ouagadougou' ? 'Ouaga' : trip.from)} <span>→</span> ${esc(trip.to)}</div>
    <div class="trip-meta">${esc(dateLabel(trip.date))} · ${esc(trip.departure)}${trip.arrival ? ` → ${esc(trip.arrival)}` : ''}</div>
    <div class="divider"></div><div class="card-bottom"><div class="driver"><span class="avatar ${trip.color}">${esc(trip.initials)}</span><span>${esc(trip.driver)}<small>${esc(trip.car)}</small></span></div><div class="price">${money(trip.price)}<small>par place · exemple</small></div></div></button>`;
}

function home() {
  const isCity = mode === 'city';
  app.innerHTML = `<section class="hero"><div class="hero-copy"><div class="eyebrow">LE COVOITURAGE À LA BURKINABÈ</div><h1>La route est plus belle <em>ensemble.</em></h1><p>En ville ou entre les villes, partagez vos trajets et avancez ensemble.</p></div><div class="hero-art" aria-hidden="true"><div class="sun"></div><div class="spark">✳</div><div class="hill"></div><div class="road"></div><div class="car"><i class="wheel one"></i><i class="wheel two"></i></div></div></section>
  <section class="search-panel" aria-label="Rechercher un trajet"><div class="tabs"><button class="tab ${!isCity ? 'active' : ''}" type="button" data-mode="intercity" aria-pressed="${!isCity}">↗ &nbsp; Entre villes</button><button class="tab ${isCity ? 'active' : ''}" type="button" data-mode="city" aria-pressed="${isCity}">⌖ &nbsp; En ville</button></div>
  <form id="search-form" class="search-grid"><div class="field"><label for="from">DÉPART</label><input id="from" name="from" required placeholder="${isCity ? 'Ex. Ouaga 2000' : 'Ex. Ouagadougou'}" value="${esc(isCity ? '' : search.from)}"></div><div class="field"><label for="to">DESTINATION</label><input id="to" name="to" required placeholder="${isCity ? 'Ex. Zogona' : 'Ex. Bobo-Dioulasso'}" value="${esc(isCity ? '' : search.to)}"></div>
  ${isCity ? '' : `<div class="field"><label for="date">DATE</label><input id="date" name="date" type="date" required value="${esc(search.date)}"></div><div class="field"><label for="passengers">PASSAGERS</label><select id="passengers" name="passengers"><option value="1">1 personne</option><option value="2">2 personnes</option><option value="3">3 personnes</option></select></div>`}
  <button class="btn search-btn" type="submit">⌕ &nbsp; ${isCity ? 'Voir l’exemple' : 'Rechercher'}</button></form><p class="hint">${isCity ? 'La course en ville est illustrée uniquement : aucun véhicule ne sera appelé.' : 'Pour essayer : Ouagadougou → Bobo-Dioulasso, à la date proposée.'}</p></section>
  <section class="content-section"><div class="section-top"><div><div class="eyebrow">PRENEZ LA ROUTE</div><h2>Trajets populaires</h2><p>Quelques exemples de destinations au Burkina Faso.</p></div><a class="text-link" href="#resultats" data-show-all>Voir les exemples &nbsp; →</a></div><div class="trip-grid">${trips.slice(0, 3).map(card).join('')}</div>
  <div class="values"><div class="value"><span class="value-icon">↗</span><div><strong>Voyagez ensemble</strong><p>Partagez la route et les frais de trajet.</p></div></div><div class="value"><span class="value-icon">♡</span><div><strong>Une communauté locale</strong><p>Des trajets pensés pour le Burkina Faso.</p></div></div><div class="value"><span class="value-icon">✳</span><div><strong>Simple et accessible</strong><p>Trouvez votre prochain trajet en quelques étapes.</p></div></div></div></section>`;
  if (!isCity) document.querySelector('#passengers').value = String(search.passengers);
}

function results() {
  const matches = trips.filter(t => (!search.from || norm(t.from).includes(norm(search.from))) && (!search.to || norm(t.to).includes(norm(search.to))) && t.date === search.date && t.seats >= search.passengers);
  app.innerHTML = `<div class="page-wrap"><a class="back" href="#accueil">← Modifier ma recherche</a><div class="page-title"><div class="eyebrow">ENTRE VILLES</div><h1>${esc(search.from || 'Tous les départs')} → ${esc(search.to || 'Toutes les destinations')}</h1><p>${esc(dateLabel(search.date))} · ${search.passengers} passager${search.passengers > 1 ? 's' : ''} · Données fictives</p></div><div class="result-summary">${matches.length} trajet${matches.length > 1 ? 's' : ''} disponible${matches.length > 1 ? 's' : ''} dans la maquette</div><div class="results">${matches.length ? matches.map(card).join('') : '<div class="box empty"><h2>Aucun trajet trouvé</h2><p>Essaie une autre destination ou la date proposée sur l’accueil.</p><a class="btn" href="#accueil">Modifier la recherche</a></div>'}</div></div>`;
}

function detail() {
  const trip = trips.find(t => t.id === selectedTrip);
  if (!trip) { location.hash = '#accueil'; return; }
  seats = Math.min(Math.max(1, seats), trip.seats);
  app.innerHTML = `<div class="page-wrap"><a class="back" href="#resultats">← Retour aux trajets</a><div class="page-title"><div class="eyebrow">DÉTAIL DU TRAJET · EXEMPLE</div><h1>${esc(trip.from)} → ${esc(trip.to)}</h1><p>${esc(dateLabel(trip.date))} · ${trip.seats} place${trip.seats > 1 ? 's' : ''} disponible${trip.seats > 1 ? 's' : ''}</p></div><div class="detail-grid"><div><div class="box"><h2>Votre itinéraire</h2><div class="stop"><span class="stop-time">${esc(trip.departure)}</span><span class="stop-dot"></span><span><strong>${esc(trip.from)}</strong><small>${esc(trip.fromPoint)}</small></span></div>${trip.via ? `<div class="stop"><span class="stop-time">—</span><span class="stop-dot"></span><span><strong>${esc(trip.via)}</strong><small>Arrêt en route</small></span></div>` : ''}<div class="stop"><span class="stop-time">${esc(trip.arrival || '—')}</span><span class="stop-dot" style="background:var(--green)"></span><span><strong>${esc(trip.to)}</strong><small>${esc(trip.toPoint)}</small></span></div></div><div class="box"><h2>Votre conducteur</h2><div class="detail-driver"><span class="avatar ${trip.color}">${esc(trip.initials)}</span><div><strong>${esc(trip.driver)}</strong><small>${esc(trip.car)} · Profil fictif</small></div></div></div><div class="notice">Maquette seulement : les identités, prix et trajets sont fictifs. Aucune vérification d’identité n’a été effectuée.</div></div>
  <div><form id="booking-form" class="box"><h2>Réserver une place</h2><div class="seat-control"><strong>Nombre de places</strong><div class="counter"><button type="button" data-seat="-1" aria-label="Retirer une place" ${seats <= 1 ? 'disabled' : ''}>−</button><strong>${seats}</strong><button type="button" data-seat="1" aria-label="Ajouter une place" ${seats >= trip.seats ? 'disabled' : ''}>+</button></div></div><span class="field-label">MOYEN DE PAIEMENT · SIMULATION</span><label class="payment-option"><input type="radio" name="payment" value="Orange Money" checked> Orange Money</label><label class="payment-option"><input type="radio" name="payment" value="Moov Money"> Moov Money</label><label class="payment-option"><input type="radio" name="payment" value="Espèces"> Espèces</label><div class="price-row"><span>Total fictif</span><strong>${money(trip.price * seats)}</strong></div><button class="btn btn-full">Simuler la réservation</button><p class="hint">Aucun paiement ne sera effectué et aucune place réelle ne sera réservée.</p></form></div></div></div>`;
}

function publish() {
  app.innerHTML = `<div class="page-wrap"><a class="back" href="#accueil">← Retour à l’accueil</a><div class="page-title"><div class="eyebrow">ESPACE CONDUCTEUR · DÉMONSTRATION</div><h1>Publier un trajet</h1><p>Proposez des places pour votre prochain voyage.</p></div><form id="publish-form" class="box"><div class="notice">Cette publication est fictive, visible seulement pendant cette session et ne contacte personne.</div><br><div class="form-grid"><div class="form-field"><label for="pub-from">Ville de départ</label><input id="pub-from" name="from" required maxlength="80" placeholder="Ex. Ouagadougou"></div><div class="form-field"><label for="pub-to">Ville d’arrivée</label><input id="pub-to" name="to" required maxlength="80" placeholder="Ex. Ouahigouya"></div><div class="form-field full"><label for="pub-via">Arrêt en route (facultatif)</label><input id="pub-via" name="via" maxlength="80" placeholder="Ex. Yako"></div><div class="form-field"><label for="pub-date">Date</label><input id="pub-date" name="date" type="date" min="${localDate(new Date())}" value="${demoDate}" required></div><div class="form-field"><label for="pub-time">Heure de départ</label><input id="pub-time" name="time" type="time" required></div><div class="form-field"><label for="pub-seats">Places disponibles</label><input id="pub-seats" name="seats" type="number" min="1" max="8" value="3" required></div><div class="form-field"><label for="pub-price">Prix par place (FCFA)</label><input id="pub-price" name="price" type="number" min="1" max="1000000" required placeholder="Ex. 3500"></div></div><div class="checkboxes"><label><input type="checkbox" name="luggage"> Bagages acceptés</label><label><input type="checkbox" name="ac"> Climatisation</label><label><input type="checkbox" name="auto"> Réservation automatique</label></div><div id="form-error" aria-live="polite"></div><button class="btn" type="submit">Publier dans la maquette</button></form></div>`;
}

function myTrips() {
  const published = trips.filter(t => t.own);
  app.innerHTML = `<div class="page-wrap"><a class="back" href="#accueil">← Retour à l’accueil</a><div class="page-title"><div class="eyebrow">VOTRE ESPACE</div><h1>Mes trajets</h1><p>Vos essais disparaissent lorsque vous rechargez la page.</p></div>${bookings.length ? `<div class="box"><h2>Réservations simulées</h2>${bookings.map(b => `<p><strong>${esc(b.from)} → ${esc(b.to)}</strong><br><span class="trip-meta">${esc(dateLabel(b.date))} · ${b.seats} place${b.seats > 1 ? 's' : ''} · ${money(b.total)} · ${esc(b.payment)} (simulation)</span></p>`).join('')}</div>` : ''}${published.length ? `<div class="box"><h2>Trajets publiés dans la maquette</h2><div class="results">${published.map(card).join('')}</div></div>` : ''}${!bookings.length && !published.length ? '<div class="box empty"><h2>Pas encore de trajet</h2><p>Explorez les exemples ou publiez un trajet fictif pour découvrir le parcours.</p><a class="btn" href="#accueil">Découvrir les trajets</a></div>' : ''}</div>`;
}

function cityExample() {
  app.innerHTML = `<div class="page-wrap"><a class="back" href="#accueil">← Retour à l’accueil</a><div class="page-title"><div class="eyebrow">EN VILLE · ILLUSTRATION</div><h1>Une course partagée</h1><p>Exemple de parcours à Ouagadougou, sans recherche ni géolocalisation réelles.</p></div><div class="detail-grid"><div class="box"><div class="city-map" aria-label="Illustration schématique, pas une carte réelle"><div class="map-route"></div><span class="map-label start">Ouaga 2000</span><span class="map-label end">Zogona</span></div><p class="hint">Illustration schématique, pas une carte ni un suivi en direct.</p></div><div class="box"><h2>Exemple de course</h2><div class="detail-driver"><span class="avatar">IO</span><div><strong>Ibrahim O.</strong><small>Toyota Corolla · conducteur fictif</small></div></div><div class="divider"></div><p class="notice">Ce parcours illustre l’idée de partage d’une course. Il ne déclenche aucun appel, message, partage ou SOS.</p><a class="btn btn-outline btn-full" style="display:block;text-align:center;margin-top:16px" href="#accueil">Retour à l’accueil</a></div></div></div>`;
}

function render() {
  const route = location.hash || '#accueil';
  if (route === '#resultats') results();
  else if (route === '#detail') detail();
  else if (route === '#publier') publish();
  else if (route === '#mes-trajets') myTrips();
  else if (route === '#ville') cityExample();
  else home();
  window.scrollTo(0, 0);
}

document.addEventListener('click', event => {
  const modeButton = event.target.closest('[data-mode]');
  const tripButton = event.target.closest('[data-trip]');
  const seatButton = event.target.closest('[data-seat]');
  if (event.target.closest('[data-show-all]')) search = { from: '', to: '', date: demoDate, passengers: 1 };
  if (modeButton) { mode = modeButton.dataset.mode; home(); }
  if (tripButton) { selectedTrip = Number(tripButton.dataset.trip); seats = 1; if (location.hash === '#detail') detail(); else location.hash = '#detail'; }
  if (seatButton && !seatButton.disabled) {
    const payment = document.querySelector('input[name="payment"]:checked').value;
    seats += Number(seatButton.dataset.seat);
    detail();
    document.querySelectorAll('input[name="payment"]').forEach(input => { input.checked = input.value === payment; });
  }
});

document.addEventListener('submit', event => {
  event.preventDefault();
  const form = event.target;
  const data = new FormData(form);
  if (form.id === 'search-form') {
    if (mode === 'city') { location.hash = '#ville'; return; }
    search = { from: data.get('from').trim(), to: data.get('to').trim(), date: data.get('date'), passengers: Number(data.get('passengers')) };
    if (location.hash === '#resultats') results(); else location.hash = '#resultats';
  }
  if (form.id === 'booking-form') {
    const trip = trips.find(t => t.id === selectedTrip);
    bookings.push({ from: trip.from, to: trip.to, date: trip.date, seats, total: trip.price * seats, payment: data.get('payment') });
    location.hash = '#mes-trajets';
  }
  if (form.id === 'publish-form') {
    const from = data.get('from').trim(), to = data.get('to').trim();
    if (!from || !to || norm(from) === norm(to)) { document.querySelector('#form-error').innerHTML = '<div class="error">Saisissez deux villes différentes.</div>'; return; }
    const options = [data.has('luggage') && 'Bagages acceptés', data.has('ac') && 'Climatisation', data.has('auto') && 'Réservation automatique'].filter(Boolean);
    trips.push({ id: Date.now(), from, to, via: data.get('via').trim(), date: data.get('date'), departure: data.get('time'), arrival: '', seats: Number(data.get('seats')), price: Number(data.get('price')), fromPoint: 'À préciser', toPoint: 'À préciser', driver: 'Vous', initials: 'VO', car: options.length ? options.join(' · ') : 'Véhicule à préciser', color: '', own: true });
    location.hash = '#mes-trajets';
  }
});
window.addEventListener('hashchange', render);
render();
