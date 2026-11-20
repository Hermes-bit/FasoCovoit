import 'package:fasocovoit/google_maps_embed.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('construit une URL Google Maps Embed avec étapes encodées', () {
    final uri = googleMapsDirectionsUri(
      apiKey: 'example-key',
      departure: 'Ouagadougou',
      destination: 'Bobo-Dioulasso',
      stop: 'Boromo',
    );

    expect(uri.host, 'www.google.com');
    expect(uri.path, '/maps/embed/v1/directions');
    expect(uri.queryParameters, {
      'key': 'example-key',
      'origin': 'Ouagadougou',
      'destination': 'Bobo-Dioulasso',
      'mode': 'driving',
      'waypoints': 'Boromo',
    });
  });

  testWidgets('signale que la carte intégrée ne concerne pas Flutter natif', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GoogleMapsRouteEmbed(
            departure: 'Ouagadougou',
            destination: 'Bobo-Dioulasso',
            apiKey: '',
          ),
        ),
      ),
    );

    expect(find.text('Carte intégrée disponible sur le Web'), findsOneWidget);
    expect(
      find.textContaining('n’est pas utilisé dans la version Flutter native'),
      findsOneWidget,
    );
  });
}
