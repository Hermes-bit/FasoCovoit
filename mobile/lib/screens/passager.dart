import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../formats.dart';
import '../google_maps_embed.dart';
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
import 'portefeuille.dart';

/// Espace passager : navigation du bas à quatre onglets.
class EspacePassager extends StatelessWidget {
  const EspacePassager({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final index = s.onglet.clamp(0, 3);
    return Scaffold(
      backgroundColor: C.sable,
      body: IndexedStack(
        index: index,
        children: const [AccueilOnglet(), MesTrajetsOnglet(), MessagesOnglet(), ProfilOnglet()],
      ),
      bottomNavigationBar: NavBas(
        index: index,
        onTap: s.allerOnglet,
        items: [
          const NavItem(Icons.search_rounded, 'Rechercher'),
          const NavItem(Icons.confirmation_number_outlined, 'Mes trajets'),
          NavItem(Icons.chat_bubble_outline_rounded, 'Messages', badge: s.messagesNonLus),
          const NavItem(Icons.person_outline_rounded, 'Profil'),
        ],
      ),
    );
  }
}

/// Bascule Passager / Conducteur des en-têtes.
class BasculeMode extends StatelessWidget {
  const BasculeMode({super.key, required this.conducteur});
  final bool conducteur;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    Widget pilule(String label, bool actif, VoidCallback? onTap) => Semantics(
      button: true,
      selected: actif,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: actif ? (conducteur ? C.etoile : C.surface) : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: actif ? FontWeight.w800 : FontWeight.w700,
              color: actif ? C.encre : Colors.white,
            ),
          ),
        ),
      ),
    );
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: conducteur ? C.encre2 : C.lateriteF,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          pilule('Passager', !conducteur, conducteur ? () => s.basculerMode(Mode.passager) : null),
          pilule('Conducteur', conducteur, conducteur
              ? null
              : () => s.estConducteur
                    ? s.basculerMode(Mode.conducteur)
                    : ouvrir(context, const DevenirIntroEcran())),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 06 · Accueil et recherche (B3, B10)
// ---------------------------------------------------------------------------

class AccueilOnglet extends StatefulWidget {
  const AccueilOnglet({super.key});

  @override
  State<AccueilOnglet> createState() => _AccueilOngletState();
}

class _AccueilOngletState extends State<AccueilOnglet> {
  Lieu _depart = lOuagaGare;
  Lieu _arrivee = lKoudCentre;
  int _places = 1;
  bool _femmes = false;

  bool get _inter => _depart.ville != _arrivee.ville;

  Future<void> _choisir({required bool depart}) async {
    final l = await choisirLieu(
      context,
      titre: depart ? "D'où partez-vous ?" : 'Où allez-vous ?',
      actuel: depart ? _depart : _arrivee,
      exclu: depart ? _arrivee : _depart,
    );
    if (l == null) return;
    setState(() => depart ? _depart = l : _arrivee = l);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Piste(
          paddingBas: 30,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ne y windiga, ${s.prenom}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                      const Titre('Où allez-vous ?'),
                      const SizedBox(height: 8),
                      Pastille(
                        fcfa(s.solde),
                        icon: Icons.account_balance_wallet_outlined,
                        fond: C.encre,
                        texte: C.etoile,
                        onTap: () => ouvrir(context, const PortefeuilleEcran()),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const BasculeMode(conducteur: false),
              ],
            ),
          ],
        ),
        Zone(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          children: [
            Onglets(
              labels: const ['En ville', 'Entre villes'],
              index: _inter ? 1 : 0,
              onChanged: (i) => setState(() {
                // Raccourcis : un trajet type pour chaque mode.
                if (i == 1 && !_inter) {
                  _depart = lOuagaGare;
                  _arrivee = lKoudCentre;
                } else if (i == 0 && _inter) {
                  _depart = lDassasgho;
                  _arrivee = lOuaga2000;
                }
              }),
            ),
            Carte(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RouteRail(
                    gap: 14,
                    haut: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ChampLieu(
                          label: 'Départ',
                          valeur: _depart,
                          indication: 'Choisir le départ',
                          onTap: () => _choisir(depart: true),
                        ),
                        const SizedBox(height: 14),
                        const Sep(),
                      ],
                    ),
                    bas: ChampLieu(
                      label: 'Arrivée',
                      valeur: _arrivee,
                      indication: 'Où allez-vous ?',
                      onTap: () => _choisir(depart: false),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Sep(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_inter ? 'Demain, 7 h' : 'Maintenant', style: T.gras),
                      ),
                      Compteur(
                        valeur: _places,
                        grand: false,
                        largeurTexte: 64,
                        texte: pluriel(_places, 'place'),
                        onMoins: _places > 1 ? () => setState(() => _places--) : null,
                        onPlus: _places < 4 ? () => setState(() => _places++) : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (s.femme)
              LigneCase(
                value: _femmes,
                onChanged: (v) => setState(() => _femmes = v),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Entre femmes', style: T.gras),
                    Doux('Seulement des conductrices'),
                  ],
                ),
              ),
            Btn(
              'Rechercher',
              icon: Icons.search_rounded,
              onPressed: () => ouvrir(
                context,
                ResultatsEcran(depart: _depart, arrivee: _arrivee, places: _places, conductrices: _femmes),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Doux('Votre trajet habituel', taille: 14, gras: true),
                const SizedBox(height: 8),
                Carte(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  onTap: () => ouvrir(context, const ResultatsEcran(depart: lDassasgho, arrivee: lOuaga2000, places: 1)),
                  child: const Row(
                    children: [
                      Icon(Icons.sync_rounded, size: 22),
                      SizedBox(width: 12),
                      Bloc('Dassasgho → Ouaga 2000', 'Lun. au ven., 7 h 15'),
                      Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
              ],
            ),
            Carte(
              pointillee: true,
              bord: C.laterite,
              epaisseur: 1.5,
              onTap: () => ouvrir(context, const ColisEnvoyerEcran()),
              child: const Row(
                children: [
                  Icon(Icons.inventory_2_outlined, color: C.laterite, size: 24),
                  SizedBox(width: 12),
                  Bloc('Envoyer un colis', 'Bientôt : documents et paquets, en ville et entre villes'),
                  Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 07 · Résultats (B3)
// ---------------------------------------------------------------------------

class ResultatsEcran extends StatefulWidget {
  const ResultatsEcran({
    super.key,
    required this.depart,
    required this.arrivee,
    required this.places,
    this.conductrices = false,
  });
  final Lieu depart;
  final Lieu arrivee;
  final int places;
  final bool conductrices;

  bool get interVilles => depart.ville != arrivee.ville;

  @override
  State<ResultatsEcran> createState() => _ResultatsEcranState();
}

class _ResultatsEcranState extends State<ResultatsEcran> {
  late bool _conductrices = widget.conductrices;
  bool _matin = false;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final d = widget.depart, a = widget.arrivee;
    final tous = s.rechercher(depart: d, arrivee: a, places: widget.places);
    final liste = s.rechercher(
      depart: d,
      arrivee: a,
      places: widget.places,
      conductrices: _conductrices,
      matin: _matin,
    );
    final ligne = Ligne.entre(d, a);
    final tarif = calculerTarif(ligne);
    final quand = widget.interVilles
        ? jourRelatifComplet(s.maintenant.add(const Duration(days: 1)), s.maintenant)
        : 'Maintenant';
    return Ecran(
      children: [
        Barre(
          titre: widget.interVilles ? '${d.ville} → ${a.ville}' : '${capitaliser(d.quartier)} → ${capitaliser(a.quartier)}',
          sousTitre: '$quand · ${pluriel(widget.places, 'place')}',
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(
            children: espacer([
              Puce(
                'Tous · ${tous.length}',
                on: !_conductrices && !_matin,
                onTap: () => setState(() => _conductrices = _matin = false),
              ),
              if (s.femme)
                Puce('Entre femmes', on: _conductrices, onTap: () => setState(() => _conductrices = !_conductrices)),
              if (widget.interVilles)
                Puce('Le matin', on: _matin, onTap: () => setState(() => _matin = !_matin)),
            ], 8),
          ),
        ),
        if (widget.interVilles)
          Container(
            margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: C.etoileC, borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                const Icon(Icons.confirmation_number_outlined, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'En car : environ ${fcfa(ligne.car)}. Ici, prix plafonné à ${fcfa(tarif.plafond)}, départ près de chez vous.',
                    style: T.petit,
                  ),
                ),
              ],
            ),
          ),
        Zone(
          gap: 12,
          children: [
            if (liste.isEmpty)
              Carte(
                child: Text(
                  tous.isEmpty
                      ? 'Aucun conducteur ne propose encore ce trajet. Essayez un lieu proche, '
                            'ou les trajets de démonstration : Ouaga → Koudougou, Dassasgho → Ouaga 2000.'
                      : 'Aucun trajet ne correspond. Essayez sans filtre ou à un autre horaire.',
                  style: T.petit,
                ),
              ),
            for (var i = 0; i < liste.length; i++)
              CarteTrajet(
                trajet: liste[i],
                selection: i == 0,
                onTap: () => ouvrir(context, FicheEcran(trajet: liste[i], places: widget.places)),
              ),
            const Doux(
              'Prix plafonnés : le conducteur partage ses frais de carburant, il ne fait pas de bénéfice.',
            ),
          ],
        ),
      ],
    );
  }
}

class CarteTrajet extends StatelessWidget {
  const CarteTrajet({super.key, required this.trajet, required this.onTap, this.selection = false});
  final Trajet trajet;
  final VoidCallback onTap;
  final bool selection;

  @override
  Widget build(BuildContext context) {
    final t = trajet;
    final c = t.conducteur;
    Widget horaire(DateTime h, String lieu) => Text.rich(
      TextSpan(
        children: [
          TextSpan(text: heure(h), style: T.gras),
          TextSpan(text: ' ${capitaliser(lieu)}', style: const TextStyle(color: C.doux)),
        ],
      ),
    );
    final contenu = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: RouteRail(
                gap: 12,
                voieMin: 18,
                haut: horaire(t.heureDepart, t.depart.quartier),
                bas: horaire(t.heureArrivee, t.arrivee.quartier),
              ),
            ),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: milliers(t.prix), style: T.titre(20)),
                  const TextSpan(
                    text: ' F',
                    style: TextStyle(fontSize: 13, color: C.doux, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Sep(),
        const SizedBox(height: 12),
        Row(
          children: [
            Ava(c.initiales, ton: c.ton),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [Text(c.court, style: T.gras), Verifie(femme: c.femme)],
                  ),
                  const SizedBox(height: 4),
                  c.nouveau
                      ? Doux(c.femme ? 'Nouvelle conductrice' : 'Nouveau conducteur')
                      : LigneNote(
                          note: c.note,
                          suite: ' · ${c.trajets} trajets${t.interVilles ? ' · ${c.voiture.split(' ').last} ${c.couleur}' : ''}',
                        ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (t.entreFemmes) ...[
                  const Pastille('Entre femmes', ton: TonPastille.femmes),
                  const SizedBox(height: 4),
                ],
                Doux(pluriel(t.placesLibres, 'place'), gras: true),
              ],
            ),
          ],
        ),
      ],
    );
    return Semantics(
      button: true,
      label: '${c.court}, départ ${heure(t.heureDepart)}, ${fcfa(t.prix)}',
      child: selection ? Carte.sel(onTap: onTap, child: contenu) : Carte(onTap: onTap, child: contenu),
    );
  }
}

// ---------------------------------------------------------------------------
// 08 · Fiche du trajet (B4, B5)
// ---------------------------------------------------------------------------

class FicheEcran extends StatefulWidget {
  const FicheEcran({super.key, required this.trajet, this.places = 1});
  final Trajet trajet;
  final int places;

  @override
  State<FicheEcran> createState() => _FicheEcranState();
}

class _FicheEcranState extends State<FicheEcran> {
  late int _places = widget.places.clamp(1, math.max(1, widget.trajet.placesLibres));

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final t = widget.trajet;
    final c = t.conducteur;
    final max = math.min(t.placesLibres, 4);
    return Ecran(
      children: [
        Barre(
          titre: '${capitaliser(jourCourt(t.heureDepart))} · ${heure(t.heureDepart)}',
          sousTitre: 'Environ ${duree(t.duree)} · ${t.km} km',
          actions: [
            IconeBtn(
              icon: Icons.share_outlined,
              label: 'Partager le trajet',
              onTap: () {
                Clipboard.setData(
                  ClipboardData(
                    text: 'FasoCovoit : ${t.titreLong}, ${jourCourt(t.heureDepart)} à ${heure(t.heureDepart)} avec ${c.court}, ${fcfa(t.prix)} la place.',
                  ),
                );
                message(context, 'Description du trajet copiée.');
              },
            ),
          ],
        ),
        Zone(
          gap: 14,
          children: [
            Carte(
              child: RouteRail(
                haut: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${heure(t.heureDepart)} · ${capitaliser(t.depart.quartier)}', style: T.gras),
                    Doux('Rendez-vous : ${t.rdv.toLowerCase()}'),
                  ],
                ),
                bas: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${heure(t.heureArrivee)} · ${t.interVilles ? '${t.arrivee.ville}, ' : ''}${t.arrivee.quartier}', style: T.gras),
                    const Doux('Dépose possible sur le trajet'),
                  ],
                ),
              ),
            ),
            if (GoogleMapsRouteEmbed.disponible)
              GoogleMapsRouteEmbed(
                departure: '${t.depart.quartier}, ${t.depart.ville}, Burkina Faso',
                destination: '${t.arrivee.quartier}, ${t.arrivee.ville}, Burkina Faso',
                height: 200,
              ),
            Carte(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Ava(c.initiales, ton: c.ton),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(c.court, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                                Verifie(femme: c.femme),
                              ],
                            ),
                            c.nouveau
                                ? Doux('${c.femme ? 'Nouvelle conductrice' : 'Nouveau conducteur'} · membre depuis ${c.depuis}')
                                : LigneNote(
                                    note: c.note,
                                    suite: ' sur 5 · ${c.trajets} trajets · membre depuis ${c.depuis}',
                                  ),
                          ],
                        ),
                      ),
                      IconeBtn(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: 'Écrire à ${c.prenom}',
                        bord: true,
                        taille: 20,
                        onTap: () {
                          final conv = s.conversationPour(c);
                          if (conv == null) {
                            message(context, 'Les messages s’ouvrent après une réservation.');
                          } else {
                            ouvrir(context, ConversationEcran(conversation: conv));
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Pastille('CNIB', ton: TonPastille.vert, icon: Icons.check_rounded),
                      Pastille('Permis', ton: TonPastille.vert, icon: Icons.check_rounded),
                      Pastille('Assurance à jour', ton: TonPastille.vert, icon: Icons.check_rounded),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Sep(),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.directions_car_outlined, size: 24),
                      const SizedBox(width: 12),
                      Bloc(c.vehicule, 'Plaque ${c.plaque}${c.climatisee ? ' · climatisée' : ''}'),
                    ],
                  ),
                ],
              ),
            ),
            Carte(
              child: Row(
                children: [
                  Bloc('Places', pluriel(t.placesLibres, 'disponible')),
                  Compteur(
                    valeur: _places,
                    onMoins: _places > 1 ? () => setState(() => _places--) : null,
                    onPlus: _places < max ? () => setState(() => _places++) : null,
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: () => ouvrir(context, const ReglesAnnulationEcran()),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.description_outlined, size: 18, color: C.doux),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: const TextStyle(fontSize: 14, color: C.doux),
                        children: [
                          TextSpan(
                            text: t.interVilles
                                ? 'Annulation gratuite plus de 24 h avant. '
                                : 'Annulation gratuite jusqu’à l’arrivée du conducteur. ',
                          ),
                          const TextSpan(
                            text: 'Voir les règles',
                            style: TextStyle(
                              color: C.vertF,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Pied(
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Titre(fcfa(_places * t.prix)),
                  Doux('$_places × ${fcfa(t.prix)}'),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Btn(
                  'Continuer',
                  onPressed: t.placesLibres < 1
                      ? null
                      : () => ouvrir(context, PaiementEcran(trajet: t, places: _places)),
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
// 09 · Paiement (C1, C2)
// ---------------------------------------------------------------------------

class PaiementEcran extends StatefulWidget {
  const PaiementEcran({super.key, required this.trajet, required this.places});
  final Trajet trajet;
  final int places;

  @override
  State<PaiementEcran> createState() => _PaiementEcranState();
}

class _PaiementEcranState extends State<PaiementEcran> {
  Paiement _mode = Paiement.portefeuille;
  bool _bonus = true;
  late final TextEditingController _numero;

  @override
  void initState() {
    super.initState();
    _numero = TextEditingController(text: AppScope.read(context).telephone);
  }

  @override
  void dispose() {
    _numero.dispose();
    super.dispose();
  }

  String _note(AppState s, Paiement p) => switch (p) {
    Paiement.portefeuille => 'Solde ${fcfa(s.solde)}${s.bonus > 0 ? ', dont ${fcfa(s.bonus)} de bonus' : ''}',
    Paiement.orange || Paiement.moov => 'Payé maintenant, place garantie',
    Paiement.especes => 'À donner au conducteur en montant',
  };

  Future<void> _payer(AppState s, int total) async {
    if (_mode.mobile) {
      final ok = await confirmer(
        context,
        titre: 'Confirmez sur votre téléphone',
        texte: 'Une demande de paiement de ${fcfa(total)} arrive sur le ${_numero.text}. '
            'Validez-la avec votre code secret ${_mode.label}. FasoCovoit ne vous demandera jamais ce code.\n\n'
            'Prototype : le paiement est simulé.',
        oui: "J'ai confirmé",
        non: 'Annuler',
      );
      if (!ok || !mounted) return;
    }
    Reservation? resa;
    final ok = essayer(context, () {
      resa = s.reserver(widget.trajet, places: widget.places, paiement: _mode, utiliserBonus: _bonus);
    });
    if (ok && mounted) remplacer(context, AttenteEcran(reservation: resa!));
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final t = widget.trajet;
    final total = widget.places * t.prix;
    final bonusPris = _mode == Paiement.portefeuille && _bonus ? s.bonusUtilisable(total) : 0;
    final manque = _mode == Paiement.portefeuille ? total - bonusPris - s.depose : 0;
    final enLigne = _mode.enLigne;
    final cta = _mode.mobile
        ? 'Payer ${fcfa(total)}'
        : (_mode == Paiement.portefeuille ? 'Payer avec mon portefeuille' : 'Envoyer la demande');
    return Ecran(
      children: [
        Barre(
          titre: 'Paiement',
          sousTitre: '${t.titre} · ${jourCourt(t.heureDepart).split(' ').first} ${heure(t.heureDepart)}',
        ),
        Zone(
          gap: 12,
          children: [
            const Etiq('Comment voulez-vous payer ?'),
            for (final p in Paiement.values)
              Choix(
                on: _mode == p,
                onTap: () => setState(() => _mode = p),
                children: [LogoPaiement(p), Bloc(p.label, _note(s, p))],
              ),
            if (_mode == Paiement.portefeuille && s.bonus > 0)
              Carte(
                bord: C.etoile,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                onTap: () => setState(() => _bonus = !_bonus),
                child: Row(
                  children: [
                    const Etoile(size: 24),
                    const SizedBox(width: 12),
                    Bloc(
                      'Utiliser mon bonus',
                      _bonus
                          ? '${fcfa(bonusPris)} de bonus + ${fcfa(total - bonusPris)} du portefeuille'
                          : '${fcfa(total)} du portefeuille',
                    ),
                    Case(value: _bonus, onChanged: (v) => setState(() => _bonus = v)),
                  ],
                ),
              ),
            if (manque > 0)
              Carte(
                couleur: C.sosC,
                bord: C.sosBord,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Il manque ${fcfa(manque)} sur votre portefeuille.', style: T.gras),
                    const SizedBox(height: 8),
                    BtnP('Déposer de l’argent', onPressed: () => ouvrir(context, const DeposerEcran())),
                  ],
                ),
              ),
            if (_mode.mobile)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Etiq('Numéro ${_mode.label}'),
                  const SizedBox(height: 8),
                  Champ(controller: _numero, actif: true, clavier: TextInputType.phone, label: 'Numéro ${_mode.label}'),
                ],
              ),
            Carte(
              child: Column(
                children: [
                  _ligne('${pluriel(widget.places, 'place')} × ${fcfa(t.prix)}', Text(fcfa(total), style: T.gras)),
                  const SizedBox(height: 8),
                  _ligne(
                    'Frais FasoCovoit',
                    const Text('0 F pendant le pilote', style: TextStyle(fontWeight: FontWeight.w700, color: C.vertF)),
                  ),
                  if (bonusPris > 0) ...[
                    const SizedBox(height: 8),
                    _ligne('Dont bonus', Text('− ${fcfa(bonusPris)}', style: const TextStyle(fontWeight: FontWeight.w700, color: C.etoileF))),
                  ],
                  const SizedBox(height: 8),
                  const Sep(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Expanded(child: Text('Total', style: T.gras)),
                      Text(fcfa(total), style: T.titre(20)),
                    ],
                  ),
                ],
              ),
            ),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Doux(
                  enLigne
                      ? 'Si le conducteur refuse ou ne répond pas en 30 min, vous êtes remboursé automatiquement.'
                      : 'Vous payez au conducteur au départ, après avoir donné votre code.',
                ),
                Lien("Règles d'annulation", taille: 13, onTap: () => ouvrir(context, const ReglesAnnulationEcran())),
              ],
            ),
          ],
        ),
        Pied(child: Btn(cta, onPressed: manque > 0 ? null : () => _payer(s, total))),
      ],
    );
  }

  Widget _ligne(String label, Widget valeur) => Row(
    children: [
      Expanded(child: Text(label, style: const TextStyle(color: C.doux))),
      valeur,
    ],
  );
}

// ---------------------------------------------------------------------------
// 10 · Demande envoyée (B6)
// ---------------------------------------------------------------------------

class AttenteEcran extends StatefulWidget {
  const AttenteEcran({super.key, required this.reservation});
  final Reservation reservation;

  @override
  State<AttenteEcran> createState() => _AttenteEcranState();
}

class _AttenteEcranState extends State<AttenteEcran> {
  Timer? _minuterie;

  @override
  void initState() {
    super.initState();
    _minuterie = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _minuterie?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final r = widget.reservation;
    final c = r.trajet.conducteur;
    final restant = r.limiteReponse.difference(s.maintenant);
    final minutes = (restant.inSeconds / 60).ceil().clamp(0, 30);
    final progres = (restant.inSeconds / Reservation.delaiReponse.inSeconds).clamp(0.0, 1.0);
    final il = c.femme ? 'elle' : 'il';
    return Ecran(
      children: [
        Barre(titre: 'Demande envoyée', onRetour: () => retourAccueil(context)),
        Zone(
          centre: true,
          gap: 18,
          children: [
            const SizedBox(height: 8),
            SizedBox(
              width: 160,
              height: 160,
              child: CustomPaint(
                painter: _Anneau(progres),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$minutes', style: T.titre(42)),
                      const Text('minutes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ),
            Titre('${c.prenom} a 30 minutes pour accepter', align: TextAlign.center),
            Doux(
              r.paiement == Paiement.especes
                  ? 'Vous recevrez une notification dès qu’$il répond. Vous paierez ${fcfa(r.montant)} en espèces au départ.'
                  : 'Vous recevrez une notification dès qu’$il répond. Votre paiement de ${fcfa(r.montant)} est mis de côté.',
              taille: 16,
              align: TextAlign.center,
            ),
            Carte(
              child: Row(
                children: [
                  const Icon(Icons.verified_user_outlined, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Sans réponse avant ${heure(r.limiteReponse)}, la demande est annulée${r.paiement.enLigne ? ' et vous êtes remboursé' : ''}.',
                      style: T.petit,
                    ),
                  ),
                ],
              ),
            ),
          ],
          bas: [
            if (r.statut == StatutResa.enAttente) ...[
              Btn(
                'Simuler l’acceptation du conducteur',
                onPressed: () {
                  s.simulerAcceptation(r);
                  remplacer(context, BilletEcran(reservation: r));
                },
              ),
              BtnClair('Annuler la demande', onPressed: () => ouvrir(context, AnnulerEcran(reservation: r))),
            ] else
              Btn('Voir mes trajets', onPressed: () {
                s.allerOnglet(1);
                retourAccueil(context);
              }),
          ],
        ),
      ],
    );
  }
}

class _Anneau extends CustomPainter {
  _Anneau(this.progres);
  final double progres;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    canvas.drawCircle(c, size.width / 2, Paint()..color = C.lateriteC);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    final r = Rect.fromCircle(center: c, radius: 70 * size.width / 160);
    canvas.drawArc(r, 0, 2 * math.pi, false, p..color = C.trait);
    canvas.drawArc(r, -math.pi / 2, 2 * math.pi * progres, false, p..color = C.laterite);
  }

  @override
  bool shouldRepaint(_Anneau old) => old.progres != progres;
}

// ---------------------------------------------------------------------------
// 11 · Billet et code de départ (B9)
// ---------------------------------------------------------------------------

class BilletEcran extends StatefulWidget {
  const BilletEcran({super.key, required this.reservation});
  final Reservation reservation;

  @override
  State<BilletEcran> createState() => _BilletEcranState();
}

class _BilletEcranState extends State<BilletEcran> {
  Timer? _minuterie;

  @override
  void initState() {
    super.initState();
    // Le QR change toutes les 30 s : une capture d'écran ne sert à rien.
    _minuterie = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _minuterie?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final r = widget.reservation;
    final t = r.trajet;
    final c = t.conducteur;
    final confirme = r.statut == StatutResa.confirmee || r.statut == StatutResa.enCours;
    final fenetre = s.maintenant.millisecondsSinceEpoch ~/ 30000;
    final (statut, ton, icone) = switch (r.statut) {
      StatutResa.enAttente => ('En attente', TonPastille.etoile, Icons.schedule_rounded),
      StatutResa.enCours => ('En route', TonPastille.vert, Icons.directions_car_outlined),
      StatutResa.confirmee => ('Confirmée', TonPastille.vert, Icons.check_rounded),
      _ => ('Terminée', TonPastille.neutre, Icons.check_rounded),
    };
    return Ecran(
      children: [
        Piste(
          retour: true,
          paddingBas: 30,
          trailing: Pastille(statut, icon: icone, fond: C.surface, texte: Pastille.couleurs(ton).$2),
          children: [
            const SizedBox(height: 6),
            Titre('${jourRelatif(t.heureDepart, s.maintenant)}, ${heure(t.heureDepart)}'),
            Text(t.titreLong, style: T.petit),
          ],
        ),
        Zone(
          gap: 14,
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
          children: [
            Billet(
              haut: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: espacer([
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Doux('N° de réservation'),
                            Text(r.ref, style: T.titre(20).copyWith(letterSpacing: 1.2)),
                          ],
                        ),
                      ),
                      Pastille(
                        '${pluriel(r.places, 'place')} · ${r.paiement == Paiement.especes ? 'espèces' : 'payée'}',
                        ton: TonPastille.vert,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      PhotoRonde(photo: s.photo, initiales: s.moi.initiales),
                      const SizedBox(width: 12),
                      Bloc(s.moi.complet, 'Billet nominatif, non cessible'),
                    ],
                  ),
                  const Sep(),
                  Row(
                    children: [
                      Ava(c.initiales, ton: c.ton, taille: 38),
                      const SizedBox(width: 12),
                      Bloc(c.court, '${c.voiture.split(' ').last} ${c.couleur} · ${c.plaque}'),
                      if (!c.nouveau) NoteEtoile(c.note),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            style: T.petit,
                            children: [
                              TextSpan(text: capitaliser(t.depart.quartier), style: T.gras),
                              TextSpan(text: ', ${t.rdv.toLowerCase()}'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ], 12),
              ),
              bas: confirme
                  ? Column(
                      children: [
                        const Doux('À MONTRER AU CONDUCTEUR', taille: 14, gras: true),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: C.trait, width: 1.5),
                          ),
                          child: Qr(graine: '${r.ref}-$fenetre'),
                        ),
                        const SizedBox(height: 12),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.sync_rounded, size: 14, color: C.vertF),
                            SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                "Le QR change toutes les 30 s : une capture d'écran ne marche pas",
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: C.vertF),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Doux('Sans appareil photo ? Donnez ce code :'),
                        const SizedBox(height: 8),
                        Semantics(
                          label: 'Code de départ ${r.code.split('').join(' ')}',
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: espacer([
                              for (final ch in r.code.split(''))
                                Chiffre(ch, largeur: 44, hauteur: 52, taille: 28),
                            ], 8),
                          ),
                        ),
                      ],
                    )
                  : const Doux(
                      'Le QR et le code de départ apparaîtront dès que le conducteur aura accepté.',
                      taille: 14,
                      align: TextAlign.center,
                    ),
            ),
            Row(
              children: espacer([
                Expanded(
                  child: _Action(
                    Icons.phone_outlined,
                    'Appeler',
                    () => informer(
                      context,
                      'Appeler ${c.prenom}',
                      "L'appel passe par l'application : votre numéro reste masqué. Prototype : l’appel n’est pas encore branché.",
                    ),
                  ),
                ),
                Expanded(
                  child: _Action(Icons.chat_bubble_outline_rounded, 'Message', () {
                    final conv = s.ouvrirConversation(c, '${t.titre} · ${jourRelatif(t.heureDepart, s.maintenant).toLowerCase()} ${heureCourte(t.heureDepart)}');
                    ouvrir(context, ConversationEcran(conversation: conv));
                  }),
                ),
                Expanded(
                  child: _Action(Icons.share_outlined, 'Partager', () {
                    Clipboard.setData(
                      ClipboardData(
                        text: 'Je voyage avec FasoCovoit : ${t.titreLong}, ${jourCourt(t.heureDepart)} à ${heure(t.heureDepart)}, ${c.vehicule} ${c.plaque}.',
                      ),
                    );
                    message(context, 'Détails du trajet copiés : collez-les dans WhatsApp ou un SMS.');
                  }),
                ),
              ], 8),
            ),
            if (confirme)
              Btn(
                'Suivre le trajet en direct',
                onPressed: () {
                  s.demarrerSuivi(r);
                  ouvrir(context, EnRouteEcran(reservation: r));
                },
              ),
            if (r.statut == StatutResa.confirmee || r.statut == StatutResa.enAttente)
              Lien(
                'Annuler la réservation',
                couleur: C.doux,
                onTap: () => ouvrir(context, AnnulerEcran(reservation: r)),
              ),
          ],
        ),
      ],
    );
  }
}

class _Action extends StatelessWidget {
  const _Action(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Carte(
    padding: const EdgeInsets.all(12),
    onTap: onTap,
    child: Column(
      children: [
        Icon(icon, size: 22),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// 12 · Mes trajets
// ---------------------------------------------------------------------------

class MesTrajetsOnglet extends StatefulWidget {
  const MesTrajetsOnglet({super.key});

  @override
  State<MesTrajetsOnglet> createState() => _MesTrajetsOngletState();
}

class _MesTrajetsOngletState extends State<MesTrajetsOnglet> {
  bool _aVenir = true;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final aVenir = s.aVenir;
    final passes = s.passees;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Piste(paddingBas: 30, children: [Titre('Mes trajets')]),
        Zone(
          gap: 12,
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
          children: [
            Onglets(
              labels: const ['À venir', 'Passés'],
              index: _aVenir ? 0 : 1,
              onChanged: (i) => setState(() => _aVenir = i == 0),
            ),
            if (_aVenir) ...[
              if (aVenir.isEmpty) ...[
                const Carte(child: Text('Aucun trajet à venir.', style: T.petit)),
                Btn('Rechercher un trajet', onPressed: () => s.allerOnglet(0)),
              ],
              for (final r in aVenir) _CarteAVenir(r, premier: r == aVenir.firstWhere((x) => x.statut != StatutResa.enAttente, orElse: () => aVenir.first)),
            ] else ...[
              if (passes.isEmpty) const Carte(child: Text('Aucun trajet passé.', style: T.petit)),
              for (final r in passes) _CartePassee(r),
            ],
          ],
        ),
      ],
    );
  }
}

class _CarteAVenir extends StatelessWidget {
  const _CarteAVenir(this.r, {required this.premier});
  final Reservation r;
  final bool premier;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final t = r.trajet;
    final attente = r.statut == StatutResa.enAttente;
    final restant = r.limiteReponse.difference(s.maintenant).inMinutes.clamp(0, 30);
    final contenu = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            attente
                ? Pastille('En attente · $restant min', ton: TonPastille.etoile, icon: Icons.schedule_rounded)
                : r.statut == StatutResa.enCours
                ? const Pastille('En route', ton: TonPastille.vert, icon: Icons.directions_car_outlined)
                : const Pastille('Confirmée', ton: TonPastille.vert, icon: Icons.check_rounded),
            const Spacer(),
            Doux(jourRelatif(t.heureDepart, s.maintenant), gras: true),
          ],
        ),
        const SizedBox(height: 12),
        RouteRail(
          haut: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${heure(t.heureDepart)} · ${t.interVilles ? t.depart.ville : t.depart.quartier}', style: T.gras),
              Doux(capitaliser(t.interVilles ? t.depart.quartier : t.rdv)),
            ],
          ),
          bas: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${heure(t.heureArrivee)} · ${t.interVilles ? t.arrivee.ville : t.arrivee.quartier}', style: T.gras),
              Doux(capitaliser(t.interVilles ? t.arrivee.quartier : t.arrivee.ville)),
            ],
          ),
        ),
        if (!attente) ...[
          const SizedBox(height: 12),
          const Sep(),
          const SizedBox(height: 12),
          Row(
            children: [
              Ava(t.conducteur.initiales, ton: t.conducteur.ton, taille: 34),
              const SizedBox(width: 8),
              Expanded(child: Text(t.conducteur.court, style: T.gras)),
              const Icon(Icons.confirmation_number_outlined, size: 20, color: C.vertF),
              const SizedBox(width: 8),
              const Text('Mon billet', style: TextStyle(fontWeight: FontWeight.w700, color: C.vertF)),
            ],
          ),
        ],
      ],
    );
    void ouvrirResa() => ouvrir(
      context,
      attente ? AttenteEcran(reservation: r) : BilletEcran(reservation: r),
    );
    return premier && !attente
        ? Carte.sel(onTap: ouvrirResa, child: contenu)
        : Carte(onTap: ouvrirResa, child: contenu);
  }
}

class _CartePassee extends StatelessWidget {
  const _CartePassee(this.r);
  final Reservation r;

  @override
  Widget build(BuildContext context) {
    final t = r.trajet;
    final date = dateCourte(t.heureDepart);
    final termine = r.statut == StatutResa.terminee;
    final remb = r.montant == 0 ? 0 : r.rembourse * 100 ~/ r.montant;
    return Carte(
      onTap: termine && !r.notee ? () => ouvrir(context, NoterEcran(reservation: r)) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Pastille(switch (r.statut) {
                StatutResa.terminee => 'Terminé · $date',
                StatutResa.expiree => 'Sans réponse · $date',
                _ => 'Annulé · $date',
              }),
              const Spacer(),
              if (termine && !r.notee)
                const Pastille('À noter', ton: TonPastille.etoile, icon: Icons.star_rounded)
              else if (termine)
                const Doux('Noté', gras: true)
              else if (r.paiement == Paiement.especes)
                const Doux('Sans frais', gras: true)
              else
                Text(
                  remb == 100 ? 'Remboursé 100 %' : (r.rembourse > 0 ? 'Remboursé ${fcfa(r.rembourse)}' : 'Non remboursé'),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: C.vertF),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(t.titreLong, style: T.gras),
          Doux(
            termine
                ? 'Avec ${t.conducteur.court} · ${fcfa(r.montant)} ${r.paiement == Paiement.especes ? 'en espèces' : 'payés par ${r.paiement.label}'}'
                : r.statut == StatutResa.expiree
                ? 'Le conducteur n’a pas répondu à temps'
                : (r.annuleeParConducteur ? 'Annulé par le conducteur' : 'Annulé par vous'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 13 · Annuler (B7, C3) et règles d'annulation
// ---------------------------------------------------------------------------

class AnnulerEcran extends StatefulWidget {
  const AnnulerEcran({super.key, required this.reservation});
  final Reservation reservation;

  @override
  State<AnnulerEcran> createState() => _AnnulerEcranState();
}

class _AnnulerEcranState extends State<AnnulerEcran> {
  String _raison = 'Mes plans ont changé';

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final r = widget.reservation;
    final t = r.trajet;
    final taux = s.tauxPour(r);
    final montant = r.paiement == Paiement.especes ? 0 : r.montant * taux ~/ 100;
    final ou = switch (r.paiement) {
      Paiement.portefeuille => 'sur votre portefeuille, tout de suite',
      Paiement.orange || Paiement.moov => 'sur votre ${r.paiement.label} sous 72 h',
      Paiement.especes => 'vous n’aviez rien payé en ligne',
    };
    final attente = r.statut == StatutResa.enAttente;
    return Ecran(
      children: [
        Barre(
          titre: attente ? 'Annuler la demande' : 'Annuler la réservation',
          sousTitre: '${t.titre} · ${jourRelatif(t.heureDepart, s.maintenant).toLowerCase()} ${heure(t.heureDepart)}',
        ),
        Zone(
          gap: 14,
          children: [
            Carte.sombre(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.paiement == Paiement.especes ? 'Annulation' : 'Vous serez remboursé',
                    style: const TextStyle(fontSize: 14, color: C.beige),
                  ),
                  Text(
                    r.paiement == Paiement.especes ? 'Sans frais' : fcfa(montant),
                    style: T.titre(34, color: C.etoile),
                  ),
                  Text(
                    r.paiement == Paiement.especes ? capitaliser(ou) : '$taux % · $ou',
                    style: const TextStyle(fontSize: 14, color: C.beige),
                  ),
                ],
              ),
            ),
            if (!attente) ReglesCarte(interVilles: t.interVilles, taux: taux),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Etiq('Pourquoi annulez-vous ? (facultatif)'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final x in const ['Mes plans ont changé', "J'ai trouvé un autre moyen", 'Autre'])
                      Puce(x, on: _raison == x, onTap: () => setState(() => _raison = x)),
                  ],
                ),
              ],
            ),
          ],
          bas: [
            Btn.lat(
              "Confirmer l'annulation",
              onPressed: () {
                var rendu = 0;
                if (essayer(context, () => rendu = s.annulerReservation(r))) {
                  s.allerOnglet(1);
                  retourAccueil(context);
                  message(
                    context,
                    rendu > 0 ? 'Réservation annulée · ${fcfa(rendu)} remboursés' : 'Réservation annulée',
                  );
                }
              },
            ),
            BtnClair(attente ? 'Garder ma demande' : 'Garder ma place', onPressed: () => Navigator.pop(context)),
          ],
        ),
      ],
    );
  }
}

/// Tableau des règles d'annulation, avec la ligne qui s'applique.
class ReglesCarte extends StatelessWidget {
  const ReglesCarte({super.key, required this.interVilles, this.taux});
  final bool interVilles;
  final int? taux;

  @override
  Widget build(BuildContext context) {
    final lignes = interVilles
        ? const [('Plus de 24 h avant le départ', 100), ('Entre 24 h et 2 h avant', 50), ('Moins de 2 h avant ou absent', 0)]
        : const [("Avant l'arrivée du conducteur", 100), ('Après son arrivée ou absent', 0)];
    return Carte(
      padding: const EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Doux(
              interVilles ? 'Règles pour un trajet entre villes' : 'Règles pour un trajet en ville',
              taille: 14,
              gras: true,
            ),
          ),
          for (final (label, pct) in lignes)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: taux == pct ? C.vertC : null,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(label, style: T.gras),
                        if (taux == pct) const Pastille('Votre cas', ton: TonPastille.vert),
                      ],
                    ),
                  ),
                  Text('$pct %', style: T.gras),
                ],
              ),
            ),
          const Sep(marge: EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
            child: Doux(
              interVilles
                  ? "En ville : gratuit jusqu'à l'arrivée du conducteur. Si le conducteur annule ou a plus de 15 min de retard : 100 %."
                  : 'Si le conducteur annule ou a plus de 15 min de retard : 100 %.',
            ),
          ),
        ],
      ),
    );
  }
}

class ReglesAnnulationEcran extends StatelessWidget {
  const ReglesAnnulationEcran({super.key});

  @override
  Widget build(BuildContext context) => const Ecran(
    children: [
      Barre(titre: "Règles d'annulation"),
      Zone(
        gap: 14,
        children: [
          ReglesCarte(interVilles: true),
          ReglesCarte(interVilles: false),
          Bandeau(
            'Payé avec le portefeuille : le remboursement arrive tout de suite. '
            'Payé par Orange Money ou Moov Money : sous 72 h. Espèces : rien à rembourser.',
          ),
        ],
      ),
    ],
  );
}

/// Carte du trajet en cours : Google Maps si la clé est configurée, sinon dessin.
class CarteDuTrajet extends StatelessWidget {
  const CarteDuTrajet({super.key, required this.depart, required this.arrivee, this.progression = .58});
  final Lieu depart;
  final Lieu arrivee;
  final double progression;

  @override
  Widget build(BuildContext context) {
    if (GoogleMapsRouteEmbed.disponible) {
      return GoogleMapsRouteEmbed(
        departure: '${depart.quartier}, ${depart.ville}, Burkina Faso',
        destination: '${arrivee.quartier}, ${arrivee.ville}, Burkina Faso',
        height: null,
      );
    }
    final inter = depart.ville != arrivee.ville;
    return Semantics(
      image: true,
      label: 'Carte : la voiture est en route vers ${arrivee.ville}',
      child: CustomPaint(
        size: Size.infinite,
        painter: CarteTrajetPainter(
          villeDepart: inter ? depart.ville : depart.quartier,
          villeArrivee: inter ? arrivee.ville : arrivee.quartier,
          etape: inter && arrivee.ville == 'Koudougou' ? 'Sabou' : '',
          progression: progression,
        ),
      ),
    );
  }
}
