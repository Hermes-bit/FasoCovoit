import 'package:flutter/material.dart';

import '../formats.dart';
import '../model.dart';
import '../painters.dart';
import '../theme.dart';
import '../ui.dart';

const _v2 = Pastille('Bientôt · version 2', fond: C.etoile, texte: C.encre);

void _bientot(BuildContext context) => message(context, 'Le transport de colis arrive en version 2.');

// ---------------------------------------------------------------------------
// 55 · Envoyer un colis
// ---------------------------------------------------------------------------

class ColisEnvoyerEcran extends StatefulWidget {
  const ColisEnvoyerEcran({super.key});

  @override
  State<ColisEnvoyerEcran> createState() => _ColisEnvoyerEcranState();
}

class _ColisEnvoyerEcranState extends State<ColisEnvoyerEcran> {
  static const _tailles = [
    ('S', 'Enveloppe, documents', 1000),
    ('M', 'Sac, 10 kg max', 2000),
    ('L', 'Carton, 25 kg max', 3500),
  ];
  int _taille = 0;
  bool _inter = true;
  final _contenu = TextEditingController(text: 'Documents');
  final _valeur = TextEditingController(text: '20 000 F');
  final _nom = TextEditingController(text: 'Paul Yaméogo');
  final _tel = TextEditingController(text: '+226 76 •• •• 18');

  @override
  void dispose() {
    for (final c in [_contenu, _valeur, _nom, _tel]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prix = _tailles[_taille].$3;
    return Scaffold(
      backgroundColor: C.sable,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  EnteteEncoche(
                    barre: _BasculeTrajet(inter: _inter, onChanged: (v) => setState(() => _inter = v)),
                    children: [
                      Row(
                        children: [
                          Transform.translate(
                            offset: const Offset(-10, 0),
                            child: IconeBtn(
                              icon: Icons.chevron_left_rounded,
                              label: 'Retour',
                              taille: 30,
                              onTap: () => Navigator.of(context).maybePop(),
                            ),
                          ),
                          const Spacer(),
                          _v2,
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Semantics(header: true, child: const Titre('Envoyer un colis', taille: 30)),
                                const SizedBox(height: 6),
                                Text(
                                  'Confié à un conducteur vérifié qui fait déjà le trajet',
                                  style: TextStyle(
                                    fontSize: 15,
                                    height: 1.3,
                                    color: Colors.white.withValues(alpha: .92),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          SizedBox(width: 108, height: 90, child: CustomPaint(painter: IllustrationColisPainter())),
                        ],
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: espacer([
                        _Section(
                          numero: 1,
                          titre: 'Le trajet du colis',
                          child: Carte(
                            child: RouteRail(
                              haut: const _Lieu(
                                'Ouagadougou · Gounghin',
                                'Vous le remettez au conducteur',
                                Pastille('Remise', ton: TonPastille.vert),
                              ),
                              bas: _Lieu(
                                _inter ? 'Koudougou · Secteur 7' : 'Ouagadougou · Ouaga 2000',
                                'Le destinataire le récupère',
                                const Pastille('Livraison', ton: TonPastille.lat),
                              ),
                            ),
                          ),
                        ),
                        _Section(
                          numero: 2,
                          titre: 'Sa taille',
                          child: IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                for (var i = 0; i < _tailles.length; i++) ...[
                                  if (i > 0) const SizedBox(width: 10),
                                  Expanded(
                                    child: _TuileTaille(
                                      index: i,
                                      lettre: _tailles[i].$1,
                                      texte: _tailles[i].$2,
                                      prix: _tailles[i].$3,
                                      on: _taille == i,
                                      onTap: () => setState(() => _taille = i),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        _Section(
                          numero: 3,
                          titre: 'Ce qu’il contient',
                          child: Carte(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: _ChampTitre(
                                        'Contenu',
                                        Champ(controller: _contenu, hauteur: 48, label: 'Contenu'),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _ChampTitre(
                                        'Valeur déclarée',
                                        Champ(controller: _valeur, hauteur: 48, label: 'Valeur déclarée'),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(child: _Photo('Colis ouvert', onTap: () => _bientot(context))),
                                    const SizedBox(width: 10),
                                    Expanded(child: _Photo('Colis fermé', onTap: () => _bientot(context))),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                const Doux('Photos obligatoires : le conducteur les verra avant d’accepter.'),
                              ],
                            ),
                          ),
                        ),
                        _Section(
                          numero: 4,
                          titre: 'Qui le récupère ?',
                          child: Carte(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    ValueListenableBuilder(
                                      valueListenable: _nom,
                                      builder: (_, v, _) => Ava(_initiale(v.text), ton: Ton.vert, taille: 44),
                                    ),
                                    const SizedBox(width: 12),
                                    const Bloc('Destinataire', 'À l’arrivée, avec un code'),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Champ(controller: _nom, hauteur: 48, label: 'Nom du destinataire'),
                                const SizedBox(height: 8),
                                Champ(controller: _tel, hauteur: 48, label: 'Téléphone du destinataire'),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(color: C.vertC, borderRadius: BorderRadius.circular(14)),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.sms_outlined, size: 20, color: C.vertF),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'Il recevra un code par SMS, à donner au conducteur.',
                                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: C.vertF),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        _Interdits(
                          onTap: () => informer(
                            context,
                            'Objets interdits',
                            'Argent liquide, armes, produits dangereux ou inflammables, médicaments sans ordonnance, '
                                'animaux vivants, denrées périssables non emballées.',
                          ),
                        ),
                      ], 22),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Pied(
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: Titre(fcfa(prix), key: ValueKey(prix)),
                    ),
                    const Doux("Prix d'exemple"),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Btn('Trouver un conducteur', onPressed: () => ouvrir(context, const ColisSuiviEcran())),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _initiale(String nom) => nom.trim().isEmpty ? '?' : nom.trim()[0].toUpperCase();

/// Choix En ville / Vers une autre ville, posé dans l'encoche de l'en-tête.
class _BasculeTrajet extends StatelessWidget {
  const _BasculeTrajet({required this.inter, required this.onChanged});
  final bool inter;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget segment(String label, IconData icone, bool valeur) {
      final on = inter == valeur;
      return Expanded(
        child: Semantics(
          button: true,
          selected: on,
          label: label,
          excludeSemantics: true,
          child: GestureDetector(
            onTap: () => onChanged(valeur),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: on ? C.laterite : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icone, size: 18, color: on ? Colors.white : C.doux),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: on ? Colors.white : C.encre),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const ShapeDecoration(
        color: C.surface,
        shape: StadiumBorder(side: BorderSide(color: C.encre, width: 2)),
      ),
      child: Row(
        children: [
          segment('En ville', Icons.location_city_rounded, false),
          segment('Entre villes', Icons.alt_route_rounded, true),
        ],
      ),
    );
  }
}

/// Étape numérotée du formulaire.
class _Section extends StatelessWidget {
  const _Section({required this.numero, required this.titre, required this.child});
  final int numero;
  final String titre;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: C.encre, shape: BoxShape.circle),
            child: Text(
              '$numero',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Semantics(header: true, child: Text(titre, style: T.titre(19))),
          ),
        ],
      ),
      const SizedBox(height: 12),
      child,
    ],
  );
}

/// Lieu de remise ou de livraison, avec sa pastille.
class _Lieu extends StatelessWidget {
  const _Lieu(this.nom, this.detail, this.pastille);
  final String nom;
  final String detail;
  final Widget pastille;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(nom, style: T.gras),
            Doux(detail),
          ],
        ),
      ),
      const SizedBox(width: 8),
      pastille,
    ],
  );
}

/// Taille S, M ou L : dessin, description et prix.
class _TuileTaille extends StatelessWidget {
  const _TuileTaille({
    required this.index,
    required this.lettre,
    required this.texte,
    required this.prix,
    required this.on,
    required this.onTap,
  });
  final int index;
  final String lettre;
  final String texte;
  final int prix;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: on,
    label: 'Taille $lettre, $texte, ${fcfa(prix)}',
    excludeSemantics: true,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: on ? C.lateriteC : C.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: on ? C.laterite : C.trait, width: on ? 2.5 : 1.5),
        boxShadow: on ? ombreDouce : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    SizedBox(
                      height: 50,
                      width: double.infinity,
                      child: CustomPaint(painter: TailleColisPainter(index)),
                    ),
                    if (on)
                      Positioned(
                        top: -6,
                        right: -2,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(color: C.laterite, shape: BoxShape.circle),
                          child: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(lettre, style: T.titre(22)),
                const SizedBox(height: 2),
                Text(
                  texte,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12.5, height: 1.25, color: C.doux),
                ),
                const Spacer(),
                const SizedBox(height: 8),
                Text(
                  fcfa(prix),
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: on ? C.lateriteF : C.encre),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Étiquette au-dessus d'un champ.
class _ChampTitre extends StatelessWidget {
  const _ChampTitre(this.titre, this.champ);
  final String titre;
  final Widget champ;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        titre,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: C.doux),
      ),
      const SizedBox(height: 6),
      champ,
    ],
  );
}

/// Emplacement d'une photo du colis (ouvert, puis fermé).
class _Photo extends StatelessWidget {
  const _Photo(this.label, {required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Carte(
    pointillee: true,
    bord: C.laterite,
    couleur: C.sable,
    rayon: 18,
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
    onTap: onTap,
    child: Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(color: C.lateriteC, shape: BoxShape.circle),
          child: const Icon(Icons.photo_camera_outlined, color: C.laterite),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
      ],
    ),
  );
}

/// Objets interdits : quelques pictogrammes, la liste complète au toucher.
class _Interdits extends StatelessWidget {
  const _Interdits({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Carte(
    couleur: C.sosC,
    bord: C.sosBord,
    onTap: onTap,
    padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
    child: Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Objets interdits',
                style: TextStyle(fontWeight: FontWeight.w800, color: C.sosF),
              ),
              SizedBox(height: 2),
              Text(
                'Argent liquide, armes, produits dangereux…',
                style: TextStyle(fontSize: 13, height: 1.35, color: C.sosF),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        for (final icone in const [
          Icons.payments_outlined,
          Icons.local_fire_department_outlined,
          Icons.medication_outlined,
          Icons.pets_outlined,
        ])
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(color: C.surface, shape: BoxShape.circle),
              child: Icon(icone, size: 17, color: C.sos),
            ),
          ),
        const Icon(Icons.chevron_right_rounded, color: C.sosF),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// 56 · Suivi du colis
// ---------------------------------------------------------------------------

class ColisSuiviEcran extends StatelessWidget {
  const ColisSuiviEcran({super.key});

  @override
  Widget build(BuildContext context) => Ecran(
    children: [
      const Barre(titre: 'Colis CL-4KM7-PQ2', sousTitre: 'Documents · Ouaga → Koudougou', actions: [_v2]),
      Zone(
        gap: 14,
        children: [
          const Carte(
            child: Column(
              children: [
                Etape(EtatEtape.fait, 'Colis créé et payé', 'Exemple · 1 000 F'),
                Etape(EtatEtape.fait, 'Remis au conducteur', 'QR scanné par le conducteur · photo vérifiée'),
                Etape(
                  EtatEtape.encours,
                  'En route',
                  'Arrivée prévue vers 8 h 30 · suivi en direct',
                  icone: Icons.directions_car_outlined,
                ),
                Etape(EtatEtape.afaire, 'Livré au destinataire', 'Quand il donne son code au conducteur'),
              ],
            ),
          ),
          const Carte(
            child: Column(
              children: [
                Doux('QR À MONTRER À LA REMISE', taille: 14, gras: true),
                SizedBox(height: 8),
                Qr(graine: 'CL-4KM7-PQ2', taille: 140, label: 'QR du colis'),
                SizedBox(height: 8),
                Doux('Déjà scanné à la remise'),
              ],
            ),
          ),
          const Bandeau(
            "Le conducteur ne touche le paiement qu'à la livraison. Colis perdu ou abîmé : remboursement "
            "jusqu'à la valeur déclarée, dans la limite d'un plafond à fixer.",
          ),
          Row(
            children: [
              Expanded(
                child: BtnClair(
                  'Écrire au conducteur',
                  icon: Icons.chat_bubble_outline_rounded,
                  onPressed: () => _bientot(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: BtnClair('Partager le suivi', icon: Icons.share_outlined, onPressed: () => _bientot(context)),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

// ---------------------------------------------------------------------------
// 57 · Colis côté conducteur
// ---------------------------------------------------------------------------

class ColisConducteurEcran extends StatefulWidget {
  const ColisConducteurEcran({super.key});

  @override
  State<ColisConducteurEcran> createState() => _ColisConducteurEcranState();
}

class _ColisConducteurEcranState extends State<ColisConducteurEcran> {
  bool? _accepte;

  @override
  Widget build(BuildContext context) {
    return Ecran(
      children: [
        const Piste(
          couleur: C.encre,
          retour: true,
          trailing: _v2,
          paddingBas: 30,
          children: [
            Text(
              'Exemple : votre trajet Ouaga → Koudougou',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: C.etoile),
            ),
            Titre('2 colis proposés'),
          ],
        ),
        Zone(
          gap: 12,
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
          children: [
            Carte.sel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Row(
                    children: [
                      Expanded(child: Text('Documents · taille S', style: T.gras)),
                      Text(
                        '+ 1 000 F',
                        style: TextStyle(fontWeight: FontWeight.w700, color: C.vertF),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(color: C.sable2, borderRadius: BorderRadius.circular(14)),
                        child: const Icon(Icons.description_outlined, size: 28, color: C.doux),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Remise : Gounghin, 6 h 45', style: T.petit),
                            Text('Livraison : Koudougou, Secteur 7', style: T.petit),
                            Doux('Photo du contenu : enveloppe kraft, 3 dossiers'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_accepte == null)
                    Row(
                      children: [
                        Expanded(
                          child: BtnClair('Refuser', hauteur: 48, onPressed: () => setState(() => _accepte = false)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Btn('Accepter', hauteur: 48, onPressed: () => setState(() => _accepte = true))),
                      ],
                    )
                  else
                    Pastille(
                      _accepte! ? 'Accepté (aperçu)' : 'Refusé (aperçu)',
                      ton: _accepte! ? TonPastille.vert : TonPastille.neutre,
                    ),
                ],
              ),
            ),
            const Carte(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text('Sac · taille M · 6 kg', style: T.gras)),
                      Text('+ 2 000 F', style: T.gras),
                    ],
                  ),
                  SizedBox(height: 4),
                  Doux('Vêtements · valeur déclarée 30 000 F', taille: 14),
                ],
              ),
            ),
            const Doux('Au moment de la remise et de la livraison', taille: 14, gras: true),
            Row(
              children: [
                Expanded(
                  child: Btn.lat(
                    'Scanner à la remise',
                    icon: Icons.photo_camera_outlined,
                    hauteur: 56,
                    taille: 15,
                    onPressed: () => _bientot(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Btn(
                    'Code du destinataire',
                    icon: Icons.check_rounded,
                    hauteur: 56,
                    taille: 15,
                    onPressed: () => _bientot(context),
                  ),
                ),
              ],
            ),
            const Doux(
              "Vérifiez le contenu avant d'accepter : vous pouvez refuser un colis. Ne transportez jamais un colis fermé que vous n'avez pas vu.",
            ),
          ],
        ),
      ],
    );
  }
}
