import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../appel.dart';
import '../formats.dart';
import '../model.dart';
import '../painters.dart';
import '../theme.dart';
import '../ui.dart';
import 'passager.dart';

// ---------------------------------------------------------------------------
// 14 · Trajet en cours (E1)
// ---------------------------------------------------------------------------

class EnRouteEcran extends StatefulWidget {
  const EnRouteEcran({super.key, required this.reservation});
  final Reservation reservation;

  @override
  State<EnRouteEcran> createState() => _EnRouteEcranState();
}

class _EnRouteEcranState extends State<EnRouteEcran> {
  bool _partage = true;
  static const _progression = .58;

  void _partager(String canal) {
    final s = AppScope.read(context);
    final t = widget.reservation.trajet;
    Clipboard.setData(
      ClipboardData(
        text: 'Je suis en route avec FasoCovoit : ${t.titreLong}, arrivée vers ${heure(t.heureArrivee)}. '
            'Véhicule ${t.conducteur.vehicule} ${t.conducteur.plaque}.',
      ),
    );
    message(context, 'Message copié pour ${s.urgenceLien} : collez-le dans $canal.');
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final r = widget.reservation;
    final t = r.trajet;
    final c = t.conducteur;
    final haut = MediaQuery.paddingOf(context).top;
    final bas = MediaQuery.paddingOf(context).bottom;
    final restant = (t.km * (1 - _progression)).round();
    return Scaffold(
      backgroundColor: C.sable2,
      body: Stack(
        children: [
          Positioned.fill(
            top: 56 + haut,
            bottom: 280,
            child: CarteDuTrajet(depart: t.depart, arrivee: t.arrivee, progression: _progression),
          ),
          Positioned(
            top: 16 + haut,
            left: 16,
            right: 16,
            child: Row(
              children: [
                Material(
                  color: C.surface,
                  shape: const CircleBorder(side: BorderSide(color: C.trait, width: 1.5)),
                  child: IconeBtn(
                    icon: Icons.chevron_left_rounded,
                    label: 'Retour',
                    taille: 28,
                    onTap: () => Navigator.maybePop(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: _bandeauSuivi(s)),
              ],
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Doux('En route avec ${c.court} · ${c.voiture.split(' ').last} ${c.plaque}'),
                            Titre('Arrivée vers ${heure(t.heureArrivee)}'),
                          ],
                        ),
                      ),
                      Doux('$restant km', taille: 14, gras: true),
                    ],
                  ),
                  _BarreProgres(_progression),
                  Row(
                    children: [
                      Expanded(
                        child: BtnClair('WhatsApp', icon: Icons.share_outlined, onPressed: () => _partager('WhatsApp')),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: BtnClair('SMS', icon: Icons.sms_outlined, onPressed: () => _partager('un SMS')),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Btn(
                          'Je suis arrivé${s.femme ? 'e' : ''}',
                          onPressed: () {
                            s.arriver(r);
                            remplacer(context, NoterEcran(reservation: r));
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 128,
                        child: Btn.sos(
                          'SOS',
                          icon: Icons.warning_amber_rounded,
                          onPressed: () => ouvrir(context, SosEcran(trajet: '${t.titreLong} avec ${c.court}')),
                        ),
                      ),
                    ],
                  ),
                ], 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bandeauSuivi(AppState s) => Container(
    padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
    decoration: BoxDecoration(
      color: C.surface,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: C.trait, width: 1.5),
    ),
    child: Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: _partage ? C.vert : C.trait,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _partage ? '${s.urgenceLien} suit le trajet' : 'Suivi non partagé',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ),
        Lien(
          _partage ? 'Arrêter' : 'Partager',
          onTap: () => setState(() => _partage = !_partage),
        ),
      ],
    ),
  );
}

class _BarreProgres extends StatelessWidget {
  const _BarreProgres(this.valeur);
  final double valeur;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Trajet effectué à ${(valeur * 100).round()} %',
    child: ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 10,
        color: C.sable2,
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: valeur,
          child: CustomPaint(painter: _Rayures(), size: const Size(double.infinity, 10)),
        ),
      ),
    ),
  );
}

class _Rayures extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = C.laterite);
    final p = Paint()..color = const Color(0xFFC9673C);
    for (var x = 12.0; x < size.width; x += 18) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 6, size.height), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// 15 · SOS (E2)
// ---------------------------------------------------------------------------

class SosEcran extends StatelessWidget {
  const SosEcran({super.key, required this.trajet});
  final String trajet;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final haut = MediaQuery.paddingOf(context).top;
    final bas = MediaQuery.paddingOf(context).bottom;
    final envoye = heure(s.maintenant);
    Widget fait(String texte) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_rounded, color: Colors.white, size: 22),
        const SizedBox(width: 12),
        Expanded(child: Text(texte, style: const TextStyle(color: Colors.white))),
      ],
    );
    return Scaffold(
      backgroundColor: C.sos,
      body: Padding(
        padding: EdgeInsets.fromLTRB(22, 28 + haut, 22, 24 + bas),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Pastille(
                'Alerte envoyée à $envoye',
                icon: Icons.warning_amber_rounded,
                fond: Colors.white,
                texte: C.sosF,
              ),
            ),
            const SizedBox(height: 18),
            Semantics(
              liveRegion: true,
              child: Text(
                "L'équipe vous rappelle dans moins de 5 minutes",
                style: T.titre(36, color: Colors.white),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF9E1116), borderRadius: BorderRadius.circular(22)),
              child: Column(
                children: espacer([
                  fait("Votre position a été envoyée à l'équipe FasoCovoit"),
                  fait('${s.urgenceNom} (${s.urgenceLien}) a reçu un SMS'),
                  fait('Le trajet et le conducteur sont enregistrés : $trajet'),
                ], 12),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Prototype : aucune alerte réelle n’est envoyée.',
              style: TextStyle(color: Color(0xFFFBE0DF), fontSize: 13),
            ),
            const Spacer(),
            Btn(
              'Appeler la police · 17',
              icon: Icons.phone_outlined,
              couleur: Colors.white,
              texte: C.sosF,
              onPressed: () => appeler(context, '17', titre: 'Appeler la police'),
            ),
            const SizedBox(height: 12),
            BtnClair(
              'Appeler les pompiers · 18',
              icon: Icons.phone_outlined,
              couleur: Colors.white,
              onPressed: () => appeler(context, '18', titre: 'Appeler les pompiers'),
            ),
            const SizedBox(height: 8),
            Lien(
              'Je suis en sécurité, fausse alerte',
              couleur: Colors.white,
              souligne: false,
              taille: 16,
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 16 · Noter (E3)
// ---------------------------------------------------------------------------

class NoterEcran extends StatefulWidget {
  const NoterEcran({super.key, required this.reservation});
  final Reservation reservation;

  @override
  State<NoterEcran> createState() => _NoterEcranState();
}

class _NoterEcranState extends State<NoterEcran> {
  static const _mots = ['', 'Très décevant', 'Décevant', 'Correct', 'Bien', 'Excellent'];
  static const _tags = ['Ponctuel', 'Conduite prudente', 'Voiture propre', 'Aimable', 'Bon point de rendez-vous'];
  int _note = 5;
  final Set<String> _choisis = {'Ponctuel', 'Conduite prudente'};
  final _avis = TextEditingController();

  @override
  void dispose() {
    _avis.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final t = widget.reservation.trajet;
    final c = t.conducteur;
    return Ecran(
      children: [
        Piste(
          centre: true,
          children: [
            Ava(c.initiales, taille: 84, fond: C.surface, texte: C.lateriteF),
            const SizedBox(height: 8),
            Titre('Le trajet avec ${c.prenom} ?', align: TextAlign.center),
            Text('${t.titre} · ${jourCourt(t.heureDepart)}', style: T.petit),
          ],
        ),
        Zone(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
          children: [
            Semantics(
              label: 'Note sur 5',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var k = 1; k <= 5; k++)
                    Semantics(
                      button: true,
                      selected: k <= _note,
                      label: '$k sur 5',
                      child: InkResponse(
                        onTap: () => setState(() => _note = k),
                        radius: 30,
                        child: Padding(
                          padding: const EdgeInsets.all(3),
                          child: Etoile(
                            size: 50,
                            color: k <= _note ? C.etoile : null,
                            contour: k <= _note ? C.lateriteF : const Color(0xFFB8A285),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Text(_mots[_note], textAlign: TextAlign.center, style: T.gras),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in _tags)
                  Puce(
                    tag,
                    on: _choisis.contains(tag),
                    tonOn: TonPastille.vert,
                    onTap: () => setState(() => _choisis.contains(tag) ? _choisis.remove(tag) : _choisis.add(tag)),
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Etiq('Un mot pour les autres (facultatif)'),
                const SizedBox(height: 8),
                Champ(controller: _avis, lignes: 3, hint: 'Très ponctuel, conduite calme.', label: 'Avis'),
              ],
            ),
          ],
          bas: [
            Btn(
              'Envoyer ma note',
              onPressed: () {
                if (essayer(context, () => s.noter(widget.reservation, _note))) {
                  s.allerOnglet(1);
                  retourAccueil(context);
                  message(context, 'Merci ! Votre note aide toute la communauté.');
                }
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Flexible(child: Doux('Vous avez 72 h pour noter')),
                const SizedBox(width: 8),
                Flexible(
                  child: Lien(
                    'Signaler un problème',
                    couleur: C.sos,
                    souligne: false,
                    taille: 13,
                    onTap: () => ouvrir(context, SignalerEcran(reservation: widget.reservation)),
                  ),
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
// 17 · Signaler (E4)
// ---------------------------------------------------------------------------

class SignalerEcran extends StatefulWidget {
  const SignalerEcran({super.key, required this.reservation});
  final Reservation reservation;

  @override
  State<SignalerEcran> createState() => _SignalerEcranState();
}

class _SignalerEcranState extends State<SignalerEcran> {
  static const _categories = [
    'Comportement déplacé',
    'Conduite dangereuse',
    'Retard ou absence',
    'Problème de paiement',
    'Objet oublié dans la voiture',
    'Autre chose',
  ];
  int _choix = 0;
  final _texte = TextEditingController();

  @override
  void dispose() {
    _texte.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.reservation.trajet;
    return Ecran(
      children: [
        Barre(
          titre: 'Signaler un problème',
          sousTitre: 'Trajet du ${dateCourte(t.heureDepart)} avec ${t.conducteur.court}',
        ),
        Zone(
          gap: 12,
          children: [
            const Etiq("Que s'est-il passé ?"),
            for (var i = 0; i < _categories.length; i++)
              Choix(
                on: _choix == i,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                onTap: () => setState(() => _choix = i),
                children: [Expanded(child: Text(_categories[i], style: T.gras))],
              ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Etiq('Décrivez en quelques mots'),
                const SizedBox(height: 8),
                Champ(controller: _texte, lignes: 3, label: 'Description'),
              ],
            ),
            const Doux("L'équipe vous répond sous 48 h. Pour un danger immédiat, appelez le 17."),
            Btn.lat(
              'Envoyer le signalement',
              onPressed: () {
                Navigator.pop(context);
                message(context, 'Signalement envoyé. L’équipe vous répond sous 48 h.');
              },
            ),
          ],
        ),
      ],
    );
  }
}
