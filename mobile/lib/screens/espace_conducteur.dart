import 'package:flutter/material.dart';

import '../carte.dart';
import '../formats.dart';
import '../model.dart';
import '../ouverture.dart';
import '../painters.dart';
import '../photo.dart';
import '../theme.dart';
import '../ui.dart';
import 'colis.dart';
import 'compte.dart';
import 'conducteur.dart';
import 'demande.dart';
import 'devenir.dart';
import 'messages_profil.dart';
import 'passager.dart';
import 'portefeuille.dart';

// ---------------------------------------------------------------------------
// Espace conducteur, en cinq onglets : Accueil, Covoit’, Proposer, Gains, Menu
// ---------------------------------------------------------------------------

/// Passe dans l'espace conducteur. La première fois, la fiche « Mode
/// conducteur » rappelle d'abord ce qu'est le covoiturage ; « J’ai compris »
/// lance le changement d'espace, « Fermer » reste là où l'on était.
void entrerModeConducteur(BuildContext context, {int onglet = 0}) {
  final s = AppScope.read(context);
  if (s.introConducteurVue) {
    changerEspace(context, Mode.conducteur, onglet: onglet);
    return;
  }
  // Un message en cours (« Bon retour… ») cacherait le bouton « J’ai compris ».
  ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => IntroConducteurEcran(onCompris: (c) => changerEspace(c, Mode.conducteur, onglet: onglet)),
    ),
  );
}

/// Change d'espace (passager ⇄ conducteur, ou premier choix à l'entrée)
/// derrière le rideau FasoCovoit : logo, cercle qui se resserre, puis
/// l'accueil de l'autre espace qui monte.
Future<void> changerEspace(BuildContext context, Mode m, {int onglet = 0}) {
  final s = AppScope.read(context);
  final nav = Navigator.of(context);
  return Ouverture.changer(context, () {
    nav.popUntil((r) => r.isFirst);
    if (s.espaceAChoisir) {
      s.choisirEspace(m);
    } else {
      s.basculerMode(m, onglet: onglet);
    }
  });
}

class EspaceConducteur extends StatelessWidget {
  const EspaceConducteur({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final index = s.onglet.clamp(0, 4);
    final demandes = s.sourdine ? 0 : demandesConducteur(s).length;
    return Scaffold(
      backgroundColor: C.sable,
      body: IndexedStack(
        index: index,
        children: const [
          AccueilConducteurOnglet(),
          CovoitOnglet(),
          ProposerOnglet(),
          GainsConducteurOnglet(),
          MenuConducteurOnglet(),
        ],
      ),
      bottomNavigationBar: NavBas(
        index: index,
        onTap: s.allerOnglet,
        items: [
          const NavItem(Icons.home_rounded, 'Accueil'),
          NavItem(Icons.directions_car_rounded, 'Covoit’', badge: demandes),
          const NavItem(Icons.add_circle_outline_rounded, 'Proposer'),
          const NavItem(Icons.account_balance_wallet_outlined, 'Gains'),
          const NavItem(Icons.menu_rounded, 'Menu'),
        ],
      ),
    );
  }
}

void _activerDabord(BuildContext context) => informer(
  context,
  'Compte conducteur à activer',
  'Pour proposer vos trajets et confirmer des passagers, finissez votre inscription : documents, '
      'validation par l’équipe, abonnement.',
);

/// Écran vide illustré.
class _Vide extends StatelessWidget {
  const _Vide({required this.peintre, required this.texte, this.titre});
  final CustomPainter peintre;
  final String texte;
  final String? titre;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 210, height: 168, child: CustomPaint(painter: peintre)),
          const SizedBox(height: 16),
          if (titre != null) ...[
            Text(titre!, textAlign: TextAlign.center, style: T.titre(20)),
            const SizedBox(height: 6),
          ],
          Doux(texte, taille: 15, align: TextAlign.center),
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Demandes à traiter : réservations, passagers sur la route, autres passagers
// ---------------------------------------------------------------------------

/// Une demande de passager vue par le conducteur.
class DemandeConducteur {
  DemandeConducteur._({
    required this.passager,
    required this.montee,
    required this.descente,
    required this.quand,
    required this.places,
    required this.prixPlace,
    required this.paiement,
    this.trajet,
    this.reservation,
    this.course,
    this.libre,
    this.note,
    this.trajets = 0,
    this.bagages = 'Aucun bagage',
  });

  /// Réservation sur un trajet publié : à accepter ou refuser.
  factory DemandeConducteur.reservation(TrajetPublie t, Passager p) => DemandeConducteur._(
    passager: p.personne,
    montee: p.montee ?? t.ligne.depart,
    descente: p.descente ?? t.ligne.arrivee,
    quand: t.depart,
    places: p.places,
    prixPlace: p.prixPlace,
    paiement: p.paiement,
    trajet: t,
    reservation: p,
    note: p.note,
    trajets: p.trajets,
  );

  /// Passager qui attend sur la route d'un trajet publié.
  factory DemandeConducteur.course(CoursePossible c) => DemandeConducteur._(
    passager: c.demande.passager,
    montee: c.demande.depart,
    descente: c.demande.arrivee,
    quand: c.passage,
    places: c.demande.places,
    prixPlace: c.trajet.prix,
    paiement: c.demande.paiement,
    trajet: c.trajet,
    course: c,
    bagages: c.demande.bagagesTexte,
  );

  /// Passager inscrit qu'aucun trajet ne croise : le conducteur peut publier sa course.
  factory DemandeConducteur.libre(DemandeTrajet d) => DemandeConducteur._(
    passager: d.passager,
    montee: d.depart,
    descente: d.arrivee,
    quand: d.quand,
    places: d.places,
    prixPlace: calculerTarif(Ligne.entre(d.depart, d.arrivee)).conseille,
    paiement: d.paiement,
    libre: d,
    bagages: d.bagagesTexte,
  );

  final Personne passager;
  final Lieu montee;
  final Lieu descente;
  final DateTime quand;
  final int places;
  final int prixPlace;
  final Paiement paiement;
  final TrajetPublie? trajet;
  final Passager? reservation;
  final CoursePossible? course;
  final DemandeTrajet? libre;
  final double? note;
  final int trajets;
  final String bagages;

  int get total => places * prixPlace;
}

/// Réservations en attente et passagers sur la route, selon les réglages.
List<DemandeConducteur> demandesConducteur(AppState s) {
  final l = <DemandeConducteur>[
    for (final t in s.trajetsPublies.where((t) => t.statut == StatutPublie.publie))
      for (final p in t.enAttente) DemandeConducteur.reservation(t, p),
    for (final c in s.coursesPossibles) DemandeConducteur.course(c),
  ];
  return s.enLigneUniquement ? l.where((d) => d.paiement.enLigne).toList() : l;
}

List<DemandeConducteur> _autresPassagers(AppState s) => [
  for (final d in s.passagersSansCourse)
    if (!s.enLigneUniquement || d.paiement.enLigne) DemandeConducteur.libre(d),
];

Widget _adresse(Lieu l, IconData icone, Color couleur) => Padding(
  padding: const EdgeInsets.only(top: 4),
  child: Row(
    children: [
      Icon(icone, size: 15, color: couleur),
      const SizedBox(width: 8),
      Expanded(
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(text: villeCourte(l.ville), style: T.gras),
              TextSpan(
                text: ' ${capitaliser(l.quartier)}',
                style: const TextStyle(color: C.doux),
              ),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14),
        ),
      ),
    ],
  ),
);

/// Carte de demande, avec sa languette qui ouvre le détail.
class CarteDemandeConducteur extends StatelessWidget {
  const CarteDemandeConducteur(this.d, {super.key});
  final DemandeConducteur d;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final p = d.passager;
    final sous = d.reservation != null
        ? 'A réservé · répondez sous ${d.reservation!.recueLe.add(Reservation.delaiReponse).difference(s.maintenant).inMinutes.clamp(0, 30)} min'
        : d.course != null
        ? 'Sur votre route · ${ecartTexte(d.course!.croisement.monte)}'
        : 'Aucun de vos trajets ne passe là';
    return CarteLanguette(
      couleur: d.libre != null ? C.doux : C.laterite,
      label: 'Demande de ${p.court}, ${jourRelatif(d.quand, s.maintenant)} ${heure(d.quand)}',
      onTap: () => ouvrir(context, DemandeConducteurEcran(demande: d)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (d.reservation == null)
                SizedBox(
                  width: 34,
                  child: IconeBtn(
                    icon: Icons.cancel_outlined,
                    label: 'Écarter la demande de ${p.court}',
                    taille: 22,
                    onTap: () => d.course != null ? s.ignorerCourse(d.course!) : s.ecarterDemande(d.libre!),
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: Icon(Icons.notifications_active_outlined, size: 22, color: C.lateriteF),
                ),
              Expanded(child: Text('${jourRelatif(d.quand, s.maintenant)} ${heure(d.quand)}', style: T.titre(17))),
              Pastille(fcfa(d.total), icon: Icons.payments_outlined, ton: TonPastille.vert),
            ],
          ),
          const SizedBox(height: 4),
          _adresse(d.montee, Icons.trip_origin_rounded, C.vert),
          _adresse(d.descente, Icons.place_rounded, C.laterite),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: C.sable, borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                Ava(p.initiales, ton: p.ton, taille: 38),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.court, style: T.gras),
                      Doux(sous),
                    ],
                  ),
                ),
                const Icon(Icons.person_outline_rounded, size: 18),
                Text(' ${d.places} pers.', style: T.gras),
              ],
            ),
          ),
          if (d.libre?.exemple == true || d.course?.demande.exemple == true) ...[
            const SizedBox(height: 6),
            const Doux('Prototype : passager fictif.'),
          ],
        ],
      ),
    );
  }
}

/// Détail d'une demande : carte, puis « Refuser » ou « Confirmer ».
class DemandeConducteurEcran extends StatelessWidget {
  const DemandeConducteurEcran({super.key, required this.demande});
  final DemandeConducteur demande;

  void _confirmer(BuildContext context) {
    final s = AppScope.read(context);
    final d = demande;
    if (!s.estConducteur) {
      _activerDabord(context);
      return;
    }
    if (d.libre != null) {
      remplacer(context, PublierEcran(demande: d.libre));
      return;
    }
    final ok = essayer(
      context,
      () => d.reservation != null ? s.repondre(d.trajet!, d.reservation!, accepter: true) : s.prendreCourse(d.course!),
    );
    if (!ok) return;
    Navigator.pop(context);
    message(
      context,
      d.course != null
          ? 'Course acceptée : ${d.passager.court} vous attend à ${capitaliser(d.montee.quartier)} vers ${heure(d.quand)}.'
          : '${d.passager.court} est confirmé sur votre trajet.',
    );
  }

  void _refuser(BuildContext context) {
    final s = AppScope.read(context);
    final d = demande;
    if (d.reservation != null) {
      s.repondre(d.trajet!, d.reservation!, accepter: false);
    } else if (d.course != null) {
      s.ignorerCourse(d.course!);
    } else {
      s.ecarterDemande(d.libre!);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final d = demande;
    final p = d.passager;
    final t = d.trajet;
    final haut = MediaQuery.paddingOf(context).top;
    final h = MediaQuery.sizeOf(context).height;
    final croise =
        d.course?.croisement ??
        (t == null ? null : correspondance(t.ligne.depart, t.ligne.arrivee, d.montee, d.descente));
    Widget stat(IconData i, String haut, String bas) => Column(
      children: [
        Icon(i, size: 26),
        const SizedBox(height: 6),
        Text(haut, style: T.gras, textAlign: TextAlign.center),
        Doux(bas, align: TextAlign.center),
      ],
    );
    Widget lieu(Color couleur, Lieu l, String? sous) => Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: couleur, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.complet, style: T.petit),
                if (sous != null) Doux(sous),
              ],
            ),
          ),
        ],
      ),
    );
    return Scaffold(
      backgroundColor: Plan.terre,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: h * .42,
            child: CarteRoute(
              depart: t?.ligne.depart ?? d.montee,
              arrivee: t?.ligne.arrivee ?? d.descente,
              margeHaut: 70,
              margeBas: 50,
            ),
          ),
          Positioned(
            top: 12 + haut,
            left: 16,
            child: Container(
              decoration: const BoxDecoration(color: C.surface, shape: BoxShape.circle, boxShadow: ombreDouce),
              child: IconeBtn(
                icon: Icons.chevron_left_rounded,
                label: 'Retour',
                taille: 28,
                onTap: () => Navigator.maybePop(context),
              ),
            ),
          ),
          Positioned.fill(
            top: h * .36,
            child: Container(
              decoration: const BoxDecoration(
                color: C.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [BoxShadow(color: Color(0x22000000), blurRadius: 16)],
              ),
              child: ListView(
                padding: EdgeInsets.fromLTRB(18, 10, 18, 24 + MediaQuery.paddingOf(context).bottom),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: C.trait, borderRadius: BorderRadius.circular(999)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: BtnClair(
                          d.reservation != null ? 'Refuser' : 'Écarter',
                          onPressed: () => _refuser(context),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Btn(
                          d.libre != null ? 'Accepter la course' : 'Confirmer',
                          hauteur: 52,
                          taille: 15,
                          onPressed: () => _confirmer(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Carte(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '${jourRelatif(d.quand, s.maintenant)} ${heure(d.quand)}',
                          textAlign: TextAlign.center,
                          style: T.titre(20),
                        ),
                        if (d.course != null) ...[
                          const SizedBox(height: 6),
                          Center(
                            child: Pastille(
                              'Vous passez chez ${p.prenom} ${ecartHoraire(d.course!.ecart)}',
                              icon: Icons.schedule_rounded,
                              ton: TonPastille.etoile,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Ava(p.initiales, ton: p.ton),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.court, style: T.gras),
                                  Doux(
                                    d.trajets > 0
                                        ? pluriel(d.trajets, 'trajet')
                                        : 'Passag${p.femme ? 'ère' : 'er'} inscrit${p.femme ? 'e' : ''}',
                                  ),
                                ],
                              ),
                            ),
                            if (d.note != null) NoteEtoile(d.note!),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  IntrinsicHeight(
                    child: Row(
                      children: [
                        Expanded(child: stat(Icons.payments_outlined, fcfa(d.total), d.paiement.label)),
                        const VerticalDivider(color: C.trait, thickness: 1.5, width: 24),
                        Expanded(
                          child: stat(
                            Icons.people_outline_rounded,
                            pluriel(d.places, 'passager'),
                            pluriel(d.places, 'place'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Sep(),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.luggage_outlined, size: 22),
                      const SizedBox(width: 10),
                      const Expanded(child: Doux('Voyage avec', taille: 14)),
                      Flexible(
                        child: Text(d.bagages, style: T.gras, textAlign: TextAlign.end),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Sep(),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Icon(Icons.route_outlined, size: 22),
                      SizedBox(width: 10),
                      Text('Itinéraire du passager', style: T.gras),
                    ],
                  ),
                  lieu(C.vert, d.montee, croise == null ? null : 'Monte ${ecartTexte(croise.monte)} de votre route'),
                  lieu(
                    C.laterite,
                    d.descente,
                    croise == null ? null : 'Descend ${ecartTexte(croise.descend)} de votre arrivée',
                  ),
                  const SizedBox(height: 14),
                  if (t != null)
                    Doux(
                      'Sur votre trajet ${t.ligne.titre} de ${heure(t.depart)} · '
                      '${pluriel(t.places - t.reservees, 'place libre', 'places libres')}',
                    )
                  else
                    const Doux(
                      'Aucun de vos trajets ne passe par là : « Accepter la course » publie le trajet depuis son adresse, à son heure.',
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Onglet Accueil : « Proposer un covoit’ » et « Mes actions »
// ---------------------------------------------------------------------------

class _Action extends StatelessWidget {
  const _Action({required this.icone, required this.titre, required this.sous, this.onTap, this.urgent = false});
  final IconData icone;
  final String titre;
  final String sous;
  final VoidCallback? onTap;
  final bool urgent;

  @override
  Widget build(BuildContext context) => Carte(
    onTap: onTap,
    bord: urgent ? C.etoile : C.trait,
    epaisseur: urgent ? 2.5 : 1.5,
    child: Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: urgent ? C.etoileC : C.sable2, shape: BoxShape.circle),
          child: Icon(icone, size: 22, color: urgent ? C.etoileF : C.encre),
        ),
        const SizedBox(width: 12),
        Bloc(titre, sous),
        if (onTap != null) const Icon(Icons.chevron_right_rounded),
      ],
    ),
  );
}

class AccueilConducteurOnglet extends StatelessWidget {
  const AccueilConducteurOnglet({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final actifs =
        s.trajetsPublies.where((t) => t.statut == StatutPublie.publie || t.statut == StatutPublie.enCours).toList()
          ..sort((a, b) => a.depart.compareTo(b.depart));
    final nbDemandes = demandesConducteur(s).length;
    final actions = <Widget>[
      if (!s.estConducteur) const ActivationConducteur(),
      if (s.suspendu)
        _Action(
          icone: Icons.block_rounded,
          titre: 'Compte suspendu',
          sous: 'Jusqu’au ${jourCourt(s.suspenduJusquau!)}, après 3 annulations en 30 jours.',
          urgent: true,
        ),
      for (final a in s.alertesDocuments)
        _Action(
          icone: a.bloquant ? Icons.block_rounded : Icons.event_busy_outlined,
          titre: a.doc == 'Assurance' ? 'Envoyer ma nouvelle assurance' : 'Envoyer ma nouvelle CNIB',
          sous: a.texte,
          urgent: true,
          onTap: () => ouvrir(context, MajDocumentEcran(doc: a.doc)),
        ),
      if (s.abonnement?.arrete == true)
        _Action(
          icone: Icons.info_outline_rounded,
          titre: 'Abonnement arrêté',
          sous: 'Vous publiez jusqu’au ${dateCourte(s.abonnement!.prochainPaiement)}.',
          onTap: () => ouvrir(context, const MonAbonnementEcran()),
        ),
      for (final t in actifs.where((t) => t.statut == StatutPublie.enCours))
        _Action(
          icone: Icons.directions_car_rounded,
          titre: 'Trajet en cours · ${t.ligne.titre}',
          sous: '${pluriel(t.aBord, 'passager')} à bord',
          urgent: true,
          onTap: () => ouvrir(context, EnRouteConducteurEcran(trajet: t)),
        ),
      if (nbDemandes > 0)
        _Action(
          icone: Icons.notifications_active_outlined,
          titre: '${pluriel(nbDemandes, 'demande de passager', 'demandes de passagers')} à traiter',
          sous: 'Confirmez ou refusez dans l’onglet « Covoit’ ».',
          urgent: true,
          onTap: () => s.allerOnglet(1),
        ),
      for (final t in actifs.where((t) => t.statut == StatutPublie.publie && t.confirmes.isNotEmpty))
        _Action(
          icone: Icons.event_available_rounded,
          titre: 'Départ ${jourRelatif(t.depart, s.maintenant).toLowerCase()} à ${heure(t.depart)}',
          sous:
              '${t.ligne.titre} · ${pluriel(t.confirmes.length, 'passager confirmé', 'passagers confirmés')} : '
              'validez leurs codes au départ.',
          onTap: () => ouvrir(context, DemandesEcran(trajet: t)),
        ),
    ];
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EnteteEncoche(
            couleur: C.encre,
            children: [
              Row(
                children: [
                  Text(
                    s.femme ? 'Mode conductrice' : 'Mode conducteur',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: C.etoile),
                  ),
                  const Spacer(),
                  const BasculeMode(conducteur: true),
                ],
              ),
              const SizedBox(height: 14),
              Semantics(
                header: true,
                child: Text('Bonjour ${s.prenom}', style: T.titre(30, color: Colors.white)),
              ),
            ],
            barre: BarreAction(
              'Proposer un covoit’',
              icon: Icons.add_location_alt_outlined,
              onTap: () => s.estConducteur ? ouvrir(context, const PublierEcran()) : _activerDabord(context),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Mes actions', style: T.titre(20)),
                const SizedBox(height: 12),
                if (actions.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: C.sable2, borderRadius: BorderRadius.circular(18)),
                    child: const Row(
                      children: [
                        Icon(Icons.task_alt_rounded, color: C.doux),
                        SizedBox(width: 12),
                        Bloc(
                          'Rien à faire pour le moment',
                          'Les actions sur vos covoit’ (demandes, départs, documents) apparaîtront ici.',
                        ),
                      ],
                    ),
                  )
                else
                  ...espacer(actions, 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Espace conducteur avant l'activation : où en est l'inscription.
class ActivationConducteur extends StatelessWidget {
  const ActivationConducteur({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final e = s.etapeConducteur;
    final (label, ecran) = switch (e) {
      EtapeConducteur.aucune => (
        s.motifRefus == null ? 'Envoyer mes documents' : 'Corriger mon dossier',
        const DocumentsEcran() as Widget,
      ),
      EtapeConducteur.documentsEnvoyes => ('Suivre ma validation', const ValidationEcran()),
      _ => ('Choisir mon abonnement', const OffresEcran()),
    };
    return Carte(
      bord: C.etoile,
      epaisseur: 2.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Activez votre compte conducteur', style: T.gras),
          const SizedBox(height: 4),
          const Doux(
            'Vous voyez déjà les passagers inscrits qui cherchent un trajet. '
            'Pour publier vos trajets et accepter des courses :',
            taille: 14,
          ),
          if (s.motifRefus != null) ...[
            const SizedBox(height: 8),
            Text(
              'Dossier refusé : ${s.motifRefus!.toLowerCase()}.',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: C.sos),
            ),
          ],
          const SizedBox(height: 12),
          Etape(
            e == EtapeConducteur.aucune ? EtatEtape.encours : EtatEtape.fait,
            'Photographier vos documents',
            'Avec l’appareil photo de l’application, et saisir ce qu’ils indiquent',
          ),
          Etape(
            switch (e) {
              EtapeConducteur.aucune => EtatEtape.afaire,
              EtapeConducteur.documentsEnvoyes => EtatEtape.encours,
              _ => EtatEtape.fait,
            },
            "Validation par l'équipe",
            'Sous 48 h, avec un court entretien',
          ),
          Etape(
            e == EtapeConducteur.valide ? EtatEtape.encours : EtatEtape.afaire,
            'Choisir votre abonnement',
            'Premier mois offert, sans engagement',
          ),
          Btn.lat(label, onPressed: () => ouvrir(context, ecran)),
          Lien('Comment ça marche', souligne: false, onTap: () => ouvrir(context, const DevenirIntroEcran())),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Onglet Covoit’ : les demandes des passagers
// ---------------------------------------------------------------------------

class CovoitOnglet extends StatelessWidget {
  const CovoitOnglet({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final demandes = demandesConducteur(s);
    final autres = _autresPassagers(s);
    final effacables = demandes.any((d) => d.course != null) || autres.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TitreOnglet(
          'Covoit’',
          action: IconeBtn(
            icon: Icons.tune_rounded,
            label: 'Réglages',
            onTap: () => ouvrir(context, const ReglagesConducteurEcran()),
          ),
        ),
        Expanded(
          child: demandes.isEmpty && autres.isEmpty
              ? _Vide(
                  peintre: IllustrationRoutePainter(),
                  texte: 'Pour recevoir des demandes de passagers, proposez un nouveau covoit’.',
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  children: [
                    if (!s.estConducteur) ...[
                      const Bandeau(
                        'Activez votre compte conducteur pour confirmer des passagers.',
                        icon: Icons.info_outline_rounded,
                        ton: TonPastille.etoile,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (demandes.isNotEmpty) ...[
                      Row(
                        children: [
                          const Text('Nouvelles demandes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                          const SizedBox(width: 8),
                          Pastille(
                            '${demandes.length}',
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                          ),
                          const Spacer(),
                          if (effacables) Lien('Tout effacer', couleur: C.sos, souligne: false, onTap: s.toutEffacer),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...espacer([for (final d in demandes) CarteDemandeConducteur(d)], 12),
                    ],
                    if (autres.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Passagers inscrits qui cherchent un trajet · ${autres.length}',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                            ),
                          ),
                          if (demandes.isEmpty)
                            Lien('Tout effacer', couleur: C.sos, souligne: false, onTap: s.toutEffacer),
                        ],
                      ),
                      const Doux('Aucun de vos trajets ne passe par là : acceptez leur course en publiant le trajet.'),
                      const SizedBox(height: 10),
                      ...espacer([for (final d in autres) CarteDemandeConducteur(d)], 12),
                    ],
                  ],
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Btn(
            'Proposer un trajet',
            onPressed: () => s.estConducteur ? ouvrir(context, const PublierEcran()) : _activerDabord(context),
          ),
        ),
      ],
    );
  }
}

/// Réglages des demandes : filtre et sourdine.
class ReglagesConducteurEcran extends StatelessWidget {
  const ReglagesConducteurEcran({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    Widget interrupteur(String titre, String sous, bool valeur, ValueChanged<bool> onChanged) => MergeSemantics(
      child: Row(
        children: [
          Bloc(titre, sous),
          Switch(value: valeur, activeTrackColor: C.vert, onChanged: onChanged),
        ],
      ),
    );
    Widget section(String t) => Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 10),
      child: Text(
        t,
        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: .6, color: C.doux),
      ),
    );
    return Scaffold(
      backgroundColor: C.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 12, 24),
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconeBtn(
                icon: Icons.close_rounded,
                label: 'Fermer',
                taille: 26,
                onTap: () => Navigator.maybePop(context),
              ),
            ),
            const Icon(Icons.tune_rounded, size: 40, color: C.laterite),
            const SizedBox(height: 6),
            Text('Réglages', textAlign: TextAlign.center, style: T.titre(22)),
            section('FILTRES'),
            interrupteur(
              'Paiement en ligne uniquement',
              'Masque les demandes réglées en espèces',
              s.enLigneUniquement,
              (v) => s.majReglages(enLigne: v),
            ),
            section('NOTIFICATIONS'),
            interrupteur(
              'Sourdine',
              s.sourdine ? 'Activée : plus d’alerte de nouvelle demande' : 'Désactivée',
              s.sourdine,
              (v) => s.majReglages(silence: v),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Onglet Proposer : mes covoit’
// ---------------------------------------------------------------------------

class ProposerOnglet extends StatelessWidget {
  const ProposerOnglet({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final actifs =
        s.trajetsPublies.where((t) => t.statut == StatutPublie.publie || t.statut == StatutPublie.enCours).toList()
          ..sort((a, b) => a.depart.compareTo(b.depart));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TitreOnglet(
          'Proposer',
          action: IconeBtn(
            icon: Icons.tune_rounded,
            label: 'Réglages',
            onTap: () => ouvrir(context, const ReglagesConducteurEcran()),
          ),
        ),
        Expanded(
          child: actifs.isEmpty
              ? _Vide(
                  peintre: IllustrationRoutePainter(),
                  texte: 'Pour recevoir des demandes de passagers, proposez un nouveau covoit’.',
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  children: espacer([for (final t in actifs) _CarteCovoit(t)], 12),
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Btn(
            'Proposer un trajet',
            onPressed: () => s.estConducteur ? ouvrir(context, const PublierEcran()) : _activerDabord(context),
          ),
        ),
      ],
    );
  }
}

class _CarteCovoit extends StatelessWidget {
  const _CarteCovoit(this.t);
  final TrajetPublie t;

  Future<void> _supprimer(BuildContext context) async {
    final s = AppScope.read(context);
    if (t.confirmes.isNotEmpty) {
      // Des passagers comptent sur ce trajet : règles d'annulation complètes.
      ouvrir(context, AnnulerTrajetEcran(trajet: t));
      return;
    }
    final ok = await confirmer(
      context,
      titre: 'Confirmer la suppression de votre covoit’ ?',
      texte: t.enAttente.isEmpty
          ? 'Les passagers ne le verront plus.'
          : 'Les demandes en attente seront annulées et les passagers prévenus.',
      oui: 'Supprimer',
      non: 'Annuler',
      danger: true,
    );
    if (ok && context.mounted && essayer(context, () => s.annulerTrajetPublie(t))) {
      message(context, 'Covoit’ supprimé.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final l = t.ligne;
    final attente = t.enAttente.length;
    final statut = t.statut == StatutPublie.enCours
        ? const Pastille('En cours', ton: TonPastille.vert, icon: Icons.directions_car_outlined)
        : attente > 0
        ? Pastille(pluriel(attente, 'demande'), ton: TonPastille.etoile, icon: Icons.notifications_none_rounded)
        : t.reservees >= t.places
        ? const Pastille('Complet', ton: TonPastille.vert)
        : Pastille('${t.reservees} / ${t.places} places');
    return Carte(
      onTap: () => ouvrir(
        context,
        t.statut == StatutPublie.enCours ? EnRouteConducteurEcran(trajet: t) : DemandesEcran(trajet: t),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 6, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [Pastille(t.regulier ? 'Trajet régulier' : 'Ponctuel', fond: C.sable2), statut],
                ),
              ),
              if (t.statut == StatutPublie.publie)
                IconeBtn(
                  icon: Icons.delete_outline_rounded,
                  label: 'Supprimer ce covoit’',
                  onTap: () => _supprimer(context),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 4),
                Text(
                  t.regulier
                      ? 'Du ${joursTexte(t.jours)} · ${heure(t.depart)}'
                      : '${jourRelatif(t.depart, s.maintenant)} · ${heure(t.depart)}',
                  style: T.titre(19),
                ),
                const SizedBox(height: 6),
                _adresse(l.depart, Icons.trip_origin_rounded, C.vert),
                _adresse(l.arrivee, Icons.place_rounded, C.laterite),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: Doux('${fcfa(t.prix)} par place', taille: 14, gras: true)),
                    Doux('${pluriel(t.reservees, 'place')} réservée${t.reservees > 1 ? 's' : ''}', taille: 14),
                  ],
                ),
                if (t.exemple) ...[
                  const SizedBox(height: 6),
                  const Doux('Prototype : les demandes de ce premier trajet sont fictives.'),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Onglet Gains
// ---------------------------------------------------------------------------

class GainsConducteurOnglet extends StatefulWidget {
  const GainsConducteurOnglet({super.key});

  @override
  State<GainsConducteurOnglet> createState() => _GainsConducteurOngletState();
}

class _GainsConducteurOngletState extends State<GainsConducteurOnglet> {
  int _onglet = 0;

  Future<void> _retirer(AppState s) async {
    final montant = s.gainsDisponibles;
    final ok = await confirmer(
      context,
      titre: 'Retirer ${fcfa(montant)} ?',
      texte: 'Vers votre Orange Money (${s.telephone}). Arrivée sous 24 h, souvent en quelques minutes.',
      oui: 'Retirer',
    );
    if (ok && mounted && essayer(context, s.retirerGains)) {
      message(context, 'Retrait de ${fcfa(montant)} en cours.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final enAttente = [
      for (final t in s.trajetsPublies.where(
        (t) => t.statut == StatutPublie.publie || t.statut == StatutPublie.enCours,
      ))
        if (t.confirmes.any((p) => p.paiement.enLigne)) t,
    ];
    final total = s.gainsDuMois.fold(0, (n, g) => n + g.total);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TitreOnglet('Gains'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
                decoration: BoxDecoration(
                  color: C.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: C.trait, width: 1.5),
                  boxShadow: ombreDouce,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'MON SOLDE',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: .6,
                              color: C.doux,
                            ),
                          ),
                          Text(fcfa(s.gainsDisponibles), style: T.titre(28)),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 116,
                      child: BtnClair(
                        'Retirer',
                        hauteur: 46,
                        onPressed: s.gainsDisponibles > 0 ? () => _retirer(s) : null,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Onglets(
                labels: const ['En attente', 'Historique'],
                index: _onglet,
                onChanged: (i) => setState(() => _onglet = i),
              ),
              const SizedBox(height: 8),
              const Doux(
                'Les paiements en ligne de vos passagers arrivent sur votre solde à la fin de chaque trajet.',
                align: TextAlign.center,
              ),
              const SizedBox(height: 14),
              if (_onglet == 0)
                if (enAttente.isEmpty)
                  SizedBox(
                    height: 300,
                    child: _Vide(
                      peintre: IllustrationPorteMonnaiePainter(),
                      titre: 'Aucun paiement en attente',
                      texte: 'Faites des covoit’ et retrouvez vos gains ici.',
                    ),
                  )
                else
                  ListeCarte(
                    children: [
                      for (final t in enAttente)
                        LigneListe(
                          onTap: () => ouvrir(context, DemandesEcran(trajet: t)),
                          children: [
                            const Icon(Icons.schedule_rounded, size: 22),
                            Bloc(
                              '${t.ligne.titre} · ${jourCourt(t.depart)}',
                              '${pluriel(t.confirmes.where((p) => p.paiement.enLigne).length, 'passager')} payé en ligne',
                            ),
                            Text(
                              fcfa(t.confirmes.where((p) => p.paiement.enLigne).fold(0, (n, p) => n + p.montant)),
                              style: T.gras,
                            ),
                          ],
                        ),
                    ],
                  )
              else if (s.gains.isEmpty && s.operationsConducteur.isEmpty)
                SizedBox(
                  height: 300,
                  child: _Vide(
                    peintre: IllustrationPorteMonnaiePainter(),
                    titre: 'Aucune transaction pour le moment',
                    texte: 'Retrouvez ici vos trajets terminés et vos retraits.',
                  ),
                )
              else ...[
                if (s.gains.isNotEmpty) ...[
                  const Doux('Trajets terminés', taille: 14, gras: true),
                  const SizedBox(height: 8),
                  ListeCarte(
                    children: [
                      for (final g in s.gains)
                        LigneListe(
                          children: [
                            Bloc(
                              g.titre,
                              '${dateCourte(g.date)} · ${pluriel(g.passagers, 'passager')} · '
                              '${g.mobile > 0 && g.especes > 0 ? 'en ligne et espèces' : (g.mobile > 0 ? 'en ligne' : 'espèces')}',
                            ),
                            Text(fcfa(g.total), style: T.gras),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
                if (s.operationsConducteur.isNotEmpty) ...[
                  const Doux('Opérations', taille: 14, gras: true),
                  const SizedBox(height: 8),
                  ListeCarte(children: [for (final o in s.operationsConducteur) LigneOperation(o)]),
                ],
              ],
              const SizedBox(height: 16),
              Carte(
                child: Row(
                  children: [
                    const Icon(Icons.insights_rounded, color: C.vert, size: 24),
                    const SizedBox(width: 12),
                    Bloc(
                      'Ce mois-ci : ${fcfa(total)} de frais partagés',
                      'Frais FasoCovoit : 0 F pendant le pilote, rien sur les espèces.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Onglet Menu
// ---------------------------------------------------------------------------

class MenuConducteurOnglet extends StatelessWidget {
  const MenuConducteurOnglet({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final haut = MediaQuery.paddingOf(context).top;
    final taux = s.tauxAnnulation;
    final niveau = s.trajetsConducteur >= 30
        ? 'EXPERT'
        : (s.trajetsConducteur > 0
              ? (s.femme ? 'CONDUCTRICE' : 'CONDUCTEUR')
              : (s.femme ? 'CONDUCTRICE DÉBUTANTE' : 'CONDUCTEUR DÉBUTANT'));
    final moi = Conducteur(
      s.prenom,
      s.nom,
      femme: s.femme,
      note: s.noteConducteur,
      trajets: s.trajetsConducteur,
      voiture: s.dossier.vehicule,
      couleur: s.dossier.couleurVoiture,
      plaque: s.dossier.plaque,
      annulations: s.annulationsConducteur,
    );
    Widget stat(IconData i, String label, String valeur, [VoidCallback? onTap]) => Carte(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      child: Column(
        children: [
          Icon(i, color: C.laterite, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: .5),
          ),
          Text(valeur, textAlign: TextAlign.center, style: T.titre(17)),
        ],
      ),
    );
    Widget section(String t) => Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 4),
      child: Text(
        t,
        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: .6, color: C.doux),
      ),
    );
    Widget ligne(IconData i, String titre, VoidCallback onTap, [String? sous]) => Column(
      children: [
        InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Row(
              children: [
                Icon(i, size: 21, color: C.laterite),
                const SizedBox(width: 14),
                Bloc(titre, sous),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
        const Sep(),
      ],
    );
    return ListView(
      padding: EdgeInsets.fromLTRB(20, 20 + haut, 20, 24),
      children: [
        Center(
          child: PhotoRonde(photo: s.photo, initiales: s.moi.initiales, taille: 84, fond: C.etoile, texte: C.encre),
        ),
        const SizedBox(height: 8),
        Text(s.moi.complet, textAlign: TextAlign.center, style: T.titre(22)),
        const SizedBox(height: 6),
        Center(
          child: Pastille(niveau, icon: Icons.verified_rounded, ton: TonPastille.lat),
        ),
        const SizedBox(height: 6),
        Center(
          child: Semantics(
            label: s.trajetsConducteur == 0 ? 'Pas encore noté' : 'Note ${s.noteConducteur} sur 5',
            excludeSemantics: true,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var k = 0; k < 5; k++)
                  Etoile(
                    size: 18,
                    color: s.trajetsConducteur > 0 && k < s.noteConducteur.round() ? C.etoile : C.sable2,
                  ),
                Doux('  (${s.trajetsConducteur})', taille: 14),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: stat(
                Icons.account_balance_wallet_outlined,
                'PORTE-MONNAIE',
                fcfa(s.gainsDisponibles),
                () => s.allerOnglet(3),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: stat(Icons.directions_car_outlined, 'COVOIT’ PASSÉS', '${s.trajetsConducteur}')),
          ],
        ),
        const SizedBox(height: 10),
        stat(Icons.cancel_outlined, 'TAUX D’ANNULATION', taux == null ? 'Non calculé' : '$taux %'),
        section('ESPACE PERSONNEL'),
        ligne(Icons.person_outline_rounded, 'Mon profil', () => ouvrir(context, const ProfilEcran())),
        ligne(
          Icons.directions_car_outlined,
          'Ma voiture',
          () => ouvrir(context, const MaVoitureEcran()),
          s.dossier.vehicule.isEmpty ? null : '${capitaliser(s.dossier.voiture)} · ${s.dossier.plaque}',
        ),
        ligne(
          Icons.chat_bubble_outline_rounded,
          'Mon profil public et mes avis',
          () => ouvrir(context, ConducteurPublicEcran(conducteur: moi)),
        ),
        ligne(Icons.folder_outlined, 'Mes documents', () => ouvrir(context, const MesDocumentsEcran())),
        ligne(
          Icons.workspace_premium_outlined,
          'Mon abonnement',
          () => ouvrir(context, s.abonnement == null ? const OffresEcran() : const MonAbonnementEcran()),
          s.abonnement == null
              ? 'Premier mois offert'
              : '${s.abonnement!.formule.nom} · ${s.abonnement!.arrete ? 'arrêté' : 'actif'}',
        ),
        ligne(
          Icons.savings_outlined,
          s.femme ? 'Portefeuille conductrice' : 'Portefeuille conducteur',
          () => ouvrir(context, const PortefeuilleConducteurEcran()),
        ),
        section('INFORMATIONS'),
        ligne(Icons.bolt_outlined, 'Comment ça marche ?', () => ouvrir(context, const IntroConducteurEcran())),
        ligne(
          Icons.verified_user_outlined,
          'Charte du conducteur',
          () => ouvrir(context, const PageTexteEcran.charte()),
        ),
        ligne(
          Icons.inventory_2_outlined,
          'Colis sur vos trajets',
          () => ouvrir(context, const ColisConducteurEcran()),
          'Bientôt',
        ),
        section('AIDE'),
        ligne(
          Icons.help_outline_rounded,
          'Obtenir de l’aide',
          () => ouvrir(context, ConversationEcran(conversation: s.conversationEquipe)),
        ),
        ligne(Icons.shield_outlined, 'Conditions et données', () => ouvrir(context, const PageTexteEcran.conditions())),
        const SizedBox(height: 22),
        BtnClair(
          'Passer en mode passag${s.femme ? 'ère' : 'er'}',
          icon: Icons.person_outline_rounded,
          onPressed: () => changerEspace(context, Mode.passager),
        ),
        const SizedBox(height: 6),
        Center(
          child: Lien(
            'Déconnexion',
            couleur: C.laterite,
            souligne: false,
            taille: 15,
            onTap: () async {
              final ok = await confirmer(
                context,
                titre: 'Se déconnecter ?',
                texte: 'Vous pourrez revenir avec votre numéro.',
                oui: 'Se déconnecter',
              );
              if (ok) s.deconnecter();
            },
          ),
        ),
      ],
    );
  }
}

/// « Ma voiture » : couleur, marque et modèle, plaque.
class MaVoitureEcran extends StatefulWidget {
  const MaVoitureEcran({super.key});

  @override
  State<MaVoitureEcran> createState() => _MaVoitureEcranState();
}

class _MaVoitureEcranState extends State<MaVoitureEcran> {
  late final AppState _s;
  late final TextEditingController _vehicule;
  late final TextEditingController _plaque;
  late String _couleur;

  @override
  void initState() {
    super.initState();
    _s = AppScope.read(context);
    _vehicule = TextEditingController(text: _s.dossier.vehicule);
    _plaque = TextEditingController(text: _s.dossier.plaque);
    _couleur = _s.dossier.couleurVoiture;
  }

  @override
  void dispose() {
    _vehicule.dispose();
    _plaque.dispose();
    super.dispose();
  }

  void _enregistrer() {
    final anciennePlaque = normaliserPlaque(_s.dossier.plaque);
    if (!essayer(context, () => _s.majVoiture(vehicule: _vehicule.text, couleur: _couleur, plaque: _plaque.text))) {
      return;
    }
    Navigator.pop(context);
    message(
      context,
      anciennePlaque.isNotEmpty && anciennePlaque != normaliserPlaque(_plaque.text)
          ? 'Voiture enregistrée. Nouvelle plaque : l’équipe vérifiera la carte grise.'
          : 'Voiture enregistrée.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final teinte = Color(couleursVoiture[_couleur] ?? 0xFF9EA3A8);
    return Ecran(
      fond: C.surface,
      children: [
        const Barre(titre: 'Ma voiture'),
        Zone(
          gap: 14,
          children: [
            Semantics(
              image: true,
              label: 'Voiture $_couleur',
              child: SizedBox(height: 140, child: CustomPaint(painter: VoiturePainter(teinte))),
            ),
            const Text(
              'COULEUR',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: .6, color: C.doux),
            ),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final e in couleursVoiture.entries)
                  Semantics(
                    button: true,
                    selected: e.key == _couleur,
                    label: e.key,
                    excludeSemantics: true,
                    child: InkResponse(
                      onTap: () => setState(() => _couleur = e.key),
                      radius: 24,
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: Center(
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: Color(e.value),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: e.key == _couleur ? C.encre : C.trait,
                                width: e.key == _couleur ? 3 : 1.5,
                              ),
                            ),
                            child: e.key == _couleur
                                ? Icon(
                                    Icons.check_rounded,
                                    size: 18,
                                    color: e.key == 'blanche' || e.key == 'jaune' ? C.encre : Colors.white,
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Etiq('Marque et modèle'),
                const SizedBox(height: 8),
                Champ(controller: _vehicule, hint: 'Toyota Corolla', label: 'Marque et modèle'),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Etiq('Plaque'),
                const SizedBox(height: 8),
                Champ(controller: _plaque, hint: '11 HH 2345', label: 'Plaque'),
              ],
            ),
            const Doux('Une nouvelle plaque est vérifiée par l’équipe avec la carte grise.'),
          ],
          bas: [Btn('Enregistrer', onPressed: _enregistrer)],
        ),
      ],
    );
  }
}

/// « Mes documents » : où en est chaque document.
class MesDocumentsEcran extends StatelessWidget {
  const MesDocumentsEcran({super.key});

  static const _icones = {
    'CNIB': Icons.badge_outlined,
    'Selfie avec la CNIB': Icons.face_outlined,
    'Permis de conduire': Icons.credit_card_rounded,
    'Carte grise': Icons.description_outlined,
    'Assurance': Icons.verified_user_outlined,
    'Photo du véhicule': Icons.directions_car_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final valide = s.etapeConducteur == EtapeConducteur.valide || s.estConducteur;
    final alertes = {for (final a in s.alertesDocuments) a.doc: a};
    return Ecran(
      fond: C.surface,
      children: [
        const Barre(titre: 'Mes documents'),
        Zone(
          gap: 12,
          children: [
            for (final e in documentsConducteur.entries)
              Builder(
                builder: (context) {
                  final envoye = s.documentsEnvoyes.contains(e.key);
                  final alerte = alertes[e.key];
                  final (texte, ton, icone) = alerte != null
                      ? (alerte.bloquant ? 'Expiré' : 'À renouveler', TonPastille.sos, Icons.warning_amber_rounded)
                      : valide && envoye
                      ? ('Vérifié', TonPastille.vert, Icons.check_rounded)
                      : envoye
                      ? ('En vérification', TonPastille.etoile, Icons.schedule_rounded)
                      : ('Non renseigné', TonPastille.etoile, Icons.error_outline_rounded);
                  return Carte(
                    onTap: alerte != null ? () => ouvrir(context, MajDocumentEcran(doc: e.key)) : null,
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(color: C.lateriteC, borderRadius: BorderRadius.circular(12)),
                          child: Icon(_icones[e.key] ?? Icons.description_outlined, color: C.lateriteF),
                        ),
                        const SizedBox(width: 12),
                        Bloc(e.key, e.value),
                        Pastille(texte, ton: ton, icon: icone),
                      ],
                    ),
                  );
                },
              ),
          ],
          bas: [
            if (s.etapeConducteur == EtapeConducteur.aucune)
              Btn('Compléter mon dossier', onPressed: () => ouvrir(context, const DocumentsEcran()))
            else if (s.etapeConducteur == EtapeConducteur.documentsEnvoyes)
              Btn('Suivre ma validation', onPressed: () => ouvrir(context, const ValidationEcran())),
            const Doux(
              'Vos documents restent privés : seule l’équipe de validation les voit.',
              align: TextAlign.center,
            ),
          ],
        ),
      ],
    );
  }
}

/// Fiche « Mode conducteur » : ce qu'est le covoiturage. « J’ai compris »
/// appelle [onCompris] (le passage dans l'espace conducteur).
class IntroConducteurEcran extends StatelessWidget {
  const IntroConducteurEcran({super.key, this.onCompris});
  final void Function(BuildContext context)? onCompris;

  @override
  Widget build(BuildContext context) {
    Widget point(IconData i, String texte) => Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(i, size: 26),
          const SizedBox(width: 16),
          Expanded(
            child: Text(texte, style: const TextStyle(fontSize: 16, height: 1.4, color: C.doux)),
          ),
        ],
      ),
    );
    return Scaffold(
      backgroundColor: C.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconeBtn(
                icon: Icons.close_rounded,
                label: 'Fermer',
                taille: 28,
                onTap: () => Navigator.maybePop(context),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                children: [
                  Text('Mode conducteur', textAlign: TextAlign.center, style: T.titre(24)),
                  const SizedBox(height: 12),
                  SizedBox(height: 150, child: CustomPaint(painter: IllustrationClesPainter())),
                  const SizedBox(height: 16),
                  Text(
                    'En tant que conducteur, vous proposez vos trajets de tous les jours pour partager vos frais et rendre service.',
                    style: T.titre(19).copyWith(height: 1.2),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Sur FasoCovoit, les prix sont plafonnés : vous partagez vos frais, vous ne faites pas de bénéfice.',
                    style: TextStyle(fontSize: 16, height: 1.4),
                  ),
                  const SizedBox(height: 18),
                  const Text('Le covoiturage, c’est :', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  point(
                    Icons.directions_car_filled_rounded,
                    'Une voiture partagée entre son conducteur et ses passagers.',
                  ),
                  point(
                    Icons.payments_rounded,
                    'Un trajet sans bénéfice : seuls les frais d’essence et d’usure sont partagés.',
                  ),
                  point(Icons.route_rounded, 'Un trajet que le conducteur fait de toute façon, pour lui-même.'),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Btn(
                'J’ai compris',
                onPressed: () {
                  AppScope.read(context).vuIntroConducteur();
                  final suite = onCompris;
                  suite == null ? Navigator.maybePop(context) : suite(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
