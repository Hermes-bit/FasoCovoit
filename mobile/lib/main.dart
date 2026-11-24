import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'model.dart';
import 'screens/compte.dart';
import 'screens/conducteur.dart';
import 'screens/passager.dart';
import 'theme.dart';

void main() {
  final state = AppState()..demarrerHorloge();
  runApp(FasoCovoitApp(state: state));
}

class FasoCovoitApp extends StatelessWidget {
  const FasoCovoitApp({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) => AppScope(
    state: state,
    child: MaterialApp(
      title: 'FasoCovoit',
      debugShowCheckedModeBanner: false,
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: construireTheme(),
      // Sur grand écran (Web), l'application garde une largeur de téléphone.
      builder: (context, child) => ColoredBox(
        color: const Color(0xFFE4D2B6),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ClipRect(child: child),
          ),
        ),
      ),
      home: const Racine(),
    ),
  );
}

/// Bienvenue hors connexion, puis espace passager ou conducteur.
class Racine extends StatelessWidget {
  const Racine({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    if (!s.connecte) return const BienvenueEcran();
    return s.mode == Mode.conducteur ? const EspaceConducteur() : const EspacePassager();
  }
}
