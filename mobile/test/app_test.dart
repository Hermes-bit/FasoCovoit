import 'package:fasocovoit/main.dart';
import 'package:fasocovoit/model.dart';
import 'package:fasocovoit/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final maintenant = DateTime(2026, 11, 24, 18);

Future<AppState> lancer(WidgetTester tester, {bool connecte = false}) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final s = AppState(horloge: () => maintenant);
  if (connecte) s.connecter();
  await tester.pumpWidget(FasoCovoitApp(state: s));
  await tester.pumpAndSettle();
  return s;
}

Future<void> toucher(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

Finder bouton(String label) => find.widgetWithText(Btn, label);

void main() {
  testWidgets('inscription : numéro, code SMS, profil, contact d’urgence', (tester) async {
    final s = await lancer(tester);
    expect(find.text('On fait la route ensemble.'), findsOneWidget);

    await toucher(tester, find.text('Commencer'));
    expect(find.text('Quel est votre numéro ?'), findsOneWidget);
    await toucher(tester, bouton('Recevoir le code'));

    expect(find.text('Entrez le code reçu'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '481927');
    await toucher(tester, bouton('Valider'));

    expect(find.text('Faisons connaissance'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Fatou');
    await toucher(tester, bouton('Continuer'));

    expect(find.text('Qui prévenir en cas de problème ?'), findsOneWidget);
    await toucher(tester, bouton('Terminer'));

    expect(s.connecte, isTrue);
    expect(find.text('Ne y windiga, Fatou'), findsOneWidget);
    expect(find.text('Où allez-vous ?'), findsOneWidget);
  });

  testWidgets('réserver avec le portefeuille, puis annuler selon les règles', (tester) async {
    final s = await lancer(tester, connecte: true);

    await toucher(tester, bouton('Rechercher'));
    expect(find.text('Ouagadougou → Koudougou'), findsOneWidget);
    await toucher(tester, find.text('Issouf K.').first);

    expect(find.text('Toyota Corolla grise'), findsOneWidget);
    await toucher(tester, bouton('Continuer'));

    expect(find.text('Comment voulez-vous payer ?'), findsOneWidget);
    await toucher(tester, bouton('Payer avec mon portefeuille'));

    expect(find.text('Issouf a 30 minutes pour accepter'), findsOneWidget);
    expect(s.depose, 5000);
    expect(s.bonus, 0);

    await toucher(tester, bouton('Simuler l’acceptation du conducteur'));
    expect(find.text('FC-7QK4-M9R'), findsOneWidget);
    expect(find.text('À MONTRER AU CONDUCTEUR'), findsOneWidget);

    await toucher(tester, find.text('Annuler la réservation'));
    // Départ dans 13 h : 50 % remboursés, bonus compris.
    expect(find.textContaining('50 %'), findsWidgets);
    await toucher(tester, bouton("Confirmer l'annulation"));

    final resa = s.reservations.firstWhere((r) => r.ref == 'FC-7QK4-M9R');
    expect(resa.statut, StatutResa.annulee);
    expect(s.depose, 6000);
    expect(s.bonus, 250);
    expect(find.text('Mes trajets'), findsWidgets);
  });

  testWidgets('devenir conductrice puis publier un premier trajet', (tester) async {
    final s = await lancer(tester, connecte: true);

    await toucher(tester, find.text('Profil'));
    await toucher(tester, find.text('Devenir conductrice'));
    await toucher(tester, find.widgetWithText(Btn, 'Commencer mon inscription'));

    expect(find.text('0 documents sur 5'), findsOneWidget);
    for (var i = 0; i < 5; i++) {
      await toucher(tester, find.widgetWithText(BtnP, 'Photo').first);
    }
    expect(find.text('5 documents sur 5'), findsOneWidget);
    await toucher(tester, find.byType(Checkbox));
    await toucher(tester, bouton('Envoyer pour validation'));

    expect(find.text("C'est en bonne voie"), findsOneWidget);
    await toucher(tester, bouton('Simuler la validation par l’équipe'));
    await toucher(tester, bouton('Compte validé : choisir mon abonnement'));
    await toucher(tester, bouton('Continuer avec le trimestriel'));
    await toucher(tester, bouton('Activer mon abonnement'));

    expect(find.text('Bienvenue parmi les conductrices, Awa !'), findsOneWidget);
    expect(s.estConducteur, isTrue);
    await toucher(tester, bouton('Publier mon premier trajet'));

    expect(find.text('Publier un trajet'), findsOneWidget);
    await toucher(tester, bouton('Publier le trajet'));

    expect(s.mode, Mode.conducteur);
    expect(s.trajetsPublies, hasLength(1));
    expect(find.text('Bonjour Awa'), findsOneWidget);
    expect(find.text('1 demande à traiter'), findsOneWidget);
  });
}
