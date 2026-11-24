import 'package:flutter/material.dart';

import 'appel_stub.dart' if (dart.library.html) 'appel_web.dart' as plateforme;
import 'model.dart';
import 'ui.dart';

/// Lien d'itinéraire Google Maps (en voiture) entre deux lieux.
Uri lienItineraire(Lieu depart, Lieu arrivee) {
  String adresse(Lieu l) => '${l.quartier}, ${l.ville}, Burkina Faso';
  return Uri.https('www.google.com', '/maps/dir/', {
    'api': '1',
    'origin': adresse(depart),
    'destination': adresse(arrivee),
    'travelmode': 'driving',
  });
}

/// Ouvre l'itinéraire dans Google Maps (Web) ; ailleurs, affiche l'adresse.
Future<void> ouvrirItineraire(BuildContext context, Lieu depart, Lieu arrivee) async {
  if (plateforme.ouvrirLien(lienItineraire(depart, arrivee))) return;
  await informer(
    context,
    'Itinéraire',
    'Destination : ${arrivee.complet}.\n\n'
        'Dans la version installée, ce bouton ouvrira Google Maps pour vous guider.',
  );
}

/// Ouvre le composeur sur le Web (lien `tel:`). Ailleurs, affiche le numéro
/// à composer : l'application native n'intègre pas encore la téléphonie.
Future<void> appeler(BuildContext context, String numero, {String? titre}) async {
  if (plateforme.ouvrirTelephone(numero)) return;
  await informer(
    context,
    titre ?? 'Appeler le $numero',
    'Composez le $numero depuis votre téléphone. '
        'Dans ce prototype, l’appel n’est pas lancé automatiquement.',
  );
}
