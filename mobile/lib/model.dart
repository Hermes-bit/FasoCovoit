import 'dart:async';

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
  String get initiales =>
      (prenom.isEmpty ? '?' : prenom[0]) + (nom.isEmpty ? '' : nom[0]);
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
  });
  final double note;
  final int trajets;
  final String voiture;
  final String couleur;
  final String plaque;
  final bool climatisee;
  final int depuis;

  bool get nouveau => trajets == 0;
  String get vehicule => '$voiture $couleur';
}

class Lieu {
  const Lieu(this.ville, this.quartier);
  final String ville;
  final String quartier;
  String get complet => '$ville, $quartier';
}

String villeCourte(String ville) => ville == 'Ouagadougou' ? 'Ouaga' : ville;

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
  const ReglagesTarifs({
    this.prixSuper = 850,
    this.prixGasoil = 750,
    this.usure = 30,
    this.villeMin = 400,
  });
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
    depart: Lieu('Ouagadougou', 'gare routière'),
    arrivee: Lieu('Koudougou', 'centre-ville'),
    km: 98,
    duree: Duration(minutes: 90),
    rdv: "Devant l'entrée principale",
    car: 2000,
  ),
  Ligne(
    id: 'koudougou-ouaga',
    depart: Lieu('Koudougou', 'gare routière'),
    arrivee: Lieu('Ouagadougou', 'gare routière'),
    km: 98,
    duree: Duration(minutes: 90),
    rdv: 'Devant la gare routière',
    car: 2000,
  ),
  Ligne(
    id: 'ouaga-bobo',
    depart: Lieu('Ouagadougou', 'gare routière'),
    arrivee: Lieu('Bobo-Dioulasso', 'centre-ville'),
    km: 360,
    duree: Duration(hours: 5),
    rdv: "Devant l'entrée principale",
    car: 7000,
    carVip: 9000,
  ),
  Ligne(
    id: 'dassasgho-ouaga2000',
    depart: Lieu('Ouagadougou', 'Dassasgho'),
    arrivee: Lieu('Ouagadougou', 'Ouaga 2000'),
    km: 9,
    duree: Duration(minutes: 25),
    rdv: 'Rue 29.12, devant la pharmacie',
    interVilles: false,
  ),
  Ligne(
    id: 'tampouy-zogona',
    depart: Lieu('Ouagadougou', 'Tampouy'),
    arrivee: Lieu('Ouagadougou', 'Zogona'),
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
  String get titreLong => interVilles
      ? '${depart.ville} → ${arrivee.ville}'
      : '${depart.quartier} → ${arrivee.quartier}';
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
  });
  final String ref;
  final Trajet trajet;
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
  bool get aVenir =>
      statut == StatutResa.enAttente ||
      statut == StatutResa.confirmee ||
      statut == StatutResa.enCours;
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
  Reclamation({
    required this.numero,
    required this.operation,
    required this.date,
    this.commentaire = '',
  });
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
  trimestriel(
    'Trimestriel',
    12000,
    3,
    'pour 3 mois',
    'Soit 4 000 F par mois : 3 000 F économisés',
  ),
  annuel(
    'Annuel',
    42000,
    12,
    'pour 12 mois',
    'Soit 3 500 F par mois : 18 000 F économisés',
  );

  const Formule(this.nom, this.prix, this.mois, this.duree, this.economie);
  final String nom;
  final int prix;
  final int mois;
  final String duree;
  final String economie;
}

DateTime ajouterMois(DateTime d, int mois) =>
    DateTime(d.year, d.month + mois, d.day, d.hour, d.minute);

class Abonnement {
  Abonnement({
    required this.formule,
    required this.debut,
    required this.offertJusquau,
    required this.prochainPaiement,
  });
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
  });
  final Personne personne;
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

  List<Passager> get confirmes =>
      passagers.where((p) => p.statut == StatutDemande.acceptee).toList();
  List<Passager> get enAttente =>
      passagers.where((p) => p.statut == StatutDemande.attente).toList();
  int get reservees => confirmes.fold(0, (t, p) => t + p.places);
  bool get toutLeMondeABord =>
      confirmes.any((p) => p.aBord) && confirmes.every((p) => p.aBord || p.absent);
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

const documentsConducteur = <String, String>{
  'CNIB': 'Recto et verso',
  'Permis de conduire': 'Délivré il y a 2 ans au moins',
  'Carte grise': 'Toyota Corolla · 11 HH 2345',
  'Assurance': 'En cours de validité',
  'Photo du véhicule': 'Plaque bien lisible',
};

// ---------------------------------------------------------------------------
// État de l'application (démonstration en mémoire)
// ---------------------------------------------------------------------------

enum Mode { passager, conducteur }

class AppState extends ChangeNotifier {
  AppState({DateTime Function()? horloge}) : _horloge = horloge ?? DateTime.now {
    _semer();
  }

  final DateTime Function() _horloge;
  DateTime get maintenant => _horloge();
  Timer? _minuterie;

  // Compte
  bool connecte = false;
  Mode mode = Mode.passager;

  /// Onglet affiché dans la navigation du bas (passager ou conducteur).
  int onglet = 0;
  void allerOnglet(int i) {
    onglet = i;
    _changer();
  }
  String telephone = '70 12 34 56';
  String prenom = 'Awa';
  String nom = 'Traoré';
  bool femme = true;
  String urgenceNom = 'Mariam Traoré';
  String urgenceTel = '+226 76 45 21 09';
  String urgenceLien = 'Maman';
  double notePassager = 4.7;
  int trajetsPassager = 9;

  Personne get moi => Personne(prenom, nom, femme: femme);
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
  final parrainage = (invites: 3, voyage: 1, gagne: 500);

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
  int get bloque => operations
      .where((o) => o.statut == StatutOp.bloque)
      .fold(0, (t, o) => t - o.montant);
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

  void connecter() {
    connecte = true;
    mode = Mode.passager;
    _changer();
  }

  void deconnecter() {
    connecte = false;
    mode = Mode.passager;
    _changer();
  }

  /// Démo : la suppression remet l'application dans son état de départ.
  void supprimerCompte() {
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
    _compteur = 0;
    _semer();
    connecte = false;
    mode = Mode.passager;
    _changer();
  }

  void majProfil({String? prenom, String? nom, bool? femme}) {
    if (prenom != null && prenom.trim().isNotEmpty) this.prenom = prenom.trim();
    if (nom != null) this.nom = nom.trim();
    if (femme != null) this.femme = femme;
    _changer();
  }

  void majUrgence(String nom, String tel, String lien) {
    urgenceNom = nom.trim();
    urgenceTel = tel.trim();
    urgenceLien = lien;
    _changer();
  }

  void basculerMode(Mode m, {int onglet = 0}) {
    if (m == Mode.conducteur && !estConducteur) {
      throw ErreurMetier("Votre compte conducteur n'est pas encore actif.");
    }
    mode = m;
    this.onglet = onglet;
    _changer();
  }

  // --------------------------------------------------------------- recherche

  List<Trajet> rechercher({
    required bool interVilles,
    int places = 1,
    bool conductrices = false,
    bool matin = false,
  }) {
    return trajets.where((t) {
      if (t.interVilles != interVilles) return false;
      if (!t.heureDepart.isAfter(maintenant)) return false;
      if (t.placesLibres < places) return false;
      if (t.entreFemmes && !femme) return false;
      if (conductrices && !t.conducteur.femme) return false;
      if (matin && t.heureDepart.hour >= 12) return false;
      return true;
    }).toList()
      ..sort((a, b) => a.heureDepart.compareTo(b.heureDepart));
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
  }) {
    if (places < 1 || places > trajet.placesLibres) {
      throw ErreurMetier("Il n'y a plus assez de places sur ce trajet.");
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
      throw ErreurMetier(
        'Vous pouvez retirer au plus ${fcfa(depose)} : le bonus ne se retire pas.',
      );
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
      numero: 'R-${maintenant.day.toString().padLeft(2, '0')}${maintenant.month.toString().padLeft(2, '0')}-${(42 + reclamations.length).toString().padLeft(4, '0')}',
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

  Conversation get conversationEquipe =>
      conversations.firstWhere((c) => c.equipe);

  Conversation? conversationPour(Personne p) {
    for (final c in conversations) {
      if (c.avec.complet == p.complet) return c;
    }
    return null;
  }

  // ------------------------------------------------------------- conducteur

  void envoyerDocument(String doc) {
    documentsEnvoyes.add(doc);
    _changer();
  }

  void envoyerPourValidation() {
    if (documentsEnvoyes.length < documentsConducteur.length) {
      throw ErreurMetier('Envoyez les ${documentsConducteur.length} documents.');
    }
    if (etapeConducteur == EtapeConducteur.aucune) {
      etapeConducteur = EtapeConducteur.documentsEnvoyes;
    }
    _changer();
  }

  /// Démo : simule la validation par l'équipe.
  void simulerValidation() {
    if (etapeConducteur == EtapeConducteur.documentsEnvoyes) {
      etapeConducteur = EtapeConducteur.valide;
      _changer();
    }
  }

  void activerAbonnement(Formule f) {
    if (etapeConducteur != EtapeConducteur.valide &&
        etapeConducteur != EtapeConducteur.actif) {
      throw ErreurMetier("Votre compte doit d'abord être validé par l'équipe.");
    }
    final debut = maintenant;
    final offert = ajouterMois(debut, 1);
    abonnement = Abonnement(
      formule: f,
      debut: debut,
      offertJusquau: offert,
      prochainPaiement: offert,
    )..recus.add('${dateCourte(debut)} · 1er mois offert · 0 F');
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

  bool get suspendu =>
      suspenduJusquau != null && maintenant.isBefore(suspenduJusquau!);

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
  }) {
    if (!estConducteur) throw ErreurMetier("Votre compte conducteur n'est pas actif.");
    if (suspendu) {
      throw ErreurMetier('Compte suspendu jusqu\'au ${jourCourt(suspenduJusquau!)}.');
    }
    if (abonnement?.arrete == true &&
        maintenant.isAfter(abonnement!.prochainPaiement)) {
      throw ErreurMetier('Votre abonnement est arrêté : renouvelez-le pour publier.');
    }
    if (!depart.isAfter(maintenant)) {
      throw ErreurMetier('Choisissez une date et une heure à venir.');
    }
    if (places < 1 || places > 4) throw ErreurMetier('De 1 à 4 places.');
    final tarif = calculerTarif(ligne);
    if (prix < tarif.plancher || prix > tarif.plafond) {
      throw ErreurMetier(
        'Prix entre ${fcfa(tarif.plancher)} et ${fcfa(tarif.plafond)} par place.',
      );
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
      rdv: ligne.rdv,
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
    }
    _changer();
    return t;
  }

  void _ajouterDemandesExemple(TrajetPublie t) {
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
  bool absencePossible(TrajetPublie t) =>
      maintenant.isAfter(t.depart.add(const Duration(minutes: 10)));

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

  List<GainTrajet> get gainsDuMois => gains
      .where((g) => g.date.month == maintenant.month && g.date.year == maintenant.year)
      .toList();

  // ------------------------------------------------------------- utilitaires

  static const _refs = ['FC-7QK4-M9R', 'FC-2PZ8-K4D', 'FC-9HC3-T7W', 'FC-5MV7-B2Q'];
  static const _codes = ['4827', '1593', '7046', '2381'];
  int _nResa = 0;

  String _ref() {
    final i = _nResa;
    if (i < _refs.length) return _refs[i];
    const a = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    String bloc(int seed, int n) =>
        List.generate(n, (k) => a[(seed * 7 + k * 13 + i * 31) % a.length]).join();
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

  void _semer() {
    final n = maintenant;
    final demain = jour(n).add(const Duration(days: 1));
    DateTime a(DateTime j, int h, [int m = 0]) => DateTime(j.year, j.month, j.day, h, m);
    DateTime arrondi(Duration d) {
      final t = n.add(d);
      return DateTime(t.year, t.month, t.day, t.hour, t.minute - t.minute % 5);
    }

    const issouf = Conducteur(
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
    const aminata = Conducteur(
      'Aminata',
      'Sawadogo',
      femme: true,
      note: 4.8,
      trajets: 12,
      voiture: 'Suzuki Swift',
      couleur: 'rouge',
      plaque: '11 KA 2290',
    );
    const boukary = Conducteur(
      'Boukary',
      'Ouédraogo',
      ton: Ton.etoile,
      note: 0,
      trajets: 0,
      voiture: 'Peugeot 406',
      couleur: 'grise',
      plaque: '11 GK 8812',
    );
    const ousmane = Conducteur(
      'Ousmane',
      'Bationo',
      ton: Ton.etoile,
      note: 4.6,
      trajets: 21,
      voiture: 'Kia Picanto',
      couleur: 'bleue',
      plaque: '11 HB 7721',
    );
    const salif = Conducteur(
      'Salif',
      'Tiendrébéogo',
      note: 3.9,
      trajets: 27,
      voiture: 'Hyundai Accent',
      couleur: 'blanche',
      plaque: '11 FA 3390',
    );

    const ouaga = Lieu('Ouagadougou', 'gare routière');
    const koud = Lieu('Koudougou', 'centre-ville');
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
        depart: const Lieu('Ouagadougou', 'Tampouy'),
        arrivee: const Lieu('Koudougou', 'Université'),
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
        depart: const Lieu('Ouagadougou', 'Pissy'),
        arrivee: const Lieu('Koudougou', 'gare routière'),
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
        depart: const Lieu('Ouagadougou', 'Dassasgho'),
        arrivee: const Lieu('Ouagadougou', 'Ouaga 2000'),
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
        depart: const Lieu('Ouagadougou', 'Dassasgho'),
        arrivee: const Lieu('Ouagadougou', 'Ouaga 2000'),
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

    // Historique passager
    final regulier = Trajet(
      id: 'r1',
      conducteur: issouf,
      depart: const Lieu('Ouagadougou', 'Dassasgho'),
      arrivee: const Lieu('Ouagadougou', 'Ouaga 2000'),
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
      depart: const Lieu('Ouagadougou', 'Pissy'),
      arrivee: const Lieu('Ouagadougou', 'Zogona'),
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
          Message(
            'Bonjour Awa, le conducteur a annulé votre trajet Pissy → Zogona.',
            annule.heureDepart,
          ),
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
  const AppScope({super.key, required AppState state, required super.child})
    : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  static AppState read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
