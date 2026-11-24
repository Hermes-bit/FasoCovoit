import 'package:flutter/material.dart';

import 'appel_stub.dart' if (dart.library.html) 'appel_web.dart' as plateforme;
import 'ui.dart';

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
