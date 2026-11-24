import 'package:web/web.dart' as web;

/// Sur le Web (téléphone), un lien `tel:` ouvre le composeur.
bool ouvrirTelephone(String numero) {
  final propre = numero.replaceAll(RegExp(r'[^0-9+]'), '');
  if (propre.isEmpty) return false;
  web.window.open('tel:$propre', '_self');
  return true;
}

/// Ouvre un lien externe (Google Maps) dans un nouvel onglet ou l'application.
bool ouvrirLien(Uri lien) {
  web.window.open(lien.toString(), '_blank');
  return true;
}
