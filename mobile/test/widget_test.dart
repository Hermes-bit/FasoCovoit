import 'package:fasocovoit/journeys.dart';
import 'package:fasocovoit/main.dart';
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
}
