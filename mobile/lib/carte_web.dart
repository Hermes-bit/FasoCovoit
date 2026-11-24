import 'dart:js_interop';

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

/// Fonctions de `web/carte.js` (chargé par `web/index.html`).
@JS('fasoCarte')
external _FasoCarte? get _fasoCarte;

extension type _FasoCarte._(JSObject _) implements JSObject {
  external JSPromise<JSAny?> afficher(web.HTMLElement div, String cle, String options, JSFunction surErreur);
  external JSPromise<JSString> suggestions(String cle, String texte);
  external JSPromise<JSString> details(String cle, String id);
}

bool get pret => _fasoCarte != null;

/// Une `div` où `carte.js` dessine la carte Google Maps.
Widget vueCarte({required String cle, required String options, required void Function() surErreur}) =>
    HtmlElementView.fromTagName(
      tagName: 'div',
      onElementCreated: (element) {
        final div = element as web.HTMLElement;
        div.style
          ..width = '100%'
          ..height = '100%';
        final f = _fasoCarte;
        if (f == null) {
          surErreur();
          return;
        }
        f.afficher(div, cle, options, surErreur.toJS);
      },
    );

Future<String> suggestions(String cle, String texte) async {
  final f = _fasoCarte;
  if (f == null) throw StateError('carte.js absent');
  return (await f.suggestions(cle, texte).toDart).toDart;
}

Future<String> details(String cle, String id) async {
  final f = _fasoCarte;
  if (f == null) throw StateError('carte.js absent');
  return (await f.details(cle, id).toDart).toDart;
}
