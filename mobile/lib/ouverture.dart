import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'page_stub.dart' if (dart.library.js_interop) 'page_web.dart' as page;
import 'theme.dart';

/// Rideau aux couleurs de FasoCovoit (repris de CityGo) : le logo apparaît sur
/// fond latérite, le fond se resserre en cercle sur le logo jusqu'à
/// disparaître, puis l'accueil monte depuis le bas. Il se joue à l'ouverture
/// de l'application et à chaque changement d'espace (passager ⇄ conducteur).
///
/// Il donne aussi aux écrans les marges de l'iPhone (encoche, barre
/// d'accueil), que Flutter Web laisse à zéro.
class Ouverture extends StatefulWidget {
  const Ouverture({super.key, required this.child, this.intro = true});

  final Widget child;

  /// Rideau au démarrage. Sur le Web, la page a déjà fait arriver le logo
  /// pendant le chargement (`web/index.html`) : Flutter reprend à cet instant.
  final bool intro;

  /// Joue le rideau et exécute [action] (le changement d'espace) quand le
  /// logo couvre l'écran. Sans rideau (animations réduites, écran testé
  /// seul), [action] s'exécute tout de suite.
  static Future<void> changer(BuildContext context, VoidCallback action) {
    final etat = context.findAncestorStateOfType<_OuvertureState>();
    if (etat == null || MediaQuery.disableAnimationsOf(context)) {
      action();
      return Future.value();
    }
    return etat._changer(action);
  }

  @override
  State<Ouverture> createState() => _OuvertureState();
}

class _OuvertureState extends State<Ouverture> with TickerProviderStateMixin {
  /// Arrivée du logo, au changement d'espace : 0 → 1.
  late final _entree = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

  /// Pause sur le logo, cercle qui se resserre, puis accueil qui monte.
  late final _sortie = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300));

  static const _resserre = Interval(.18, .55, curve: Curves.easeInCubic);
  static const _logoEfface = Interval(.3, .55);
  static const _monte = Interval(.62, 1, curve: Curves.easeOutCubic);
  static const _apparait = Interval(.62, .8);

  bool _rideau = false;
  EdgeInsets _marges = EdgeInsets.zero;

  @override
  void initState() {
    super.initState();
    _marges = page.margesEcran();
    page.surRedimension(() {
      if (mounted) setState(() => _marges = page.margesEcran());
    });
    if (widget.intro) {
      _rideau = true;
      _entree.value = 1;
      WidgetsBinding.instance.addPostFrameCallback((_) => _demarrer());
    } else {
      _sortie.value = 1;
      page.retirerIntroPage();
    }
  }

  @override
  void dispose() {
    _entree.dispose();
    _sortie.dispose();
    super.dispose();
  }

  Future<void> _demarrer() async {
    if (!mounted) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      page.retirerIntroPage();
      _sortie.value = 1;
      setState(() => _rideau = false);
      return;
    }
    // Le logo de Flutter doit être prêt avant de retirer celui de la page.
    if (kIsWeb) await Future.wait([for (final c in _Logo.calques) precacheImage(AssetImage(c), context)]);
    await page.introPage();
    if (!mounted) return;
    page.retirerIntroPage();
    await _jouerSortie();
  }

  Future<void> _changer(VoidCallback action) async {
    if (_rideau) return;
    setState(() => _rideau = true);
    _sortie.value = 0;
    try {
      await _entree.forward(from: 0).orCancel;
    } on TickerCanceled {
      return;
    }
    action();
    await _jouerSortie();
  }

  Future<void> _jouerSortie() async {
    try {
      await _sortie.forward(from: 0).orCancel;
    } on TickerCanceled {
      return;
    }
    if (mounted) setState(() => _rideau = false);
  }

  EdgeInsets _avecMarges(EdgeInsets a) => EdgeInsets.fromLTRB(
    math.max(a.left, _marges.left),
    math.max(a.top, _marges.top),
    math.max(a.right, _marges.right),
    math.max(a.bottom, _marges.bottom),
  );

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final padding = _avecMarges(mq.padding);
    return MediaQuery(
      data: mq.copyWith(
        // Clavier ouvert : la barre d'accueil est dessous, pas de marge en bas.
        padding: mq.viewInsets.bottom > 0 ? padding.copyWith(bottom: mq.padding.bottom) : padding,
        viewPadding: _avecMarges(mq.viewPadding),
      ),
      child: ColoredBox(
        color: C.sable,
        child: AnimatedBuilder(
          animation: Listenable.merge([_entree, _sortie]),
          child: widget.child,
          builder: (context, app) {
            // Quand le logo couvre l'écran, l'accueil attend en bas, invisible.
            final cache = _rideau && _entree.value == 1;
            final monte = cache ? _monte.transform(_sortie.value) : 1.0;
            final apparait = cache ? _apparait.transform(_sortie.value) : 1.0;
            return Stack(
              fit: StackFit.expand,
              children: [
                Opacity(
                  opacity: apparait,
                  child: FractionalTranslation(translation: Offset(0, .4 * (1 - monte)), child: app),
                ),
                if (_rideau) AbsorbPointer(child: ExcludeSemantics(child: _dessinRideau())),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _dessinRideau() {
    final f = _sortie.value;
    return Opacity(
      opacity: const Interval(0, .3, curve: Curves.easeOut).transform(_entree.value),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipPath(
            clipper: _Cercle(1 - _resserre.transform(f)),
            child: const ColoredBox(color: C.laterite),
          ),
          Center(
            child: Opacity(opacity: 1 - _logoEfface.transform(f), child: _Logo(_entree.value)),
          ),
        ],
      ),
    );
  }
}

/// Cercle centré sur le logo ; à 1, il couvre tout l'écran.
class _Cercle extends CustomClipper<Path> {
  _Cercle(this.part);
  final double part;

  @override
  Path getClip(Size size) {
    final centre = size.center(Offset.zero);
    return Path()..addOval(Rect.fromCircle(center: centre, radius: part * centre.distance));
  }

  @override
  bool shouldReclip(_Cercle old) => old.part != part;
}

/// Logo FasoCovoit en quatre calques (`assets/logo`), placés et animés comme
/// dans `web/index.html` : l'épingle tombe et rebondit, « FasoC » et « voit »
/// glissent vers le centre, puis le slogan monte.
class _Logo extends StatelessWidget {
  const _Logo(this.t);

  /// Arrivée : 0 → 1 ; à 1, le logo est au repos.
  final double t;

  static const calques = [
    'assets/logo/logo_faso.png',
    'assets/logo/logo_voit.png',
    'assets/logo/logo_slogan.png',
    'assets/logo/logo_epingle.png',
  ];

  /// Largeur sur hauteur des calques.
  static const _format = 886 / 279;

  @override
  Widget build(BuildContext context) {
    final largeur = math.min(MediaQuery.sizeOf(context).width * .72, 320.0);
    final hauteur = largeur / _format;
    Widget calque(int i, {double dx = 0, double dy = 0, double opacite = 1}) => Opacity(
      opacity: opacite.clamp(0, 1),
      child: Transform.translate(
        offset: Offset(dx * largeur, dy * hauteur),
        child: Image.asset(
          calques[i],
          width: largeur,
          height: hauteur,
          fit: BoxFit.fill,
          gaplessPlayback: true,
          excludeFromSemantics: true,
        ),
      ),
    );
    final mots = const Interval(.3, .85, curve: Curves.easeOutCubic).transform(t);
    final slogan = const Interval(.55, 1, curve: Curves.easeOutCubic).transform(t);
    final chute = Curves.bounceOut.transform(const Interval(0, .72).transform(t));
    return SizedBox(
      width: largeur,
      height: hauteur,
      child: Stack(
        children: [
          calque(0, dx: -.05 * (1 - mots), opacite: mots),
          calque(1, dx: .05 * (1 - mots), opacite: mots),
          calque(2, dy: .1 * (1 - slogan), opacite: slogan),
          calque(3, dy: -.7 * (1 - chute), opacite: const Interval(0, .3).transform(t)),
        ],
      ),
    );
  }
}
