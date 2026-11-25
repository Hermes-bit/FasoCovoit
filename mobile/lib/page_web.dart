import 'dart:js_interop';

import 'package:flutter/painting.dart';
import 'package:web/web.dart' as web;

/// Fonctions de `window.fasoPage`, définies dans `web/index.html`.
@JS('fasoPage')
external _FasoPage? get _fasoPage;

extension type _FasoPage._(JSObject _) implements JSObject {
  external JSPromise<JSAny?> get intro;
  external void retirer();
  external String marges();
}

/// Attend la fin de l'animation du logo, jouée par la page pendant le
/// chargement de Flutter.
Future<void> introPage() async {
  final p = _fasoPage;
  if (p == null) return;
  await p.intro.toDart;
}

/// Retire l'écran d'ouverture de la page : Flutter affiche le même dessous.
void retirerIntroPage() => _fasoPage?.retirer();

/// Marges de l'écran (encoche, barre d'accueil de l'iPhone), que Flutter Web
/// ne fournit pas : il les donne toujours à zéro.
EdgeInsets margesEcran() {
  final p = _fasoPage;
  if (p == null) return EdgeInsets.zero;
  final v = p.marges().split(',').map((e) => double.tryParse(e) ?? 0).toList();
  if (v.length != 4) return EdgeInsets.zero;
  return EdgeInsets.fromLTRB(v[3], v[0], v[1], v[2]);
}

/// Appelle [f] quand la fenêtre change de taille (rotation de l'écran).
void surRedimension(void Function() f) => web.window.addEventListener('resize', ((web.Event _) => f()).toJS);
