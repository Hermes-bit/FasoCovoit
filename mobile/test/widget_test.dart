import 'package:fasocovoit/journeys.dart';
import 'package:fasocovoit/main.dart';
import 'package:fasocovoit/profile_screens.dart';
import 'package:fasocovoit/screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:fasocovoit/route_preview.dart';

Future<RouteLine> _fakeRoute(
  String departure,
  String destination,
  String? stop,
) async {
  final waypoints = [
    RouteWaypoint(name: departure, location: const LatLng(12, -2)),
    if (stop != null && stop.isNotEmpty)
      RouteWaypoint(name: stop, location: const LatLng(11.7, -3)),
    RouteWaypoint(name: destination, location: const LatLng(11, -4)),
  ];
  return RouteLine(
    points: waypoints.map((waypoint) => waypoint.location).toList(),
    waypoints: waypoints,
    distanceMeters: 355000,
    durationSeconds: 15000,
  );
}

Future<RouteLine> _failedRoute(
  String departure,
  String destination,
  String? stop,
) async {
  throw const RoutePreviewException('Itinéraire indisponible pour le test.');
}

FasoCovoitApp _demoApp(JourneyStore store) =>
    FasoCovoitApp(store: store, routeLoader: _fakeRoute);

void main() {
  testWidgets('recherche et réservation restent des simulations', (
    tester,
  ) async {
    final store = JourneyStore.demo();
    await tester.pumpWidget(_demoApp(store));
    expect(find.textContaining('DÉMONSTRATION LOCALE'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Rechercher les trajets'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(SearchScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text('Rechercher les trajets'));
    await tester.pumpAndSettle();
    expect(find.text('Trajets disponibles'), findsOneWidget);
    await tester.tap(find.textContaining('Ibrahim O.').first);
    await tester.pumpAndSettle();
    expect(find.text('Aperçu de l’itinéraire'), findsOneWidget);
    expect(find.textContaining('355 km'), findsOneWidget);
    await tester.tap(find.text('Simuler la réservation'));
    await tester.pumpAndSettle();
    expect(store.bookings.single.seats, 1);
    expect(store.availableSeats(store.journeys.first), 2);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.route_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annuler ma demande'));
    await tester.pumpAndSettle();
    expect(store.bookings.single.status, BookingStatus.cancelled);
    expect(store.availableSeats(store.journeys.first), 3);
  });

  testWidgets('la réservation est bloquée si le calcul de route échoue', (
    tester,
  ) async {
    final store = JourneyStore.demo();
    await tester.pumpWidget(
      MaterialApp(
        home: DetailScreen(
          store: store,
          journey: store.journeys.first,
          initialSeats: 1,
          routeLoader: _failedRoute,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Itinéraire indisponible'), findsOneWidget);
    expect(find.text('Simuler la réservation'), findsNothing);
  });

  testWidgets('publication locale visible dans mes trajets', (tester) async {
    final store = JourneyStore.demo();
    await tester.pumpWidget(_demoApp(store));
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
    expect(find.text('Mes trajets comme conducteur'), findsOneWidget);
  });

  testWidgets('le conducteur peut accepter une demande en attente', (
    tester,
  ) async {
    final store = JourneyStore.demo(includeDriverRequest: true);
    await tester.pumpWidget(_demoApp(store));
    await tester.tap(find.byIcon(Icons.route_outlined));
    await tester.pumpAndSettle();
    final scrollable = find
        .descendant(
          of: find.byType(MyJourneysScreen),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.text('Accepter'),
      200,
      scrollable: scrollable,
    );
    await tester.ensureVisible(find.text('Accepter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Accepter'));
    await tester.pumpAndSettle();

    expect(store.bookings.single.status, BookingStatus.accepted);
    expect(find.text('Confirmée dans la démo'), findsOneWidget);
  });

  testWidgets('profil, aide et signalement restent sans envoi réel', (
    tester,
  ) async {
    await tester.pumpWidget(_demoApp(JourneyStore.demo()));
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
    await tester.pumpWidget(_demoApp(JourneyStore.demo()));
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

  testWidgets('profil propose un accès passager et conducteur', (tester) async {
    await tester.pumpWidget(_demoApp(JourneyStore.demo()));
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    final scrollable = find
        .descendant(
          of: find.byType(ProfileScreen),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.text('Prendre un trajet'),
      200,
      scrollable: scrollable,
    );
    await tester.tap(find.text('Prendre un trajet'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Rechercher les trajets'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(SearchScreen),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('Rechercher les trajets'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();
    final profileScrollable = find
        .descendant(
          of: find.byType(ProfileScreen),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.text('Proposer un trajet'),
      200,
      scrollable: profileScrollable,
    );
    await tester.tap(find.text('Proposer un trajet'));
    await tester.pumpAndSettle();
    expect(find.text('Publier un trajet'), findsOneWidget);
  });
}
