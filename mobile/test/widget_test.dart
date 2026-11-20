import 'package:fasocovoit/journeys.dart';
import 'package:fasocovoit/main.dart';
import 'package:fasocovoit/passenger_profile_screen.dart';
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
    await tester.tap(find.byIcon(Icons.bookmark_outline));
    await tester.pumpAndSettle();
    expect(find.text('Mes réservations'), findsWidgets);
    await tester.tap(find.text('Annuler la simulation'));
    await tester.pumpAndSettle();
    expect(store.bookings, isEmpty);
    expect(store.availableSeats(store.journeys.first), 3);
  });

  testWidgets('profil passager modifiable et distinct du conducteur', (
    tester,
  ) async {
    final store = JourneyStore.demo();
    await tester.pumpWidget(FasoCovoitApp(store: store));
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    expect(find.text('ESPACE PASSAGER'), findsOneWidget);
    expect(find.text('Trajets réservés'), findsOneWidget);
    expect(find.text('Publier'), findsNothing);

    final profileScrollable = find
        .descendant(
          of: find.byType(PassengerProfileScreen),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.text('Mes informations'),
      200,
      scrollable: profileScrollable,
    );
    await tester.tap(find.text('Mes informations'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Awa Demo');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Awa Demo'),
      -200,
      scrollable: profileScrollable,
    );
    expect(find.text('Awa Demo'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Moyens de paiement'),
      200,
      scrollable: profileScrollable,
    );
    await tester.ensureVisible(find.text('Moyens de paiement'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Moyens de paiement'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Ne saisissez pas de coordonnées bancaires.'),
      findsOneWidget,
    );
  });
}
