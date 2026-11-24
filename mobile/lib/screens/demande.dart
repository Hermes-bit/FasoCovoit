import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../carte.dart';
import '../formats.dart';
import '../model.dart';
import '../painters.dart';
import '../theme.dart';
import '../ui.dart';
import 'lieux.dart';
import 'passager.dart';
import 'portefeuille.dart';

// ---------------------------------------------------------------------------
// Parcours passager simple : une question par écran. Le passager envoie sa
// demande, les conducteurs qui passent par là l'acceptent, il en choisit un.
// ---------------------------------------------------------------------------

String _libelle(Lieu l) => '${capitaliser(l.quartier)}, ${villeCourte(l.ville)}';

/// Carte à choix unique, façon bouton radio.
class ChoixRadio extends StatelessWidget {
  const ChoixRadio({
    super.key,
    required this.titre,
    required this.on,
    required this.onTap,
    this.sous,
    this.suite,
    this.detail,
  });
  final String titre;
  final String? sous;
  final bool on;
  final VoidCallback onTap;

  /// À droite du titre (logo du moyen de paiement…).
  final Widget? suite;

  /// Affiché sous le titre quand ce choix est sélectionné.
  final Widget? detail;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: on,
    button: true,
    label: titre,
    child: Material(
      color: C.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: on ? C.laterite : C.trait, width: on ? 2 : 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: on ? C.laterite : C.trait, width: 2),
                    ),
                    child: on
                        ? Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(color: C.laterite, shape: BoxShape.circle),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(titre, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        if (sous != null) Doux(sous!),
                      ],
                    ),
                  ),
                  ?suite,
                ],
              ),
              if (on && detail != null) ...[const SizedBox(height: 12), detail!],
            ],
          ),
        ),
      ),
    ),
  );
}

/// Ligne avec compteur rond « − 1 + ».
class LigneCompteur extends StatelessWidget {
  const LigneCompteur({
    super.key,
    required this.titre,
    required this.sous,
    required this.valeur,
    required this.onMoins,
    required this.onPlus,
    this.icone,
  });
  final String titre;
  final String sous;
  final int valeur;
  final VoidCallback? onMoins;
  final VoidCallback? onPlus;
  final IconData? icone;

  Widget _bouton(IconData i, String label, VoidCallback? onTap) => Semantics(
    button: true,
    enabled: onTap != null,
    label: label,
    excludeSemantics: true,
    child: InkResponse(
      onTap: onTap,
      radius: 26,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: onTap == null ? C.sable : C.sable2, shape: BoxShape.circle),
            child: Icon(i, size: 20, color: onTap == null ? C.trait : C.encre),
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 8, 6, 8),
    decoration: BoxDecoration(
      color: C.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: C.trait, width: 1.5),
    ),
    child: Row(
      children: [
        if (icone != null) ...[Icon(icone, size: 24), const SizedBox(width: 12)],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titre, style: T.gras),
              Doux(sous),
            ],
          ),
        ),
        _bouton(Icons.remove_rounded, 'Moins : $titre', onMoins),
        SizedBox(
          width: 28,
          child: Text(
            '$valeur',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            semanticsLabel: '$titre : $valeur',
          ),
        ),
        _bouton(Icons.add_rounded, 'Plus : $titre', onPlus),
      ],
    ),
  );
}

/// Barres de progression des étapes.
class SegmentsEtapes extends StatelessWidget {
  const SegmentsEtapes({super.key, required this.total, required this.actuelle});
  final int total;
  final int actuelle;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Étape ${actuelle + 1} sur $total',
    excludeSemantics: true,
    child: Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 5,
              decoration: BoxDecoration(
                color: i <= actuelle ? C.laterite : C.trait,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

/// Conseil, avec une ampoule.
class Astuce extends StatelessWidget {
  const Astuce(this.texte, {super.key});
  final String texte;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: C.etoileC, borderRadius: BorderRadius.circular(16)),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.lightbulb_outline_rounded, color: C.etoileF, size: 22),
        const SizedBox(width: 10),
        Expanded(child: Text(texte, style: const TextStyle(fontSize: 14, height: 1.4))),
      ],
    ),
  );
}

/// Information sur fond clair (dans les cartes d'offre).
class _Info extends StatelessWidget {
  const _Info(this.icone, this.texte);
  final IconData icone;
  final String texte;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(color: C.sable, borderRadius: BorderRadius.circular(12)),
    child: Row(
      children: [
        Icon(icone, size: 18, color: C.doux),
        const SizedBox(width: 8),
        Expanded(
          child: Text(texte, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );
}

/// Bouton rond « Retour » posé sur une carte.
class _RetourRond extends StatelessWidget {
  const _RetourRond();

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(color: C.surface, shape: BoxShape.circle, boxShadow: ombreDouce),
    child: IconeBtn(
      icon: Icons.chevron_left_rounded,
      label: 'Retour',
      taille: 28,
      onTap: () => Navigator.maybePop(context),
    ),
  );
}

// ---------------------------------------------------------------------------
// 1 · Votre itinéraire
// ---------------------------------------------------------------------------

class ItineraireEcran extends StatefulWidget {
  const ItineraireEcran({super.key});

  @override
  State<ItineraireEcran> createState() => _ItineraireEcranState();
}

class _ItineraireEcranState extends State<ItineraireEcran> {
  Lieu? _depart;
  Lieu? _arrivee;
  final _texteDepart = TextEditingController();
  final _texteArrivee = TextEditingController();
  final _focusDepart = FocusNode();
  final _focusArrivee = FocusNode();
  bool _surDepart = false;
  int _onglet = 0;

  @override
  void initState() {
    super.initState();
    final s = AppScope.read(context);
    // Départ par défaut : le lieu favori (la maison), sinon le plus récent.
    _depart = s.lieuxFavoris.isNotEmpty ? s.lieuxFavoris.first : (s.lieuxRecents.isEmpty ? null : s.lieuxRecents.first);
    if (_depart != null) _texteDepart.text = _libelle(_depart!);
    _surDepart = _depart == null;
    void suivre() => setState(() {});
    _texteDepart.addListener(suivre);
    _texteArrivee.addListener(suivre);
    _focusDepart.addListener(() {
      if (_focusDepart.hasFocus) setState(() => _surDepart = true);
    });
    _focusArrivee.addListener(() {
      if (_focusArrivee.hasFocus) setState(() => _surDepart = false);
    });
  }

  @override
  void dispose() {
    _texteDepart.dispose();
    _texteArrivee.dispose();
    _focusDepart.dispose();
    _focusArrivee.dispose();
    super.dispose();
  }

  /// Texte recherché dans le champ actif (vide s'il affiche déjà le lieu choisi).
  String get _requete {
    final lieu = _surDepart ? _depart : _arrivee;
    final texte = (_surDepart ? _texteDepart : _texteArrivee).text;
    return lieu != null && texte == _libelle(lieu) ? '' : texte;
  }

  void _choisir(Lieu l) {
    setState(() {
      if (_surDepart) {
        _depart = l;
        _texteDepart.text = _libelle(l);
        if (_arrivee == null) _focusArrivee.requestFocus();
      } else {
        _arrivee = l;
        _texteArrivee.text = _libelle(l);
      }
    });
    if (_depart != null && _arrivee != null) _continuer();
  }

  void _inverser() => setState(() {
    final d = _depart;
    _depart = _arrivee;
    _arrivee = d;
    _texteDepart.text = _depart == null ? '' : _libelle(_depart!);
    _texteArrivee.text = _arrivee == null ? '' : _libelle(_arrivee!);
  });

  Future<void> _continuer() async {
    final d = _depart, a = _arrivee;
    if (d == null || a == null) return;
    if (d == a) {
      message(context, 'Le départ et l’arrivée doivent être différents.');
      return;
    }
    FocusScope.of(context).unfocus();
    final modifier = await ouvrir<String>(context, ConfirmerAdressesEcran(depart: d, arrivee: a));
    if (!mounted || modifier == null) return;
    // « Modifier » sur la carte : on revient au champ concerné.
    setState(() {
      if (modifier == 'depart') {
        _texteDepart.clear();
        _focusDepart.requestFocus();
      } else {
        _texteArrivee.clear();
        _focusArrivee.requestFocus();
      }
    });
  }

  Widget _champ({
    required TextEditingController ctrl,
    required FocusNode focus,
    required String hint,
    required Color couleur,
    required IconData icone,
    bool autofocus = false,
  }) => TextField(
    controller: ctrl,
    focusNode: focus,
    autofocus: autofocus,
    textInputAction: TextInputAction.search,
    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    decoration: InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: C.sable,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 15),
      prefixIcon: Icon(icone, color: couleur, size: 20),
      suffixIcon: ctrl.text.isEmpty
          ? null
          : IconButton(tooltip: 'Effacer', icon: const Icon(Icons.close_rounded, size: 20), onPressed: ctrl.clear),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: C.trait, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: C.laterite, width: 2),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final requete = _requete;
    final liste = _onglet == 0 ? s.lieuxRecents : s.lieuxFavoris.toList();
    final exclu = _surDepart ? _arrivee : _depart;
    return Ecran(
      fond: C.surface,
      children: [
        const Barre(titre: 'Votre itinéraire'),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                label: 'Départ',
                child: _champ(
                  ctrl: _texteDepart,
                  focus: _focusDepart,
                  hint: 'Départ : quartier, adresse…',
                  couleur: C.vert,
                  icone: Icons.trip_origin_rounded,
                  autofocus: _depart == null,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      label: 'Arrivée',
                      child: _champ(
                        ctrl: _texteArrivee,
                        focus: _focusArrivee,
                        hint: "Adresse d'arrivée",
                        couleur: C.laterite,
                        icone: Icons.place_rounded,
                        autofocus: _depart != null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconeBtn(
                    icon: Icons.swap_vert_rounded,
                    label: 'Inverser départ et arrivée',
                    bord: true,
                    onTap: _inverser,
                  ),
                ],
              ),
              if (requete.isEmpty) ...[
                const SizedBox(height: 14),
                Onglets(
                  labels: const ['Historique', 'Favoris'],
                  index: _onglet,
                  onChanged: (i) => setState(() => _onglet = i),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: ResultatsLieux(
            requete: requete,
            exclu: exclu,
            actuel: _surDepart ? _depart : _arrivee,
            onChoisi: _choisir,
            // Sans saisie : historique ou favoris, puis les lieux connus.
            entete: requete.isNotEmpty
                ? const []
                : [
                    if (liste.where((l) => l != exclu).isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Doux(
                          _onglet == 0
                              ? 'Vos derniers lieux apparaîtront ici.'
                              : 'Touchez l’étoile d’un lieu pour le garder en favori.',
                          taille: 14,
                        ),
                      )
                    else ...[
                      ListeCarte(
                        children: [
                          for (final l in liste)
                            if (l != exclu)
                              LigneListe(
                                onTap: () => _choisir(l),
                                children: [
                                  Icon(_onglet == 0 ? Icons.history_rounded : Icons.home_outlined, size: 22),
                                  Bloc(capitaliser(l.quartier), l.ville),
                                  IconeBtn(
                                    icon: s.lieuxFavoris.contains(l) ? Icons.star_rounded : Icons.star_border_rounded,
                                    label: s.lieuxFavoris.contains(l) ? 'Retirer des favoris' : 'Ajouter aux favoris',
                                    couleur: s.lieuxFavoris.contains(l) ? C.etoile : C.doux,
                                    onTap: () => s.basculerFavori(l),
                                  ),
                                ],
                              ),
                        ],
                      ),
                      const SizedBox(height: 18),
                    ],
                    const Doux('Lieux connus', taille: 14, gras: true),
                    const SizedBox(height: 8),
                  ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 2 · Confirmer les adresses sur la carte
// ---------------------------------------------------------------------------

class ConfirmerAdressesEcran extends StatelessWidget {
  const ConfirmerAdressesEcran({super.key, required this.depart, required this.arrivee});
  final Lieu depart;
  final Lieu arrivee;

  Widget _etiquette(BuildContext context, String label, Lieu l, Color couleur, String retour) => Container(
    decoration: BoxDecoration(color: C.surface, borderRadius: BorderRadius.circular(16), boxShadow: ombreDouce),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: couleur, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Doux(label),
                Text(l.complet, style: T.gras, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          IconeBtn(
            icon: Icons.edit_outlined,
            label: 'Modifier : ${label.toLowerCase()}',
            taille: 20,
            onTap: () => Navigator.pop(context, retour),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final haut = MediaQuery.paddingOf(context).top;
    final bas = MediaQuery.paddingOf(context).bottom;
    final ligne = Ligne.entre(depart, arrivee);
    return Scaffold(
      backgroundColor: Plan.terre,
      body: Stack(
        children: [
          Positioned.fill(
            child: CarteRoute(depart: depart, arrivee: arrivee, margeHaut: 200, margeBas: 150),
          ),
          Positioned(
            top: 12 + haut,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _RetourRond(),
                const SizedBox(height: 10),
                _etiquette(context, 'Départ', depart, C.vert, 'depart'),
                const SizedBox(height: 8),
                _etiquette(context, 'Arrivée', arrivee, C.laterite, 'arrivee'),
              ],
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16 + bas,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Pastille(
                    '${ligne.km} km · environ ${duree(ligne.duree)}',
                    icon: Icons.route_outlined,
                    fond: C.surface,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                ),
                const SizedBox(height: 10),
                Btn(
                  'Confirmer les adresses',
                  onPressed: () => ouvrir(context, DemandeEcran(depart: depart, arrivee: arrivee)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3 · Quatre questions : quand, qui, quoi, comment
// ---------------------------------------------------------------------------

DateTime _arrondi5(DateTime d) {
  final m = (d.minute + 4) ~/ 5 * 5;
  return DateTime(d.year, d.month, d.day, d.hour).add(Duration(minutes: m));
}

class DemandeEcran extends StatefulWidget {
  const DemandeEcran({super.key, required this.depart, required this.arrivee});
  final Lieu depart;
  final Lieu arrivee;

  @override
  State<DemandeEcran> createState() => _DemandeEcranState();
}

class _DemandeEcranState extends State<DemandeEcran> {
  static const _titres = [
    'Quand souhaitez-vous partir ?',
    'Qui voyage ?',
    'Que transportez-vous ?',
    'Comment réglez-vous ?',
  ];
  int _etape = 0;
  bool _plusTard = false;
  late DateTime _quand;
  late DateTime _min;
  int _adultes = 1;
  int _enfants = 0;
  int _bagages = 0;
  int _poussettes = 0;
  final _autre = TextEditingController();
  late Paiement _paiement;

  bool get _inter => widget.depart.ville != widget.arrivee.ville;

  @override
  void initState() {
    super.initState();
    final s = AppScope.read(context);
    final n = s.maintenant;
    _min = _arrondi5(n);
    // Entre villes, on part souvent le lendemain matin ; en ville, dans l'heure.
    final defaut = _inter ? DateTime(n.year, n.month, n.day + 1, 7) : _arrondi5(n.add(const Duration(hours: 1)));
    _quand = defaut.isBefore(_min) ? _min : defaut;
    _plusTard = _inter;
    _paiement = s.solde > 0 ? Paiement.portefeuille : Paiement.especes;
  }

  @override
  void dispose() {
    _autre.dispose();
    super.dispose();
  }

  void _envoyer() {
    final s = AppScope.read(context);
    DemandeTrajet? d;
    final ok = essayer(context, () {
      d = s.demanderTrajet(
        depart: widget.depart,
        arrivee: widget.arrivee,
        quand: _plusTard ? _quand : null,
        adultes: _adultes,
        enfants: _enfants,
        bagages: _bagages,
        poussettes: _poussettes,
        autre: _autre.text,
        paiement: _paiement,
      );
    });
    if (!ok) return;
    Navigator.of(
      context,
    ).pushAndRemoveUntil(MaterialPageRoute<void>(builder: (_) => RechercheEcran(demande: d!)), (r) => r.isFirst);
  }

  List<Widget> _quandContenu(AppState s) => [
    ChoixRadio(
      titre: 'Maintenant',
      sous: 'Les conducteurs qui passent tout près sont prévenus',
      on: !_plusTard,
      onTap: () => setState(() => _plusTard = false),
    ),
    ChoixRadio(
      titre: 'Plus tard',
      sous: _plusTard
          ? '${jourRelatifComplet(_quand, s.maintenant)} · ${heure(_quand)}'
          : 'Choisissez le jour et l’heure',
      on: _plusTard,
      onTap: () => setState(() => _plusTard = true),
      detail: SizedBox(
        height: 180,
        child: CupertinoTheme(
          data: const CupertinoThemeData(
            primaryColor: C.laterite,
            textTheme: CupertinoTextThemeData(
              dateTimePickerTextStyle: TextStyle(fontFamily: 'Figtree', fontSize: 19, color: C.encre),
            ),
          ),
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.dateAndTime,
            use24hFormat: true,
            minuteInterval: 5,
            initialDateTime: _quand,
            minimumDate: _min,
            maximumDate: _min.add(const Duration(days: 60)),
            onDateTimeChanged: (d) => setState(() => _quand = d),
          ),
        ),
      ),
    ),
  ];

  List<Widget> _quiContenu() => [
    LigneCompteur(
      titre: 'Adultes',
      sous: '11 ans et plus',
      valeur: _adultes,
      onMoins: _adultes > 1 ? () => setState(() => _adultes--) : null,
      onPlus: _adultes + _enfants < 4 ? () => setState(() => _adultes++) : null,
    ),
    LigneCompteur(
      titre: 'Enfants',
      sous: 'De 0 à 10 ans',
      valeur: _enfants,
      onMoins: _enfants > 0 ? () => setState(() => _enfants--) : null,
      onPlus: _adultes + _enfants < 4 ? () => setState(() => _enfants++) : null,
    ),
    const Doux('Une place par personne, enfants compris : 4 places au plus.', taille: 14),
  ];

  List<Widget> _quoiContenu() => [
    const Astuce(
      'Indiquez ce qui prend de la place : le conducteur vérifie qu’il a assez de place dans sa voiture. '
      'Sans cela, il pourrait devoir annuler le trajet.',
    ),
    LigneCompteur(
      titre: 'Bagage',
      sous: 'Gros sac ou valise',
      icone: Icons.luggage_outlined,
      valeur: _bagages,
      onMoins: _bagages > 0 ? () => setState(() => _bagages--) : null,
      onPlus: _bagages < 4 ? () => setState(() => _bagages++) : null,
    ),
    LigneCompteur(
      titre: 'Poussette',
      sous: 'Simple ou double',
      icone: Icons.child_friendly_outlined,
      valeur: _poussettes,
      onMoins: _poussettes > 0 ? () => setState(() => _poussettes--) : null,
      onPlus: _poussettes < 2 ? () => setState(() => _poussettes++) : null,
    ),
    Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: C.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: C.trait, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.inventory_2_outlined, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Autre chose', style: T.gras),
                    Doux('Dites-le à votre conducteur'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Champ(controller: _autre, hint: 'Un sac de céréales, un carton…', label: 'Autre chose à transporter'),
        ],
      ),
    ),
  ];

  List<Widget> _commentContenu(AppState s, int total) {
    final bonus = s.bonusUtilisable(total);
    final manque = _paiement == Paiement.portefeuille ? total - bonus - s.depose : 0;
    return [
      for (final p in Paiement.values)
        ChoixRadio(
          titre: p.label,
          sous: switch (p) {
            Paiement.portefeuille => 'Solde ${fcfa(s.solde)}',
            Paiement.orange || Paiement.moov => 'Payé quand vous choisissez votre conducteur',
            Paiement.especes => 'Au conducteur, au départ',
          },
          suite: LogoPaiement(p),
          on: _paiement == p,
          onTap: () => setState(() => _paiement = p),
          detail: switch (p) {
            Paiement.especes => const Astuce('Prévoyez le montant exact : le conducteur n’a pas toujours la monnaie.'),
            Paiement.portefeuille =>
              manque > 0
                  ? Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Il manque environ ${fcfa(manque)}.',
                            style: const TextStyle(fontWeight: FontWeight.w700, color: C.sos),
                          ),
                        ),
                        BtnP('Déposer', onPressed: () => ouvrir(context, const DeposerEcran())),
                      ],
                    )
                  : Doux(
                      bonus > 0
                          ? 'Dont ${fcfa(bonus)} de bonus. Bloqué jusqu’à la fin du trajet.'
                          : 'Bloqué jusqu’à la fin du trajet, remboursé selon les règles d’annulation.',
                    ),
            _ => Doux('Une demande de paiement arrivera sur le ${s.telephone}.'),
          },
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final ligne = Ligne.entre(widget.depart, widget.arrivee);
    final tarif = calculerTarif(ligne);
    final places = _adultes + _enfants;
    final total = tarif.conseille * places;
    final manque = _paiement == Paiement.portefeuille ? total - s.bonusUtilisable(total) - s.depose : 0;
    final contenu = switch (_etape) {
      0 => _quandContenu(s),
      1 => _quiContenu(),
      2 => _quoiContenu(),
      _ => _commentContenu(s, total),
    };
    return Scaffold(
      backgroundColor: C.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: SegmentsEtapes(total: 4, actuelle: _etape),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(header: true, child: Text(_titres[_etape], style: T.titre(24))),
                    const SizedBox(height: 18),
                    ...espacer(contenu, 12),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_etape == 3) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: C.trait, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Total', style: T.gras),
                                Doux('Prix conseillé, plafonné'),
                              ],
                            ),
                          ),
                          Text(fcfa(total), style: T.titre(22)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: BtnClair(
                          'Retour',
                          onPressed: () => _etape == 0 ? Navigator.pop(context) : setState(() => _etape--),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Btn(
                          _etape == 3 ? 'Confirmer' : 'Suivant',
                          hauteur: 52,
                          onPressed: _etape < 3 ? () => setState(() => _etape++) : (manque > 0 ? null : _envoyer),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 4 · Recherche en cours, puis les conducteurs qui acceptent
// ---------------------------------------------------------------------------

Future<void> supprimerDemande(BuildContext context, DemandeTrajet d) async {
  final s = AppScope.read(context);
  final ok = await confirmer(
    context,
    titre: 'Votre demande va être supprimée, souhaitez-vous continuer ?',
    texte: d.offres.isEmpty
        ? 'Les conducteurs contactés ne la verront plus.'
        : 'Un ou plusieurs conducteurs ont accepté votre demande.',
    oui: 'Supprimer ma demande',
    non: 'Annuler',
    danger: true,
  );
  if (!ok || !context.mounted) return;
  s.retirerDemande(d);
  retourAccueil(context);
  message(context, 'Votre demande a été supprimée.');
}

class RechercheEcran extends StatefulWidget {
  const RechercheEcran({super.key, required this.demande});
  final DemandeTrajet demande;

  /// Délai entre deux réponses de conducteurs (démonstration).
  static const rythme = Duration(seconds: 3);

  @override
  State<RechercheEcran> createState() => _RechercheEcranState();
}

class _RechercheEcranState extends State<RechercheEcran> {
  Timer? _minuterie;

  @override
  void initState() {
    super.initState();
    _minuterie = Timer.periodic(RechercheEcran.rythme, (_) {
      final s = AppScope.read(context);
      final d = widget.demande;
      if (!s.demandesTrajet.contains(d) || d.offres.length >= 4) {
        _minuterie?.cancel();
        return;
      }
      s.recevoirOffre(d);
    });
  }

  @override
  void dispose() {
    _minuterie?.cancel();
    super.dispose();
  }

  Widget _progres(int contactes) => Semantics(
    label: '$contactes conducteurs contactés',
    excludeSemantics: true,
    child: Center(
      child: SizedBox(
        width: 120,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: (0.08 + contactes / 14).clamp(0.0, 1.0),
            minHeight: 6,
            color: C.laterite,
            backgroundColor: C.sable2,
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final d = widget.demande;
    final offres = s.offresValables(d);
    final actif = s.demandesTrajet.contains(d);
    final quand = d.desQuePossible
        ? 'maintenant'
        : '${jourRelatif(d.quand, s.maintenant).toLowerCase()} vers ${heure(d.quand)}';
    final supprimer = Lien(
      'Supprimer ma demande',
      couleur: C.sos,
      souligne: false,
      taille: 15,
      onTap: () => supprimerDemande(context, d),
    );
    return Scaffold(
      backgroundColor: C.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
              child: Row(
                children: [
                  IconeBtn(
                    icon: Icons.close_rounded,
                    label: 'Fermer',
                    taille: 28,
                    onTap: () => Navigator.maybePop(context),
                  ),
                ],
              ),
            ),
            if (!actif)
              const Expanded(child: Center(child: Doux('Cette demande n’est plus active.', taille: 15)))
            else if (offres.isEmpty)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      SizedBox(width: 190, height: 150, child: CustomPaint(painter: IllustrationRecherchePainter())),
                      const SizedBox(height: 22),
                      _progres(d.contactes),
                      const SizedBox(height: 22),
                      Semantics(
                        liveRegion: true,
                        child: Text('Recherche en cours…', textAlign: TextAlign.center, style: T.titre(24)),
                      ),
                      const SizedBox(height: 10),
                      Doux(
                        'Nous contactons les conducteurs qui passent par ${capitaliser(d.depart.quartier)} $quand. '
                        'Dès qu’un conducteur accepte, il apparaît ici.',
                        taille: 15,
                        align: TextAlign.center,
                      ),
                      const Spacer(),
                      const Icon(Icons.lightbulb_outline_rounded, color: C.etoileF),
                      const SizedBox(height: 6),
                      const Doux(
                        'Vous pouvez fermer : votre demande reste dans « Mes covoit’ » sur l’accueil.',
                        taille: 14,
                        align: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      supprimer,
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              )
            else ...[
              _progres(d.contactes),
              const SizedBox(height: 14),
              Semantics(
                liveRegion: true,
                child: Text(
                  pluriel(offres.length, 'acceptation conducteur', 'acceptations conducteurs'),
                  textAlign: TextAlign.center,
                  style: T.titre(22),
                ),
              ),
              Doux('${d.contactes} conducteurs contactés', align: TextAlign.center, taille: 14),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: espacer([for (final o in offres) _CarteOffre(d, o)], 14),
                ),
              ),
              Padding(padding: const EdgeInsets.only(bottom: 12), child: supprimer),
            ],
          ],
        ),
      ),
    );
  }
}

String _fiabilite(Conducteur c) => c.nouveau
    ? 'Nouveau sur FasoCovoit · documents vérifiés'
    : c.annulations == 0
    ? 'N’annule jamais'
    : '${pluriel(c.annulations, 'annulation')} ces 30 derniers jours';

class _CarteOffre extends StatelessWidget {
  const _CarteOffre(this.d, this.o);
  final DemandeTrajet d;
  final Offre o;

  @override
  Widget build(BuildContext context) {
    final c = o.trajet.conducteur;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: C.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: C.trait, width: 1.5),
        boxShadow: ombreDouce,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.schedule_rounded, size: 16, color: C.laterite),
              const SizedBox(width: 6),
              Text(
                'CONFIRMER AVANT ${heure(o.limite)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .6,
                  color: C.lateriteF,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: Text('${capitaliser(jourCourt(o.passage))} · ${heure(o.passage)}', style: T.titre(18))),
              Pastille(fcfa(o.prix * d.places), icon: Icons.payments_outlined, ton: TonPastille.vert),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Ava(c.initiales, ton: c.ton),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.court, style: T.gras),
                    c.nouveau ? const Doux('Pas encore noté') : LigneNote(note: c.note, suite: ' (${c.trajets} avis)'),
                    Doux(capitaliser(c.vehicule)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _Info(
            o.minutes != null ? Icons.near_me_outlined : Icons.place_outlined,
            o.minutes != null
                ? '${c.prenom} est à environ ${o.minutes} minutes'
                : 'Passe à ${capitaliser(d.depart.quartier)} vers ${heure(o.passage)}',
          ),
          const SizedBox(height: 6),
          _Info(Icons.verified_outlined, _fiabilite(c)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: BtnClair('Voir détails', onPressed: () => ouvrir(context, ConducteurPublicEcran(conducteur: c))),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Btn(
                  'Accepter',
                  hauteur: 52,
                  onPressed: () => ouvrir(context, OffreEcran(demande: d, offre: o)),
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
// 5 · Le conducteur choisi : confirmer
// ---------------------------------------------------------------------------

class OffreEcran extends StatelessWidget {
  const OffreEcran({super.key, required this.demande, required this.offre});
  final DemandeTrajet demande;
  final Offre offre;

  Future<void> _confirmer(BuildContext context) async {
    final s = AppScope.read(context);
    final d = demande, o = offre;
    if (d.paiement.mobile) {
      final ok = await confirmer(
        context,
        titre: 'Confirmez sur votre téléphone',
        texte:
            'Une demande de paiement de ${fcfa(o.prix * d.places)} arrive sur le ${s.telephone}. '
            'Validez-la avec votre code secret ${d.paiement.label}. FasoCovoit ne vous demandera jamais ce code.\n\n'
            'Prototype : le paiement est simulé.',
        oui: "J'ai confirmé",
        non: 'Annuler',
      );
      if (!ok || !context.mounted) return;
    }
    Reservation? r;
    if (!essayer(context, () => r = s.accepterOffre(d, o))) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => BilletEcran(reservation: r!)),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final d = demande, o = offre;
    final c = o.trajet.conducteur;
    final haut = MediaQuery.paddingOf(context).top;
    final h = MediaQuery.sizeOf(context).height;
    final restant = o.limite.difference(s.maintenant).inMinutes.clamp(0, AppState.delaiOffre.inMinutes);
    final expiree = s.maintenant.isAfter(o.limite);
    final croise = s.correspondancePour(o.trajet, d.depart, d.arrivee);
    Widget stat(IconData i, String haut, String bas) => Column(
      children: [
        Icon(i, size: 26),
        const SizedBox(height: 6),
        Text(haut, style: T.gras, textAlign: TextAlign.center),
        Doux(bas, align: TextAlign.center),
      ],
    );
    Widget adresse(Color couleur, String texte, [String? sous]) => Padding(
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
                Text(texte, style: T.petit),
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
            child: CarteRoute(depart: d.depart, arrivee: d.arrivee, margeHaut: 70, margeBas: 50),
          ),
          Positioned(top: 12 + haut, left: 16, child: const _RetourRond()),
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
                  Text(
                    expiree
                        ? 'CETTE ACCEPTATION A EXPIRÉ'
                        : 'CONFIRMEZ DANS LES ${pluriel(restant, 'MINUTE', 'MINUTES')}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .6,
                      color: C.lateriteF,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Btn('Confirmer', onPressed: expiree ? null : () => _confirmer(context)),
                  const SizedBox(height: 16),
                  Carte(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '${jourRelatif(o.passage, s.maintenant)} ${heure(o.passage)}',
                          textAlign: TextAlign.center,
                          style: T.titre(20),
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => ouvrir(context, ConducteurPublicEcran(conducteur: c)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Ava(c.initiales, ton: c.ton),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(c.court, style: T.gras),
                                      Doux(
                                        c.expert
                                            ? 'Expert · 30+ trajets'
                                            : (c.nouveau ? 'Nouveau conducteur' : pluriel(c.trajets, 'trajet')),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (!c.nouveau) NoteEtoile(c.note),
                                    Doux(c.nouveau ? 'Nouveau' : '${c.trajets} avis'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _Info(Icons.verified_outlined, _fiabilite(c)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  IntrinsicHeight(
                    child: Row(
                      children: [
                        Expanded(child: stat(Icons.payments_outlined, fcfa(o.prix * d.places), d.paiement.label)),
                        const VerticalDivider(color: C.trait, thickness: 1.5, width: 24),
                        Expanded(
                          child: stat(
                            Icons.people_outline_rounded,
                            pluriel(d.places, 'passager'),
                            '${pluriel(d.adultes, 'adulte')}${d.enfants > 0 ? ', ${pluriel(d.enfants, 'enfant')}' : ''}',
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
                        child: Text(d.bagagesTexte, style: T.gras, textAlign: TextAlign.end),
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
                      Text('Itinéraire', style: T.gras),
                    ],
                  ),
                  adresse(
                    C.vert,
                    d.depart.complet,
                    o.minutes != null
                        ? '${c.prenom} vient vous prendre ici'
                        : 'Le conducteur passe vers ${heure(o.passage)}${croise == null ? '' : ' · montée ${ecartTexte(croise.monte)}'}',
                  ),
                  adresse(
                    C.laterite,
                    d.arrivee.complet,
                    croise == null ? null : 'Dépose ${ecartTexte(croise.descend)} de votre adresse',
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Lien(
                      "Règles d'annulation",
                      taille: 14,
                      onTap: () => ouvrir(context, const ReglesAnnulationEcran()),
                    ),
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
// 6 · Profil d'un conducteur : avis et vérifications
// ---------------------------------------------------------------------------

class ConducteurPublicEcran extends StatefulWidget {
  const ConducteurPublicEcran({super.key, required this.conducteur});
  final Conducteur conducteur;

  @override
  State<ConducteurPublicEcran> createState() => _ConducteurPublicEcranState();
}

class _ConducteurPublicEcranState extends State<ConducteurPublicEcran> {
  int _onglet = 0;

  /// Prototype : avis fictifs, cohérents avec la note du conducteur.
  List<(String, int, int, String)> _avis(Conducteur c) => [
    ('Moussa O.', 5, 1, 'Très ponctuel, conduite calme.'),
    if (c.note < 4.5)
      ('Issa T.', 3, 3, 'Un peu en retard au rendez-vous.')
    else
      ('Fatou S.', 5, 3, 'Voiture propre, je recommande.'),
    ('Ali K.', 4, 6, ''),
    ('Rasmata Z.', 5, 9, 'Bon point de rendez-vous.'),
  ];

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = widget.conducteur;
    final avis = <Widget>[
      if (c.nouveau)
        const Carte(
          child: Text(
            'Pas encore d’avis : c’est un nouveau conducteur. Ses documents ont été vérifiés par l’équipe.',
            style: T.petit,
          ),
        )
      else ...[
        for (final (nom, note, jours, texte) in _avis(c))
          LigneListe(
            haut: true,
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: [
              Ava(nom.split(' ').map((m) => m[0]).join(), taille: 38),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(nom, style: T.gras)),
                        Doux(dateCourte(s.maintenant.subtract(Duration(days: jours)))),
                      ],
                    ),
                    Semantics(
                      label: '$note sur 5',
                      excludeSemantics: true,
                      child: Row(
                        children: [for (var k = 0; k < 5; k++) Etoile(size: 15, color: k < note ? C.etoile : C.sable2)],
                      ),
                    ),
                    if (texte.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(texte, style: T.petit),
                      ),
                  ],
                ),
              ),
            ],
          ),
        const SizedBox(height: 8),
        const Doux('Prototype : avis fictifs.'),
      ],
    ];
    final details = <Widget>[
      Row(
        children: [
          const Icon(Icons.directions_car_filled_outlined, size: 40),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(capitaliser(c.vehicule), style: T.gras),
                Doux('Plaque ${c.plaque}${c.climatisee ? ' · climatisée' : ''}', taille: 14),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
      const Sep(),
      const SizedBox(height: 14),
      Text(
        c.annulations == 0
            ? '${c.prenom} n’annule jamais ses covoit’.'
            : '${c.prenom} a annulé ${pluriel(c.annulations, 'trajet')} ces 30 derniers jours.',
        style: T.petit,
      ),
      const SizedBox(height: 14),
      const Sep(),
      const SizedBox(height: 14),
      Doux('${c.prenom}, membre depuis ${c.depuis}, a fait vérifier :', taille: 14),
      const SizedBox(height: 8),
      for (final x in const ['Téléphone', 'CNIB et selfie', 'Permis de conduire', 'Carte grise', 'Assurance'])
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: C.vert, size: 22),
              const SizedBox(width: 10),
              Text(x, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
      const SizedBox(height: 10),
      const Doux(
        'L’équipe contrôle chaque document et rencontre le conducteur avec ses originaux et sa voiture avant de valider son compte.',
      ),
    ];
    return Scaffold(
      backgroundColor: C.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
              child: Row(
                children: [
                  IconeBtn(icon: Icons.arrow_back_rounded, label: 'Retour', onTap: () => Navigator.maybePop(context)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Titre(c.prenom),
                        Text(
                          c.expert ? 'EXPERT · 30+ TRAJETS' : (c.nouveau ? 'NOUVEAU' : '${c.trajets} TRAJETS'),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .6,
                            color: C.lateriteF,
                          ),
                        ),
                        const SizedBox(height: 4),
                        c.nouveau
                            ? const Doux('Pas encore noté')
                            : LigneNote(note: c.note, suite: ' (${c.trajets} avis)'),
                      ],
                    ),
                  ),
                  Ava(c.initiales, ton: c.ton, taille: 72),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Onglets(
                labels: const ['Avis', 'Détails'],
                index: _onglet,
                onChanged: (i) => setState(() => _onglet = i),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: _onglet == 0 ? avis : details,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Demande en cours, sur l'accueil et dans « Mes trajets ».
class CarteDemandeEnCours extends StatelessWidget {
  const CarteDemandeEnCours(this.d, {super.key});
  final DemandeTrajet d;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final n = s.offresValables(d).length;
    return Carte(
      pointillee: n == 0,
      bord: n == 0 ? C.laterite : C.vert,
      epaisseur: n == 0 ? 1.5 : 2.5,
      onTap: () => ouvrir(context, RechercheEcran(demande: d)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: n == 0
                    ? const Pastille('Recherche en cours', ton: TonPastille.etoile, icon: Icons.campaign_outlined)
                    : Pastille(pluriel(n, 'acceptation'), ton: TonPastille.vert, icon: Icons.check_rounded),
              ),
              const SizedBox(width: 8),
              Doux(d.desQuePossible ? 'Maintenant' : jourRelatif(d.quand, s.maintenant), gras: true),
            ],
          ),
          const SizedBox(height: 12),
          RouteRail(
            haut: Text(
              '${d.desQuePossible ? 'Dès que possible' : heure(d.quand)} · ${capitaliser(d.depart.quartier)}',
              style: T.gras,
            ),
            bas: Text('${capitaliser(d.arrivee.quartier)}, ${villeCourte(d.arrivee.ville)}', style: T.gras),
          ),
        ],
      ),
    );
  }
}
