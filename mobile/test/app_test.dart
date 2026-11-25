import 'dart:convert';

import 'package:fasocovoit/formats.dart';
import 'package:fasocovoit/main.dart';
import 'package:fasocovoit/model.dart';
import 'package:fasocovoit/ouverture.dart';
import 'package:fasocovoit/photo.dart';
import 'package:fasocovoit/screens/compte.dart';
import 'package:fasocovoit/screens/demande.dart';
import 'package:fasocovoit/screens/espace_conducteur.dart';
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
    expect(find.textContaining('Ne y windiga, Fatou !'), findsOneWidget);
    expect(find.text('Recherchez un nouveau covoit’'), findsOneWidget);
    expect(find.text('Où allez-vous ?'), findsOneWidget);
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
    expect(find.textContaining('Ne y windiga, Hermès !'), findsOneWidget);
  });

  testWidgets('conducteur dès l’entrée, sans passer par l’espace passager', (tester) async {
    final s = await lancer(tester);
    await toucher(tester, find.text("J'ai déjà un compte"));
    await toucher(tester, bouton('Recevoir le code'));
    await tester.enterText(find.byType(TextField), s.dernierCodeSms!);
    await toucher(tester, bouton('Me connecter'));

    // Première entrée : la fiche « Mode conducteur », puis « J’ai compris »
    // ouvre l'espace conducteur derrière le logo FasoCovoit.
    await toucher(tester, find.text('Je propose mes trajets'));
    expect(find.text('Le covoiturage, c’est :'), findsOneWidget);
    expect(s.espaceAChoisir, isTrue);
    await tester.tap(bouton('J’ai compris'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(Ouverture), findsOneWidget);
    expect(find.image(const AssetImage('assets/logo/logo_epingle.png')), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.image(const AssetImage('assets/logo/logo_epingle.png')), findsNothing);
    expect(s.mode, Mode.conducteur);
    expect(s.introConducteurVue, isTrue);
    expect(find.text('Bonjour Hermès'), findsOneWidget);
    expect(find.text('Activez votre compte conducteur'), findsOneWidget);

    // Les passagers inscrits sont déjà visibles dans « Covoit’ ».
    await toucher(tester, find.text('Covoit’'));
    expect(find.textContaining('Passagers inscrits qui cherchent un trajet'), findsOneWidget);
    expect(find.text('Fatou S.'), findsOneWidget);

    await toucher(tester, find.text('Accueil'));
    await toucher(tester, find.widgetWithText(Btn, 'Envoyer mes documents'));
    expect(find.text('0 document sur 6'), findsOneWidget);
  });

  testWidgets('ouverture : le logo FasoCovoit couvre l’écran, puis l’accueil monte', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final s = AppState(horloge: () => maintenant)..connecter();
    await tester.pumpWidget(FasoCovoitApp(state: s));
    final logo = find.image(const AssetImage('assets/logo/logo_faso.png'));
    final barre = find.text('Où allez-vous ?');
    expect(logo, findsOneWidget);
    // Tant que le logo est là, l'accueil est construit mais ne répond pas.
    expect(barre, findsOneWidget);
    expect(barre.hitTestable(), findsNothing);
    await tester.pumpAndSettle();
    expect(logo, findsNothing);
    expect(barre.hitTestable(), findsOneWidget);
    expect(find.textContaining('Ne y windiga, Hermès'), findsOneWidget);
  });

  testWidgets('changer d’espace : logo, cercle, puis l’autre accueil monte', (tester) async {
    final s = await lancer(tester, connecte: true);
    s.vuIntroConducteur();
    final logo = find.image(const AssetImage('assets/logo/logo_epingle.png'));

    await tester.tap(find.text('Conducteur').first);
    await tester.pump(const Duration(milliseconds: 400));
    expect(logo, findsOneWidget);
    expect(s.mode, Mode.passager, reason: 'l’espace change quand le logo couvre l’écran');
    await tester.pumpAndSettle();
    expect(logo, findsNothing);
    expect(s.mode, Mode.conducteur);
    expect(find.text('Bonjour Hermès'), findsOneWidget);

    await toucher(tester, find.text('Menu'));
    final passager = find.widgetWithText(BtnClair, 'Passer en mode passager');
    await tester.scrollUntilVisible(
      passager,
      300,
      scrollable: find.descendant(of: find.byType(MenuConducteurOnglet), matching: find.byType(Scrollable)).first,
    );
    await toucher(tester, passager);
    expect(s.mode, Mode.passager);
    expect(find.textContaining('Ne y windiga, Hermès'), findsOneWidget);
  });

  testWidgets('envoyer un colis : en ville ou vers une autre ville, taille et prix, puis suivi', (tester) async {
    await lancer(tester, connecte: true);
    await toucher(tester, find.text('Envoyer un colis'));
    expect(find.text('Le trajet du colis'), findsOneWidget);
    expect(find.text('Koudougou · Secteur 7'), findsOneWidget);
    Finder prix(int n) => find.descendant(of: find.byType(Pied), matching: find.text(fcfa(n)));
    expect(prix(1000), findsOneWidget);

    await toucher(tester, find.text('En ville'));
    expect(find.text('Ouagadougou · Ouaga 2000'), findsOneWidget);
    await toucher(tester, find.text('L'));
    expect(prix(3500), findsOneWidget);

    await toucher(tester, find.text('Objets interdits'));
    expect(find.textContaining('animaux vivants'), findsOneWidget);
    await toucher(tester, bouton('Compris'));

    await toucher(tester, bouton('Trouver un conducteur'));
    expect(find.text('Colis CL-4KM7-PQ2'), findsOneWidget);
  });

  testWidgets('noter le conducteur : « Retour » ramène à l’écran précédent', (tester) async {
    final s = await lancer(tester, connecte: true);
    await toucher(tester, find.text('Mes trajets'));
    await toucher(tester, find.text('Passés'));
    await toucher(tester, find.textContaining('Koudougou').first);
    expect(find.text('Le trajet avec Issouf ?'), findsOneWidget);

    await toucher(tester, find.byTooltip('Retour'));
    expect(find.text('Le trajet avec Issouf ?'), findsNothing);
    expect(find.text('Passés'), findsOneWidget);
    expect(s.reservations.firstWhere((r) => r.ref == 'FC-8LM2-Q5E').notee, isFalse);
  });

  testWidgets('passager : où allez-vous, puis les conducteurs acceptent (en ville, maintenant)', (tester) async {
    final s = await lancer(tester, connecte: true);
    await toucher(tester, find.text('Où allez-vous ?'));
    expect(find.text('Votre itinéraire'), findsOneWidget);
    // Départ : la maison (Dassasgho, en favori). Arrivée : on cherche.
    expect(find.text('Dassasgho, Ouaga'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'ouaga 2000');
    await tester.pumpAndSettle();
    await toucher(tester, find.text('Ouaga 2000'));

    expect(find.text('Confirmer les adresses'), findsOneWidget);
    await toucher(tester, bouton('Confirmer les adresses'));

    // Une question par écran.
    expect(find.text('Quand souhaitez-vous partir ?'), findsOneWidget);
    await toucher(tester, bouton('Suivant'));
    expect(find.text('Qui voyage ?'), findsOneWidget);
    await toucher(tester, bouton('Suivant'));
    expect(find.text('Que transportez-vous ?'), findsOneWidget);
    await toucher(tester, bouton('Suivant'));
    expect(find.text('Comment réglez-vous ?'), findsOneWidget);
    await toucher(tester, find.text('Espèces'));
    await toucher(tester, bouton('Confirmer'));

    expect(find.text('Recherche en cours…'), findsOneWidget);
    final d = s.demandesTrajet.singleWhere((d) => d.moi);
    expect(d.desQuePossible, isTrue);
    await tester.pump(RechercheEcran.rythme);
    await tester.pumpAndSettle();
    expect(find.text('1 acceptation conducteur'), findsOneWidget);
    expect(find.text('Ousmane B.'), findsOneWidget);
    await tester.pump(RechercheEcran.rythme);
    await tester.pumpAndSettle();
    expect(find.text('2 acceptations conducteurs'), findsOneWidget);
    expect(find.text('Salif est à environ 6 minutes'), findsOneWidget);

    // Profil du conducteur : avis et vérifications.
    await toucher(tester, find.widgetWithText(BtnClair, 'Voir détails').first);
    await toucher(tester, find.text('Détails'));
    expect(find.text('CNIB et selfie'), findsOneWidget);
    await toucher(tester, find.byTooltip('Retour'));

    await toucher(tester, find.widgetWithText(Btn, 'Accepter').first);
    expect(find.text('CONFIRMEZ DANS LES 15 MINUTES'), findsOneWidget);
    await toucher(tester, bouton('Confirmer'));
    expect(s.demandesTrajet.contains(d), isFalse);
    expect(s.reservations.last.statut, StatutResa.confirmee);
    expect(s.reservations.last.trajet.conducteur.prenom, 'Ousmane');
    expect(find.text('À MONTRER AU CONDUCTEUR'), findsOneWidget);
  });

  testWidgets('passager : supprimer sa demande, après confirmation', (tester) async {
    final s = await lancer(tester, connecte: true);
    s.demanderTrajet(depart: lDassasgho, arrivee: lUnivOuaga);
    await tester.pumpAndSettle();
    await toucher(tester, find.text('Recherche en cours'));
    expect(find.text('Recherche en cours…'), findsOneWidget);
    await toucher(tester, find.text('Supprimer ma demande'));
    expect(find.text('Votre demande va être supprimée, souhaitez-vous continuer ?'), findsOneWidget);
    await toucher(tester, find.widgetWithText(Btn, 'Supprimer ma demande'));
    expect(s.demandesTrajet.where((d) => d.moi), isEmpty);
    expect(find.text('Votre demande a été supprimée.'), findsOneWidget);
    expect(find.text('Où allez-vous ?'), findsOneWidget);
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

  testWidgets('connexion Google annoncée mais pas encore branchée', (tester) async {
    await lancer(tester);
    await toucher(tester, find.text('Continuer avec Google'));
    expect(find.text('Connexion avec Google'), findsOneWidget);
    expect(find.textContaining('70 00 00 00'), findsOneWidget);
  });

  testWidgets('entre villes, plus tard, payé avec le portefeuille, puis annulé selon les règles', (tester) async {
    final s = await lancer(tester, connecte: true);
    await toucher(tester, find.text('Où allez-vous ?'));
    // Départ : la gare routière de Ouaga. Arrivée : le centre de Koudougou.
    await tester.enterText(find.byType(TextField).first, 'gare');
    await tester.pumpAndSettle();
    await toucher(tester, find.text('Gare routière').first);
    await tester.enterText(find.byType(TextField).last, 'koudougou');
    await tester.pumpAndSettle();
    await toucher(tester, find.text('Centre-ville'));
    await toucher(tester, bouton('Confirmer les adresses'));

    // Entre villes : « Plus tard », demain 7 h, proposé d'office.
    expect(find.text('Demain, mer. 25 nov. · 7 h 00'), findsOneWidget);
    for (var i = 0; i < 3; i++) {
      await toucher(tester, bouton('Suivant'));
    }
    // Portefeuille choisi d'office : le solde le permet.
    expect(find.text('Solde ${fcfa(7500)}'), findsOneWidget);
    await toucher(tester, bouton('Confirmer'));

    await tester.pump(RechercheEcran.rythme);
    await tester.pumpAndSettle();
    expect(find.text('Issouf K.'), findsOneWidget);
    await toucher(tester, find.widgetWithText(Btn, 'Accepter').first);
    await toucher(tester, bouton('Confirmer'));
    // 2 500 F dont 500 F de bonus ; le conducteur avait déjà accepté.
    expect(s.depose, 5000);
    expect(s.bonus, 0);
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

    expect(find.text('0 document sur 6'), findsOneWidget);
    // Appareil photo seulement : pas de choix « Importer une photo ».
    for (var i = 0; i < 6; i++) {
      await toucher(tester, find.widgetWithText(BtnP, 'Photo').first);
      expect(find.text('Importer une photo'), findsNothing);
    }
    expect(find.text('6 documents sur 6'), findsOneWidget);
    expect(s.photosDocuments, hasLength(6));
    // Démo : informations des documents d'Hermès pré-remplies, contrôles réussis.
    expect(s.dossierComplet, isTrue);
    await toucher(tester, find.byType(Checkbox));
    await toucher(tester, bouton('Envoyer pour validation'));

    expect(find.text("C'est en bonne voie"), findsOneWidget);
    await toucher(tester, bouton('Vérification par l’équipe (démo)'));
    expect(find.text('Vérification du dossier'), findsOneWidget);
    expect(tester.widget<Btn>(bouton('Valider le conducteur')).onPressed, isNull, reason: 'liste incomplète');
    final points = find.byType(Checkbox).evaluate().length;
    expect(points, 13);
    for (var i = 0; i < points; i++) {
      await toucher(tester, find.byType(Checkbox).at(i));
    }
    await toucher(tester, bouton('Valider le conducteur'));
    expect(find.text('Votre compte est validé'), findsOneWidget);
    await toucher(tester, bouton('Compte validé : choisir mon abonnement'));
    await toucher(tester, bouton('Continuer avec le trimestriel'));
    await toucher(tester, bouton('Activer mon abonnement'));

    expect(find.text('Bienvenue parmi les conducteurs, Hermès !'), findsOneWidget);
    expect(s.estConducteur, isTrue);
    await toucher(tester, bouton('Publier mon premier trajet'));

    // « Nouveau covoit’ » : sans destination, pas d'étape suivante.
    expect(find.text('Nouveau covoit’'), findsOneWidget);
    expect(tester.widget<Btn>(bouton('Suivant')).onPressed, isNull);

    // Le conducteur cherche et choisit sa destination.
    await toucher(tester, find.text('Arrivée'));
    await tester.enterText(find.byType(TextField), 'secteur');
    await tester.pumpAndSettle();
    await toucher(tester, find.text('Secteur 7'));
    expect(find.text('Koudougou, Secteur 7'), findsOneWidget);
    expect(find.textContaining('98 km'), findsOneWidget);
    expect(find.text('Ponctuel'), findsOneWidget);

    await toucher(tester, bouton('Suivant'));
    expect(find.text('Places et prix'), findsOneWidget);
    await toucher(tester, bouton('Publier'));
    await toucher(tester, bouton('Valider le covoit’'));
    expect(find.text('Trajet enregistré'), findsOneWidget);
    await toucher(tester, bouton('Ok'));

    expect(s.mode, Mode.conducteur);
    expect(s.trajetsPublies, hasLength(1));
    expect(s.trajetsPublies.single.ligne.arrivee, lKoudS7);
    // Onglet « Proposer » : le covoit’ publié, avec une demande à traiter.
    expect(s.onglet, 2);
    expect(find.text('1 demande'), findsOneWidget);

    // Onglet « Covoit’ » : les demandes, cartes à languette.
    await toucher(tester, find.text('Covoit’'));
    expect(find.text('Nouvelles demandes'), findsOneWidget);
    final t = s.trajetsPublies.single;
    // Rasmata a réservé : on confirme.
    await toucher(tester, find.text('Rasmata Z.'));
    await toucher(tester, bouton('Confirmer'));
    expect(t.enAttente, isEmpty);
    // Un passager attend sur la route : on prend la course.
    final avant = s.coursesPossibles.length;
    expect(avant, greaterThan(0));
    await toucher(tester, find.byType(CarteDemandeConducteur).first);
    await toucher(tester, bouton('Confirmer'));
    expect(s.coursesPossibles.length, lessThan(avant));
    expect(find.textContaining('Course acceptée'), findsOneWidget);
  });
}
