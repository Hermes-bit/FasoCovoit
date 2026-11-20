import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'journeys.dart';
import 'screens.dart';

void main() =>
    runApp(FasoCovoitApp(store: JourneyStore.demo(includeDriverRequest: true)));

class FasoCovoitApp extends StatelessWidget {
  const FasoCovoitApp({super.key, required this.store});

  final JourneyStore store;

  @override
  Widget build(BuildContext context) {
    const green = Color(0xff09683f);
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: green, primary: green),
      scaffoldBackgroundColor: const Color(0xfff7f5ef),
      useMaterial3: true,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
    return MaterialApp(
      title: 'FasoCovoit',
      debugShowCheckedModeBanner: false,
      locale: const Locale('fr'),
      supportedLocales: const [Locale('fr')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: theme,
      home: MainScreen(store: store),
    );
  }
}
