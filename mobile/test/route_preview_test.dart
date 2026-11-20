import 'dart:convert';

import 'package:fasocovoit/route_preview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';

void main() {
  test('calcule et décode l’itinéraire en passant par l’arrêt', () async {
    final client = MockClient((request) async {
      expect(request.url.path, contains('-1.5197,12.3714'));
      expect(request.url.path, contains('-2.9286,11.7458'));
      expect(request.url.path, contains('-4.2979,11.1771'));
      expect(request.url.queryParameters['geometries'], 'geojson');
      return http.Response(
        jsonEncode({
          'code': 'Ok',
          'routes': [
            {
              'distance': 356066.4,
              'duration': 15355.4,
              'geometry': {
                'coordinates': [
                  [-1.5197, 12.3714],
                  [-2.9286, 11.7458],
                  [-4.2979, 11.1771],
                ],
              },
            },
          ],
        }),
        200,
      );
    });

    final route = await fetchRoadRoute(
      'Ouagadougou',
      'Bobo-Dioulasso',
      'Boromo',
      client: client,
    );

    expect(route.waypoints.map((waypoint) => waypoint.name), [
      'Ouagadougou',
      'Boromo',
      'Bobo-Dioulasso',
    ]);
    expect(route.points, [
      const LatLng(12.3714, -1.5197),
      const LatLng(11.7458, -2.9286),
      const LatLng(11.1771, -4.2979),
    ]);
    expect(route.distanceLabel, '356 km');
    expect(route.durationLabel, '~4 h 16');
  });

  test('refuse une ville sans coordonnées configurées', () async {
    var requestCount = 0;
    final client = MockClient((request) async {
      requestCount++;
      return http.Response('{}', 200);
    });

    await expectLater(
      fetchRoadRoute('Ville inconnue', 'Bobo-Dioulasso', null, client: client),
      throwsA(isA<RoutePreviewException>()),
    );
    expect(requestCount, 0);
  });
}
