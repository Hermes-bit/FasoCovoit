import 'package:fasocovoit/journeys.dart';
import 'package:fasocovoit/main.dart';
import 'package:fasocovoit/profile_screens.dart';
import 'package:fasocovoit/screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('recherche et réservation restent des simulations', (
    tester,
  ) async {
    final store = JourneyStore.demo();
    await tester.pumpWidget(FasoCovoitApp(store: store));
    expect(find.textContaining('DÉMONSTRATION LOCALE'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Trouver un trajet'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(SearchScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text('Trouver un trajet'));
    await tester.pumpAndSettle();
    expect(find.text('Trajets disponibles'), findsOneWidget);
    await tester.tap(find.textContaining('Ibrahim O.').first);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Simuler la réservation'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(DetailScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text('Simuler la réservation'));
    await tester.pumpAndSettle();
    expect(store.bookings.single.seats, 1);
    expect(store.availableSeats(store.journeys.first), 2);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.route_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annuler la simulation'));
    await tester.pumpAndSettle();
    expect(store.bookings, isEmpty);
    expect(store.availableSeats(store.journeys.first), 3);
  });

  testWidgets('publication locale visible dans mes trajets', (tester) async {
    final store = JourneyStore.demo();
    await tester.pumpWidget(FasoCovoitApp(store: store));
    await tester.tap(find.text('Publier'));
    await tester.pumpAndSettle();
    final scrollable = find
        .descendant(
          of: find.byType(PublishScreen),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.widgetWithText(TextFormField, 'Prix par place (FCFA)'),
      200,
      scrollable: scrollable,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Prix par place (FCFA)'),
      '3500',
    );
    await tester.scrollUntilVisible(
      find.text('Publier dans la démonstration'),
      200,
      scrollable: scrollable,
    );
    await tester.tap(find.text('Publier dans la démonstration'));
    await tester.pumpAndSettle();
    expect(store.journeys.where((journey) => journey.own), hasLength(1));
    expect(find.text('Trajets publiés'), findsOneWidget);
  });

  testWidgets('profil, aide et signalement restent sans envoi réel', (
    tester,
  ) async {
    await tester.pumpWidget(FasoCovoitApp(store: JourneyStore.demo()));
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    expect(find.text('Profil de démonstration'), findsOneWidget);

    await tester.tap(find.text('Centre d’aide'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Une réservation est-elle réelle ?'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('ne réserve aucune place réelle'),
      findsOneWidget,
    );

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    final profileScrollable = find
        .descendant(
          of: find.byType(ProfileScreen),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.text('Centre de sécurité'),
      200,
      scrollable: profileScrollable,
    );
    await tester.tap(find.text('Centre de sécurité'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Signaler un problème (démo)'));
    await tester.tap(find.text('Signaler un problème (démo)'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField),
      'Le bouton ne répond pas.',
    );
    await tester.tap(find.text('Tester l’envoi (aucun envoi réel)'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Aucun signalement n’a été envoyé'),
      findsOneWidget,
    );
  });

  testWidgets('guide d’accueil présente ses trois étapes', (tester) async {
    await tester.pumpWidget(FasoCovoitApp(store: JourneyStore.demo()));
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Comment ça marche ?'));
    await tester.pumpAndSettle();
    expect(find.text('Trouvez un trajet'), findsOneWidget);
    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();
    expect(find.text('Vérifiez les détails'), findsOneWidget);
    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();
    expect(find.text('Préparez le voyage'), findsOneWidget);
    expect(find.text('Terminer'), findsOneWidget);
  });
}
