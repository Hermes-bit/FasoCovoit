import 'package:web/web.dart' as web;

/// Sur le Web (téléphone), un lien `tel:` ouvre le composeur.
bool ouvrirTelephone(String numero) {
  final propre = numero.replaceAll(RegExp(r'[^0-9+]'), '');
  if (propre.isEmpty) return false;
  web.window.open('tel:$propre', '_self');
  return true;
}
