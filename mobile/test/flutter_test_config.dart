import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Charge les vraies polices de l'application : sans elles, les tests
/// utilisent une police de remplacement très large et la mise en page
/// ne ressemble pas à celle du téléphone.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> charger(String famille, List<String> fichiers) async {
    final loader = FontLoader(famille);
    for (final f in fichiers) {
      loader.addFont(rootBundle.load('assets/fonts/$f'));
    }
    await loader.load();
  }

  await charger('Figtree', [
    'Figtree-Regular.ttf',
    'Figtree-Medium.ttf',
    'Figtree-SemiBold.ttf',
    'Figtree-Bold.ttf',
    'Figtree-ExtraBold.ttf',
  ]);
  await charger('Bricolage', ['BricolageGrotesque-Bold.ttf', 'BricolageGrotesque-ExtraBold.ttf']);
  await testMain();
}
