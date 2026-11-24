import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'theme.dart';

/// Étoile du drapeau (même tracé que la maquette, viewBox 24).
Path etoilePath(double size) {
  final s = size / 24;
  return Path()
    ..moveTo(12 * s, 2.6 * s)
    ..lineTo(14.9 * s, 8.6 * s)
    ..lineTo(21.4 * s, 9.5 * s)
    ..lineTo(16.7 * s, 14.1 * s)
    ..lineTo(17.8 * s, 20.6 * s)
    ..lineTo(12 * s, 17.5 * s)
    ..lineTo(6.2 * s, 20.6 * s)
    ..lineTo(7.3 * s, 14.1 * s)
    ..lineTo(2.6 * s, 9.5 * s)
    ..lineTo(9.1 * s, 8.6 * s)
    ..close();
}

class Etoile extends StatelessWidget {
  const Etoile({
    super.key,
    this.size = 18,
    this.color = C.etoile,
    this.contour,
    this.epaisseur = 1.4,
  });
  final double size;
  final Color? color;
  final Color? contour;
  final double epaisseur;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: _EtoilePainter(color, contour, epaisseur),
  );
}

class _EtoilePainter extends CustomPainter {
  _EtoilePainter(this.color, this.contour, this.epaisseur);
  final Color? color;
  final Color? contour;
  final double epaisseur;

  @override
  void paint(Canvas canvas, Size size) {
    final p = etoilePath(size.width);
    if (color != null) canvas.drawPath(p, Paint()..color = color!);
    if (contour != null) {
      canvas.drawPath(
        p,
        Paint()
          ..color = contour!
          ..style = PaintingStyle.stroke
          ..strokeWidth = epaisseur * size.width / 24
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  @override
  bool shouldRepaint(_EtoilePainter old) =>
      old.color != color || old.contour != contour;
}

/// Trait pointillé horizontal (la « piste » sous les en-têtes, la coupe du billet).
class Pointilles extends StatelessWidget {
  const Pointilles({
    super.key,
    this.color = C.trait,
    this.epaisseur = 2,
    this.plein = 6,
    this.vide = 5,
    this.vertical = false,
  });
  final Color color;
  final double epaisseur;
  final double plein;
  final double vide;
  final bool vertical;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: vertical ? Size(epaisseur, double.infinity) : Size(double.infinity, epaisseur),
    painter: _PointillesPainter(color, epaisseur, plein, vide, vertical),
  );
}

class _PointillesPainter extends CustomPainter {
  _PointillesPainter(this.color, this.epaisseur, this.plein, this.vide, this.vertical);
  final Color color;
  final double epaisseur;
  final double plein;
  final double vide;
  final bool vertical;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final longueur = vertical ? size.height : size.width;
    for (var x = 0.0; x < longueur; x += plein + vide) {
      final fin = math.min(x + plein, longueur);
      canvas.drawRect(
        vertical
            ? Rect.fromLTRB(0, x, size.width, fin)
            : Rect.fromLTRB(x, 0, fin, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_PointillesPainter old) => old.color != color;
}

/// Paysage de l'écran de bienvenue : soleil, collines, baobab, piste et voiture.
class PaysagePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Les collines s'étirent sur toute la largeur ; le reste de la scène garde
    // ses proportions et reste centré (téléphone comme grand écran).
    final sx = size.width / 390;
    final s = math.min(sx, size.height * .6 / 330);
    double y(double v) => size.height - (330 - v) * s;
    double x(double v) => v * sx;
    canvas.drawPath(
      Path()
        ..moveTo(x(0), y(170))
        ..quadraticBezierTo(x(120), y(150), x(200), y(165))
        ..quadraticBezierTo(x(280), y(180), x(390), y(150))
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close(),
      Paint()..color = const Color(0xFF9C4422),
    );
    canvas.drawPath(
      Path()
        ..moveTo(x(0), y(215))
        ..quadraticBezierTo(x(150), y(195), x(390), y(210))
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close(),
      Paint()..color = C.lateriteF,
    );
    canvas.save();
    canvas.translate(size.width / 2 - 195 * s, size.height - 330 * s);
    canvas.scale(s);
    canvas.drawCircle(const Offset(300, 96), 44, Paint()..color = C.etoile);
    canvas.drawPath(
      Path()
        ..moveTo(150, 330)
        ..cubicTo(175, 270, 215, 235, 232, 168)
        ..lineTo(244, 168)
        ..cubicTo(250, 236, 268, 272, 300, 330)
        ..close(),
      Paint()..color = const Color(0xFFD9824F),
    );
    final ligne = Paint()
      ..color = Colors.white.withValues(alpha: .8)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(237, 176), const Offset(240, 200), ligne);
    canvas.drawLine(const Offset(240, 222), const Offset(244, 252), ligne);
    canvas.drawLine(const Offset(247, 276), const Offset(252, 310), ligne);
    final arbre = Paint()..color = const Color(0xFF5E2A12);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(74, 120, 16, 70), const Radius.circular(6)),
      arbre,
    );
    canvas.drawOval(Rect.fromCenter(center: const Offset(82, 112), width: 80, height: 36), arbre);
    canvas.drawOval(Rect.fromCenter(center: const Offset(60, 122), width: 32, height: 18), arbre);
    canvas.drawOval(Rect.fromCenter(center: const Offset(106, 120), width: 36, height: 18), arbre);
    canvas.translate(176, 250);
    final vert = Paint()..color = C.vert;
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(0, 0, 76, 30), const Radius.circular(10)), vert);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(12, -14, 48, 20), const Radius.circular(7)), vert);
    final roue = Paint()..color = C.encre;
    canvas.drawCircle(const Offset(16, 32), 8, roue);
    canvas.drawCircle(const Offset(60, 32), 8, roue);
    final vitre = Paint()..color = const Color(0xFFCFE8D8);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(18, -10, 16, 12), const Radius.circular(3)), vitre);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(38, -10, 16, 12), const Radius.circular(3)), vitre);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Couleurs de carte claires, proches de Plans et de Google Maps (les mêmes
/// que le style Google Maps de `web/carte.js`).
abstract final class Plan {
  static const terre = Color(0xFFF6F3EE);
  static const ilot = Color(0xFFEBE6DC);
  static const parc = Color(0xFFC8E8B6);
  static const parcTexte = Color(0xFF3B7A35);
  static const eau = Color(0xFF9FD3F5);
  static const eauTexte = Color(0xFF33739F);
  static const rue = Color(0xFFFFFFFF);
  static const rueBord = Color(0xFFE4DDD1);
  static const axe = Color(0xFFFDE49A);
  static const axeBord = Color(0xFFF1C75A);
  static const route = Color(0xFF3D8BFD);
  static const routeBord = Color(0xFF1A5FD0);
  static const routeFaite = Color(0xFFA9C4F2);
  static const texte = Color(0xFF2C3440);
}

/// Carte dessinée du trajet, au style clair et coloré de Plans (remplacée
/// par Google Maps sur le Web quand la clé est configurée).
class CarteTrajetPainter extends CustomPainter {
  CarteTrajetPainter({
    required this.villeDepart,
    required this.villeArrivee,
    this.etape = 'Sabou',
    this.progression = .58,
    this.voiture = true,
  });
  final String villeDepart;
  final String villeArrivee;
  final String etape;
  final double progression;

  /// Affiche la position de la voiture (trajet en cours).
  final bool voiture;

  @override
  void paint(Canvas canvas, Size size) {
    // Mise à l'échelle uniforme « couvrante », centrée.
    final s = math.max(size.width / 390, size.height / 560);
    canvas.drawRect(Offset.zero & size, Paint()..color = Plan.terre);
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.translate((size.width - 390 * s) / 2, (size.height - 560 * s) / 2);
    canvas.scale(s);
    Paint trait(Color c, double w) => Paint()
      ..color = c
      ..strokeWidth = w
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    void texte(String t, Offset o, double taille, FontWeight w, Color c, {bool halo = true}) {
      TextPainter tp(Paint? contour) => TextPainter(
        text: TextSpan(
          text: t,
          style: TextStyle(
            fontFamily: 'Figtree',
            fontSize: taille,
            fontWeight: w,
            color: contour == null ? c : null,
            foreground: contour,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      if (halo) tp(trait(Colors.white, 4)).paint(canvas, o);
      tp(null).paint(canvas, o);
    }

    // Îlots bâtis.
    final ilot = Paint()..color = Plan.ilot;
    for (final r in const [
      Rect.fromLTWH(16, 120, 84, 52),
      Rect.fromLTWH(170, 34, 70, 64),
      Rect.fromLTWH(250, 250, 110, 66),
      Rect.fromLTWH(30, 380, 70, 90),
      Rect.fromLTWH(196, 470, 84, 60),
      Rect.fromLTWH(120, 236, 56, 46),
    ]) {
      canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(8)), ilot);
    }
    // Parc (à l'écart de l'itinéraire) et plans d'eau.
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(270, 96, 112, 92), const Radius.circular(26)),
      Paint()..color = Plan.parc,
    );
    texte('Parc', const Offset(310, 132), 12, FontWeight.w700, Plan.parcTexte);
    canvas.drawPath(
      Path()
        ..moveTo(270, -10)
        ..cubicTo(300, 40, 360, 60, 410, 50)
        ..lineTo(410, -10)
        ..close(),
      Paint()..color = Plan.eau,
    );
    canvas.drawOval(const Rect.fromLTWH(8, 214, 64, 34), Paint()..color = Plan.eau);
    texte('Barrage', const Offset(330, 14), 12, FontWeight.w700, Plan.eauTexte);
    // Rues blanches bordées.
    final rues = [
      Path()
        ..moveTo(-10, 190)
        ..cubicTo(90, 170, 150, 230, 250, 205)
        ..cubicTo(350, 180, 380, 150, 410, 170),
      Path()
        ..moveTo(120, -10)
        ..cubicTo(150, 140, 90, 300, 160, 580),
      Path()
        ..moveTo(-10, 350)
        ..lineTo(410, 330),
      Path()
        ..moveTo(240, -10)
        ..lineTo(230, 580),
    ];
    for (final r in rues) {
      canvas.drawPath(r, trait(Plan.rueBord, 12));
    }
    for (final r in rues) {
      canvas.drawPath(r, trait(Plan.rue, 9));
    }
    // Grand axe jaune sous l'itinéraire.
    final route = Path()
      ..moveTo(335, 520)
      ..cubicTo(290, 440, 250, 360, 205, 290)
      ..cubicTo(160, 220, 110, 150, 70, 80);
    canvas.drawPath(route, trait(Plan.axeBord, 22));
    canvas.drawPath(route, trait(Plan.axe, 19));
    // Itinéraire bleu, partie faite plus claire.
    canvas.drawPath(route, trait(Plan.routeBord, 11));
    canvas.drawPath(route, trait(Plan.route, 7));
    final metrique = route.computeMetrics().first;
    final p = progression.clamp(0.0, 1.0);
    if (voiture && p > 0) {
      canvas.drawPath(metrique.extractPath(0, metrique.length * p), trait(Plan.routeFaite, 7));
    }
    // Départ (vert) et destination (latérite).
    canvas.drawCircle(const Offset(335, 520), 11, Paint()..color = Colors.white);
    canvas.drawCircle(const Offset(335, 520), 8, Paint()..color = C.vert);
    canvas.drawCircle(const Offset(70, 80), 14, Paint()..color = Colors.white);
    canvas.drawCircle(const Offset(70, 80), 11, Paint()..color = C.laterite);
    canvas.save();
    canvas.translate(62, 72);
    canvas.scale(.7);
    canvas.drawPath(etoilePath(24), Paint()..color = Colors.white);
    canvas.restore();
    final pos = metrique.getTangentForOffset(metrique.length * p)!.position;
    if (voiture) {
      canvas.drawCircle(pos, 24, Paint()..color = Plan.route.withValues(alpha: .22));
      canvas.drawCircle(pos, 12, Paint()..color = Colors.white);
      canvas.drawCircle(pos, 9, Paint()..color = Plan.route);
    }
    texte(villeArrivee, const Offset(92, 66), 14, FontWeight.w800, Plan.texte);
    texte(villeDepart, const Offset(222, 531), 14, FontWeight.w800, Plan.texte);
    if (etape.isNotEmpty) {
      final o = voiture ? Offset(pos.dx + 22, pos.dy - 22) : const Offset(220, 300);
      texte(etape, o, 13, FontWeight.w600, const Color(0xFF6D7580));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(CarteTrajetPainter old) =>
      old.progression != progression || old.villeArrivee != villeArrivee || old.villeDepart != villeDepart || old.voiture != voiture;
}

// ---------------------------------------------------------------------------
// Illustrations au trait (style autocollant), aux couleurs de FasoCovoit
// ---------------------------------------------------------------------------

Paint _contour([double w = 2.6]) => Paint()
  ..color = C.encre
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeJoin = StrokeJoin.round
  ..strokeCap = StrokeCap.round;

void _remplir(Canvas c, Path p, Color couleur, {double trait = 2.6}) {
  c.drawPath(p, Paint()..color = couleur);
  c.drawPath(p, _contour(trait));
}

/// Petite étoile à quatre branches, au trait.
void _scintille(Canvas c, Offset o, double r, {bool plein = false}) {
  final p = Path()
    ..moveTo(o.dx, o.dy - r)
    ..quadraticBezierTo(o.dx, o.dy, o.dx + r, o.dy)
    ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy + r)
    ..quadraticBezierTo(o.dx, o.dy, o.dx - r, o.dy)
    ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy - r)
    ..close();
  if (plein) c.drawPath(p, Paint()..color = C.encre);
  c.drawPath(p, _contour(1.6));
}

Path _poly(List<Offset> pts) => Path()..addPolygon(pts, true);

/// Accueil vide : une carte pliée et une épingle (« Mes covoit' »).
class IllustrationCartePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width / 150, size.height / 120);
    canvas.save();
    canvas.translate((size.width - 150 * s) / 2, (size.height - 120 * s) / 2);
    canvas.scale(s);
    canvas.drawOval(const Rect.fromLTWH(22, 104, 106, 10), Paint()..color = C.sable2);
    _remplir(canvas, _poly(const [Offset(18, 34), Offset(56, 22), Offset(56, 92), Offset(18, 104)]), C.etoile);
    _remplir(canvas, _poly(const [Offset(56, 22), Offset(94, 34), Offset(94, 104), Offset(56, 92)]), C.surface);
    _remplir(canvas, _poly(const [Offset(94, 34), Offset(132, 22), Offset(132, 92), Offset(94, 104)]), C.vertC);
    // Rues blanches et chemin en pointillés.
    final rue = Paint()
      ..color = Colors.white
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(Path()..moveTo(22, 60)..quadraticBezierTo(70, 52, 128, 70), rue);
    final pointilles = Path()
      ..moveTo(32, 86)
      ..cubicTo(52, 80, 62, 66, 78, 64)
      ..cubicTo(92, 62, 100, 56, 104, 48);
    for (final m in pointilles.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 7) {
        canvas.drawPath(m.extractPath(d, d + 3.5), _contour(2));
      }
    }
    canvas.drawCircle(const Offset(32, 86), 5.5, Paint()..color = C.vert);
    canvas.drawCircle(const Offset(32, 86), 5.5, _contour(2.2));
    // Épingle latérite.
    final epingle = Path()
      ..moveTo(106, 50)
      ..cubicTo(98, 40, 92, 33, 92, 24)
      ..arcToPoint(const Offset(120, 24), radius: const Radius.circular(14))
      ..cubicTo(120, 33, 114, 40, 106, 50)
      ..close();
    _remplir(canvas, epingle, C.laterite);
    canvas.drawCircle(const Offset(106, 24), 5, Paint()..color = Colors.white);
    canvas.drawCircle(const Offset(106, 24), 5, _contour(2));
    _scintille(canvas, const Offset(138, 10), 7);
    _scintille(canvas, const Offset(10, 18), 5, plein: true);
    _scintille(canvas, const Offset(140, 100), 6);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Recherche en cours : un téléphone, une loupe et une voiture.
class IllustrationRecherchePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width / 150, size.height / 120);
    canvas.save();
    canvas.translate((size.width - 150 * s) / 2, (size.height - 120 * s) / 2);
    canvas.scale(s);
    canvas.drawOval(const Rect.fromLTWH(30, 106, 96, 9), Paint()..color = C.sable2);
    // Téléphone et carte à l'écran.
    final tel = Path()..addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(24, 10, 58, 96), const Radius.circular(12)));
    _remplir(canvas, tel, C.laterite);
    final ecran = Path()..addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(31, 20, 44, 76), const Radius.circular(6)));
    canvas.drawPath(ecran, Paint()..color = C.surface);
    canvas.save();
    canvas.clipPath(ecran);
    final route = Paint()
      ..color = C.etoile
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;
    canvas.drawPath(Path()..moveTo(28, 40)..lineTo(80, 78), route);
    canvas.drawPath(Path()..moveTo(50, 18)..lineTo(40, 98), route);
    canvas.restore();
    canvas.drawPath(ecran, _contour(2));
    // Loupe verte avec une voiture.
    Paint manche(Color c, double w) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(98, 78), const Offset(124, 104), manche(C.encre, 15));
    canvas.drawLine(const Offset(98, 78), const Offset(124, 104), manche(C.vert, 10));
    canvas.drawCircle(const Offset(80, 60), 27, Paint()..color = C.vert);
    canvas.drawCircle(const Offset(80, 60), 27, _contour());
    canvas.drawCircle(const Offset(80, 60), 19, Paint()..color = Colors.white);
    canvas.drawCircle(const Offset(80, 60), 19, _contour(2));
    final voiture = Path()
      ..moveTo(66, 66)
      ..lineTo(66, 60)
      ..quadraticBezierTo(66, 57, 70, 56)
      ..lineTo(73, 51)
      ..lineTo(87, 51)
      ..lineTo(91, 56)
      ..quadraticBezierTo(95, 57, 95, 60)
      ..lineTo(95, 66)
      ..close();
    _remplir(canvas, voiture, C.laterite, trait: 2);
    for (final x in const [72.0, 89.0]) {
      canvas.drawCircle(Offset(x, 66), 3.2, Paint()..color = C.encre);
    }
    canvas.drawRect(const Rect.fromLTWH(75, 53, 9, 3), Paint()..color = Colors.white);
    _scintille(canvas, const Offset(16, 14), 7);
    _scintille(canvas, const Offset(120, 24), 5, plein: true);
    _scintille(canvas, const Offset(132, 40), 7);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Fond discret de courbes de niveau (accueil).
class ContoursPainter extends CustomPainter {
  ContoursPainter({this.couleur = C.sable2});
  final Color couleur;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = couleur
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    void boucles(Offset centre, double depart, int n, double graine) {
      for (var k = 0; k < n; k++) {
        final r0 = depart + k * 22;
        final chemin = Path();
        for (var i = 0; i <= 72; i++) {
          final a = i / 72 * 2 * math.pi;
          final r = r0 * (1 + .10 * math.sin(3 * a + graine + k * .4) + .05 * math.cos(5 * a - graine));
          final pt = centre + Offset(math.cos(a) * r, math.sin(a) * r * .8);
          i == 0 ? chemin.moveTo(pt.dx, pt.dy) : chemin.lineTo(pt.dx, pt.dy);
        }
        canvas.drawPath(chemin..close(), p);
      }
    }

    canvas.save();
    canvas.clipRect(Offset.zero & size);
    boucles(Offset(size.width * .95, size.height * .25), 30, 9, 1.2);
    boucles(Offset(size.width * .05, size.height * .8), 24, 10, 2.6);
    canvas.restore();
  }

  @override
  bool shouldRepaint(ContoursPainter old) => old.couleur != couleur;
}

/// QR d'illustration (non lisible) : motif déterministe qui change avec la graine.
class QrPainter extends CustomPainter {
  QrPainter(this.graine, {this.modules = 25});
  final String graine;
  final int modules;

  @override
  void paint(Canvas canvas, Size size) {
    final m = size.width / modules;
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    final encre = Paint()..color = C.encre;
    var etat = graine.codeUnits.fold<int>(17, (h, c) => (h * 31 + c) & 0x7fffffff);
    bool bit() {
      etat = (etat * 1103515245 + 12345) & 0x7fffffff;
      return (etat >> 16) & 1 == 1;
    }

    final centre = size.width / 2;
    final rayon = size.width * .104;
    for (var y = 0; y < modules; y++) {
      for (var x = 0; x < modules; x++) {
        final b = bit();
        final dansRepere = (x < 8 && y < 8) || (x >= modules - 8 && y < 8) || (x < 8 && y >= modules - 8);
        if (dansRepere) continue;
        final cx = (x + .5) * m - centre;
        final cy = (y + .5) * m - centre;
        if (cx * cx + cy * cy < (rayon + m) * (rayon + m)) continue;
        if (b) canvas.drawRect(Rect.fromLTWH(x * m, y * m, m, m), encre);
      }
    }
    void repere(double x, double y) {
      canvas.drawRect(Rect.fromLTWH(x, y, 7 * m, 7 * m), encre);
      canvas.drawRect(Rect.fromLTWH(x + m, y + m, 5 * m, 5 * m), Paint()..color = Colors.white);
      canvas.drawRect(Rect.fromLTWH(x + 2 * m, y + 2 * m, 3 * m, 3 * m), encre);
    }

    repere(0, 0);
    repere((modules - 7) * m, 0);
    repere(0, (modules - 7) * m);
    canvas.drawCircle(Offset(centre, centre), rayon, Paint()..color = Colors.white);
    final t = rayon * 1.6;
    canvas.save();
    canvas.translate(centre - t / 2, centre - t / 2);
    canvas.drawPath(etoilePath(t), Paint()..color = C.laterite);
    canvas.restore();
  }

  @override
  bool shouldRepaint(QrPainter old) => old.graine != graine;
}

class Qr extends StatelessWidget {
  const Qr({super.key, required this.graine, this.taille = 176, this.label = 'QR code du billet'});
  final String graine;
  final double taille;
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    image: true,
    child: CustomPaint(size: Size.square(taille), painter: QrPainter(graine)),
  );
}
