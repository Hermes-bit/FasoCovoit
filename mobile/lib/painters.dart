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
    final s = size.width / 390;
    canvas.save();
    canvas.translate(0, size.height - 330 * s);
    canvas.scale(s);
    canvas.drawCircle(const Offset(300, 96), 44, Paint()..color = C.etoile);
    canvas.drawPath(
      Path()
        ..moveTo(0, 170)
        ..quadraticBezierTo(120, 150, 200, 165)
        ..quadraticBezierTo(280, 180, 390, 150)
        ..lineTo(390, 330)
        ..lineTo(0, 330)
        ..close(),
      Paint()..color = const Color(0xFF9C4422),
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, 215)
        ..quadraticBezierTo(150, 195, 390, 210)
        ..lineTo(390, 330)
        ..lineTo(0, 330)
        ..close(),
      Paint()..color = C.lateriteF,
    );
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

/// Carte dessinée du trajet (remplacée par Google Maps quand la clé est configurée).
class CarteTrajetPainter extends CustomPainter {
  CarteTrajetPainter({
    required this.villeDepart,
    required this.villeArrivee,
    this.etape = 'Sabou',
    this.progression = .58,
  });
  final String villeDepart;
  final String villeArrivee;
  final String etape;
  final double progression;

  @override
  void paint(Canvas canvas, Size size) {
    // Mise à l'échelle uniforme « couvrante », centrée.
    final s = math.max(size.width / 390, size.height / 560);
    canvas.drawRect(Offset.zero & size, Paint()..color = C.sable2);
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.translate((size.width - 390 * s) / 2, (size.height - 560 * s) / 2);
    canvas.scale(s);
    canvas.drawRect(const Rect.fromLTWH(0, 0, 390, 560), Paint()..color = C.sable2);
    final bloc = Paint()..color = C.trait;
    for (final r in const [
      Rect.fromLTWH(20, 40, 90, 60),
      Rect.fromLTWH(250, 250, 110, 70),
      Rect.fromLTWH(40, 380, 70, 90),
    ]) {
      canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(10)), bloc);
    }
    Paint trait(Color c, double w) => Paint()
      ..color = c
      ..strokeWidth = w
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(-10, 190)
        ..cubicTo(90, 170, 150, 230, 250, 205)
        ..cubicTo(350, 180, 380, 150, 410, 170),
      trait(C.surface, 12),
    );
    canvas.drawPath(
      Path()
        ..moveTo(120, -10)
        ..cubicTo(150, 140, 90, 300, 160, 580),
      trait(C.surface, 9),
    );
    final route = Path()
      ..moveTo(335, 520)
      ..cubicTo(290, 440, 250, 360, 205, 290)
      ..cubicTo(160, 220, 110, 150, 70, 80);
    canvas.drawPath(route, trait(const Color(0xFFD9824F), 16));
    final metrique = route.computeMetrics().first;
    for (var d = 0.0; d < metrique.length; d += 22) {
      canvas.drawPath(metrique.extractPath(d, d + 10), trait(C.surface, 3));
    }
    final parcouru = metrique.extractPath(0, metrique.length * progression);
    canvas.drawPath(parcouru, trait(C.laterite, 16));
    canvas.drawCircle(const Offset(335, 520), 10, Paint()..color = C.surface);
    canvas.drawCircle(const Offset(335, 520), 10, trait(C.vert, 5));
    canvas.save();
    canvas.translate(56, 62);
    canvas.scale(1.2);
    final e = etoilePath(24);
    canvas.drawPath(e, Paint()..color = C.etoile);
    canvas.drawPath(e, trait(C.lateriteF, 1.5));
    canvas.restore();
    final pos = metrique.getTangentForOffset(metrique.length * progression)!.position;
    canvas.drawCircle(pos, 24, Paint()..color = C.vert.withValues(alpha: .2));
    canvas.drawCircle(pos, 13, Paint()..color = C.vert);
    canvas.drawCircle(pos, 13, trait(Colors.white, 4));
    void texte(String t, Offset o, double taille, FontWeight w, Color c) {
      final tp = TextPainter(
        text: TextSpan(
          text: t,
          style: TextStyle(fontFamily: 'Figtree', fontSize: taille, fontWeight: w, color: c),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, o);
    }

    texte(villeArrivee, const Offset(96, 64), 14, FontWeight.w800, C.encre);
    texte(villeDepart, const Offset(222, 531), 14, FontWeight.w800, C.encre);
    if (etape.isNotEmpty) {
      texte(etape, Offset(pos.dx + 20, pos.dy - 20), 13, FontWeight.w600, C.doux);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(CarteTrajetPainter old) =>
      old.progression != progression || old.villeArrivee != villeArrivee;
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
