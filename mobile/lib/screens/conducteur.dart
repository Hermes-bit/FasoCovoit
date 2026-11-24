import 'dart:async';

import 'package:flutter/material.dart';

import '../appel.dart';
import '../carte.dart';
import '../formats.dart';
import '../model.dart';
import '../painters.dart';
import '../photo.dart';
import '../theme.dart';
import '../ui.dart';
import 'colis.dart';
import 'devenir.dart';
import 'jour_j.dart';
import 'lieux.dart';
import 'messages_profil.dart';
import 'passager.dart';
import 'portefeuille.dart';

TrajetPublie? prochainTrajet(AppState s) {
  final actifs = s.trajetsPublies
      .where((t) => t.statut == StatutPublie.publie || t.statut == StatutPublie.enCours)
      .toList()
    ..sort((a, b) => a.depart.compareTo(b.depart));
  return actifs.isEmpty ? null : actifs.first;
}

String _quand(TrajetPublie t, DateTime maintenant) =>
    '${jourRelatif(t.depart, maintenant)} · ${heure(t.depart)}';

/// Espace conducteur : navigation du bas à quatre onglets.
class EspaceConducteur extends StatelessWidget {
  const EspaceConducteur({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final index = s.onglet.clamp(0, 3);
    final demandes = s.trajetsPublies
        .where((t) => t.statut == StatutPublie.publie)
        .fold(0, (n, t) => n + t.enAttente.length);
    return Scaffold(
      backgroundColor: C.sable,
      body: IndexedStack(
        index: index,
        children: const [ConducteurAccueilOnglet(), DemandesEcran(), GainsOnglet(), ProfilConducteurOnglet()],
      ),
      bottomNavigationBar: NavBas(
        index: index,
        onTap: s.allerOnglet,
        items: [
          // Badge : courses possibles sur la route du conducteur.
          NavItem(Icons.directions_car_outlined, 'Mes trajets', badge: s.coursesPossibles.length),
          NavItem(Icons.notifications_none_rounded, 'Demandes', badge: demandes),
          const NavItem(Icons.account_balance_wallet_outlined, 'Gains'),
          const NavItem(Icons.person_outline_rounded, 'Profil'),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 25 · Mes trajets publiés
// ---------------------------------------------------------------------------

class ConducteurAccueilOnglet extends StatelessWidget {
  const ConducteurAccueilOnglet({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final actifs = s.trajetsPublies
        .where((t) => t.statut == StatutPublie.publie || t.statut == StatutPublie.enCours)
        .toList()
      ..sort((a, b) => a.depart.compareTo(b.depart));
    final moisTotal = s.gainsDuMois.fold(0, (n, g) => n + g.total);
    final courses = s.coursesPossibles;
    final autres = s.passagersSansCourse;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Piste(
          couleur: C.encre,
          paddingBas: 30,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.femme ? 'Mode conductrice' : 'Mode conducteur',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: C.etoile),
                      ),
                      Titre('Bonjour ${s.prenom}'),
                    ],
                  ),
                ),
                const BasculeMode(conducteur: true),
              ],
            ),
          ],
        ),
        Zone(
          gap: 14,
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
          children: [
            if (s.suspendu)
              Bandeau(
                'Compte suspendu jusqu’au ${jourCourt(s.suspenduJusquau!)} après 3 annulations en 30 jours.',
                icon: Icons.block_rounded,
                ton: TonPastille.sos,
              ),
            if (s.abonnement?.arrete == true)
              Bandeau(
                'Abonnement arrêté : vous publiez jusqu’au ${dateCourte(s.abonnement!.prochainPaiement)}.',
                icon: Icons.info_outline_rounded,
                ton: TonPastille.etoile,
              ),
            // Documents qui expirent : rappel, puis blocage une fois expirés.
            for (final a in s.alertesDocuments)
              Carte(
                couleur: a.bloquant ? C.sosC : C.etoileC,
                bord: a.bloquant ? C.sosBord : C.etoile,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(a.bloquant ? Icons.block_rounded : Icons.event_busy_outlined, size: 22),
                        const SizedBox(width: 12),
                        Expanded(child: Text(a.texte, style: T.petit)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    BtnClair(
                      a.doc == 'Assurance' ? 'Envoyer ma nouvelle assurance' : 'Envoyer ma nouvelle CNIB',
                      icon: Icons.photo_camera_outlined,
                      onPressed: () => ouvrir(context, MajDocumentEcran(doc: a.doc)),
                    ),
                  ],
                ),
              ),
            if (!s.estConducteur)
              const _ActivationConducteur()
            else
              Btn.lat('Publier un trajet', icon: Icons.add_rounded, onPressed: () => ouvrir(context, const PublierEcran())),
            if (courses.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.notifications_active_outlined, color: C.lateriteF, size: 20),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      courses.length > 1
                          ? '${courses.length} courses possibles sur votre route'
                          : 'Course possible sur votre route',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: C.lateriteF),
                    ),
                  ),
                ],
              ),
              for (final c in courses) _AlerteCourse(c),
            ],
            if (s.estConducteur && actifs.isEmpty)
              const Carte(
                child: Text(
                  'Aucun trajet publié. Publiez votre premier trajet : les passagers le verront tout de suite.',
                  style: T.petit,
                ),
              )
            else if (actifs.isNotEmpty) ...[
              const Doux('À venir', taille: 14, gras: true),
              for (final t in actifs) _CarteTrajetPublie(t),
            ],
            if (autres.isNotEmpty) ...[
              Doux('Passagers inscrits qui cherchent un trajet · ${autres.length}', taille: 14, gras: true),
              for (final d in autres) _CartePassagerInscrit(d),
            ],
            Carte(
              pointillee: true,
              bord: C.laterite,
              onTap: () => ouvrir(context, const ColisConducteurEcran()),
              child: const Row(
                children: [
                  Icon(Icons.inventory_2_outlined, color: C.laterite, size: 24),
                  SizedBox(width: 12),
                  Bloc('Colis sur vos trajets', 'Bientôt : gagnez plus en transportant des colis'),
                  Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
            Carte(
              onTap: () => s.allerOnglet(2),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet_outlined, color: C.vert, size: 26),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Doux('Ce mois-ci'),
                        Text('${fcfa(moisTotal)} de frais partagés', style: T.gras),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CarteTrajetPublie extends StatelessWidget {
  const _CarteTrajetPublie(this.t);
  final TrajetPublie t;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final l = t.ligne;
    final attente = t.enAttente.length;
    final contenu = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (t.statut == StatutPublie.enCours)
              const Pastille('En cours', ton: TonPastille.vert, icon: Icons.directions_car_outlined)
            else if (attente > 0)
              Pastille(
                attente > 1 ? '$attente demandes à traiter' : '1 demande à traiter',
                ton: TonPastille.etoile,
                icon: Icons.notifications_none_rounded,
              )
            else if (t.reservees >= t.places)
              const Pastille('Complet', ton: TonPastille.vert)
            else
              const Pastille('Publié'),
            const Spacer(),
            Doux(jourRelatif(t.depart, s.maintenant), gras: true),
          ],
        ),
        const SizedBox(height: 12),
        RouteRail(
          haut: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${heure(t.depart)} · ${l.interVilles ? l.depart.ville : l.depart.quartier}', style: T.gras),
              Doux(capitaliser(l.interVilles ? l.depart.quartier : t.rdv)),
            ],
          ),
          bas: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${heure(t.depart.add(l.duree))} · ${l.interVilles ? l.arrivee.ville : l.arrivee.quartier}',
                style: T.gras,
              ),
              Doux(capitaliser(l.interVilles ? l.arrivee.quartier : l.arrivee.ville)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Sep(),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: T.petit,
                  children: [
                    TextSpan(
                      text: '${pluriel(t.reservees, 'place')} réservée${t.reservees > 1 ? 's' : ''}',
                      style: T.gras,
                    ),
                    TextSpan(text: ' sur ${t.places}'),
                  ],
                ),
              ),
            ),
            Text('${fcfa(t.prix)} / place', style: T.gras),
          ],
        ),
        if (t.regulier) ...[
          const SizedBox(height: 8),
          Pastille('Trajet régulier · ${_jours(t.jours)}', icon: Icons.sync_rounded),
        ],
        if (t.exemple) ...[
          const SizedBox(height: 8),
          const Doux('Prototype : les demandes de ce premier trajet sont fictives.'),
        ],
      ],
    );
    void ouvrirT() => ouvrir(
      context,
      t.statut == StatutPublie.enCours ? EnRouteConducteurEcran(trajet: t) : DemandesEcran(trajet: t),
    );
    return attente > 0 ? Carte.sel(onTap: ouvrirT, child: contenu) : Carte(onTap: ouvrirT, child: contenu);
  }
}

String _lieuCourt(Lieu l) => '${capitaliser(l.quartier)} (${villeCourte(l.ville)})';

/// Alerte : un passager inscrit attend sur la route d'un trajet du
/// conducteur, vers l'heure où il y passe. Le conducteur choisit.
class _AlerteCourse extends StatelessWidget {
  const _AlerteCourse(this.c);
  final CoursePossible c;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final d = c.demande, t = c.trajet;
    return Carte(
      couleur: C.etoileC,
      bord: C.etoile,
      epaisseur: 2.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Ava(d.passager.initiales, ton: d.passager.ton),
              const SizedBox(width: 12),
              Bloc(
                d.passager.court,
                'Veut partir ${jourRelatif(d.quand, s.maintenant).toLowerCase()} à ${heure(d.quand)} · ${pluriel(d.places, 'place')}',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('${_lieuCourt(d.depart)} → ${_lieuCourt(d.arrivee)}', style: T.gras),
          const SizedBox(height: 6),
          Text(
            '${t.statut == StatutPublie.enCours ? 'Sur votre trajet en cours' : 'Sur votre trajet de ${heure(t.depart)}'} : '
            'vous passez vers ${heure(c.passage)} (${ecartHoraire(c.ecart)}), '
            'montée ${ecartTexte(c.croisement.monte)}, dépose ${ecartTexte(c.croisement.descend)}.',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: C.vertF),
          ),
          if (d.exemple) ...[
            const SizedBox(height: 6),
            const Doux('Prototype : passager fictif.'),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: BtnClair('Ignorer', onPressed: () => s.ignorerCourse(c))),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Btn(
                  'Prendre la course',
                  hauteur: 52,
                  taille: 15,
                  onPressed: () {
                    if (essayer(context, () => s.prendreCourse(c))) {
                      message(
                        context,
                        'Course acceptée : ${d.passager.court} vous attend à ${capitaliser(d.depart.quartier)} vers ${heure(c.passage)}.',
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Passager inscrit qu'aucun trajet du conducteur ne croise encore : le
/// conducteur accepte sa course en publiant le trajet, à son heure.
class _CartePassagerInscrit extends StatelessWidget {
  const _CartePassagerInscrit(this.d);
  final DemandeTrajet d;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return Carte(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Ava(d.passager.initiales, ton: d.passager.ton),
              const SizedBox(width: 12),
              Bloc(
                d.passager.court,
                '${jourRelatif(d.quand, s.maintenant)} à ${heure(d.quand)} · ${pluriel(d.places, 'place')}',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('${_lieuCourt(d.depart)} → ${_lieuCourt(d.arrivee)}', style: T.gras),
          const SizedBox(height: 6),
          const Doux('Aucun de vos trajets ne passe par là à cette heure.'),
          const SizedBox(height: 10),
          BtnClair(
            'Accepter la course',
            icon: Icons.add_rounded,
            onPressed: () => s.estConducteur
                ? ouvrir(context, PublierEcran(demande: d))
                : informer(
                    context,
                    'Compte conducteur à activer',
                    'Pour accepter la course de ${d.passager.court}, finissez votre inscription : documents, validation par l’équipe, abonnement.',
                  ),
          ),
        ],
      ),
    );
  }
}

/// Espace conducteur avant l'activation : où en est l'inscription.
class _ActivationConducteur extends StatelessWidget {
  const _ActivationConducteur();

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

/// Où le passager monte et descend, par rapport à la route du conducteur.
class _AdressesPassager extends StatelessWidget {
  const _AdressesPassager(this.t, this.p);
  final TrajetPublie t;
  final Passager p;

  @override
  Widget build(BuildContext context) {
    final m = p.montee, d = p.descente;
    if (m == null || d == null) return const SizedBox.shrink();
    final c = correspondance(t.ligne.depart, t.ligne.arrivee, m, d);
    Widget ligne(IconData i, Color couleur, String texte) => Row(
      children: [
        Icon(i, size: 16, color: couleur),
        const SizedBox(width: 6),
        Expanded(child: Text(texte, style: T.petit)),
      ],
    );
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          ligne(Icons.trip_origin_rounded, C.vert, 'Monte : ${m.complet}${c == null ? '' : ' · ${ecartTexte(c.monte)}'}'),
          const SizedBox(height: 4),
          ligne(Icons.flag_outlined, C.laterite, 'Descend : ${d.complet}${c == null ? '' : ' · ${ecartTexte(c.descend)}'}'),
        ],
      ),
    );
  }
}

const _lettresJours = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
const _nomsJours = ['lun.', 'mar.', 'mer.', 'jeu.', 'ven.', 'sam.', 'dim.'];

String _jours(Set<int> j) {
  if (j.length == 5 && j.containsAll({0, 1, 2, 3, 4})) return 'lun. au ven.';
  if (j.length == 7) return 'tous les jours';
  return (j.toList()..sort()).map((i) => _nomsJours[i]).join(', ');
}

// ---------------------------------------------------------------------------
// 26 · Publier (B1, B2, B8, B10)
// ---------------------------------------------------------------------------

class PublierEcran extends StatefulWidget {
  const PublierEcran({super.key, this.depart, this.arrivee, this.quand, this.demande});

  /// Pré-remplissage.
  final Lieu? depart;
  final Lieu? arrivee;
  final DateTime? quand;

  /// Course acceptée : le trajet part de l'adresse du passager, à son heure,
  /// et le passager y est ajouté à la publication.
  final DemandeTrajet? demande;

  @override
  State<PublierEcran> createState() => _PublierEcranState();
}

class _PublierEcranState extends State<PublierEcran> {
  Lieu _lieuDepart = lOuagaGare;
  Lieu? _lieuArrivee;
  final _rdv = TextEditingController(text: lOuagaGare.rdv);
  late DateTime _date;
  TimeOfDay _heure = const TimeOfDay(hour: 7, minute: 0);
  int _places = 3;
  late int _prix;
  bool _auto = false;
  bool _regulier = false;
  final Set<int> _joursChoisis = {0, 1, 2, 3, 4};
  bool _femmes = false;
  bool _especes = true;
  bool _mobile = true;

  @override
  void initState() {
    super.initState();
    final n = AppScope.read(context).maintenant;
    _date = jour(n).add(const Duration(days: 2));
    _prix = 0;
    final dem = widget.demande;
    final q = widget.quand ?? dem?.quand;
    if (q != null) {
      _date = jour(q);
      _heure = TimeOfDay(hour: q.hour, minute: q.minute);
    }
    final dep = widget.depart ?? dem?.depart;
    if (dep != null) {
      _lieuDepart = dep;
      _rdv.text = dep.rdv ?? '';
    }
    _lieuArrivee = widget.arrivee ?? dem?.arrivee;
    if (dem != null && dem.places > _places) _places = dem.places.clamp(1, 4);
    final l = _ligne;
    if (l != null) _prix = calculerTarif(l).conseille;
  }

  @override
  void dispose() {
    _rdv.dispose();
    super.dispose();
  }

  DateTime get _depart => DateTime(_date.year, _date.month, _date.day, _heure.hour, _heure.minute);

  /// Le trajet n'existe qu'une fois la destination choisie.
  Ligne? get _ligne => _lieuArrivee == null ? null : Ligne.entre(_lieuDepart, _lieuArrivee!);

  void _majTrajet({Lieu? depart, Lieu? arrivee}) {
    setState(() {
      if (depart != null) {
        _lieuDepart = depart;
        _rdv.text = depart.rdv ?? '';
      }
      if (arrivee != null) _lieuArrivee = arrivee;
      final l = _ligne;
      if (l != null) _prix = calculerTarif(l).conseille;
    });
  }

  Future<void> _choisirDepart() async {
    final l = await choisirLieu(context, titre: "D'où partez-vous ?", actuel: _lieuDepart, exclu: _lieuArrivee);
    if (l != null) _majTrajet(depart: l);
  }

  Future<void> _choisirArrivee() async {
    final l = await choisirLieu(context, titre: 'Où allez-vous ?', actuel: _lieuArrivee, exclu: _lieuDepart);
    if (l != null) _majTrajet(arrivee: l);
  }

  void _inverser() {
    final a = _lieuArrivee;
    if (a == null) return;
    _lieuArrivee = _lieuDepart;
    _majTrajet(depart: a);
  }

  Future<void> _choisirDate() async {
    final n = AppScope.read(context).maintenant;
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: jour(n),
      lastDate: jour(n).add(const Duration(days: 60)),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _choisirHeure() async {
    final h = await showTimePicker(context: context, initialTime: _heure);
    if (h != null) setState(() => _heure = h);
  }

  void _publier() {
    final s = AppScope.read(context);
    final ligne = _ligne;
    if (ligne == null) {
      message(context, 'Choisissez votre destination.');
      return;
    }
    TrajetPublie? t;
    final ok = essayer(context, () {
      t = s.publier(
        ligne: ligne,
        rdv: _rdv.text,
        depart: _depart,
        places: _places,
        prix: _prix,
        accepteAuto: _auto,
        regulier: _regulier,
        jours: _regulier ? {..._joursChoisis} : const {},
        entreFemmes: _femmes,
        especes: _especes,
        mobile: _mobile,
      );
    });
    if (!ok) return;
    final publie = t!;
    // Course acceptée depuis la demande d'un passager : il est ajouté au
    // trajet si celui-ci passe toujours chez lui, à son heure.
    final dem = widget.demande;
    String? course;
    if (dem != null) {
      final c = s.coursePour(dem, publie);
      if (c != null && essayer(context, () => s.prendreCourse(c))) {
        course = 'Course acceptée : ${dem.passager.court} vous attend à ${capitaliser(dem.depart.quartier)} à ${heure(c.passage)}.';
      } else {
        course = "Trajet publié, mais il ne passe plus chez ${dem.passager.court} à son heure : sa demande reste visible.";
      }
    }
    final alertes = s.coursesPour(publie).length;
    s.allerOnglet(0);
    Navigator.pop(context);
    message(
      context,
      course ??
          (alertes > 0
              ? 'Trajet publié. ${alertes > 1 ? '$alertes passagers attendent' : 'Un passager attend'} sur votre route : voir l’alerte.'
              : publie.exemple
              ? 'Trajet publié. Des demandes fictives arrivent pour la démonstration.'
              : 'Trajet publié.'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final ligne = _ligne;
    return Ecran(
      children: [
        Barre(
          titre: widget.demande == null ? 'Publier un trajet' : 'Accepter la course',
          sousTitre: widget.demande?.passager.court,
        ),
        Zone(
          gap: 14,
          children: [
            if (widget.demande != null)
              Bandeau(
                '${widget.demande!.passager.court} veut partir ${jourRelatif(widget.demande!.quand, s.maintenant).toLowerCase()} '
                'à ${heure(widget.demande!.quand)} de ${capitaliser(widget.demande!.depart.quartier)}. '
                'Le trajet part de son adresse à son heure : vous pouvez changer votre départ, '
                'tant que vous passez chez ${widget.demande!.passager.prenom} à peu près à cette heure.',
                icon: Icons.notifications_active_outlined,
                ton: TonPastille.etoile,
              ),
            Carte(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: RouteRail(
                          gap: 12,
                          haut: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ChampLieu(
                                label: "D'où partez-vous ?",
                                valeur: _lieuDepart,
                                indication: 'Choisir le départ',
                                onTap: _choisirDepart,
                              ),
                              const SizedBox(height: 12),
                              const Sep(),
                            ],
                          ),
                          bas: ChampLieu(
                            label: 'Destination',
                            valeur: _lieuArrivee,
                            indication: 'Où allez-vous ?',
                            onTap: _choisirArrivee,
                          ),
                        ),
                      ),
                      if (_lieuArrivee != null)
                        IconeBtn(
                          icon: Icons.swap_vert_rounded,
                          label: 'Inverser départ et destination',
                          onTap: _inverser,
                        ),
                    ],
                  ),
                  if (ligne != null) ...[
                    const SizedBox(height: 12),
                    const Sep(),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.route_outlined, size: 20, color: C.doux),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Doux(
                            '${ligne.km} km · environ ${duree(ligne.duree)} · ${ligne.interVilles ? 'entre villes' : 'en ville'}',
                            taille: 14,
                            gras: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (_lieuArrivee == null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Doux('Trajets fréquents', taille: 14, gras: true),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final l in lignes)
                        Puce(l.titre, on: false, onTap: () => _majTrajet(depart: l.depart, arrivee: l.arrivee)),
                    ],
                  ),
                ],
              ),
            if (ligne != null && googleMapsDisponible)
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  height: 180,
                  child: CarteRoute(
                    depart: _lieuDepart,
                    arrivee: _lieuArrivee!,
                    interactive: false,
                    margeHaut: 28,
                    margeBas: 28,
                  ),
                ),
              ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Etiq('Point de rendez-vous'),
                const SizedBox(height: 8),
                Champ(controller: _rdv, hint: "Ex. : devant l'entrée principale", label: 'Point de rendez-vous'),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Carte(
                    onTap: _choisirDate,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [const Doux('Date'), Text(capitaliser(jourCourt(_date)), style: T.gras)],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Carte(
                    onTap: _choisirHeure,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [const Doux('Heure'), Text(heure(_depart), style: T.gras)],
                    ),
                  ),
                ),
              ],
            ),
            Carte(
              child: Row(
                children: [
                  const Expanded(child: Text('Places proposées', style: T.gras)),
                  Compteur(
                    valeur: _places,
                    onMoins: _places > 1 ? () => setState(() => _places--) : null,
                    onPlus: _places < 4 ? () => setState(() => _places++) : null,
                  ),
                ],
              ),
            ),
            if (ligne == null)
              const Carte(
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 22),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Choisissez votre destination : le prix conseillé et le plafond se calculent selon la distance.',
                        style: T.petit,
                      ),
                    ),
                  ],
                ),
              )
            else
              _CartePrix(
                ligne: ligne,
                prix: _prix,
                places: _places,
                onPrix: (p) => setState(() => _prix = p),
              ),
            LigneCase(
              value: _auto,
              onChanged: (v) => setState(() => _auto = v),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [Text('Accepter automatiquement', style: T.gras), Doux('Sinon, 30 min pour répondre')],
              ),
            ),
            Carte(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () => setState(() => _regulier = !_regulier),
                    child: Row(
                      children: [
                        const Bloc('Trajet régulier', 'Republié chaque semaine'),
                        Case(value: _regulier, onChanged: (v) => setState(() => _regulier = v)),
                      ],
                    ),
                  ),
                  if (_regulier) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (var i = 0; i < 7; i++)
                          Semantics(
                            label: _nomsJours[i],
                            selected: _joursChoisis.contains(i),
                            child: Pastille(
                              _lettresJours[i],
                              ton: _joursChoisis.contains(i) ? TonPastille.lat : TonPastille.neutre,
                              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                              onTap: () => setState(
                                () => _joursChoisis.contains(i) ? _joursChoisis.remove(i) : _joursChoisis.add(i),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (s.femme)
              LigneCase(
                value: _femmes,
                onChanged: (v) => setState(() => _femmes = v),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [Text('Entre femmes', style: T.gras), Doux('Visible seulement par des passagères')],
                ),
              ),
            Carte(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Paiements acceptés', style: T.gras),
                  const SizedBox(height: 8),
                  LigneCase(
                    carte: false,
                    value: _especes,
                    onChanged: (v) => setState(() => _especes = v),
                    child: const Padding(padding: EdgeInsets.only(top: 4), child: Text('Espèces')),
                  ),
                  const SizedBox(height: 8),
                  LigneCase(
                    carte: false,
                    value: _mobile,
                    onChanged: (v) => setState(() => _mobile = v),
                    child: const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text('Portefeuille, Orange Money et Moov Money'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Pied(child: Btn('Publier le trajet', onPressed: ligne == null ? null : _publier)),
      ],
    );
  }
}

class _CartePrix extends StatelessWidget {
  const _CartePrix({required this.ligne, required this.prix, required this.places, required this.onPrix});
  final Ligne ligne;
  final int prix;
  final int places;
  final ValueChanged<int> onPrix;

  @override
  Widget build(BuildContext context) {
    final tarif = calculerTarif(ligne);
    final divisions = ((tarif.plafond - tarif.plancher) / tarif.pas).round();
    final valeur = tarif.borner(prix);
    final connue = lignes.any((l) => l.interVilles && l.depart.ville == ligne.depart.ville && l.arrivee.ville == ligne.arrivee.ville);
    return Carte(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Expanded(child: Text('Prix par place', style: T.gras)),
              Titre(fcfa(valeur)),
            ],
          ),
          Slider(
            value: valeur.toDouble(),
            min: tarif.plancher.toDouble(),
            max: tarif.plafond.toDouble(),
            divisions: divisions > 0 ? divisions : null,
            label: fcfa(valeur),
            onChanged: (v) => onPrix(tarif.borner(v.round())),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Pastille('Conseillé ${fcfa(tarif.conseille)}', ton: TonPastille.vert),
              Pastille('Plafond ${fcfa(tarif.plafond)}', ton: TonPastille.lat),
            ],
          ),
          const SizedBox(height: 8),
          Doux(
            !ligne.interVilles
                ? 'En ville, le prix reste sous le coût d’un VTC (environ ${fcfa(ligne.km * 200)}). Plancher : ${fcfa(tarif.plancher)}.'
                : connue && ligne.car > 0
                ? 'Le car coûte environ ${fcfa(ligne.car)} sur cette ligne. Plancher : ${fcfa(tarif.plancher)}.'
                : 'Pas de tarif de car connu sur ce trajet : prix calculé sur les frais d’essence. Plancher : ${fcfa(tarif.plancher)}.',
          ),
          const SizedBox(height: 8),
          Text(
            'Vous partagez ${fcfa(places * valeur)} de frais si la voiture est pleine.',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: C.vertF),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 27 · Demandes (B6)
// ---------------------------------------------------------------------------

class DemandesEcran extends StatelessWidget {
  const DemandesEcran({super.key, this.trajet});

  /// Nul : onglet « Demandes », qui affiche le prochain trajet.
  final TrajetPublie? trajet;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final t = trajet ?? prochainTrajet(s);
    if (t == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Piste(couleur: C.encre, paddingBas: 30, children: [Titre('Demandes')]),
          Zone(
            children: [
              const Carte(child: Text('Aucun trajet à venir : publiez un trajet pour recevoir des demandes.', style: T.petit)),
              Btn.lat('Publier un trajet', icon: Icons.add_rounded, onPressed: () => ouvrir(context, const PublierEcran())),
            ],
          ),
        ],
      );
    }
    final enCours = t.statut == StatutPublie.enCours;
    final corps = <Widget>[
      Piste(
        couleur: C.encre,
        paddingBas: 30,
        retour: trajet != null,
        children: [
          Text(_quand(t, s.maintenant), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: C.etoile)),
          Titre(t.ligne.titre),
          Text('${pluriel(t.reservees, 'place')} réservée${t.reservees > 1 ? 's' : ''} sur ${t.places}', style: T.petit),
        ],
      ),
      Zone(
        gap: 12,
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
        children: [
          for (final p in t.enAttente) _CarteDemande(t, p),
          const Doux('Passagers confirmés', taille: 14, gras: true),
          if (t.confirmes.isEmpty)
            const Carte(child: Text('Aucun passager confirmé pour l’instant.', style: T.petit))
          else
            ListeCarte(
              children: [
                for (final p in t.confirmes)
                  LigneListe(
                    children: [
                      Ava(p.personne.initiales, ton: p.personne.ton),
                      Bloc(
                        p.personne.court,
                        '${pluriel(p.places, 'place')} · ${p.paiement == Paiement.especes ? 'espèces au départ' : 'payé par ${p.paiement.label}'}'
                        '${p.montee == null || p.descente == null ? '' : '\nMonte : ${capitaliser(p.montee!.quartier)} · descend : ${capitaliser(p.descente!.quartier)}'}',
                      ),
                      IconeBtn(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: 'Écrire à ${p.personne.prenom}',
                        taille: 20,
                        onTap: () {
                          final conv = s.ouvrirConversation(p.personne, '${t.ligne.titre} · ${_quand(t, s.maintenant).toLowerCase()}');
                          ouvrir(context, ConversationEcran(conversation: conv));
                        },
                      ),
                    ],
                  ),
              ],
            ),
        ],
        bas: [
          if (enCours)
            Btn('Voir le trajet en cours', onPressed: () => ouvrir(context, EnRouteConducteurEcran(trajet: t)))
          else ...[
            Btn(
              'Je suis au point de départ',
              onPressed: t.confirmes.isEmpty ? null : () => ouvrir(context, DepartEcran(trajet: t)),
            ),
            Lien(
              'Annuler ce trajet',
              couleur: C.sos,
              souligne: false,
              onTap: () => ouvrir(context, AnnulerTrajetEcran(trajet: t)),
            ),
          ],
        ],
      ),
    ];
    if (trajet == null) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: corps);
    }
    return Ecran(children: corps);
  }
}

class _CarteDemande extends StatelessWidget {
  const _CarteDemande(this.t, this.p);
  final TrajetPublie t;
  final Passager p;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final restant = p.recueLe.add(Reservation.delaiReponse).difference(s.maintenant).inMinutes.clamp(0, 30);
    return Carte(
      bord: C.etoile,
      epaisseur: 2.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(child: Text('Nouvelle demande', style: T.gras)),
              Pastille('$restant min pour répondre', ton: TonPastille.etoile, icon: Icons.schedule_rounded),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Ava(p.personne.initiales, ton: p.personne.ton),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.personne.court, style: T.gras),
                    LigneNote(
                      note: p.note,
                      suite: ' · ${p.trajets} trajets · ${p.paiement == Paiement.especes ? 'paiera en espèces' : 'payé par ${p.paiement.label}'}',
                    ),
                  ],
                ),
              ),
            ],
          ),
          _AdressesPassager(t, p),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: BtnClair('Refuser', onPressed: () => s.repondre(t, p, accepter: false)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Btn(
                  'Accepter',
                  hauteur: 52,
                  onPressed: () => essayer(context, () => s.repondre(t, p, accepter: true)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 28 · Code de départ (B9)
// ---------------------------------------------------------------------------

class DepartEcran extends StatefulWidget {
  const DepartEcran({super.key, required this.trajet});
  final TrajetPublie trajet;

  @override
  State<DepartEcran> createState() => _DepartEcranState();
}

class _DepartEcranState extends State<DepartEcran> {
  final Map<Passager, TextEditingController> _codes = {};

  TextEditingController _ctrl(Passager p) => _codes.putIfAbsent(p, TextEditingController.new);

  @override
  void dispose() {
    for (final c in _codes.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _verifier(Passager p, String code) {
    final s = AppScope.read(context);
    if (p.aBord) return;
    if (s.validerCode(p, code)) {
      message(context, '${p.personne.court} est à bord.');
    } else {
      message(context, 'Code incorrect. Redemandez-le à ${p.personne.prenom}.');
      final c = _ctrl(p);
      scheduleMicrotask(c.clear);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final t = widget.trajet;
    final ouverture = t.depart.add(const Duration(minutes: 10));
    final absencePossible = s.absencePossible(t);
    final restant = ouverture.difference(s.maintenant);
    final quandAbsent = restant.inMinutes < 60
        ? 'dans ${restant.inMinutes.clamp(1, 60)} min'
        : 'à partir de ${heure(ouverture)}${ecartJours(ouverture, s.maintenant) == 0 ? '' : ' (${jourRelatif(ouverture, s.maintenant).toLowerCase()})'}';
    final absents = t.confirmes.where((p) => !p.aBord && !p.absent).toList();
    return Ecran(
      children: [
        Barre(
          titre: 'Départ · ${t.ligne.depart.quartier}',
          sousTitre: 'Scannez le QR ou saisissez le code de chaque passager',
        ),
        Zone(
          gap: 14,
          children: [
            Btn.lat(
              'Scanner le QR du passager',
              icon: Icons.photo_camera_outlined,
              onPressed: absents.isEmpty ? null : () => ouvrir(context, ScannerQrEcran(trajet: t)),
            ),
            for (final p in t.confirmes)
              if (p.aBord || p.absent)
                Carte(
                  child: Row(
                    children: [
                      Ava(p.personne.initiales, ton: p.personne.ton),
                      const SizedBox(width: 12),
                      Bloc(
                        p.personne.court,
                        p.paiement == Paiement.especes
                            ? 'Espèces : ${fcfa(p.montant)} à encaisser'
                            : 'Payé par ${p.paiement.label}',
                      ),
                      p.absent
                          ? const Pastille('Absent', ton: TonPastille.sos)
                          : const Pastille('À bord', ton: TonPastille.vert, icon: Icons.check_rounded),
                    ],
                  ),
                )
              else
                Carte(
                  bord: C.vert,
                  epaisseur: 2.5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Ava(p.personne.initiales, ton: p.personne.ton),
                          const SizedBox(width: 12),
                          Bloc(
                            p.personne.court,
                            p.paiement == Paiement.especes
                                ? 'Espèces : ${fcfa(p.montant)} à encaisser'
                                : 'Payé par ${p.paiement.label}',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Etiq('Ou le code donné par ${p.personne.prenom}'),
                      const SizedBox(height: 8),
                      CodeCases(
                        controller: _ctrl(p),
                        longueur: 4,
                        hauteur: 64,
                        taille: 28,
                        label: 'Code de ${p.personne.prenom}',
                        onComplet: (code) => _verifier(p, code),
                      ),
                      const SizedBox(height: 8),
                      Doux('Prototype : le code de ${p.personne.prenom} est ${p.code}.'),
                    ],
                  ),
                ),
            Carte(
              child: Row(
                children: [
                  const Icon(Icons.schedule_rounded, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      absencePossible
                          ? '« Passager absent » est maintenant possible.'
                          : "« Passager absent » possible après 10 min d'attente, $quandAbsent.",
                      style: T.petit,
                    ),
                  ),
                ],
              ),
            ),
          ],
          bas: [
            Btn(
              'Démarrer le trajet',
              onPressed: t.toutLeMondeABord
                  ? () {
                      if (essayer(context, () => s.demarrerTrajet(t))) {
                        remplacer(context, EnRouteConducteurEcran(trajet: t));
                      }
                    }
                  : null,
            ),
            BtnClair(
              'Passager absent',
              onPressed: absencePossible && absents.isNotEmpty
                  ? () async {
                      final p = absents.first;
                      final ok = await confirmer(
                        context,
                        titre: '${p.personne.court} est absent ?',
                        texte: 'Le passager ne sera pas remboursé. Vous pourrez démarrer sans lui.',
                        oui: 'Marquer absent',
                      );
                      if (ok && context.mounted) essayer(context, () => s.marquerAbsent(t, p));
                    }
                  : null,
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 53 · Scanner le QR du billet
// ---------------------------------------------------------------------------

enum _Scan { ok, deja, autre, expire }

class ScannerQrEcran extends StatefulWidget {
  const ScannerQrEcran({super.key, required this.trajet});
  final TrajetPublie trajet;

  @override
  State<ScannerQrEcran> createState() => _ScannerQrEcranState();
}

class _ScannerQrEcranState extends State<ScannerQrEcran> {
  _Scan _cas = _Scan.ok;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final t = widget.trajet;
    final haut = MediaQuery.paddingOf(context).top;
    final bas = MediaQuery.paddingOf(context).bottom;
    final suivant = t.confirmes.where((p) => !p.aBord && !p.absent).toList()
      ..sort((a, b) => a.paiement.enLigne == b.paiement.enLigne ? 0 : (a.paiement.enLigne ? -1 : 1));
    final p = suivant.isEmpty ? null : suivant.first;
    const cas = [
      (_Scan.ok, 'Valable', C.vert, Colors.white),
      (_Scan.deja, 'Déjà utilisé', C.sos, Colors.white),
      (_Scan.autre, 'Autre trajet', C.etoile, C.encre),
      (_Scan.expire, "Capture d'écran", C.encre2, Colors.white),
    ];
    Widget coin(Alignment a) {
      final gauche = a.x < 0, hautC = a.y < 0;
      return Align(
        alignment: a,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            border: Border(
              left: gauche ? const BorderSide(color: C.etoile, width: 5) : BorderSide.none,
              right: !gauche ? const BorderSide(color: C.etoile, width: 5) : BorderSide.none,
              top: hautC ? const BorderSide(color: C.etoile, width: 5) : BorderSide.none,
              bottom: !hautC ? const BorderSide(color: C.etoile, width: 5) : BorderSide.none,
            ),
          ),
        ),
      );
    }

    final resultat = switch (_cas) {
      _Scan.ok => [
        const Align(
          alignment: Alignment.centerLeft,
          child: Pastille('Billet valable', ton: TonPastille.vert, icon: Icons.check_rounded),
        ),
        if (p == null)
          const Text('Tous les passagers sont déjà à bord.', style: T.gras)
        else ...[
          Row(
            children: [
              Ava(p.personne.initiales, ton: p.personne.ton, taille: 64),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.personne.complet, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    Doux(
                      '${pluriel(p.places, 'place')} · ${p.paiement == Paiement.especes ? 'espèces' : 'payé par ${p.paiement.label}'}',
                      taille: 14,
                    ),
                    const Text(
                      "Vérifiez que c'est bien la personne de la photo",
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: C.lateriteF),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Btn(
            'Confirmer la montée',
            onPressed: () {
              final monte = s.monterParQr(t);
              Navigator.pop(context);
              if (monte != null) message(context, '${monte.personne.court} est à bord.');
            },
          ),
        ],
      ],
      _Scan.deja => [
        const Align(
          alignment: Alignment.centerLeft,
          child: Pastille('Billet déjà utilisé', ton: TonPastille.sos, icon: Icons.close_rounded),
        ),
        const Text('Ce billet a déjà été validé sur un autre téléphone.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const Doux("Ne laissez pas monter. L'équipe est prévenue automatiquement.", taille: 14),
        BtnClair(
          "Contacter l'équipe",
          onPressed: () => ouvrir(context, ConversationEcran(conversation: s.conversationEquipe)),
        ),
      ],
      _Scan.autre => [
        const Align(
          alignment: Alignment.centerLeft,
          child: Pastille('Pas pour ce trajet', ton: TonPastille.etoile, icon: Icons.warning_amber_rounded),
        ),
        const Text('Ce billet est pour un autre départ.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const Doux('Indiquez au passager le bon point de rendez-vous.', taille: 14),
      ],
      _Scan.expire => [
        const Align(
          alignment: Alignment.centerLeft,
          child: Pastille('QR expiré', ton: TonPastille.etoile, icon: Icons.schedule_rounded),
        ),
        const Text("C'est sans doute une capture d'écran.", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const Doux(
          'Demandez au passager d’ouvrir son billet dans l’application, ou de vous donner son code à 4 chiffres.',
          taille: 14,
        ),
        BtnClair('Saisir le code à la place', onPressed: () => Navigator.pop(context)),
      ],
    };

    return Scaffold(
      backgroundColor: const Color(0xFF1A110C),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(12, 14 + haut, 12, 14),
            child: Row(
              children: [
                IconeBtn(
                  icon: Icons.chevron_left_rounded,
                  label: 'Retour',
                  taille: 30,
                  couleur: Colors.white,
                  onTap: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Scanner le billet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
                const Pastille('Marche hors connexion', icon: Icons.lock_outline_rounded, fond: C.encre2, texte: C.etoile),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 260,
                    height: 260,
                    child: Stack(
                      children: [
                        coin(Alignment.topLeft),
                        coin(Alignment.topRight),
                        coin(Alignment.bottomLeft),
                        coin(Alignment.bottomRight),
                        Center(
                          child: Opacity(
                            opacity: .9,
                            child: Qr(graine: 'scan-${t.id}-${_cas.name}', taille: 180, label: 'QR du passager'),
                          ),
                        ),
                        Positioned(
                          left: 24,
                          right: 24,
                          top: 128,
                          child: Container(
                            height: 3,
                            decoration: const BoxDecoration(
                              color: C.etoile,
                              boxShadow: [BoxShadow(color: C.etoile, blurRadius: 12)],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Placez le QR du passager dans le cadre', style: TextStyle(fontSize: 14, color: C.beige)),
                  const SizedBox(height: 10),
                  const Text('Simuler le résultat :', style: TextStyle(fontSize: 13, color: C.beige2)),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final (c, label, bg, ink) in cas)
                        Pastille(
                          label,
                          fond: c == _cas ? bg : C.encre2,
                          texte: c == _cas ? ink : C.beige,
                          onTap: () => setState(() => _cas = c),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(20, 18, 20, 22 + bas),
            decoration: const BoxDecoration(
              color: C.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: espacer(resultat, 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 29 · En route, terminer (B9)
// ---------------------------------------------------------------------------

class EnRouteConducteurEcran extends StatelessWidget {
  const EnRouteConducteurEcran({super.key, required this.trajet});
  final TrajetPublie trajet;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final t = trajet;
    final l = t.ligne;
    final haut = MediaQuery.paddingOf(context).top;
    final bas = MediaQuery.paddingOf(context).bottom;
    final aBord = t.confirmes.where((p) => p.aBord).toList();
    final arrivee = t.depart.add(l.duree);
    // En route : passagers qui attendent sur la route, et ceux à prendre en chemin.
    final courses = s.coursesPour(t);
    final aPrendre = t.confirmes.where((p) => !p.aBord && !p.absent).toList();
    return Scaffold(
      backgroundColor: C.sable2,
      body: Stack(
        children: [
          Positioned.fill(top: 56 + haut, bottom: 330, child: CarteDuTrajet(depart: l.depart, arrivee: l.arrivee)),
          Positioned(
            top: 16 + haut,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.fromLTRB(6, 4, 16, 4),
              decoration: BoxDecoration(color: C.encre, borderRadius: BorderRadius.circular(999)),
              child: Row(
                children: [
                  IconeBtn(
                    icon: Icons.chevron_left_rounded,
                    label: 'Retour',
                    couleur: Colors.white,
                    onTap: () => Navigator.maybePop(context),
                  ),
                  const Icon(Icons.directions_car_outlined, color: C.etoile, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Trajet en cours · ${pluriel(aBord.length, 'passager')} à bord',
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 22 + bas),
              decoration: const BoxDecoration(
                color: C.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(top: BorderSide(color: C.trait, width: 1.5)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: espacer([
                  // Une alerte à la fois en conduisant : la plus proche dans le temps.
                  if (courses.isNotEmpty) _AlerteEnRoute(courses.first, autres: courses.length - 1),
                  for (final p in aPrendre)
                    Row(
                      children: [
                        const Icon(Icons.person_pin_circle_outlined, color: C.laterite),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'À prendre : ${p.personne.court}${p.montee == null ? '' : ' · ${capitaliser(p.montee!.quartier)}'}',
                            style: T.gras,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 110,
                          child: Btn('À bord', hauteur: 48, taille: 15, onPressed: () => s.monterEnChemin(t, p)),
                        ),
                      ],
                    ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Doux('Prochaine dépose · ${l.arrivee.ville}'),
                            Titre(capitaliser(l.arrivee.quartier)),
                          ],
                        ),
                      ),
                      Doux('${(l.km * .42).round()} km · ${heure(arrivee)}', taille: 14, gras: true),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [for (final p in aBord) Pastille(p.personne.court, ton: TonPastille.vert)],
                  ),
                  BtnClair(
                    'Itinéraire vers ${l.arrivee.quartier}',
                    icon: Icons.navigation_outlined,
                    onPressed: () => ouvrirItineraire(context, l.depart, l.arrivee),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Btn(
                          'Terminer le trajet',
                          onPressed: () async {
                            final ok = await confirmer(
                              context,
                              titre: 'Terminer le trajet ?',
                              texte: 'Faites-le à l’arrivée : les passagers pourront alors vous noter et vous serez payé.',
                              oui: 'Terminer',
                            );
                            if (!ok || !context.mounted) return;
                            final g = s.terminerTrajet(t);
                            s.allerOnglet(2);
                            retourAccueil(context);
                            message(context, 'Trajet terminé · ${fcfa(g.total)} de frais partagés.');
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 120,
                        child: Btn.sos(
                          'SOS',
                          icon: Icons.warning_amber_rounded,
                          onPressed: () => ouvrir(context, SosEcran(trajet: '${l.titre}, ${pluriel(aBord.length, 'passager')} à bord')),
                        ),
                      ),
                    ],
                  ),
                  const Doux("Terminez à l'arrivée : les passagers pourront alors vous noter."),
                ], 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Alerte compacte pendant le trajet : un passager attend sur la route.
class _AlerteEnRoute extends StatelessWidget {
  const _AlerteEnRoute(this.c, {this.autres = 0});
  final CoursePossible c;

  /// Autres courses possibles, affichées une fois celle-ci traitée.
  final int autres;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final d = c.demande;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: C.etoileC,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: C.etoile, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.notifications_active_outlined, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Course possible : ${d.passager.court} attend à ${capitaliser(d.depart.quartier)}, '
                    '${ecartTexte(c.croisement.monte)} de votre route, vers ${heure(c.passage)}. '
                    'Dépose : ${capitaliser(d.arrivee.quartier)}.',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: BtnClair('Ignorer', hauteur: 48, onPressed: () => s.ignorerCourse(c))),
                const SizedBox(width: 8),
                Expanded(
                  child: Btn(
                    'Prendre',
                    hauteur: 48,
                    taille: 15,
                    onPressed: () {
                      if (essayer(context, () => s.prendreCourse(c))) {
                        message(context, '${d.passager.court} vous attend à ${capitaliser(d.depart.quartier)}.');
                      }
                    },
                  ),
                ),
              ],
            ),
            if (autres > 0) ...[
              const SizedBox(height: 6),
              Doux(
                autres > 1 ? 'Encore $autres courses possibles ensuite.' : 'Encore une course possible ensuite.',
                align: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 30 · Mes gains (C4)
// ---------------------------------------------------------------------------

class GainsOnglet extends StatelessWidget {
  const GainsOnglet({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final mois = s.gainsDuMois;
    final total = mois.fold(0, (n, g) => n + g.total);
    final mobile = mois.fold(0, (n, g) => n + g.mobile);
    final especes = mois.fold(0, (n, g) => n + g.especes);
    Widget bloc(String label, int montant, String note) => Expanded(
      child: Carte(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Doux(label), Text(fcfa(montant), style: T.titre(20)), Doux(note)],
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Piste(
          couleur: C.vert,
          children: [
            Text(moisAnnee(s.maintenant, annee: true), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(fcfa(total), style: T.titre(44, color: Colors.white)),
            Text('de frais partagés sur ${pluriel(mois.length, 'trajet')}', style: T.petit),
          ],
        ),
        Zone(
          gap: 12,
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                bloc('En ligne', mobile, 'Versé sur votre portefeuille conducteur'),
                const SizedBox(width: 10),
                bloc('Espèces', especes, 'Reçus en main propre'),
              ],
            ),
            const Carte(
              child: Row(
                children: [
                  Icon(Icons.confirmation_number_outlined, size: 22),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: T.petit,
                        children: [
                          TextSpan(text: 'Frais FasoCovoit : '),
                          TextSpan(text: '0 F', style: T.gras),
                          TextSpan(text: ' pendant le pilote.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Btn(
              'Mon portefeuille : retirer mes gains',
              taille: 15,
              icon: Icons.account_balance_wallet_outlined,
              onPressed: () => ouvrir(context, const PortefeuilleConducteurEcran()),
            ),
            const Doux('Derniers trajets', taille: 14, gras: true),
            if (s.gains.isEmpty)
              const Carte(child: Text('Vos trajets terminés apparaîtront ici.', style: T.petit))
            else
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
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 31 · Annuler un trajet (B7)
// ---------------------------------------------------------------------------

class AnnulerTrajetEcran extends StatefulWidget {
  const AnnulerTrajetEcran({super.key, required this.trajet});
  final TrajetPublie trajet;

  @override
  State<AnnulerTrajetEcran> createState() => _AnnulerTrajetEcranState();
}

class _AnnulerTrajetEcranState extends State<AnnulerTrajetEcran> {
  String _raison = 'Panne du véhicule';

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final t = widget.trajet;
    final n = t.confirmes.length;
    final apres = s.annulationsConducteur + (n > 0 ? 1 : 0);
    return Ecran(
      children: [
        Barre(titre: 'Annuler ce trajet', sousTitre: '${t.ligne.titre} · ${_quand(t, s.maintenant).toLowerCase()}'),
        Zone(
          gap: 14,
          children: [
            Titre(n == 0 ? 'Aucun passager confirmé' : '${pluriel(n, 'passager')} compte${n > 1 ? 'nt' : ''} sur vous'),
            Carte(
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.account_balance_wallet_outlined, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            style: T.petit,
                            children: [
                              TextSpan(text: n == 0 ? 'Les demandes en attente seront ' : 'Ils seront '),
                              TextSpan(text: n == 0 ? 'annulées' : 'remboursés à 100 %', style: T.gras),
                              const TextSpan(text: ' et prévenus tout de suite.'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (n > 0) ...[
                    const SizedBox(height: 12),
                    const Sep(),
                    const SizedBox(height: 12),
                    const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, size: 22),
                        SizedBox(width: 12),
                        Expanded(child: Text('Vous recevrez un avertissement.', style: T.petit)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Carte(
              couleur: C.sosC,
              bord: C.sosBord,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Expanded(child: Text('Annulations sur 30 jours', style: T.gras)),
                      Text('${apres.clamp(0, 3)} sur 3', style: T.gras),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (var i = 0; i < 3; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            height: 10,
                            decoration: BoxDecoration(
                              color: i < apres ? C.sos : C.sosBord,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('À 3 annulations, votre compte est suspendu 7 jours.', style: T.mini),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Etiq('Raison'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final r in const ['Panne du véhicule', 'Imprévu personnel', 'Maladie', 'Autre'])
                      Puce(r, on: _raison == r, onTap: () => setState(() => _raison = r)),
                  ],
                ),
              ],
            ),
          ],
          bas: [
            Btn.sos(
              'Annuler le trajet',
              onPressed: () {
                if (essayer(context, () => s.annulerTrajetPublie(t))) {
                  s.allerOnglet(0);
                  retourAccueil(context);
                  message(context, 'Trajet annulé. Les passagers sont prévenus.');
                }
              },
            ),
            BtnClair('Garder le trajet', onPressed: () => Navigator.pop(context)),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 40 · Mon abonnement
// ---------------------------------------------------------------------------

class MonAbonnementEcran extends StatelessWidget {
  const MonAbonnementEcran({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final a = s.abonnement;
    if (a == null) {
      return const Ecran(children: [Barre(titre: 'Mon abonnement'), Zone(children: [Text('Aucun abonnement.')])]);
    }
    final prochain = a.formuleSuivante ?? a.formule;
    return Ecran(
      children: [
        const Barre(titre: 'Mon abonnement'),
        Zone(
          gap: 14,
          children: [
            Carte.sombre(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(child: Titre(a.formule.nom, couleur: Colors.white)),
                      a.arrete
                          ? const Pastille('Arrêté', ton: TonPastille.sos)
                          : const Pastille('Actif', ton: TonPastille.vert),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          a.arrete ? 'Accès jusqu’au' : 'Prochain paiement',
                          style: const TextStyle(fontSize: 14, color: C.beige),
                        ),
                      ),
                      Text(
                        a.arrete ? dateCourte(a.prochainPaiement) : '${dateCourte(a.prochainPaiement)} · ${fcfa(prochain.prix)}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Btn(
                    'Payer maintenant',
                    hauteur: 52,
                    couleur: C.etoile,
                    texte: C.encre,
                    onPressed: () async {
                      final ok = await confirmer(
                        context,
                        titre: 'Payer ${fcfa(prochain.prix)} ?',
                        texte: 'Formule ${prochain.nom}, ${prochain.duree}. Une demande de paiement arrive sur votre Orange Money.\n\nPrototype : paiement simulé.',
                        oui: 'Payer',
                      );
                      if (ok && context.mounted) {
                        s.payerAbonnement();
                        message(context, 'Paiement reçu. Prochaine échéance : ${dateCourte(s.abonnement!.prochainPaiement)}.');
                      }
                    },
                  ),
                ],
              ),
            ),
            const Carte(
              child: Row(
                children: [
                  Icon(Icons.notifications_none_rounded, size: 22),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Rappel 3 jours avant. Sans paiement, vos trajets restent visibles 3 jours, puis sont mis en pause.',
                      style: T.petit,
                    ),
                  ),
                ],
              ),
            ),
            ListeCarte(
              children: [
                LigneListe(
                  onTap: () async {
                    final f = await showModalBottomSheet<Formule>(
                      context: context,
                      builder: (c) => SafeArea(
                        child: ListView(
                          shrinkWrap: true,
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          children: [
                            Text('Changer de formule', style: T.titre(22)),
                            const SizedBox(height: 12),
                            for (final f in Formule.values)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Choix(
                                  on: f == prochain,
                                  onTap: () => Navigator.pop(c, f),
                                  children: [Bloc(f.nom, '${fcfa(f.prix)} ${f.duree}')],
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                    if (f != null) s.changerFormule(f);
                  },
                  children: [
                    const Icon(Icons.sync_rounded, size: 22),
                    Bloc(
                      'Changer de formule',
                      a.formuleSuivante == null
                          ? 'Prend effet au prochain paiement'
                          : '${a.formuleSuivante!.nom} à partir du ${dateCourte(a.prochainPaiement)}',
                    ),
                    const Icon(Icons.chevron_right_rounded, size: 20),
                  ],
                ),
                LigneListe(
                  onTap: () => informer(context, 'Reçus', a.recus.join('\n')),
                  children: [
                    const Icon(Icons.description_outlined, size: 22),
                    Bloc('Reçus', a.recus.first),
                    const Icon(Icons.chevron_right_rounded, size: 20),
                  ],
                ),
              ],
            ),
          ],
          bas: [
            if (a.arrete)
              Lien('Reprendre l’abonnement', onTap: s.reprendreAbonnement)
            else
              Lien(
                "Arrêter l'abonnement",
                couleur: C.sos,
                souligne: false,
                onTap: () async {
                  final ok = await confirmer(
                    context,
                    titre: "Arrêter l'abonnement ?",
                    texte: 'Vous gardez l’accès jusqu’au ${dateCourte(a.prochainPaiement)}.',
                    oui: 'Arrêter',
                    danger: true,
                  );
                  if (ok) s.arreterAbonnement();
                },
              ),
            const Doux('Vous gardez l’accès jusqu’à la fin de la période payée.', align: TextAlign.center),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 41 · Profil conducteur
// ---------------------------------------------------------------------------

class ProfilConducteurOnglet extends StatelessWidget {
  const ProfilConducteurOnglet({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final a = s.abonnement;
    final reguliers = s.trajetsPublies.where((t) => t.regulier && t.statut == StatutPublie.publie).length;
    Widget ligne(IconData i, String titre, String? sous, VoidCallback onTap) => LigneListe(
      onTap: onTap,
      children: [Icon(i, size: 22), Bloc(titre, sous), const Icon(Icons.chevron_right_rounded, size: 20)],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Piste(
          couleur: C.encre,
          paddingBas: 32,
          children: [
            Row(
              children: [
                PhotoRonde(photo: s.photo, initiales: s.moi.initiales, taille: 84, fond: C.etoile, texte: C.encre),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.femme ? 'Profil conductrice' : 'Profil conducteur',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: C.etoile),
                      ),
                      Titre(s.moi.complet),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (s.trajetsConducteur > 0) NoteEtoile(s.noteConducteur == 0 ? 5 : s.noteConducteur) else const Text('Nouveau', style: T.gras),
                          Text(' · ${pluriel(s.trajetsConducteur, 'trajet')} comme ${s.femme ? 'conductrice' : 'conducteur'}', style: T.petit),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        Zone(
          gap: 12,
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
          children: [
            if (a != null)
              Carte(
                bord: C.etoile,
                epaisseur: 2.5,
                onTap: () => ouvrir(context, const MonAbonnementEcran()),
                child: Row(
                  children: [
                    const Etoile(size: 26, color: C.laterite),
                    const SizedBox(width: 12),
                    Bloc(
                      'Abonnement ${a.formule.nom} · ${a.arrete ? 'arrêté' : 'actif'}',
                      a.arrete
                          ? 'Accès jusqu’au ${dateCourte(a.prochainPaiement)}'
                          : 'Prochain paiement le ${dateCourte(a.prochainPaiement)} · ${fcfa((a.formuleSuivante ?? a.formule).prix)}',
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
            ListeCarte(
              children: [
                ligne(
                  Icons.directions_car_outlined,
                  'Mon véhicule',
                  '${s.dossier.vehicule} · ${s.dossier.plaque}',
                  () => informer(
                    context,
                    'Mon véhicule',
                    '${s.dossier.vehicule}.\nPlaque ${s.dossier.plaque}.\n\nUn changement de véhicule passe par une nouvelle validation de la carte grise.',
                  ),
                ),
                ligne(
                  Icons.description_outlined,
                  'Mes documents',
                  '${s.documentsEnvoyes.length} documents validés',
                  () => ouvrir(context, const ValidationEcran()),
                ),
                ligne(Icons.account_balance_wallet_outlined, 'Mes gains', '${fcfa(s.gainsDuMois.fold(0, (n, g) => n + g.total))} ce mois-ci', () => s.allerOnglet(2)),
                ligne(
                  Icons.savings_outlined,
                  s.femme ? 'Portefeuille conductrice' : 'Portefeuille conducteur',
                  '${fcfa(s.gainsDisponibles)} disponibles au retrait',
                  () => ouvrir(context, const PortefeuilleConducteurEcran()),
                ),
                ligne(Icons.sync_rounded, 'Trajets réguliers', pluriel(reguliers, 'trajet actif', 'trajets actifs'), () => s.allerOnglet(0)),
              ],
            ),
            ListeCarte(
              children: [
                ligne(Icons.verified_user_outlined, 'Charte du conducteur', null, () => ouvrir(context, const PageTexteEcran.charte())),
                ligne(
                  Icons.chat_bubble_outline_rounded,
                  "Aide : écrire à l'équipe",
                  null,
                  () => ouvrir(context, ConversationEcran(conversation: s.conversationEquipe)),
                ),
              ],
            ),
            BtnClair(
              'Passer à mon profil passag${s.femme ? 'ère' : 'er'}',
              icon: Icons.person_outline_rounded,
              onPressed: () => s.basculerMode(Mode.passager, onglet: 3),
            ),
            Doux(
              'Vos notes de ${s.femme ? 'conductrice' : 'conducteur'} et de passag${s.femme ? 'ère' : 'er'} sont séparées.',
              align: TextAlign.center,
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 49 · Portefeuille conducteur
// ---------------------------------------------------------------------------

class PortefeuilleConducteurEcran extends StatelessWidget {
  const PortefeuilleConducteurEcran({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final attente = s.gainsEnAttente;
    return Ecran(
      children: [
        Piste(
          couleur: C.vert,
          retour: true,
          trailing: Pastille(
            s.femme ? 'Portefeuille conductrice' : 'Portefeuille conducteur',
            fond: C.surface,
            texte: C.vertF,
          ),
          children: [
            const Text('Disponible pour un retrait', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            Text(fcfa(s.gainsDisponibles), style: T.titre(44, color: Colors.white)),
          ],
        ),
        Zone(
          gap: 14,
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
          children: [
            if (attente > 0)
              Carte(
                child: Row(
                  children: [
                    const Icon(Icons.schedule_rounded, size: 22),
                    const SizedBox(width: 12),
                    Bloc('${fcfa(attente)} en attente', 'Trajets à venir : versé quand vous les terminez'),
                  ],
                ),
              ),
            Btn(
              'Retirer vers Orange Money',
              icon: Icons.account_balance_wallet_outlined,
              onPressed: s.gainsDisponibles <= 0
                  ? null
                  : () async {
                      final montant = s.gainsDisponibles;
                      final ok = await confirmer(
                        context,
                        titre: 'Retirer ${fcfa(montant)} ?',
                        texte: 'Vers votre Orange Money (${s.telephone}). Arrivée sous 24 h, souvent en quelques minutes.',
                        oui: 'Retirer',
                      );
                      if (ok && context.mounted && essayer(context, s.retirerGains)) {
                        message(context, 'Retrait de ${fcfa(montant)} en cours.');
                      }
                    },
            ),
            const Doux('Opérations', taille: 14, gras: true),
            if (s.operationsConducteur.isEmpty)
              const Carte(child: Text('Les paiements en ligne de vos passagers arriveront ici.', style: T.petit))
            else
              ListeCarte(children: [for (final o in s.operationsConducteur) LigneOperation(o)]),
            const Doux('Pendant le pilote, FasoCovoit ne prend rien. Ensuite, la commission de 10 % est déduite avant le versement.'),
          ],
        ),
      ],
    );
  }
}
