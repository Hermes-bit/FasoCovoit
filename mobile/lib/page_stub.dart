import 'package:flutter/painting.dart';

/// Hors du Web : pas d'écran d'ouverture dans la page, pas de marges à lire.
Future<void> introPage() async {}

void retirerIntroPage() {}

EdgeInsets margesEcran() => EdgeInsets.zero;

void surRedimension(void Function() f) {}
