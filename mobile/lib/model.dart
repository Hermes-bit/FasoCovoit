import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/widgets.dart';

import 'formats.dart';

/// Erreur de règle métier, affichée telle quelle à l'utilisateur.
class ErreurMetier implements Exception {
  ErreurMetier(this.message);
  final String message;
  @override
  String toString() => message;
}

enum Ton { lat, vert, etoile }

class Personne {
  const Personne(this.prenom, this.nom, {this.ton = Ton.lat, this.femme = false});
  final String prenom;
  final String nom;
  final Ton ton;
  final bool femme;

  String get court => nom.isEmpty ? prenom : '$prenom ${nom[0]}.';
  String get complet => '$prenom $nom'.trim();
  String get initiales => (prenom.isEmpty ? '?' : prenom[0]) + (nom.isEmpty ? '' : nom[0]);
}

class Conducteur extends Personne {
  const Conducteur(
    super.prenom,
    super.nom, {
    super.ton,
    super.femme,
    required this.note,
    required this.trajets,
    required this.voiture,
    required this.couleur,
    required this.plaque,
    this.climatisee = false,
    this.depuis = 2027,
    this.annulations = 0,
  });
  final double note;
  final int trajets;
  final String voiture;
  final String couleur;
  final String plaque;
  final bool climatisee;
  final int depuis;

  /// Trajets annulés par le conducteur.
  final int annulations;

  bool get nouveau => trajets == 0;
  bool get expert => trajets >= 30;
  String get vehicule => '$voiture $couleur';
}

class Lieu {
  const Lieu(this.ville, this.quartier, {this.lat, this.lng, this.rdv});
  final String ville;
  final String quartier;

  /// Coordonnées approximatives (sinon : centre de la ville).
  final double? lat;
  final double? lng;

  /// Point de rendez-vous habituel proposé au conducteur.
  final String? rdv;

  String get complet => '$ville, $quartier';

  (double, double) get position =>
      lat != null && lng != null ? (lat!, lng!) : (centresVilles[ville] ?? (12.3714, -1.5197));

  @override
  bool operator ==(Object other) =>
      other is Lieu && other.ville == ville && other.quartier.toLowerCase() == quartier.toLowerCase();

  @override
  int get hashCode => Object.hash(ville, quartier.toLowerCase());
}

String villeCourte(String ville) => ville == 'Ouagadougou' ? 'Ouaga' : ville;

/// Villes desservies (centre approximatif).
const centresVilles = <String, (double, double)>{
  'Ouagadougou': (12.3714, -1.5197),
  'Koudougou': (12.2526, -2.3627),
  'Bobo-Dioulasso': (11.1771, -4.2979),
};

// Lieux connus (coordonnées approximatives, à remplacer par Google Places).
const lOuagaGare = Lieu('Ouagadougou', 'gare routière', lat: 12.3410, lng: -1.5450, rdv: "Devant l'entrée principale");
const lOuagaCentre = Lieu('Ouagadougou', 'centre-ville', lat: 12.3686, lng: -1.5275, rdv: 'Place des Nations unies');
const lDassasgho = Lieu('Ouagadougou', 'Dassasgho', lat: 12.3780, lng: -1.4820, rdv: 'Rue 29.12, devant la pharmacie');
const lOuaga2000 = Lieu('Ouagadougou', 'Ouaga 2000', lat: 12.3170, lng: -1.4870, rdv: 'Avenue Pascal Zagré');
const lTampouy = Lieu('Ouagadougou', 'Tampouy', lat: 12.4100, lng: -1.5550, rdv: 'Rond-point de Tampouy');
const lZogona = Lieu('Ouagadougou', 'Zogona', lat: 12.3780, lng: -1.5020, rdv: 'Marché de Zogona');
const lPissy = Lieu('Ouagadougou', 'Pissy', lat: 12.3300, lng: -1.5700, rdv: 'Station Total de Pissy');
const lGounghin = Lieu('Ouagadougou', 'Gounghin', lat: 12.3650, lng: -1.5550, rdv: 'Marché de Gounghin');
const lCissin = Lieu('Ouagadougou', 'Cissin', lat: 12.3300, lng: -1.5350, rdv: 'Rond-point de Cissin');
const lPatteOie = Lieu('Ouagadougou', "Patte d'Oie", lat: 12.3360, lng: -1.5050, rdv: "Échangeur de la Patte d'Oie");
const lTanghin = Lieu('Ouagadougou', 'Tanghin', lat: 12.4050, lng: -1.5150, rdv: 'Barrage de Tanghin');
const lUnivOuaga = Lieu(
  'Ouagadougou',
  'Université Joseph Ki-Zerbo',
  lat: 12.3770,
  lng: -1.4990,
  rdv: "Entrée de l'université",
);
const lAeroport = Lieu('Ouagadougou', 'aéroport', lat: 12.3530, lng: -1.5120, rdv: 'Parking des arrivées');
const lKoudCentre = Lieu('Koudougou', 'centre-ville', lat: 12.2526, lng: -2.3627, rdv: 'Devant la mairie');
const lKoudGare = Lieu('Koudougou', 'gare routière', lat: 12.2470, lng: -2.3650, rdv: 'Devant la gare routière');
const lKoudUniv = Lieu(
  'Koudougou',
  'Université Norbert Zongo',
  lat: 12.2650,
  lng: -2.3500,
  rdv: "Entrée de l'université",
);
const lKoudS7 = Lieu('Koudougou', 'Secteur 7', lat: 12.2600, lng: -2.3750, rdv: 'Marché du secteur 7');
const lBoboGare = Lieu('Bobo-Dioulasso', 'gare routière', lat: 11.1700, lng: -4.2900, rdv: 'Devant la gare routière');
const lBoboCentre = Lieu('Bobo-Dioulasso', 'centre-ville', lat: 11.1771, lng: -4.2979, rdv: 'Grand marché');

const lieux = <Lieu>[
  lOuagaGare,
  lOuagaCentre,
  lDassasgho,
  lOuaga2000,
  lTampouy,
  lZogona,
  lPissy,
  lGounghin,
  lCissin,
  lPatteOie,
  lTanghin,
  lUnivOuaga,
  lAeroport,
  lKoudCentre,
  lKoudGare,
  lKoudUniv,
  lKoudS7,
  lBoboGare,
  lBoboCentre,
];

/// Distance à vol d'oiseau, en km.
double distanceKm(Lieu a, Lieu b) {
  final (la1, lo1) = a.position;
  final (la2, lo2) = b.position;
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(la2 - la1);
  final dLng = rad(lo2 - lo1);
  final h = math.pow(math.sin(dLat / 2), 2) + math.cos(rad(la1)) * math.cos(rad(la2)) * math.pow(math.sin(dLng / 2), 2);
  return 2 * 6371 * math.asin(math.sqrt(h));
}

/// Position de [p] le long du segment [a]→[b] : `t` (0 = départ, 1 = arrivée)
/// et distance en km au segment (projection plane, suffisante à cette échelle).
({double t, double km}) projeter(Lieu p, Lieu a, Lieu b) {
  final (la, loa) = a.position;
  final (lb, lob) = b.position;
  final (lp, lop) = p.position;
  final k = math.cos(la * math.pi / 180);
  double x(double lo) => lo * 111.32 * k;
  double y(double lat) => lat * 110.57;
  final ax = x(loa), ay = y(la), bx = x(lob), by = y(lb), px = x(lop), py = y(lp);
  final dx = bx - ax, dy = by - ay;
  final l2 = dx * dx + dy * dy;
  final t = l2 == 0 ? 0.0 : (((px - ax) * dx + (py - ay) * dy) / l2).clamp(0.0, 1.0);
  final cx = ax + t * dx, cy = ay + t * dy;
  return (t: t, km: math.sqrt((px - cx) * (px - cx) + (py - cy) * (py - cy)));
}

/// Croisement entre l'adresse d'un passager et la route d'un conducteur :
/// écarts de montée et de dépose (km), et [fraction] de la route parcourue
/// quand le passager monte (0 = départ du conducteur, 1 = arrivée).
typedef Croisement = ({double monte, double descend, double fraction});

/// Distance de montée (au départ ou le long de la route) et de dépose.
/// Null si c'est trop loin ou dans le mauvais sens.
Croisement? correspondance(Lieu departTrajet, Lieu arriveeTrajet, Lieu depart, Lieu arrivee) {
  // Rayon large seulement si le passager va lui aussi d'une ville à l'autre :
  // pour un trajet en ville, il reste de 3 km, même sur la route d'un
  // conducteur qui sort de la ville.
  final inter = departTrajet.ville != arriveeTrajet.ville && depart.ville != arrivee.ville;
  final rayon = inter ? AppState.rayonInter : AppState.rayonVille;
  final m = projeter(depart, departTrajet, arriveeTrajet);
  final d = projeter(arrivee, departTrajet, arriveeTrajet);
  final auDepart = distanceKm(depart, departTrajet);
  final monte = math.min(auDepart, m.km);
  final descend = math.min(distanceKm(arrivee, arriveeTrajet), d.km);
  if (monte > rayon || descend > rayon) return null;
  if (m.t > d.t + 0.05) return null; // il faut descendre après être monté
  return (monte: monte, descend: descend, fraction: auDepart <= m.km ? 0.0 : m.t);
}

/// Heure à laquelle le conducteur passe prendre le passager, arrondie aux
/// 5 minutes : départ du trajet plus la part de route déjà faite.
DateTime heurePassage(DateTime depart, Duration duree, Croisement c) {
  final h = depart.add(Duration(minutes: (duree.inMinutes * c.fraction).round()));
  return DateTime(h.year, h.month, h.day, h.hour, h.minute - h.minute % 5);
}

/// « sur la route », « à 800 m », « à 2,4 km ».
String ecartTexte(double km) {
  if (km < 0.3) return 'sur la route';
  if (km < 1) return 'à ${(km * 1000 / 100).round() * 100} m';
  return 'à ${km.toStringAsFixed(1).replaceAll('.', ',')} km';
}

/// Un passager qui cherche un trajet : les conducteurs qui passent par là
/// l'acceptent, puis le passager choisit l'un d'eux.
class DemandeTrajet {
  DemandeTrajet({
    required this.id,
    required this.passager,
    required this.depart,
    required this.arrivee,
    required this.quand,
    this.places = 1,
    this.moi = false,
    this.exemple = false,
    this.enfants = 0,
    this.bagages = 0,
    this.poussettes = 0,
    this.autre = '',
    this.paiement = Paiement.especes,
    this.desQuePossible = false,
  });
  final String id;
  final Personne passager;
  final Lieu depart;
  final Lieu arrivee;

  /// Date et heure de départ choisies par le passager.
  final DateTime quand;

  /// Places : une par personne, enfants compris.
  final int places;
  final bool moi;

  /// Démo : passager fictif.
  final bool exemple;

  final int enfants;
  final int bagages;
  final int poussettes;

  /// Autre objet à signaler au conducteur.
  final String autre;
  final Paiement paiement;

  /// « Maintenant » plutôt qu'une heure choisie.
  final bool desQuePossible;

  /// Conducteurs qui ont accepté (le passager en choisit un).
  final List<Offre> offres = [];

  /// Conducteurs contactés jusqu'ici.
  int contactes = 0;
  int conducteursDemo = 0;

  int get adultes => places - enfants;

  /// « Aucun bagage », « 1 bagage, 1 poussette, un sac de mil ».
  String get bagagesTexte {
    final l = [
      if (bagages > 0) pluriel(bagages, 'bagage'),
      if (poussettes > 0) pluriel(poussettes, 'poussette'),
      if (autre.trim().isNotEmpty) autre.trim(),
    ];
    return l.isEmpty ? 'Aucun bagage' : l.join(', ');
  }
}

/// Un conducteur a accepté la demande. Le passager confirme avant [limite].
class Offre {
  Offre({required this.trajet, required this.recueLe, required this.passage, this.minutes});
  final Trajet trajet;
  final DateTime recueLe;

  /// Heure où le conducteur passe prendre le passager à son adresse.
  final DateTime passage;

  /// Départ immédiat : minutes avant l'arrivée du conducteur.
  final int? minutes;

  DateTime get limite => recueLe.add(AppState.delaiOffre);
  int get prix => trajet.prix;
}

/// Une course possible : un passager inscrit attend sur la route d'un trajet
/// publié, à peu près à l'heure où le conducteur y passe.
class CoursePossible {
  const CoursePossible(this.demande, this.trajet, this.croisement, this.passage);
  final DemandeTrajet demande;
  final TrajetPublie trajet;
  final Croisement croisement;

  /// Heure de passage du conducteur à l'adresse du passager.
  final DateTime passage;

  /// Écart avec l'heure choisie par le passager (positif : le conducteur passe après).
  Duration get ecart => passage.difference(demande.quand);

  /// Recalculée à chaque lecture : même passager et même trajet, même course.
  @override
  bool operator ==(Object other) => other is CoursePossible && other.demande == demande && other.trajet == trajet;

  @override
  int get hashCode => Object.hash(demande, trajet);
}

/// « à l'heure », « 20 min après », « 1 h 30 avant ».
String ecartHoraire(Duration d) {
  final m = d.inMinutes.abs();
  if (m < 5) return "à l'heure";
  return '${duree(Duration(minutes: m))} ${d.isNegative ? 'avant' : 'après'}';
}

/// Minuscules sans accents, pour la recherche de lieux.
String normaliser(String s) {
  const avec = 'àâäáãéèêëíìîïóòôöõúùûüçñ';
  const sans = 'aaaaaeeeeiiiiooooouuuucn';
  final b = StringBuffer();
  for (final ch in s.toLowerCase().split('')) {
    final i = avec.indexOf(ch);
    b.write(i >= 0 ? sans[i] : ch);
  }
  return b.toString().trim();
}

// ---------------------------------------------------------------------------
// Tarifs (règles R30 à R41, reprises du simulateur du back-office)
// ---------------------------------------------------------------------------

class Ligne {
  const Ligne({
    required this.id,
    required this.depart,
    required this.arrivee,
    required this.km,
    required this.duree,
    required this.rdv,
    this.interVilles = true,
    this.car = 0,
    this.carVip = 0,
  });
  final String id;
  final Lieu depart;
  final Lieu arrivee;
  final int km;
  final Duration duree;
  final String rdv;
  final bool interVilles;

  /// Prix du car standard et VIP (0 si inconnu), référence entre villes.
  final int car;
  final int carVip;

  String get titre => interVilles
      ? '${villeCourte(depart.ville)} → ${villeCourte(arrivee.ville)}'
      : '${depart.quartier} → ${arrivee.quartier}';

  /// Trajet entre deux lieux quelconques : distance, durée et prix du car
  /// estimés (valeurs connues reprises pour les lignes fréquentes).
  factory Ligne.entre(Lieu a, Lieu b) {
    final inter = a.ville != b.ville;
    Ligne? connue;
    for (final l in lignes) {
      if (inter && l.interVilles && l.depart.ville == a.ville && l.arrivee.ville == b.ville) {
        connue = l;
        break;
      }
    }
    final vol = distanceKm(a, b);
    final km = connue?.km ?? math.max(2, (vol * (inter ? 1.1 : 1.3)).round());
    final minutes = inter ? km / 65 * 60 : math.max(10.0, km / 22 * 60);
    return Ligne(
      id: '${a.ville}/${a.quartier}>${b.ville}/${b.quartier}',
      depart: a,
      arrivee: b,
      km: km,
      duree: connue?.duree ?? Duration(minutes: (minutes / 5).round() * 5),
      rdv: a.rdv ?? 'À préciser avec les passagers',
      interVilles: inter,
      // Prix du car : connu sur les lignes relevées ; sinon 0 et la règle R39 s'applique.
      car: !inter ? 0 : (connue?.car ?? 0),
      carVip: connue?.carVip ?? 0,
    );
  }
}

enum Vehicule {
  berlineEssence('Berline essence', 8, false),
  berlineDiesel('Berline diesel', 8, true),
  citadineEssence('Citadine essence', 6.5, false),
  citadineDiesel('Citadine diesel', 6.5, true);

  const Vehicule(this.label, this.conso, this.diesel);
  final String label;
  final double conso;
  final bool diesel;
}

class ReglagesTarifs {
  const ReglagesTarifs({this.prixSuper = 850, this.prixGasoil = 750, this.usure = 30, this.villeMin = 400});
  final int prixSuper;
  final int prixGasoil;
  final int usure;
  final int villeMin;
}

class Tarif {
  const Tarif({
    required this.plancher,
    required this.conseille,
    required this.plafond,
    required this.pas,
    required this.fraisTrajet,
    required this.limiteFrais,
  });
  final int plancher;
  final int conseille;
  final int plafond;
  final int pas;
  final int fraisTrajet;
  final int limiteFrais;

  int borner(int prix) {
    final p = (prix / pas).round() * pas;
    return p.clamp(plancher, plafond);
  }
}

/// Plancher, prix conseillé et plafond par place pour une ligne.
Tarif calculerTarif(
  Ligne ligne, {
  Vehicule vehicule = Vehicule.berlineEssence,
  ReglagesTarifs reglages = const ReglagesTarifs(),
}) {
  final carburant = vehicule.diesel ? reglages.prixGasoil : reglages.prixSuper;
  final conso = vehicule.conso - (vehicule.diesel ? 1 : 0);
  final parKm = conso / 100 * carburant * (1 + reglages.usure / 100);
  final frais = parKm * ligne.km;
  final pas = ligne.interVilles ? 100 : 50;
  int r(double x) => (x / pas).round() * pas;
  final limite = r(frais * 1.3 / 4);
  int conseille, plafond, plancher;
  if (!ligne.interVilles) {
    conseille = r(frais / 4) < reglages.villeMin ? reglages.villeMin : r(frais / 4);
    final p = r(conseille * 1.3);
    plafond = p < 700 ? 700 : p;
    plancher = 200;
  } else if (ligne.car <= 0) {
    // R39 : pas de tarif de car connu → même calcul qu'en ville, sans minimum.
    conseille = r(frais / 4);
    plafond = r(conseille * 1.3);
    plancher = r(conseille * 0.5);
  } else {
    conseille = r(ligne.car * 0.9);
    plafond = ligne.carVip > 0 ? ligne.carVip : r(ligne.car * 1.25);
    plancher = r(ligne.car * 0.5);
    if (plafond > limite) plafond = limite;
    if (conseille > plafond) conseille = plafond;
  }
  return Tarif(
    plancher: plancher,
    conseille: conseille,
    plafond: plafond,
    pas: pas,
    fraisTrajet: frais.round(),
    limiteFrais: limite,
  );
}

const lignes = <Ligne>[
  Ligne(
    id: 'ouaga-koudougou',
    depart: lOuagaGare,
    arrivee: lKoudCentre,
    km: 98,
    duree: Duration(minutes: 90),
    rdv: "Devant l'entrée principale",
    car: 2000,
  ),
  Ligne(
    id: 'koudougou-ouaga',
    depart: lKoudGare,
    arrivee: lOuagaGare,
    km: 98,
    duree: Duration(minutes: 90),
    rdv: 'Devant la gare routière',
    car: 2000,
  ),
  Ligne(
    id: 'ouaga-bobo',
    depart: lOuagaGare,
    arrivee: lBoboCentre,
    km: 360,
    duree: Duration(hours: 5),
    rdv: "Devant l'entrée principale",
    car: 7000,
    carVip: 9000,
  ),
  Ligne(
    id: 'dassasgho-ouaga2000',
    depart: lDassasgho,
    arrivee: lOuaga2000,
    km: 9,
    duree: Duration(minutes: 25),
    rdv: 'Rue 29.12, devant la pharmacie',
    interVilles: false,
  ),
  Ligne(
    id: 'tampouy-zogona',
    depart: lTampouy,
    arrivee: lZogona,
    km: 8,
    duree: Duration(minutes: 25),
    rdv: 'Rond-point de Tampouy',
    interVilles: false,
  ),
];

Ligne ligneParId(String id) => lignes.firstWhere((l) => l.id == id);

// ---------------------------------------------------------------------------
// Trajets et réservations côté passager
// ---------------------------------------------------------------------------

class Trajet {
  Trajet({
    required this.id,
    required this.conducteur,
    required this.depart,
    required this.arrivee,
    required this.rdv,
    required this.heureDepart,
    required this.duree,
    required this.km,
    required this.prix,
    required this.places,
    this.placesPrises = 0,
    this.entreFemmes = false,
    this.interVilles = true,
  });
  final String id;
  final Conducteur conducteur;
  final Lieu depart;
  final Lieu arrivee;
  final String rdv;
  final DateTime heureDepart;
  final Duration duree;
  final int km;
  final int prix;
  final int places;
  int placesPrises;
  final bool entreFemmes;
  final bool interVilles;

  int get placesLibres => places - placesPrises;
  DateTime get heureArrivee => heureDepart.add(duree);
  String get titre => interVilles
      ? '${villeCourte(depart.ville)} → ${villeCourte(arrivee.ville)}'
      : '${depart.quartier} → ${arrivee.quartier}';
  String get titreLong =>
      interVilles ? '${depart.ville} → ${arrivee.ville}' : '${depart.quartier} → ${arrivee.quartier}';
}

enum Paiement {
  portefeuille('Mon portefeuille', 'FC'),
  orange('Orange Money', 'OM'),
  moov('Moov Money', 'MM'),
  especes('Espèces', 'F');

  const Paiement(this.label, this.logo);
  final String label;
  final String logo;
  bool get mobile => this == orange || this == moov;
  bool get enLigne => this != especes;
}

enum StatutResa { enAttente, confirmee, enCours, terminee, annulee, expiree }

class Reservation {
  Reservation({
    required this.ref,
    required this.trajet,
    required this.places,
    required this.paiement,
    required this.montant,
    required this.code,
    required this.creeLe,
    this.bonusUtilise = 0,
    this.statut = StatutResa.enAttente,
    this.notee = false,
    this.montee,
    this.descente,
  });
  final String ref;
  final Trajet trajet;

  /// Adresses du passager (montée et dépose), si différentes du trajet.
  final Lieu? montee;
  final Lieu? descente;
  final int places;
  final Paiement paiement;
  final int montant;
  final int bonusUtilise;
  final String code;
  final DateTime creeLe;
  StatutResa statut;
  bool notee;
  bool annuleeParConducteur = false;
  int rembourse = 0;
  DateTime? annuleeLe;

  static const delaiReponse = Duration(minutes: 30);
  DateTime get limiteReponse => creeLe.add(delaiReponse);
  bool get aVenir => statut == StatutResa.enAttente || statut == StatutResa.confirmee || statut == StatutResa.enCours;
}

/// Pourcentage remboursé selon les règles B7 / C3.
int tauxRemboursement({
  required bool interVilles,
  required Duration avantDepart,
  bool parConducteur = false,
  bool enAttente = false,
  bool conducteurArrive = false,
}) {
  if (parConducteur || enAttente) return 100;
  if (!interVilles) return conducteurArrive ? 0 : 100;
  if (avantDepart > const Duration(hours: 24)) return 100;
  if (avantDepart >= const Duration(hours: 2)) return 50;
  return 0;
}

// ---------------------------------------------------------------------------
// Portefeuille
// ---------------------------------------------------------------------------

enum TypeOp { depot, trajet, remboursement, bonus, retrait }

enum StatutOp { confirme, enAttente, bloque, reclamation }

class Operation {
  Operation({
    required this.type,
    required this.titre,
    required this.detail,
    required this.montant,
    required this.date,
    this.ref,
    this.statut = StatutOp.confirme,
  });
  final TypeOp type;
  final String titre;
  String detail;
  final int montant;
  final DateTime date;
  final String? ref;
  StatutOp statut;
}

class Reclamation {
  Reclamation({required this.numero, required this.operation, required this.date, this.commentaire = ''});
  final String numero;
  final Operation operation;
  final DateTime date;
  String commentaire;
}

// ---------------------------------------------------------------------------
// Messages et notifications
// ---------------------------------------------------------------------------

class Message {
  Message(this.texte, this.date, {this.moi = false});
  final String texte;
  final DateTime date;
  final bool moi;
}

class Conversation {
  Conversation({
    required this.id,
    required this.avec,
    required this.contexte,
    required this.messages,
    this.nonLus = 0,
    this.verifie = false,
    this.equipe = false,
  });
  final String id;
  final Personne avec;
  final String contexte;
  final List<Message> messages;
  int nonLus;
  final bool verifie;
  final bool equipe;
}

enum TypeNotif { acceptee, rappel, arrive, annulee, rembourse, info }

class Notif {
  Notif(this.type, this.titre, this.texte, this.date, {this.lue = false});
  final TypeNotif type;
  final String titre;
  final String texte;
  final DateTime date;
  bool lue;
}

// ---------------------------------------------------------------------------
// Espace conducteur
// ---------------------------------------------------------------------------

enum EtapeConducteur { aucune, documentsEnvoyes, valide, actif }

enum Formule {
  mensuel('Mensuel', 5000, 1, 'par mois', 'Pour essayer'),
  trimestriel('Trimestriel', 12000, 3, 'pour 3 mois', 'Soit 4 000 F par mois : 3 000 F économisés'),
  annuel('Annuel', 42000, 12, 'pour 12 mois', 'Soit 3 500 F par mois : 18 000 F économisés');

  const Formule(this.nom, this.prix, this.mois, this.duree, this.economie);
  final String nom;
  final int prix;
  final int mois;
  final String duree;
  final String economie;
}

DateTime ajouterMois(DateTime d, int mois) => DateTime(d.year, d.month + mois, d.day, d.hour, d.minute);

class Abonnement {
  Abonnement({required this.formule, required this.debut, required this.offertJusquau, required this.prochainPaiement});
  Formule formule;
  final DateTime debut;
  final DateTime offertJusquau;
  DateTime prochainPaiement;
  Formule? formuleSuivante;
  bool arrete = false;
  final List<String> recus = [];
}

enum StatutDemande { attente, acceptee, refusee }

class Passager {
  Passager({
    required this.personne,
    required this.places,
    required this.paiement,
    required this.code,
    required this.recueLe,
    required this.prixPlace,
    this.statut = StatutDemande.attente,
    this.note = 4.7,
    this.trajets = 9,
    this.montee,
    this.descente,
  });
  final Personne personne;

  /// Où le passager monte et descend : le conducteur choisit en fonction.
  final Lieu? montee;
  final Lieu? descente;
  final int places;
  final Paiement paiement;
  final String code;
  final DateTime recueLe;
  final int prixPlace;
  final double note;
  final int trajets;
  StatutDemande statut;
  bool aBord = false;
  bool absent = false;
  int get montant => places * prixPlace;
}

enum StatutPublie { publie, enCours, termine, annule }

class TrajetPublie {
  TrajetPublie({
    required this.id,
    required this.ligne,
    required this.depart,
    required this.places,
    required this.prix,
    required this.rdv,
    this.accepteAuto = false,
    this.regulier = false,
    this.jours = const {},
    this.entreFemmes = false,
    this.especes = true,
    this.mobile = true,
  });
  final String id;
  final Ligne ligne;
  final DateTime depart;
  final int places;
  final int prix;
  final String rdv;
  final bool accepteAuto;
  final bool regulier;
  final Set<int> jours;
  final bool entreFemmes;
  final bool especes;
  final bool mobile;
  final List<Passager> passagers = [];
  StatutPublie statut = StatutPublie.publie;
  bool exemple = false;

  List<Passager> get confirmes => passagers.where((p) => p.statut == StatutDemande.acceptee).toList();
  List<Passager> get enAttente => passagers.where((p) => p.statut == StatutDemande.attente).toList();
  int get reservees => confirmes.fold(0, (t, p) => t + p.places);
  bool get toutLeMondeABord => confirmes.any((p) => p.aBord) && confirmes.every((p) => p.aBord || p.absent);
  int get aBord => confirmes.where((p) => p.aBord).length;
}

class GainTrajet {
  GainTrajet({
    required this.titre,
    required this.date,
    required this.passagers,
    required this.mobile,
    required this.especes,
  });
  final String titre;
  final DateTime date;
  final int passagers;
  final int mobile;
  final int especes;
  int get total => mobile + especes;
}

/// Documents du conducteur, photographiés avec l'appareil photo de
/// l'application (pas d'import depuis la galerie).
const documentsConducteur = <String, String>{
  'CNIB': 'Recto et verso',
  'Selfie avec la CNIB': 'Votre visage et la carte, sur la même photo',
  'Permis de conduire': 'Délivré il y a 2 ans au moins',
  'Carte grise': 'Au nom du conducteur ou du propriétaire',
  'Assurance': 'Attestation en cours de validité',
  'Photo du véhicule': 'Plaque bien lisible',
};

/// Documents pris avec la caméra avant.
const selfiesDocuments = {'Selfie avec la CNIB'};

/// Ce que disent les documents, saisi par le conducteur : l'application
/// contrôle les règles, l'équipe compare avec les photos et les originaux.
class DossierConducteur {
  DateTime? naissance;
  String cnibNumero = '';
  DateTime? cnibExpire;
  String permisNumero = '';
  DateTime? permisDelivre;
  String plaque = '';

  /// Marque et modèle (« Toyota Corolla »).
  String vehicule = '';

  /// Couleur de la voiture (« grise »), choisie dans « Ma voiture ».
  String couleurVoiture = '';
  String assureur = '';
  String police = '';
  String plaqueAssurance = '';
  DateTime? assuranceFin;

  void vider() {
    naissance = cnibExpire = permisDelivre = assuranceFin = null;
    cnibNumero = permisNumero = plaque = vehicule = couleurVoiture = assureur = police = plaqueAssurance = '';
  }

  /// « Toyota Corolla grise ».
  String get voiture => '$vehicule $couleurVoiture'.trim();
}

/// Couleurs de voiture proposées dans « Ma voiture ».
const couleursVoiture = <String, int>{
  'rouge': 0xFFD7322B,
  'jaune': 0xFFF2C230,
  'verte': 0xFF4CB86E,
  'bleue': 0xFF2F6FE0,
  'marron': 0xFF6B3F25,
  'grise': 0xFF9EA3A8,
  'blanche': 0xFFF4F4F1,
  'noire': 0xFF22201F,
};

/// Résultat d'un contrôle automatique du dossier.
class Controle {
  const Controle(this.libelle, this.ok, [this.detail]);
  final String libelle;
  final bool ok;
  final String? detail;
}

/// « 11 hh-2345 » → « 11HH2345 ».
String normaliserPlaque(String p) => p.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');

/// Format habituel des plaques burkinabè : « 11 HH 2345 ».
bool plaqueValide(String p) => RegExp(r'^\d{2}[A-Z]{1,2}\d{4}$').hasMatch(normaliserPlaque(p));

/// Âge révolu à une date (ou ancienneté d'un permis).
int anneesEntre(DateTime debut, DateTime date) {
  var a = date.year - debut.year;
  if (date.month < debut.month || (date.month == debut.month && date.day < debut.day)) a--;
  return a;
}

/// Liste de vérification de l'équipe, à cocher pour chaque conducteur avant
/// de valider son compte (futur back-office).
const verificationEquipe = <(String, List<String>)>[
  (
    'Identité',
    [
      'CNIB nette, recto et verso, sans trace de retouche',
      'Nom de la CNIB identique à celui du compte',
      'Visage du selfie identique à la photo de la CNIB',
      'Numéro, date de naissance et validité saisis conformes à la CNIB',
    ],
  ),
  ('Permis', ['Nom du permis identique à celui de la CNIB', 'Catégorie B et date de délivrance conformes à la saisie']),
  (
    'Véhicule',
    [
      'Plaque de la carte grise identique à celle de la photo du véhicule',
      'Modèle et couleur de la photo conformes à la carte grise',
    ],
  ),
  (
    'Assurance',
    [
      'Attestation pour cette plaque, dates conformes à la saisie',
      "Validité confirmée par l'assureur (appel avec le numéro de police)",
    ],
  ),
  (
    'Entretien',
    [
      'Originaux vus en personne : CNIB, permis, carte grise, assurance',
      'Véhicule vu : plaque, modèle et couleur conformes',
      'Charte du conducteur expliquée et acceptée',
    ],
  ),
];

/// Motifs de refus proposés à l'équipe.
const motifsRefus = [
  'Photo illisible',
  'Nom différent selon les documents',
  'Visage différent de la CNIB',
  'Plaque différente',
  'Assurance non valable',
  'Originaux non présentés',
];

// ---------------------------------------------------------------------------
// État de l'application (démonstration en mémoire)
// ---------------------------------------------------------------------------

enum Mode { passager, conducteur }

// Conducteurs de démonstration (entre villes et en ville).
const _issouf = Conducteur(
  'Issouf',
  'Kaboré',
  ton: Ton.vert,
  note: 4.9,
  trajets: 37,
  voiture: 'Toyota Corolla',
  couleur: 'grise',
  plaque: '11 HH 2345',
  climatisee: true,
);
const _ousmane = Conducteur(
  'Ousmane',
  'Bationo',
  ton: Ton.etoile,
  note: 4.6,
  trajets: 21,
  voiture: 'Kia Picanto',
  couleur: 'bleue',
  plaque: '11 HB 7721',
  depuis: 2026,
);
const _aminata = Conducteur(
  'Aminata',
  'Sawadogo',
  femme: true,
  note: 4.8,
  trajets: 12,
  voiture: 'Suzuki Swift',
  couleur: 'rouge',
  plaque: '11 KA 2290',
);
const _boukary = Conducteur(
  'Boukary',
  'Ouédraogo',
  ton: Ton.etoile,
  note: 0,
  trajets: 0,
  voiture: 'Peugeot 406',
  couleur: 'grise',
  plaque: '11 GK 8812',
);
const _salif = Conducteur(
  'Salif',
  'Tiendrébéogo',
  note: 3.9,
  trajets: 27,
  voiture: 'Hyundai Accent',
  couleur: 'blanche',
  plaque: '11 FA 3390',
  annulations: 2,
);

class AppState extends ChangeNotifier {
  AppState({DateTime Function()? horloge, math.Random? alea})
    : _horloge = horloge ?? DateTime.now,
      _alea = alea ?? math.Random() {
    _semer();
  }

  final DateTime Function() _horloge;
  final math.Random _alea;
  DateTime get maintenant => _horloge();
  Timer? _minuterie;

  // Compte
  bool connecte = false;
  Mode mode = Mode.passager;

  /// À l'entrée, l'utilisateur choisit son espace : passager ou conducteur.
  /// Être passager n'est pas obligatoire pour utiliser l'application.
  bool espaceAChoisir = false;

  /// Onglet affiché dans la navigation du bas (passager ou conducteur).
  int onglet = 0;
  void allerOnglet(int i) {
    onglet = i;
    _changer();
  }

  String telephone = '70 00 00 00';
  String prenom = 'Hermès';
  String nom = 'Barry';
  bool femme = false;

  /// Photo de profil (prise ou importée), gardée en mémoire.
  Uint8List? photo;
  String urgenceNom = 'Mariam Traoré';
  String urgenceTel = '+226 76 45 21 09';
  String urgenceLien = 'Maman';
  double notePassager = 4.7;
  int trajetsPassager = 9;

  Personne get moi => Personne(prenom, nom, femme: femme);
  bool get aUrgence => urgenceNom.trim().isNotEmpty;

  /// « Maman », sinon le prénom du contact d'urgence.
  String get urgenceCourt =>
      urgenceLien.isNotEmpty ? urgenceLien : (aUrgence ? urgenceNom.trim().split(' ').first : '');

  // --------------------------------------------------- comptes et code SMS

  /// Compte de démonstration déjà existant (historique, portefeuille…).
  static const numeroDemo = '70000000';
  static const dureeCode = Duration(minutes: 10); // T1
  static const essaisMax = 5;
  static const attenteApresEchecs = Duration(minutes: 15); // T2

  /// Numéros bloqués après 5 codes faux, jusqu'à l'heure indiquée.
  final Map<String, DateTime> _bloqueJusqua = {};

  /// Numéros qui ont un compte. Démo : en mémoire, pour cette session.
  final Set<String> _comptes = {numeroDemo};
  String _compteCharge = numeroDemo;
  String? _codeSms;
  String? _telSms;
  DateTime? _expireSms;
  int _essaisSms = 0;

  static String chiffres(String tel) => tel.replaceAll(RegExp(r'\D'), '');
  static String formaterTel(String c) => [for (var i = 0; i + 2 <= c.length; i += 2) c.substring(i, i + 2)].join(' ');

  bool compteExiste(String tel) => _comptes.contains(chiffres(tel));

  /// Dernier code « envoyé » par SMS. Tant qu'aucun fournisseur SMS n'est
  /// branché, l'application l'affiche comme un SMS reçu.
  String? get dernierCodeSms => _codeSms;
  DateTime? get expirationCode => _expireSms;

  String envoyerCode(String tel) {
    final c = chiffres(tel);
    if (c.length != 8) throw ErreurMetier('Saisissez les 8 chiffres de votre numéro.');
    final bloque = _bloqueJusqua[c];
    if (bloque != null && maintenant.isBefore(bloque)) {
      throw ErreurMetier("Trop d'essais : demandez un nouveau code à partir de ${heure(bloque)}.");
    }
    _telSms = c;
    _codeSms = (100000 + _alea.nextInt(900000)).toString();
    _expireSms = maintenant.add(dureeCode);
    _essaisSms = 0;
    _changer();
    return _codeSms!;
  }

  /// Vérifie le code reçu. Retourne vrai si le numéro avait déjà un compte :
  /// la session s'ouvre alors directement. Sinon, un compte vierge est créé
  /// et l'inscription continue (profil, contact d'urgence).
  bool verifierCode(String code) {
    final tel = _telSms;
    if (_codeSms == null || tel == null) throw ErreurMetier("Demandez d'abord un code.");
    if (maintenant.isAfter(_expireSms!)) {
      throw ErreurMetier('Ce code a expiré : demandez-en un nouveau.');
    }
    if (_essaisSms >= essaisMax) {
      throw ErreurMetier("Trop d'essais : demandez un nouveau code.");
    }
    if (code.trim() != _codeSms) {
      _essaisSms++;
      final reste = essaisMax - _essaisSms;
      if (reste <= 0) {
        final fin = maintenant.add(attenteApresEchecs);
        _bloqueJusqua[tel] = fin;
        _codeSms = null;
        throw ErreurMetier("Trop d'essais : demandez un nouveau code à partir de ${heure(fin)}.");
      }
      throw ErreurMetier('Code incorrect. Encore ${pluriel(reste, 'essai')}.');
    }
    _codeSms = null;
    _telSms = null;
    final existe = _comptes.contains(tel);
    if (existe) {
      if (tel != _compteCharge) _reinitialiser(tel);
      connecte = true;
      espaceAChoisir = true;
      mode = Mode.passager;
      onglet = 0;
    } else {
      _comptes.add(tel);
      _reinitialiser(tel);
    }
    _changer();
    return existe;
  }

  /// Charge les données du compte : historique complet pour le compte de
  /// démonstration, compte vierge pour un nouveau numéro.
  void _reinitialiser(String tel) {
    trajets.clear();
    reservations.clear();
    operations.clear();
    reclamations.clear();
    conversations.clear();
    notifications.clear();
    documentsEnvoyes.clear();
    trajetsPublies.clear();
    gains.clear();
    operationsConducteur.clear();
    etapeConducteur = EtapeConducteur.aucune;
    abonnement = null;
    gainsDisponibles = 0;
    annulationsConducteur = 0;
    suspenduJusquau = null;
    trajetsConducteur = 0;
    _exempleAjoute = false;
    _coursesIgnorees.clear();
    _demandesEcartees.clear();
    enLigneUniquement = false;
    sourdine = false;
    introConducteurVue = false;
    _compteur = 0;
    _nResa = 0;
    mode = Mode.passager;
    onglet = 0;
    _compteCharge = tel;
    telephone = formaterTel(tel);
    final demo = tel == numeroDemo;
    photo = null;
    photosDocuments.clear();
    _photosImportees.clear();
    lieuxRecents.clear();
    lieuxFavoris.clear();
    dossier.vider();
    verificationsFaites.clear();
    motifRefus = null;
    valideLe = null;
    if (demo) {
      prenom = 'Hermès';
      nom = 'Barry';
      femme = false;
      urgenceNom = 'Mariam Traoré';
      urgenceTel = '+226 76 45 21 09';
      urgenceLien = 'Maman';
      notePassager = 4.7;
      trajetsPassager = 9;
      parrainage = (invites: 3, voyage: 1, gagne: 500);
    } else {
      prenom = '';
      nom = '';
      femme = false;
      urgenceNom = '';
      urgenceTel = '';
      urgenceLien = '';
      notePassager = 0;
      trajetsPassager = 0;
      parrainage = (invites: 0, voyage: 0, gagne: 0);
    }
    _semer(historique: demo);
  }

  String get codeParrainage {
    final base = prenom
        .toUpperCase()
        .replaceAll(RegExp('[ÀÂÄ]'), 'A')
        .replaceAll(RegExp('[ÉÈÊË]'), 'E')
        .replaceAll(RegExp('[ÎÏ]'), 'I')
        .replaceAll(RegExp('[ÔÖ]'), 'O')
        .replaceAll(RegExp('[ÛÜÙ]'), 'U')
        .replaceAll(RegExp('[^A-Z]'), '');
    return '${base.isEmpty ? 'FASO' : base.substring(0, base.length < 3 ? base.length : 3)}-25';
  }

  // Données
  final List<Trajet> trajets = [];
  final List<Reservation> reservations = [];
  final List<Operation> operations = [];
  final List<Reclamation> reclamations = [];
  final List<Conversation> conversations = [];
  final List<Notif> notifications = [];
  int depose = 0;
  int bonus = 0;
  late DateTime bonusExpire;
  static const soldeMax = 100000;
  static const partBonus = 50; // % d'une place payable en bonus
  ({int invites, int voyage, int gagne}) parrainage = (invites: 3, voyage: 1, gagne: 500);

  // Conducteur
  EtapeConducteur etapeConducteur = EtapeConducteur.aucune;
  final Set<String> documentsEnvoyes = {};
  Abonnement? abonnement;
  final List<TrajetPublie> trajetsPublies = [];
  final List<GainTrajet> gains = [];
  final List<Operation> operationsConducteur = [];
  int gainsDisponibles = 0;
  int annulationsConducteur = 0;
  DateTime? suspenduJusquau;
  double noteConducteur = 0;
  int trajetsConducteur = 0;
  bool _exempleAjoute = false;

  int _compteur = 0;

  int get solde => depose + bonus;
  int get bloque => operations.where((o) => o.statut == StatutOp.bloque).fold(0, (t, o) => t - o.montant);
  int get notificationsNonLues => notifications.where((n) => !n.lue).length;
  int get messagesNonLus => conversations.fold(0, (t, c) => t + c.nonLus);
  bool get estConducteur => etapeConducteur == EtapeConducteur.actif;

  List<Reservation> get aVenir =>
      reservations.where((r) => r.aVenir).toList()
        ..sort((a, b) => a.trajet.heureDepart.compareTo(b.trajet.heureDepart));
  List<Reservation> get passees =>
      reservations.where((r) => !r.aVenir).toList()
        ..sort((a, b) => b.trajet.heureDepart.compareTo(a.trajet.heureDepart));

  void _changer() => notifyListeners();

  /// Fait expirer les demandes sans réponse (à appeler périodiquement).
  void demarrerHorloge() {
    _minuterie ??= Timer.periodic(const Duration(seconds: 20), (_) => verifierDelais());
  }

  void verifierDelais() {
    var change = false;
    for (final r in reservations) {
      if (r.statut == StatutResa.enAttente && maintenant.isAfter(r.limiteReponse)) {
        _rembourser(r, 100);
        r.statut = StatutResa.expiree;
        _notifier(
          TypeNotif.annulee,
          'Demande sans réponse',
          '${r.trajet.conducteur.court} n\'a pas répondu à temps : la demande est annulée.',
        );
        change = true;
      }
    }
    if (change) _changer();
  }

  @override
  void dispose() {
    _minuterie?.cancel();
    super.dispose();
  }

  // ------------------------------------------------------------------ compte

  /// Ouvre la session. Avec [choisirEspace], l'utilisateur choisit d'abord
  /// s'il entre comme passager ou comme conducteur.
  void connecter({bool choisirEspace = false}) {
    connecte = true;
    espaceAChoisir = choisirEspace;
    mode = Mode.passager;
    onglet = 0;
    _changer();
  }

  void deconnecter() {
    connecte = false;
    espaceAChoisir = false;
    mode = Mode.passager;
    _changer();
  }

  /// Choix fait à l'entrée. Le conducteur dont le compte n'est pas encore
  /// actif arrive dans son espace, où il finit son inscription.
  void choisirEspace(Mode m) {
    mode = m;
    onglet = 0;
    espaceAChoisir = false;
    _changer();
  }

  /// Supprime le compte connecté. Le compte de démonstration, lui, est
  /// simplement remis dans son état de départ.
  void supprimerCompte() {
    if (_compteCharge != numeroDemo) _comptes.remove(_compteCharge);
    _reinitialiser(numeroDemo);
    connecte = false;
    _changer();
  }

  void majProfil({String? prenom, String? nom, bool? femme}) {
    if (prenom != null && prenom.trim().isNotEmpty) this.prenom = prenom.trim();
    if (nom != null) this.nom = nom.trim();
    if (femme != null) this.femme = femme;
    _changer();
  }

  /// Nouvelle photo de profil, ou null pour la retirer.
  void majPhoto(Uint8List? octets) {
    photo = octets == null || octets.isEmpty ? null : octets;
    _changer();
  }

  void majUrgence(String nom, String tel, String lien) {
    urgenceNom = nom.trim();
    urgenceTel = tel.trim();
    urgenceLien = lien;
    _changer();
  }

  /// Passe d'un espace à l'autre. L'espace conducteur est ouvert même avant
  /// l'activation du compte : il guide alors vers l'inscription.
  void basculerMode(Mode m, {int onglet = 0}) {
    mode = m;
    this.onglet = onglet;
    _changer();
  }

  // --------------------------------------------------------------- recherche

  /// Écart maximal (km) entre l'adresse du passager et le trajet du conducteur.
  static const rayonVille = 3.0;
  static const rayonInter = 8.0;

  /// Passagers qui cherchent un trajet (les leurs et ceux des autres).
  final List<DemandeTrajet> demandesTrajet = [];

  /// Écart toléré entre l'heure choisie par le passager et le passage du
  /// conducteur à son adresse.
  static const fenetreVille = Duration(minutes: 30);
  static const fenetreInter = Duration(hours: 1);
  static Duration fenetre(bool interVilles) => interVilles ? fenetreInter : fenetreVille;

  /// Croisement entre une offre et l'adresse du passager.
  Croisement? correspondancePour(Trajet t, Lieu depart, Lieu arrivee) =>
      correspondance(t.depart, t.arrivee, depart, arrivee);

  /// Heure à laquelle le conducteur de [t] passe à l'adresse [depart].
  DateTime passagePour(Trajet t, Lieu depart, Lieu arrivee) {
    final c = correspondancePour(t, depart, arrivee);
    return c == null ? t.heureDepart : heurePassage(t.heureDepart, t.duree, c);
  }

  /// Temps laissé au passager pour confirmer un conducteur qui a accepté.
  static const delaiOffre = Duration(minutes: 15);

  /// Le passager envoie sa demande : les conducteurs qui passent par là sont
  /// contactés. [quand] nul : départ dès que possible.
  DemandeTrajet demanderTrajet({
    required Lieu depart,
    required Lieu arrivee,
    DateTime? quand,
    int adultes = 1,
    int enfants = 0,
    int bagages = 0,
    int poussettes = 0,
    String autre = '',
    Paiement paiement = Paiement.especes,
  }) {
    if (depart == arrivee) throw ErreurMetier('Le départ et la destination doivent être différents.');
    if (adultes < 1) throw ErreurMetier('Au moins un adulte voyage.');
    if (adultes + enfants > 4) throw ErreurMetier('4 places au plus par demande.');
    if (quand != null && quand.isBefore(maintenant.subtract(const Duration(minutes: 5)))) {
      throw ErreurMetier('Choisissez une date et une heure à venir.');
    }
    final d = DemandeTrajet(
      id: 'D${demandesTrajet.length + 1}-${maintenant.millisecondsSinceEpoch % 100000}',
      passager: moi,
      depart: depart,
      arrivee: arrivee,
      quand: quand ?? maintenant,
      desQuePossible: quand == null,
      places: adultes + enfants,
      enfants: enfants,
      bagages: bagages,
      poussettes: poussettes,
      autre: autre.trim(),
      paiement: paiement,
      moi: true,
    );
    demandesTrajet.add(d);
    retenirLieu(depart);
    retenirLieu(arrivee);
    _changer();
    return d;
  }

  void retirerDemande(DemandeTrajet d) {
    demandesTrajet.remove(d);
    _changer();
  }

  /// Offres encore valables d'une demande du passager.
  List<Offre> offresValables(DemandeTrajet d) => d.offres.where((o) => !maintenant.isAfter(o.limite)).toList();

  /// Démo : un conducteur de plus répond. D'abord les conducteurs dont un
  /// trajet publié passe chez le passager, puis des conducteurs inscrits
  /// alertés qui viennent le prendre à son adresse, à son heure.
  Offre? recevoirOffre(DemandeTrajet d) {
    if (!demandesTrajet.contains(d) || d.offres.length >= 4) return null;
    d.contactes += 2 + d.offres.length % 2;
    final dejaLa = {for (final o in d.offres) o.trajet.conducteur.complet};
    Offre? offre;
    for (final t in rechercher(depart: d.depart, arrivee: d.arrivee, quand: d.quand, places: d.places)) {
      if (dejaLa.contains(t.conducteur.complet)) continue;
      offre = Offre(trajet: t, recueLe: maintenant, passage: passagePour(t, d.depart, d.arrivee));
      break;
    }
    if (offre == null && d.conducteursDemo < 2) {
      final inter = d.depart.ville != d.arrivee.ville;
      final candidats = [
        ...inter ? const [_issouf, _boukary] : const [_ousmane, _salif],
        if (femme) _aminata,
      ].where((c) => !dejaLa.contains(c.complet));
      if (candidats.isNotEmpty) {
        final c = candidats.first;
        final minutes = d.desQuePossible ? const [6, 11, 14][d.conducteursDemo] : null;
        final ligne = Ligne.entre(d.depart, d.arrivee);
        final h = d.desQuePossible ? maintenant.add(Duration(minutes: minutes!)) : d.quand;
        final trajet = Trajet(
          id: 'o${d.id}-${d.conducteursDemo}',
          conducteur: c,
          depart: d.depart,
          arrivee: d.arrivee,
          rdv: d.depart.rdv ?? 'À votre adresse',
          heureDepart: DateTime(h.year, h.month, h.day, h.hour, h.minute),
          duree: ligne.duree,
          km: ligne.km,
          prix: calculerTarif(ligne).conseille,
          places: math.max(3, d.places),
          interVilles: inter,
        );
        d.conducteursDemo++;
        offre = Offre(trajet: trajet, recueLe: maintenant, passage: trajet.heureDepart, minutes: minutes);
      }
    }
    if (offre != null) d.offres.add(offre);
    _changer();
    return offre;
  }

  /// Le passager choisit un conducteur : la place est réservée et confirmée
  /// (le conducteur a déjà accepté), payée comme indiqué dans la demande.
  Reservation accepterOffre(DemandeTrajet d, Offre o, {bool utiliserBonus = true}) {
    if (!demandesTrajet.contains(d)) throw ErreurMetier("Cette demande n'est plus active.");
    if (maintenant.isAfter(o.limite)) {
      throw ErreurMetier('Cette acceptation a expiré : choisissez un autre conducteur.');
    }
    final r = reserver(
      o.trajet,
      places: d.places,
      paiement: d.paiement,
      utiliserBonus: utiliserBonus,
      montee: d.depart,
      descente: d.arrivee,
    );
    if (!trajets.contains(o.trajet)) trajets.add(o.trajet);
    demandesTrajet.remove(d);
    simulerAcceptation(r);
    return r;
  }

  // Lieux récents et favoris du passager (« Votre itinéraire »).
  final List<Lieu> lieuxRecents = [];
  final Set<Lieu> lieuxFavoris = {};

  void retenirLieu(Lieu l) {
    lieuxRecents
      ..remove(l)
      ..insert(0, l);
    if (lieuxRecents.length > 8) lieuxRecents.removeLast();
  }

  void basculerFavori(Lieu l) {
    lieuxFavoris.contains(l) ? lieuxFavoris.remove(l) : lieuxFavoris.add(l);
    _changer();
  }

  /// Courses que le conducteur a écartées (« trajet/demande »).
  final Set<String> _coursesIgnorees = {};

  /// Le trajet [t] peut-il prendre le passager de [d] ? Il faut qu'il passe
  /// près de son adresse, dans le bon sens, à peu près à l'heure choisie.
  CoursePossible? coursePour(DemandeTrajet d, TrajetPublie t) {
    if (d.moi) return null;
    if (t.statut != StatutPublie.publie && t.statut != StatutPublie.enCours) return null;
    if (t.places - t.reservees < d.places) return null;
    if (t.entreFemmes && !d.passager.femme) return null;
    if (t.passagers.any((p) => p.personne.complet == d.passager.complet)) return null;
    final c = correspondance(t.ligne.depart, t.ligne.arrivee, d.depart, d.arrivee);
    if (c == null) return null;
    final passage = heurePassage(t.depart, t.ligne.duree, c);
    if (passage.difference(d.quand).abs() > fenetre(t.ligne.interVilles)) return null;
    return CoursePossible(d, t, c, passage);
  }

  /// Alertes du conducteur : les passagers inscrits qui attendent sur la
  /// route d'un de ses trajets, vers l'heure où il y passe (une par passager).
  List<CoursePossible> get coursesPossibles {
    final resultat = <CoursePossible>[];
    for (final d in demandesTrajet.where((d) => !d.moi)) {
      CoursePossible? meilleure;
      var score = double.infinity;
      for (final t in trajetsPublies) {
        if (_coursesIgnorees.contains('${t.id}/${d.id}')) continue;
        final c = coursePour(d, t);
        if (c == null) continue;
        final s = c.ecart.inMinutes.abs() + 5 * (c.croisement.monte + c.croisement.descend);
        if (s < score) {
          score = s;
          meilleure = c;
        }
      }
      if (meilleure != null) resultat.add(meilleure);
    }
    return resultat..sort((a, b) => a.passage.compareTo(b.passage));
  }

  List<CoursePossible> coursesPour(TrajetPublie t) => coursesPossibles.where((c) => c.trajet == t).toList();

  /// Tous les passagers inscrits qui cherchent un trajet et qu'aucun trajet
  /// du conducteur ne croise : il peut accepter leur course en la publiant.
  List<DemandeTrajet> get passagersSansCourse {
    final avecCourse = {for (final c in coursesPossibles) c.demande};
    return demandesTrajet.where((d) => !d.moi && !avecCourse.contains(d) && !_demandesEcartees.contains(d.id)).toList()
      ..sort((a, b) => a.quand.compareTo(b.quand));
  }

  /// Demandes de passagers que le conducteur a écartées de sa liste.
  final Set<String> _demandesEcartees = {};

  void ignorerCourse(CoursePossible c) {
    _coursesIgnorees.add('${c.trajet.id}/${c.demande.id}');
    _changer();
  }

  /// Le conducteur écarte la demande d'un passager qu'aucun de ses trajets ne croise.
  void ecarterDemande(DemandeTrajet d) {
    _demandesEcartees.add(d.id);
    _changer();
  }

  /// « Tout effacer » : écarte les courses possibles et les autres demandes.
  /// Les réservations sur ses trajets, elles, attendent une réponse.
  void toutEffacer() {
    for (final c in coursesPossibles) {
      _coursesIgnorees.add('${c.trajet.id}/${c.demande.id}');
    }
    for (final d in demandesTrajet.where((d) => !d.moi)) {
      _demandesEcartees.add(d.id);
    }
    _changer();
  }

  // Réglages du conducteur.
  /// N'afficher que les demandes payées en ligne (portefeuille, Orange, Moov).
  bool enLigneUniquement = false;

  /// Pas de notification de nouvelle demande.
  bool sourdine = false;

  void majReglages({bool? enLigne, bool? silence}) {
    if (enLigne != null) enLigneUniquement = enLigne;
    if (silence != null) sourdine = silence;
    _changer();
  }

  /// La fiche « Mode conducteur » s'affiche une fois, à la première entrée.
  bool introConducteurVue = false;

  void vuIntroConducteur() => introConducteurVue = true;

  /// Taux d'annulation du conducteur (%), null tant qu'il n'a pas roulé.
  int? get tauxAnnulation {
    final total = trajetsConducteur + annulationsConducteur;
    return trajetsConducteur == 0 ? null : annulationsConducteur * 100 ~/ total;
  }

  /// « Ma voiture » : marque et modèle, couleur, plaque.
  void majVoiture({required String vehicule, required String couleur, required String plaque}) {
    if (vehicule.trim().isEmpty) throw ErreurMetier('Indiquez la marque et le modèle.');
    if (!plaqueValide(plaque)) throw ErreurMetier('Plaque au format habituel : 11 HH 2345.');
    dossier
      ..vehicule = vehicule.trim()
      ..couleurVoiture = couleur
      ..plaque = plaque.trim().toUpperCase();
    _changer();
  }

  /// Le conducteur prend la course sur un trajet qui passe par là.
  void prendreCourse(CoursePossible c) {
    if (coursePour(c.demande, c.trajet) == null) {
      throw ErreurMetier("Ce trajet ne passe plus par l'adresse de ${c.demande.passager.court} à son heure.");
    }
    proposerPlace(c.demande, c.trajet);
  }

  /// Le conducteur propose une place : démo, le passager accepte aussitôt.
  void proposerPlace(DemandeTrajet d, TrajetPublie t) {
    if (!estConducteur) throw ErreurMetier('Activez votre compte conducteur pour accepter des courses.');
    if (!demandesTrajet.contains(d)) throw ErreurMetier("Ce passager n'attend plus.");
    if (t.places - t.reservees < d.places) throw ErreurMetier('Plus assez de places libres sur ce trajet.');
    t.passagers.add(
      Passager(
        personne: d.passager,
        places: d.places,
        paiement: Paiement.especes,
        code: ((1000 + demandesTrajet.length * 7919 + t.passagers.length * 613) % 9000 + 1000).toString(),
        recueLe: maintenant,
        prixPlace: t.prix,
        statut: StatutDemande.acceptee,
        montee: d.depart,
        descente: d.arrivee,
      ),
    );
    demandesTrajet.remove(d);
    _changer();
  }

  /// Un passager pris en route monte à bord.
  void monterEnChemin(TrajetPublie t, Passager p) {
    p.aBord = true;
    _changer();
  }

  /// Trajets disponibles. Avec [depart] et [arrivee] : croisement avec
  /// l'adresse du passager. Avec [quand] : le conducteur passe ce jour-là,
  /// pas avant l'heure choisie (moins la tolérance). Sans [quand] : dès
  /// maintenant.
  List<Trajet> rechercher({
    bool? interVilles,
    Lieu? depart,
    Lieu? arrivee,
    DateTime? quand,
    int places = 1,
    bool conductrices = false,
    bool matin = false,
  }) {
    final inter = depart != null && arrivee != null ? depart.ville != arrivee.ville : (interVilles ?? true);
    return trajets.where((t) {
      if (t.interVilles != inter) return false;
      // Croisement avec l'adresse du passager : montée au départ ou sur la
      // route, dépose près de son adresse, dans le bon sens.
      final c = depart != null && arrivee != null ? correspondancePour(t, depart, arrivee) : null;
      if (depart != null && arrivee != null && c == null) return false;
      if (quand != null) {
        final passage = c == null ? t.heureDepart : heurePassage(t.heureDepart, t.duree, c);
        if (ecartJours(passage, quand) != 0) return false;
        if (passage.isBefore(quand.subtract(fenetre(t.interVilles)))) return false;
      }
      if (!t.heureDepart.isAfter(maintenant)) return false;
      if (t.placesLibres < places) return false;
      if (t.entreFemmes && !femme) return false;
      if (conductrices && !t.conducteur.femme) return false;
      if (matin && t.heureDepart.hour >= 12) return false;
      return true;
    }).toList()..sort((a, b) => a.heureDepart.compareTo(b.heureDepart));
  }

  // ------------------------------------------------------------- réservation

  int bonusUtilisable(int total) {
    final max = total * partBonus ~/ 100;
    return bonus < max ? bonus : max;
  }

  Reservation reserver(
    Trajet trajet, {
    required int places,
    required Paiement paiement,
    bool utiliserBonus = true,
    Lieu? montee,
    Lieu? descente,
  }) {
    if (trajet.placesLibres <= 0) throw ErreurMetier('Trajet complet.'); // T5
    if (places < 1 || places > trajet.placesLibres) {
      throw ErreurMetier("Il ne reste que ${pluriel(trajet.placesLibres, 'place')} sur ce trajet.");
    }
    if (reservations.any((r) => r.trajet == trajet && r.aVenir)) {
      throw ErreurMetier('Vous avez déjà une réservation sur ce trajet.');
    }
    final total = places * trajet.prix;
    var bonusPris = 0;
    if (paiement == Paiement.portefeuille) {
      bonusPris = utiliserBonus ? bonusUtilisable(total) : 0;
      if (depose < total - bonusPris) {
        throw ErreurMetier(
          'Solde insuffisant : il manque ${fcfa(total - bonusPris - depose)}. Déposez de l\'argent ou choisissez un autre moyen.',
        );
      }
      bonus -= bonusPris;
      depose -= total - bonusPris;
    }
    final resa = Reservation(
      ref: _ref(),
      trajet: trajet,
      places: places,
      paiement: paiement,
      montant: total,
      bonusUtilise: bonusPris,
      code: _code(),
      creeLe: maintenant,
      montee: montee,
      descente: descente,
    );
    if (paiement == Paiement.portefeuille) {
      operations.insert(
        0,
        Operation(
          type: TypeOp.trajet,
          titre: 'Trajet ${trajet.titre}',
          detail: bonusPris > 0
              ? 'Bloqué jusqu\'à la fin du trajet · dont ${fcfa(bonusPris)} de bonus'
              : 'Bloqué jusqu\'à la fin du trajet',
          montant: -total,
          date: maintenant,
          ref: resa.ref,
          statut: StatutOp.bloque,
        ),
      );
    }
    trajet.placesPrises += places;
    reservations.add(resa);
    _changer();
    return resa;
  }

  /// Démo : simule l'acceptation par le conducteur.
  void simulerAcceptation(Reservation r) {
    if (r.statut != StatutResa.enAttente) return;
    r.statut = StatutResa.confirmee;
    final c = r.trajet.conducteur;
    _notifier(
      TypeNotif.acceptee,
      'Demande acceptée',
      '${c.court} a accepté votre demande pour ${jourRelatif(r.trajet.heureDepart, maintenant).toLowerCase()} ${heureCourte(r.trajet.heureDepart)}.',
    );
    _conversationAvec(
      c,
      r.trajet,
      messages: [
        'Bonsoir $prenom, c\'est bien noté pour ${jourRelatif(r.trajet.heureDepart, maintenant).toLowerCase()} ${heureCourte(r.trajet.heureDepart)}.',
        'Je serai ${r.trajet.rdv.toLowerCase()}.',
      ],
    );
    _changer();
  }

  int tauxPour(Reservation r) => tauxRemboursement(
    interVilles: r.trajet.interVilles,
    avantDepart: r.trajet.heureDepart.difference(maintenant),
    enAttente: r.statut == StatutResa.enAttente,
  );

  /// Annule et rembourse selon les règles. Retourne le montant remboursé.
  int annulerReservation(Reservation r) {
    if (!r.aVenir || r.statut == StatutResa.enCours) {
      throw ErreurMetier('Cette réservation ne peut plus être annulée.');
    }
    final taux = tauxPour(r);
    final rembourse = _rembourser(r, taux);
    r.statut = StatutResa.annulee;
    r.annuleeLe = maintenant;
    _changer();
    return rembourse;
  }

  int _rembourser(Reservation r, int taux) {
    r.trajet.placesPrises -= r.places;
    final montant = r.paiement == Paiement.especes ? 0 : r.montant * taux ~/ 100;
    r.rembourse = montant;
    if (r.paiement == Paiement.portefeuille) {
      final retourBonus = r.bonusUtilise * taux ~/ 100;
      bonus += retourBonus;
      depose += montant - retourBonus;
      for (final o in operations) {
        if (o.ref == r.ref && o.statut == StatutOp.bloque) {
          o.statut = StatutOp.confirme;
          o.detail = 'Réservation annulée';
        }
      }
      if (montant > 0) {
        operations.insert(
          0,
          Operation(
            type: TypeOp.remboursement,
            titre: 'Remboursement · $taux %',
            detail: 'Trajet ${r.trajet.titre}',
            montant: montant,
            date: maintenant,
            ref: r.ref,
          ),
        );
      }
    }
    return montant;
  }

  void demarrerSuivi(Reservation r) {
    if (r.statut == StatutResa.confirmee) {
      r.statut = StatutResa.enCours;
      _changer();
    }
  }

  void arriver(Reservation r) {
    if (r.statut == StatutResa.terminee) return; // déjà arrivé
    r.statut = StatutResa.terminee;
    for (final o in operations) {
      if (o.ref == r.ref && o.statut == StatutOp.bloque) {
        o.statut = StatutOp.confirme;
        o.detail = 'Payé au conducteur à l\'arrivée';
      }
    }
    trajetsPassager += 1;
    _changer();
  }

  void noter(Reservation r, int note) {
    if (note < 1 || note > 5) throw ErreurMetier('Choisissez une note de 1 à 5.');
    r.notee = true;
    _changer();
  }

  // ---------------------------------------------------------- portefeuille

  String deposer(int montant, Paiement operateur) {
    if (!operateur.mobile) throw ErreurMetier('Choisissez Orange Money ou Moov Money.');
    if (montant < 500) throw ErreurMetier('Dépôt minimum : 500 F.');
    if (montant > 50000) throw ErreurMetier('Dépôt maximum : 50 000 F par dépôt.'); // R43
    if (solde + montant > soldeMax) {
      throw ErreurMetier('Solde maximum : ${fcfa(soldeMax)}.');
    }
    depose += montant;
    final ref = '${operateur.logo}-${(58300 + _compteur * 37) % 100000}';
    _compteur++;
    operations.insert(
      0,
      Operation(
        type: TypeOp.depot,
        titre: 'Dépôt ${operateur.label}',
        detail: '${heure(maintenant)} · réf. $ref',
        montant: montant,
        date: maintenant,
        ref: ref,
      ),
    );
    _changer();
    return ref;
  }

  void retirer(int montant, String pin) {
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      throw ErreurMetier('Saisissez votre code FasoCovoit à 4 chiffres.');
    }
    if (montant < 1000) throw ErreurMetier('Retrait minimum : 1 000 F.');
    if (montant > depose) {
      throw ErreurMetier('Vous pouvez retirer au plus ${fcfa(depose)} : le bonus ne se retire pas.');
    }
    depose -= montant;
    operations.insert(
      0,
      Operation(
        type: TypeOp.retrait,
        titre: 'Retrait vers Orange Money',
        detail: 'En cours d\'envoi · sous 24 h',
        montant: -montant,
        date: maintenant,
      ),
    );
    _changer();
  }

  Reclamation reclamer(Operation op, String commentaire) {
    final existante = reclamations.where((r) => r.operation == op);
    if (existante.isNotEmpty) return existante.first;
    final rec = Reclamation(
      numero:
          'R-${maintenant.day.toString().padLeft(2, '0')}${maintenant.month.toString().padLeft(2, '0')}-${(42 + reclamations.length).toString().padLeft(4, '0')}',
      operation: op,
      date: maintenant,
      commentaire: commentaire,
    );
    op.statut = StatutOp.reclamation;
    reclamations.add(rec);
    _changer();
    return rec;
  }

  // -------------------------------------------------------- messages/notifs

  void envoyerMessage(Conversation c, String texte) {
    final t = texte.trim();
    if (t.isEmpty) return;
    c.messages.add(Message(t, maintenant, moi: true));
    if (c.equipe) {
      c.messages.add(
        Message(
          'Merci $prenom, votre message est bien reçu. Un membre de l\'équipe vous répond sous 24 h.',
          maintenant,
        ),
      );
    }
    _changer();
  }

  /// Ouvre (ou crée) la conversation avec une personne.
  Conversation ouvrirConversation(Personne p, String contexte) {
    final existante = conversationPour(p);
    if (existante != null) return existante;
    final conv = Conversation(
      id: 'c-${conversations.length}',
      avec: p,
      contexte: contexte,
      messages: [],
      verifie: p is Conducteur,
    );
    conversations.insert(0, conv);
    _changer();
    return conv;
  }

  void lireConversation(Conversation c) {
    if (c.nonLus == 0) return;
    c.nonLus = 0;
    _changer();
  }

  void toutLu() {
    for (final n in notifications) {
      n.lue = true;
    }
    _changer();
  }

  Conversation get conversationEquipe => conversations.firstWhere((c) => c.equipe);

  Conversation? conversationPour(Personne p) {
    for (final c in conversations) {
      if (c.avec.complet == p.complet) return c;
    }
    return null;
  }

  // ------------------------------------------------------------- conducteur

  /// Photos des documents du conducteur (CNIB, permis…), en mémoire.
  final Map<String, Uint8List> photosDocuments = {};

  /// Documents dont la photo a été importée au lieu d'être prise : refusés.
  final Set<String> _photosImportees = {};

  /// Ce que disent les documents (saisi par le conducteur).
  final DossierConducteur dossier = DossierConducteur();

  /// Points de la liste de vérification déjà cochés par l'équipe.
  final Set<String> verificationsFaites = {};

  /// Motif du dernier refus de l'équipe, à corriger avant de renvoyer.
  String? motifRefus;
  DateTime? valideLe;

  void envoyerDocument(String doc, {Uint8List? photo, bool appareil = true}) {
    documentsEnvoyes.add(doc);
    if (photo != null && photo.isNotEmpty) photosDocuments[doc] = photo;
    appareil ? _photosImportees.remove(doc) : _photosImportees.add(doc);
    _changer();
  }

  void majDossier(void Function(DossierConducteur d) maj) {
    maj(dossier);
    _changer();
  }

  /// Contrôles automatiques du dossier, avant l'envoi à l'équipe.
  List<Controle> get controlesDossier {
    final d = dossier, n = jour(maintenant);
    final manquants = documentsConducteur.keys.where((k) => !documentsEnvoyes.contains(k)).length;
    final importees = documentsEnvoyes.where(_photosImportees.contains).length;
    final age = d.naissance == null ? null : anneesEntre(d.naissance!, n);
    final permis = d.permisDelivre == null ? null : anneesEntre(d.permisDelivre!, n);
    final plaque = normaliserPlaque(d.plaque), plaqueA = normaliserPlaque(d.plaqueAssurance);
    final jAssurance = d.assuranceFin == null ? null : jour(d.assuranceFin!).difference(n).inDays;
    final jCnib = d.cnibExpire == null ? null : jour(d.cnibExpire!).difference(n).inDays;
    return [
      Controle(
        'Photos des ${documentsConducteur.length} documents',
        manquants == 0,
        manquants == 0 ? null : pluriel(manquants, 'photo manquante', 'photos manquantes'),
      ),
      Controle(
        "Photos prises avec l'appareil photo",
        importees == 0,
        importees == 0 ? null : '${pluriel(importees, 'photo importée', 'photos importées')} : reprenez-les',
      ),
      Controle('21 ans ou plus', age != null && age >= 21, age == null ? 'Date de naissance à saisir' : '$age ans'),
      Controle(
        'CNIB en cours de validité',
        d.cnibNumero.trim().isNotEmpty && jCnib != null && jCnib >= 0,
        d.cnibNumero.trim().isEmpty
            ? 'Numéro à saisir'
            : jCnib == null
            ? 'Date de fin de validité à saisir'
            : jCnib < 0
            ? 'Expirée depuis le ${dateLongue(d.cnibExpire!)}'
            : "Jusqu'au ${dateLongue(d.cnibExpire!)} ${d.cnibExpire!.year}",
      ),
      Controle(
        'Permis depuis 2 ans au moins',
        d.permisNumero.trim().isNotEmpty && permis != null && permis >= 2,
        d.permisNumero.trim().isEmpty
            ? 'Numéro à saisir'
            : permis == null
            ? 'Date de délivrance à saisir'
            : 'Délivré il y a ${pluriel(permis, 'an')}',
      ),
      Controle(
        'Plaque au format habituel (ex. 11 HH 2345)',
        plaqueValide(d.plaque),
        d.plaque.trim().isEmpty ? 'Plaque de la carte grise à saisir' : null,
      ),
      Controle(
        "Même plaque sur la carte grise et l'assurance",
        plaque.isNotEmpty && plaque == plaqueA,
        plaqueA.isEmpty ? "Plaque de l'attestation à saisir" : (plaque == plaqueA ? null : 'Les plaques diffèrent'),
      ),
      Controle(
        'Assurance en cours de validité',
        d.police.trim().isNotEmpty && jAssurance != null && jAssurance >= 0,
        d.police.trim().isEmpty
            ? 'Numéro de police à saisir'
            : jAssurance == null
            ? 'Date de fin à saisir'
            : jAssurance < 0
            ? 'Expirée depuis le ${dateLongue(d.assuranceFin!)}'
            : "Jusqu'au ${dateLongue(d.assuranceFin!)} ${d.assuranceFin!.year}",
      ),
    ];
  }

  bool get dossierComplet => controlesDossier.every((c) => c.ok);

  void envoyerPourValidation() {
    final aCorriger = controlesDossier.where((c) => !c.ok).toList();
    if (aCorriger.isNotEmpty) {
      final c = aCorriger.first;
      throw ErreurMetier('À corriger : ${c.libelle.toLowerCase()}${c.detail == null ? '' : ' (${c.detail})'}.');
    }
    if (etapeConducteur == EtapeConducteur.aucune) {
      etapeConducteur = EtapeConducteur.documentsEnvoyes;
      verificationsFaites.clear();
      motifRefus = null;
    }
    _changer();
  }

  static final _pointsVerification = [for (final (_, points) in verificationEquipe) ...points];

  /// L'équipe coche (ou décoche) un point de la liste de vérification.
  void cocherVerification(String point) {
    verificationsFaites.contains(point) ? verificationsFaites.remove(point) : verificationsFaites.add(point);
    _changer();
  }

  int get pointsRestants => _pointsVerification.where((p) => !verificationsFaites.contains(p)).length;

  /// L'équipe valide le compte : tous les points doivent être cochés.
  void validerParEquipe() {
    if (etapeConducteur != EtapeConducteur.documentsEnvoyes) {
      throw ErreurMetier("Le dossier n'est pas en attente de validation.");
    }
    if (pointsRestants > 0) {
      throw ErreurMetier('Encore ${pluriel(pointsRestants, 'point')} à vérifier.');
    }
    etapeConducteur = EtapeConducteur.valide;
    valideLe = maintenant;
    _changer();
  }

  /// L'équipe refuse le dossier : le conducteur corrige puis le renvoie.
  void refuserDossier(String motif) {
    if (etapeConducteur != EtapeConducteur.documentsEnvoyes) return;
    etapeConducteur = EtapeConducteur.aucune;
    motifRefus = motif;
    verificationsFaites.clear();
    _changer();
  }

  /// Démo : l'équipe coche toute la liste et valide.
  void simulerValidation() {
    if (etapeConducteur != EtapeConducteur.documentsEnvoyes) return;
    verificationsFaites.addAll(_pointsVerification);
    validerParEquipe();
  }

  /// Rappels des documents qui expirent : 30 jours avant, puis bloquants
  /// (plus de publication) une fois expirés.
  List<({String doc, String texte, bool bloquant})> get alertesDocuments {
    if (etapeConducteur == EtapeConducteur.aucune) return const [];
    final r = <({String doc, String texte, bool bloquant})>[];
    void verifier(String doc, String nom, DateTime? fin) {
      if (fin == null) return;
      final j = jour(fin).difference(jour(maintenant)).inDays;
      if (j < 0) {
        r.add((
          doc: doc,
          texte:
              '$nom a expiré le ${dateLongue(fin)} : envoyez le nouveau document. En attendant, vous ne pouvez plus publier.',
          bloquant: true,
        ));
      } else if (j <= 30) {
        r.add((
          doc: doc,
          texte:
              '$nom expire le ${dateLongue(fin)}${j == 0 ? " (aujourd'hui)" : ' (dans ${pluriel(j, 'jour')})'} : envoyez le nouveau document.',
          bloquant: false,
        ));
      }
    }

    verifier('Assurance', 'Votre assurance', dossier.assuranceFin);
    verifier('CNIB', 'Votre CNIB', dossier.cnibExpire);
    return r;
  }

  bool get documentsExpires => alertesDocuments.any((a) => a.bloquant);

  /// Nouvelle assurance ou nouvelle CNIB : photo prise avec l'appareil et
  /// nouvelle date de fin de validité.
  void renouvelerDocument(String doc, {required DateTime fin, required Uint8List photo}) {
    if (doc != 'Assurance' && doc != 'CNIB') throw ErreurMetier('Document inconnu.');
    if (photo.isEmpty) throw ErreurMetier('Prenez la photo du nouveau document.');
    if (jour(fin).isBefore(jour(maintenant))) throw ErreurMetier('Ce document est déjà expiré.');
    doc == 'Assurance' ? dossier.assuranceFin = fin : dossier.cnibExpire = fin;
    photosDocuments[doc] = photo;
    _photosImportees.remove(doc);
    _changer();
  }

  void activerAbonnement(Formule f) {
    if (etapeConducteur != EtapeConducteur.valide && etapeConducteur != EtapeConducteur.actif) {
      throw ErreurMetier("Votre compte doit d'abord être validé par l'équipe.");
    }
    final debut = maintenant;
    final offert = ajouterMois(debut, 1);
    abonnement = Abonnement(formule: f, debut: debut, offertJusquau: offert, prochainPaiement: offert)
      ..recus.add('${dateCourte(debut)} · 1er mois offert · 0 F');
    etapeConducteur = EtapeConducteur.actif;
    _changer();
  }

  void payerAbonnement() {
    final a = abonnement;
    if (a == null) return;
    if (a.formuleSuivante != null) {
      a.formule = a.formuleSuivante!;
      a.formuleSuivante = null;
    }
    a.recus.insert(0, '${dateCourte(maintenant)} · ${a.formule.nom} · ${fcfa(a.formule.prix)}');
    a.prochainPaiement = ajouterMois(a.prochainPaiement, a.formule.mois);
    a.arrete = false;
    _changer();
  }

  void changerFormule(Formule f) {
    final a = abonnement;
    if (a == null) return;
    a.formuleSuivante = f == a.formule ? null : f;
    _changer();
  }

  void arreterAbonnement() {
    abonnement?.arrete = true;
    _changer();
  }

  void reprendreAbonnement() {
    abonnement?.arrete = false;
    _changer();
  }

  bool get suspendu => suspenduJusquau != null && maintenant.isBefore(suspenduJusquau!);

  TrajetPublie publier({
    required Ligne ligne,
    required DateTime depart,
    required int places,
    required int prix,
    bool accepteAuto = false,
    bool regulier = false,
    Set<int> jours = const {},
    bool entreFemmes = false,
    bool especes = true,
    bool mobile = true,
    String? rdv,
  }) {
    if (!estConducteur) throw ErreurMetier("Votre compte conducteur n'est pas actif.");
    if (ligne.depart == ligne.arrivee) {
      throw ErreurMetier('Le départ et la destination doivent être différents.');
    }
    if (suspendu) {
      throw ErreurMetier('Compte suspendu jusqu\'au ${jourCourt(suspenduJusquau!)}.');
    }
    if (documentsExpires) {
      throw ErreurMetier('Document expiré : envoyez votre nouvelle assurance ou CNIB pour publier.');
    }
    if (abonnement?.arrete == true && maintenant.isAfter(abonnement!.prochainPaiement)) {
      throw ErreurMetier('Votre abonnement est arrêté : renouvelez-le pour publier.');
    }
    if (!depart.isAfter(maintenant)) {
      throw ErreurMetier('Choisissez une date et une heure à venir.');
    }
    if (places < 1 || places > 4) throw ErreurMetier('De 1 à 4 places.');
    final tarif = calculerTarif(ligne);
    if (prix < tarif.plancher || prix > tarif.plafond) {
      throw ErreurMetier('Prix entre ${fcfa(tarif.plancher)} et ${fcfa(tarif.plafond)} par place.');
    }
    if (!especes && !mobile) throw ErreurMetier('Acceptez au moins un moyen de paiement.');
    if (entreFemmes && !femme) {
      throw ErreurMetier('L\'option « Entre femmes » est réservée aux conductrices.');
    }
    final t = TrajetPublie(
      id: 'P${trajetsPublies.length + 1}',
      ligne: ligne,
      depart: depart,
      places: places,
      prix: prix,
      rdv: rdv == null || rdv.trim().isEmpty ? ligne.rdv : rdv.trim(),
      accepteAuto: accepteAuto,
      regulier: regulier,
      jours: jours,
      entreFemmes: entreFemmes,
      especes: especes,
      mobile: mobile,
    );
    trajetsPublies.add(t);
    if (!_exempleAjoute) {
      _exempleAjoute = true;
      t.exemple = true;
      _ajouterDemandesExemple(t);
      _ajouterCourseExemple(t);
    }
    _changer();
    return t;
  }

  /// Démo : un passager fictif attend le long de la route du premier trajet
  /// publié, à l'heure où le conducteur y passe : l'alerte s'affiche.
  void _ajouterCourseExemple(TrajetPublie t) {
    final l = t.ligne;
    (Lieu, Lieu, Croisement)? meilleur;
    for (final a in lieux.where((x) => x.ville == l.depart.ville && x != l.depart)) {
      for (final b in lieux.where((x) => x.ville == l.arrivee.ville && x != l.arrivee && x != a)) {
        final c = correspondance(l.depart, l.arrivee, a, b);
        if (c == null || c.monte < 0.3) continue;
        if (meilleur == null || c.monte + c.descend < meilleur.$3.monte + meilleur.$3.descend) {
          meilleur = (a, b, c);
        }
      }
    }
    if (meilleur == null) return;
    final (a, b, c) = meilleur;
    demandesTrajet.add(
      DemandeTrajet(
        id: 'D-route',
        passager: const Personne('Adama', 'Kinda', ton: Ton.vert),
        depart: a,
        arrivee: b,
        quand: heurePassage(t.depart, l.duree, c),
        exemple: true,
      ),
    );
  }

  void _ajouterDemandesExemple(TrajetPublie t) {
    // Lieu connu le plus proche, dans la même ville, autre que [l].
    Lieu voisin(Lieu l) {
      final autres = lieux.where((x) => x.ville == l.ville && x != l).toList()
        ..sort((a, b) => distanceKm(a, l).compareTo(distanceKm(b, l)));
      return autres.isEmpty ? l : autres.first;
    }

    final demandes = <Passager>[
      if (t.especes)
        Passager(
          personne: const Personne('Moussa', 'Ouédraogo', ton: Ton.etoile),
          places: 1,
          paiement: Paiement.especes,
          code: '3915',
          recueLe: maintenant.subtract(const Duration(minutes: 1)),
          prixPlace: t.prix,
          statut: StatutDemande.acceptee,
          note: 4.8,
          trajets: 14,
          montee: t.ligne.depart,
          descente: t.ligne.arrivee,
        ),
      if (t.mobile && t.places > 1 || t.mobile && !t.especes)
        Passager(
          personne: const Personne('Rasmata', 'Zongo', femme: true),
          places: 1,
          paiement: Paiement.orange,
          code: '6204',
          recueLe: maintenant,
          prixPlace: t.prix,
          statut: t.accepteAuto ? StatutDemande.acceptee : StatutDemande.attente,
          montee: voisin(t.ligne.depart),
          descente: voisin(t.ligne.arrivee),
        ),
    ];
    t.passagers.addAll(demandes);
  }

  void repondre(TrajetPublie t, Passager p, {required bool accepter}) {
    if (accepter && t.reservees + p.places > t.places) {
      throw ErreurMetier('Plus assez de places libres sur ce trajet.');
    }
    p.statut = accepter ? StatutDemande.acceptee : StatutDemande.refusee;
    _changer();
  }

  /// « Passager absent » : possible 10 min après l'heure de départ.
  bool absencePossible(TrajetPublie t) => maintenant.isAfter(t.depart.add(const Duration(minutes: 10)));

  void marquerAbsent(TrajetPublie t, Passager p) {
    if (!absencePossible(t)) {
      throw ErreurMetier('Attendez 10 minutes après l\'heure de départ.');
    }
    p.absent = true;
    _changer();
  }

  /// Vérifie le code donné par le passager. Retourne vrai s'il est bon.
  bool validerCode(Passager p, String code) {
    if (code == p.code) {
      p.aBord = true;
      _changer();
      return true;
    }
    return false;
  }

  /// QR valable : fait monter le prochain passager confirmé payé en ligne.
  Passager? monterParQr(TrajetPublie t) {
    final candidats = t.confirmes.where((p) => !p.aBord).toList()
      ..sort((a, b) => a.paiement.enLigne == b.paiement.enLigne ? 0 : (a.paiement.enLigne ? -1 : 1));
    if (candidats.isEmpty) return null;
    candidats.first.aBord = true;
    _changer();
    return candidats.first;
  }

  void demarrerTrajet(TrajetPublie t) {
    if (!t.toutLeMondeABord) {
      throw ErreurMetier('Validez le code de chaque passager avant de démarrer.');
    }
    t.statut = StatutPublie.enCours;
    _changer();
  }

  GainTrajet terminerTrajet(TrajetPublie t) {
    var mobile = 0, especes = 0;
    for (final p in t.confirmes) {
      if (p.aBord && p.paiement == Paiement.especes) {
        especes += p.montant;
      } else if (p.paiement.enLigne && (p.aBord || p.absent)) {
        // Un passager absent qui a payé en ligne n'est pas remboursé (règle B7).
        mobile += p.montant;
      }
    }
    t.statut = StatutPublie.termine;
    gainsDisponibles += mobile;
    trajetsConducteur += 1;
    final g = GainTrajet(
      titre: t.ligne.titre,
      date: t.depart,
      passagers: t.confirmes.where((p) => p.aBord).length,
      mobile: mobile,
      especes: especes,
    );
    gains.insert(0, g);
    if (mobile > 0) {
      operationsConducteur.insert(
        0,
        Operation(
          type: TypeOp.trajet,
          titre: 'Trajet ${t.ligne.titre} · ${dateCourte(t.depart)}',
          detail: '${pluriel(g.passagers, 'place')} payée${g.passagers > 1 ? 's' : ''} en ligne',
          montant: mobile,
          date: maintenant,
        ),
      );
    }
    _changer();
    return g;
  }

  void annulerTrajetPublie(TrajetPublie t) {
    if (t.statut != StatutPublie.publie) {
      throw ErreurMetier('Ce trajet ne peut plus être annulé.');
    }
    t.statut = StatutPublie.annule;
    if (t.confirmes.isNotEmpty) {
      annulationsConducteur += 1;
      if (annulationsConducteur >= 3) {
        suspenduJusquau = maintenant.add(const Duration(days: 7));
      }
    }
    _changer();
  }

  int get gainsEnAttente => trajetsPublies
      .where((t) => t.statut == StatutPublie.publie || t.statut == StatutPublie.enCours)
      .expand((t) => t.confirmes)
      .where((p) => p.paiement.enLigne)
      .fold(0, (s, p) => s + p.montant);

  void retirerGains() {
    if (gainsDisponibles <= 0) throw ErreurMetier('Aucun gain à retirer.');
    operationsConducteur.insert(
      0,
      Operation(
        type: TypeOp.retrait,
        titre: 'Retrait vers Orange Money',
        detail: '${dateCourte(maintenant)} · en cours d\'envoi',
        montant: -gainsDisponibles,
        date: maintenant,
      ),
    );
    gainsDisponibles = 0;
    _changer();
  }

  List<GainTrajet> get gainsDuMois =>
      gains.where((g) => g.date.month == maintenant.month && g.date.year == maintenant.year).toList();

  // ------------------------------------------------------------- utilitaires

  static const _refs = ['FC-7QK4-M9R', 'FC-2PZ8-K4D', 'FC-9HC3-T7W', 'FC-5MV7-B2Q'];
  static const _codes = ['4827', '1593', '7046', '2381'];
  int _nResa = 0;

  String _ref() {
    final i = _nResa;
    if (i < _refs.length) return _refs[i];
    const a = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    String bloc(int seed, int n) => List.generate(n, (k) => a[(seed * 7 + k * 13 + i * 31) % a.length]).join();
    return 'FC-${bloc(i, 4)}-${bloc(i + 3, 3)}';
  }

  String _code() {
    final i = _nResa++;
    if (i < _codes.length) return _codes[i];
    return ((1000 + i * 7919) % 9000 + 1000).toString();
  }

  void _notifier(TypeNotif type, String titre, String texte) {
    notifications.insert(0, Notif(type, titre, texte, maintenant));
  }

  Conversation _conversationAvec(Conducteur c, Trajet t, {List<String> messages = const []}) {
    final existante = conversationPour(c);
    if (existante != null) return existante;
    final conv = Conversation(
      id: 'c-${conversations.length}',
      avec: c,
      contexte: '${t.titre} · ${jourRelatif(t.heureDepart, maintenant).toLowerCase()} ${heureCourte(t.heureDepart)}',
      verifie: true,
      nonLus: messages.length,
      messages: [for (final m in messages) Message(m, maintenant)],
    );
    conversations.insert(0, conv);
    return conv;
  }

  // ----------------------------------------------------------- données démo

  void _semer({bool historique = true}) {
    final n = maintenant;
    final demain = jour(n).add(const Duration(days: 1));
    DateTime a(DateTime j, int h, [int m = 0]) => DateTime(j.year, j.month, j.day, h, m);
    DateTime arrondi(Duration d) {
      final t = n.add(d);
      return DateTime(t.year, t.month, t.day, t.hour, t.minute - t.minute % 5);
    }

    const issouf = _issouf;
    const aminata = _aminata;
    const boukary = _boukary;
    const ousmane = _ousmane;
    const salif = _salif;

    const ouaga = lOuagaGare;
    const koud = lKoudCentre;
    trajets.addAll([
      Trajet(
        id: 't1',
        conducteur: issouf,
        depart: ouaga,
        arrivee: koud,
        rdv: "Devant l'entrée principale",
        heureDepart: a(demain, 7),
        duree: const Duration(minutes: 90),
        km: 98,
        prix: 2500,
        places: 3,
        placesPrises: 1,
      ),
      Trajet(
        id: 't2',
        conducteur: aminata,
        depart: lTampouy,
        arrivee: lKoudUniv,
        rdv: 'Rond-point de Tampouy',
        heureDepart: a(demain, 9, 30),
        duree: const Duration(minutes: 90),
        km: 104,
        prix: 1800,
        places: 2,
        placesPrises: 1,
        entreFemmes: true,
      ),
      Trajet(
        id: 't3',
        conducteur: boukary,
        depart: lPissy,
        arrivee: lKoudGare,
        rdv: 'Station Total de Pissy',
        heureDepart: a(demain, 16),
        duree: const Duration(minutes: 100),
        km: 96,
        prix: 2500,
        places: 4,
        placesPrises: 1,
      ),
      Trajet(
        id: 'v1',
        conducteur: ousmane,
        depart: lDassasgho,
        arrivee: lOuaga2000,
        rdv: 'Rue 29.12, devant la pharmacie',
        heureDepart: arrondi(const Duration(minutes: 20)),
        duree: const Duration(minutes: 25),
        km: 9,
        prix: 700,
        places: 3,
        interVilles: false,
      ),
      Trajet(
        id: 'v2',
        conducteur: aminata,
        depart: lDassasgho,
        arrivee: lOuaga2000,
        rdv: 'Marché de Dassasgho',
        heureDepart: arrondi(const Duration(minutes: 45)),
        duree: const Duration(minutes: 25),
        km: 9,
        prix: 600,
        places: 2,
        entreFemmes: true,
        interVilles: false,
      ),
    ]);

    // D'autres passagers cherchent un trajet : les conducteurs le voient.
    demandesTrajet
      ..clear()
      ..addAll([
        DemandeTrajet(
          id: 'D-ex1',
          passager: const Personne('Fatou', 'Sanou', femme: true),
          depart: lPatteOie,
          arrivee: lKoudS7,
          quand: a(demain, 7),
        ),
        DemandeTrajet(
          id: 'D-ex2',
          passager: const Personne('Ali', 'Kaboré', ton: Ton.vert),
          depart: lTampouy,
          arrivee: lKoudCentre,
          quand: a(jour(n).add(const Duration(days: 2)), 6, 30),
          places: 2,
        ),
        DemandeTrajet(
          id: 'D-ex3',
          passager: const Personne('Salam', 'Ouédraogo', ton: Ton.etoile),
          depart: lDassasgho,
          arrivee: lUnivOuaga,
          quand: a(demain, 7, 30),
        ),
      ]);

    if (!historique) {
      // Nouveau compte : aucun historique, portefeuille vide.
      depose = 0;
      bonus = 0;
      bonusExpire = jour(n);
      conversations.add(
        Conversation(
          id: 'equipe',
          avec: const Personne('Équipe', 'FasoCovoit'),
          contexte: 'Aide',
          equipe: true,
          nonLus: 1,
          messages: [Message('Bienvenue sur FasoCovoit ! Une question ? Écrivez-nous ici.', n)],
        ),
      );
      return;
    }

    // Lieux habituels d'Hermès : il habite à Dassasgho.
    lieuxRecents.addAll([lDassasgho, lOuaga2000, lOuagaGare, lKoudCentre]);
    lieuxFavoris.add(lDassasgho);

    // Démo : ce que disent les documents d'Hermès (les photos restent à
    // prendre). L'assurance expire bientôt : le rappel s'affiche.
    dossier
      ..naissance = DateTime(1994, 3, 12)
      ..cnibNumero = 'B10984527'
      ..cnibExpire = DateTime(n.year + 4, 6, 30)
      ..permisNumero = 'BF-2015-0412873'
      ..permisDelivre = DateTime(2015, 6, 1)
      ..plaque = '11 HH 2345'
      ..vehicule = 'Toyota Corolla'
      ..couleurVoiture = 'grise'
      ..assureur = 'Assureur de démonstration'
      ..police = 'AUTO-2026-58213'
      ..plaqueAssurance = '11 HH 2345'
      ..assuranceFin = jour(n).add(const Duration(days: 20));

    // Historique passager
    final regulier = Trajet(
      id: 'r1',
      conducteur: issouf,
      depart: lDassasgho,
      arrivee: lOuaga2000,
      rdv: 'Rue 29.12',
      heureDepart: a(jour(n).add(const Duration(days: 2)), 7, 15),
      duree: const Duration(minutes: 25),
      km: 9,
      prix: 700,
      places: 3,
      placesPrises: 1,
      interVilles: false,
    );
    final passe = Trajet(
      id: 'h1',
      conducteur: issouf,
      depart: ouaga,
      arrivee: koud,
      rdv: "Devant l'entrée principale",
      heureDepart: a(jour(n).subtract(const Duration(days: 2)), 7),
      duree: const Duration(minutes: 90),
      km: 98,
      prix: 2500,
      places: 3,
      placesPrises: 3,
    );
    final annule = Trajet(
      id: 'h2',
      conducteur: salif,
      depart: lPissy,
      arrivee: lZogona,
      rdv: 'Pissy',
      heureDepart: a(jour(n).subtract(const Duration(days: 12)), 12),
      duree: const Duration(minutes: 30),
      km: 11,
      prix: 1500,
      places: 3,
      interVilles: false,
    );
    reservations.addAll([
      Reservation(
        ref: 'FC-3RT6-W2A',
        trajet: regulier,
        places: 1,
        paiement: Paiement.especes,
        montant: 700,
        code: '5512',
        creeLe: n.subtract(const Duration(minutes: 8)),
      ),
      Reservation(
        ref: 'FC-8LM2-Q5E',
        trajet: passe,
        places: 1,
        paiement: Paiement.orange,
        montant: 2500,
        code: '9034',
        creeLe: n.subtract(const Duration(days: 4)),
        statut: StatutResa.terminee,
      ),
      Reservation(
          ref: 'FC-4XN9-H3P',
          trajet: annule,
          places: 1,
          paiement: Paiement.portefeuille,
          montant: 1500,
          code: '2208',
          creeLe: n.subtract(const Duration(days: 13)),
          statut: StatutResa.annulee,
        )
        ..annuleeParConducteur = true
        ..rembourse = 1500,
    ]);

    // Portefeuille : 7 000 F déposés + 500 F de bonus
    depose = 7000;
    bonus = 500;
    bonusExpire = jour(n).add(const Duration(days: 88));
    operations.addAll([
      Operation(
        type: TypeOp.depot,
        titre: 'Dépôt Moov Money',
        detail: '${heure(n.subtract(const Duration(minutes: 29)))} · réf. MM-90417',
        montant: 2000,
        date: n.subtract(const Duration(minutes: 29)),
        ref: 'MM-90417',
        statut: StatutOp.enAttente,
      ),
      Operation(
        type: TypeOp.depot,
        titre: 'Dépôt Orange Money',
        detail: '${heure(n.subtract(const Duration(minutes: 48)))} · réf. OM-58213',
        montant: 5000,
        date: n.subtract(const Duration(minutes: 48)),
        ref: 'OM-58213',
      ),
      Operation(
        type: TypeOp.remboursement,
        titre: 'Remboursement · trajet annulé',
        detail: '${dateCourte(annule.heureDepart)} · par le conducteur',
        montant: 1500,
        date: annule.heureDepart,
        ref: 'FC-4XN9-H3P',
      ),
      Operation(
        type: TypeOp.trajet,
        titre: 'Trajet Pissy → Zogona',
        detail: '${dateCourte(annule.heureDepart.subtract(const Duration(days: 1)))} · réservation annulée',
        montant: -1500,
        date: annule.heureDepart.subtract(const Duration(days: 1)),
        ref: 'FC-4XN9-H3P',
      ),
      Operation(
        type: TypeOp.bonus,
        titre: 'Bonus de parrainage',
        detail: 'Moussa O. a fait son premier trajet',
        montant: 500,
        date: n.subtract(const Duration(days: 14)),
        ref: 'PAR-0071',
      ),
      Operation(
        type: TypeOp.depot,
        titre: 'Dépôt Orange Money',
        detail: '${dateCourte(n.subtract(const Duration(days: 15)))} · réf. OM-51877',
        montant: 2000,
        date: n.subtract(const Duration(days: 15)),
        ref: 'OM-51877',
      ),
    ]);

    conversations.addAll([
      Conversation(
        id: 'equipe',
        avec: const Personne('Équipe', 'FasoCovoit'),
        contexte: 'Aide',
        equipe: true,
        messages: [
          Message('Bonjour $prenom, le conducteur a annulé votre trajet Pissy → Zogona.', annule.heureDepart),
          Message('Votre remboursement a été envoyé.', n.subtract(const Duration(days: 1))),
        ],
      ),
      Conversation(
        id: 'aminata',
        avec: aminata,
        contexte: 'Tampouy → Université · ${dateCourte(n.subtract(const Duration(days: 5)))}',
        verifie: true,
        messages: [
          Message('Je suis au rond-point, voiture rouge.', n.subtract(const Duration(days: 5))),
          Message('J\'arrive dans 2 minutes !', n.subtract(const Duration(days: 5)), moi: true),
          Message('Merci et bonne journée !', n.subtract(const Duration(days: 5))),
        ],
      ),
    ]);

    notifications.addAll([
      Notif(
        TypeNotif.rembourse,
        'Remboursement envoyé',
        '1 500 F sur votre portefeuille.',
        annule.heureDepart,
        lue: true,
      ),
      Notif(
        TypeNotif.annulee,
        'Trajet annulé',
        'Le conducteur a annulé Pissy → Zogona.',
        annule.heureDepart.subtract(const Duration(hours: 2)),
        lue: true,
      ),
    ]);
  }
}

/// Donne accès à l'état depuis n'importe quel écran.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);

  static AppState of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  static AppState read(BuildContext context) => context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
