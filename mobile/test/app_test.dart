import 'dart:convert';

import 'package:fasocovoit/main.dart';
import 'package:fasocovoit/model.dart';
import 'package:fasocovoit/photo.dart';
import 'package:fasocovoit/screens/compte.dart';
import 'package:fasocovoit/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final maintenant = DateTime(2026, 11, 24, 18);

/// Image PNG d'un pixel : l'appareil photo n'existe pas dans les tests.
final pixel = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

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
  setUp(() => preneurPhoto = (source, {selfie = false}) async => pixel);

  testWidgets('photo de profil : prendre, puis retirer', (tester) async {
    final s = await lancer(tester, connecte: true);
    await toucher(tester, find.text('Profil'));
    expect(s.photo, isNull);

    await toucher(tester, find.byType(BoutonPhotoProfil));
    expect(find.text('Prendre une photo'), findsOneWidget);
    expect(find.text('Importer une photo'), findsOneWidget);
    await toucher(tester, find.text('Prendre une photo'));
    expect(s.photo, pixel);

    await toucher(tester, find.byType(BoutonPhotoProfil));
    await toucher(tester, find.text('Retirer la photo'));
    expect(s.photo, isNull);
  });

  testWidgets('inscription avec un nouveau numéro : compte vierge', (tester) async {
    final s = await lancer(tester);
    expect(find.text('On fait la route ensemble.'), findsOneWidget);

    await toucher(tester, find.text('Commencer'));
    expect(find.text('Quel est votre numéro ?'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '76543210');
    await toucher(tester, bouton('Recevoir le code'));

    expect(find.text('Entrez le code reçu'), findsOneWidget);
    expect(find.text('SMS · FasoCovoit'), findsOneWidget);
    await tester.enterText(find.byType(TextField), s.dernierCodeSms!);
    await toucher(tester, bouton('Valider'));

    expect(find.text('Faisons connaissance'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), 'Fatou');
    await tester.enterText(find.byType(TextField).at(1), 'Sanou');
    await toucher(tester, bouton('Continuer'));
    expect(find.text('Faisons connaissance'), findsOneWidget, reason: 'le genre est obligatoire');
    await toucher(tester, find.text('Femme'));
    await toucher(tester, bouton('Continuer'));

    expect(find.text('Qui prévenir en cas de problème ?'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), 'Ali Sanou');
    await tester.enterText(find.byType(TextField).at(1), '+226 76 11 22 33');
    await toucher(tester, bouton('Terminer'));

    // À l'entrée, on choisit son espace.
    expect(find.text('Comment utilisez-vous FasoCovoit ?'), findsOneWidget);
    await toucher(tester, find.text('Je cherche un trajet'));

    expect(s.connecte, isTrue);
    expect(s.telephone, '76 54 32 10');
    expect(s.solde, 0);
    expect(s.reservations, isEmpty);
    expect(find.text('Ne y windiga, Fatou'), findsOneWidget);
    expect(find.text('Où allez-vous ?'), findsOneWidget);
  });

  testWidgets('compte existant 70 00 00 00 : connexion avec le code SMS', (tester) async {
    final s = await lancer(tester);
    await toucher(tester, find.text("J'ai déjà un compte"));

    // Le numéro de démonstration est pré-rempli.
    await toucher(tester, bouton('Recevoir le code'));
    expect(find.textContaining('vous allez vous connecter'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '000000');
    await toucher(tester, bouton('Me connecter'));
    expect(find.textContaining('Code incorrect'), findsOneWidget);
    expect(s.connecte, isFalse);

    await tester.enterText(find.byType(TextField), s.dernierCodeSms!);
    await toucher(tester, bouton('Me connecter'));
    expect(s.connecte, isTrue);
    expect(find.text('Comment utilisez-vous FasoCovoit ?'), findsOneWidget);
    await toucher(tester, find.text('Je cherche un trajet'));
    expect(s.solde, 7500);
    expect(find.text('Ne y windiga, Hermès'), findsOneWidget);
  });

  testWidgets('conducteur dès l’entrée, sans passer par l’espace passager', (tester) async {
    final s = await lancer(tester);
    await toucher(tester, find.text("J'ai déjà un compte"));
    await toucher(tester, bouton('Recevoir le code'));
    await tester.enterText(find.byType(TextField), s.dernierCodeSms!);
    await toucher(tester, bouton('Me connecter'));

    await toucher(tester, find.text('Je propose mes trajets'));
    expect(s.mode, Mode.conducteur);
    expect(find.text('Mode conducteur'), findsOneWidget);
    expect(find.text('Activez votre compte conducteur'), findsOneWidget);
    // Les passagers inscrits sont déjà visibles.
    expect(find.textContaining('Passagers inscrits qui cherchent un trajet'), findsOneWidget);
    expect(find.text('Fatou S.'), findsOneWidget);

    await toucher(tester, find.widgetWithText(Btn, 'Envoyer mes documents'));
    expect(find.text('0 documents sur 5'), findsOneWidget);
  });

  testWidgets('passager : choisir la date et l’heure, publier sa demande, un conducteur vient', (tester) async {
    final s = await lancer(tester, connecte: true);
    await toucher(tester, find.text('Demain, mer. 25 nov. · 7 h 00'));
    // Calendrier puis horloge.
    await toucher(tester, find.text('26'));
    await toucher(tester, find.text('OK'));
    await toucher(tester, find.text('OK'));
    expect(find.text('Jeu. 26 nov. · 7 h 00'), findsOneWidget);

    await toucher(tester, bouton('Rechercher'));
    expect(find.textContaining('Aucun conducteur ne passe par là jeu. 26 nov. vers 7 h'), findsOneWidget);
    await toucher(tester, find.widgetWithText(BtnClair, 'Publier ma demande'));
    final d = s.demandesTrajet.singleWhere((d) => d.moi);
    expect(d.quand, DateTime(2026, 11, 26, 7));

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    await toucher(tester, find.text('Mes trajets').last);
    expect(find.text('En attente d’un conducteur'), findsOneWidget);
    await toucher(tester, bouton('Simuler la réponse d’un conducteur'));
    final r = s.reservations.singleWhere((r) => r.montee == d.depart && r.trajet.heureDepart == d.quand);
    expect(r.statut, StatutResa.confirmee);
    expect(find.text('En attente d’un conducteur'), findsNothing);
  });

  testWidgets('numéro inconnu sur « J’ai déjà un compte » : création proposée', (tester) async {
    final s = await lancer(tester);
    await toucher(tester, find.text("J'ai déjà un compte"));
    await tester.enterText(find.byType(TextField), '65 43 21 09');
    await toucher(tester, bouton('Recevoir le code'));

    expect(find.text('Aucun compte avec ce numéro'), findsOneWidget);
    await toucher(tester, bouton('Créer un compte'));
    expect(find.text('Entrez le code reçu'), findsOneWidget);
    expect(find.text('Valider'), findsOneWidget);
    expect(s.compteExiste('65432109'), isFalse);
  });

  testWidgets('passager : choisir un trajet en ville', (tester) async {
    await lancer(tester, connecte: true);
    await toucher(tester, find.text('En ville'));
    expect(find.text('Ouagadougou, Dassasgho'), findsOneWidget);
    await toucher(tester, bouton('Rechercher'));
    expect(find.text('Dassasgho → Ouaga 2000'), findsOneWidget);
    expect(find.text('Ousmane B.'), findsOneWidget);
  });

  testWidgets('passager : les offres se croisent avec son adresse, sinon il publie sa demande', (tester) async {
    final s = await lancer(tester, connecte: true);
    await toucher(tester, bouton('Rechercher'));
    expect(find.textContaining('de votre adresse'), findsWidgets);
    await toucher(tester, find.widgetWithText(BtnClair, 'Publier ma demande'));
    expect(s.demandesTrajet.where((d) => d.moi), hasLength(1));
  });

  testWidgets('connexion Google annoncée mais pas encore branchée', (tester) async {
    await lancer(tester);
    await toucher(tester, find.text('Continuer avec Google'));
    expect(find.text('Connexion avec Google'), findsOneWidget);
    expect(find.textContaining('70 00 00 00'), findsOneWidget);
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

  testWidgets('devenir conducteur puis publier un premier trajet', (tester) async {
    final s = await lancer(tester, connecte: true);

    await toucher(tester, find.text('Profil'));
    await toucher(tester, find.text('Devenir conducteur'));
    await toucher(tester, find.widgetWithText(Btn, 'Commencer mon inscription'));

    expect(find.text('0 documents sur 5'), findsOneWidget);
    for (var i = 0; i < 5; i++) {
      await toucher(tester, find.widgetWithText(BtnP, 'Photo').first);
      await toucher(tester, find.text('Importer une photo'));
    }
    expect(find.text('5 documents sur 5'), findsOneWidget);
    expect(s.photosDocuments, hasLength(5));
    await toucher(tester, find.byType(Checkbox));
    await toucher(tester, bouton('Envoyer pour validation'));

    expect(find.text("C'est en bonne voie"), findsOneWidget);
    await toucher(tester, bouton('Simuler la validation par l’équipe'));
    await toucher(tester, bouton('Compte validé : choisir mon abonnement'));
    await toucher(tester, bouton('Continuer avec le trimestriel'));
    await toucher(tester, bouton('Activer mon abonnement'));

    expect(find.text('Bienvenue parmi les conducteurs, Hermès !'), findsOneWidget);
    expect(s.estConducteur, isTrue);
    await toucher(tester, bouton('Publier mon premier trajet'));

    expect(find.text('Publier un trajet'), findsOneWidget);
    // Sans destination, on ne peut pas publier.
    await toucher(tester, bouton('Publier le trajet'));
    expect(s.trajetsPublies, isEmpty);

    // Le conducteur cherche et choisit sa destination.
    await toucher(tester, find.text('Où allez-vous ?'));
    await tester.enterText(find.byType(TextField), 'secteur');
    await tester.pumpAndSettle();
    await toucher(tester, find.text('Secteur 7'));
    expect(find.text('Koudougou, Secteur 7'), findsOneWidget);
    expect(find.textContaining('98 km'), findsOneWidget);

    await toucher(tester, bouton('Publier le trajet'));

    expect(s.mode, Mode.conducteur);
    expect(s.trajetsPublies, hasLength(1));
    expect(s.trajetsPublies.single.ligne.arrivee, lKoudS7);
    expect(find.text('Bonjour Hermès'), findsOneWidget);
    expect(find.text('1 demande à traiter'), findsOneWidget);

    // Des passagers attendent sur sa route : il est alerté et choisit.
    final avant = s.coursesPossibles.length;
    expect(avant, greaterThan(0));
    expect(find.widgetWithText(Btn, 'Prendre la course'), findsNWidgets(avant));
    await toucher(tester, find.widgetWithText(Btn, 'Prendre la course').first);
    // Moins d'alertes : celle prise, et celles qui n'ont plus assez de places.
    expect(s.coursesPossibles.length, lessThan(avant));
    expect(find.textContaining('Course acceptée'), findsOneWidget);
  });
}
