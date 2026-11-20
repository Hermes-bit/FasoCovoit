import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

typedef RouteLoader =
    Future<RouteLine> Function(
      String departure,
      String destination,
      String? stop,
    );

class RoutePreviewException implements Exception {
  const RoutePreviewException(this.message);

  final String message;

  @override
  String toString() => message;
}

class RouteWaypoint {
  const RouteWaypoint({required this.name, required this.location});

  final String name;
  final LatLng location;
}

class RouteLine {
  const RouteLine({
    required this.points,
    required this.waypoints,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  final List<LatLng> points;
  final List<RouteWaypoint> waypoints;
  final double distanceMeters;
  final double durationSeconds;

  String get distanceLabel => '${(distanceMeters / 1000).round()} km';

  String get durationLabel {
    final minutes = (durationSeconds / 60).round();
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return hours == 0
        ? '~$remainingMinutes min'
        : '~$hours h ${remainingMinutes.toString().padLeft(2, '0')}';
  }
}

const _knownCities = <String, RouteWaypoint>{
  'ouagadougou': RouteWaypoint(
    name: 'Ouagadougou',
    location: LatLng(12.3714, -1.5197),
  ),
  'bobo': RouteWaypoint(
    name: 'Bobo-Dioulasso',
    location: LatLng(11.1771, -4.2979),
  ),
  'boromo': RouteWaypoint(name: 'Boromo', location: LatLng(11.7458, -2.9286)),
  'koudougou': RouteWaypoint(
    name: 'Koudougou',
    location: LatLng(12.2526, -2.3627),
  ),
  'kaya': RouteWaypoint(name: 'Kaya', location: LatLng(13.0917, -1.0844)),
  'ouahigouya': RouteWaypoint(
    name: 'Ouahigouya',
    location: LatLng(13.5828, -2.421),
  ),
  'banfora': RouteWaypoint(name: 'Banfora', location: LatLng(10.6333, -4.7589)),
  'dedougou': RouteWaypoint(
    name: 'Dédougou',
    location: LatLng(12.4634, -3.4608),
  ),
  'fada': RouteWaypoint(
    name: "Fada N'Gourma",
    location: LatLng(12.0616, 0.3584),
  ),
  'tenkodogo': RouteWaypoint(
    name: 'Tenkodogo',
    location: LatLng(11.7800, -0.3698),
  ),
  'koupela': RouteWaypoint(name: 'Koupéla', location: LatLng(12.1786, -0.3496)),
  'dori': RouteWaypoint(name: 'Dori', location: LatLng(14.035, -0.0345)),
  'ziniare': RouteWaypoint(name: 'Ziniaré', location: LatLng(12.5833, -1.2974)),
  'hounde': RouteWaypoint(name: 'Houndé', location: LatLng(11.5, -3.5192)),
};

String _cityKey(String value) {
  const replacements = {
    'à': 'a',
    'â': 'a',
    'ä': 'a',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'î': 'i',
    'ï': 'i',
    'ô': 'o',
    'ö': 'o',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'ç': 'c',
  };
  var key = value.trim().toLowerCase().replaceAll('’', "'");
  replacements.forEach((accent, letter) {
    key = key.replaceAll(accent, letter);
  });
  return key.replaceAll(RegExp(r'[^a-z0-9]'), '');
}

RouteWaypoint _resolveCity(String city) {
  final key = _cityKey(city);
  final canonicalKey = switch (key) {
    'ouaga' => 'ouagadougou',
    'bobodioulasso' => 'bobo',
    'fadangourma' => 'fada',
    _ => key,
  };
  final waypoint = _knownCities[canonicalKey];
  if (waypoint == null) {
    throw RoutePreviewException(
      'Aperçu indisponible : la ville « $city » n’est pas encore référencée.',
    );
  }
  return waypoint;
}

Future<RouteLine> fetchRoadRoute(
  String departure,
  String destination,
  String? stop, {
  http.Client? client,
}) async {
  final waypoints = <RouteWaypoint>[
    _resolveCity(departure),
    if (stop != null && stop.trim().isNotEmpty) _resolveCity(stop),
    _resolveCity(destination),
  ];
  final coordinates = waypoints
      .map((waypoint) {
        final location = waypoint.location;
        return '${location.longitude},${location.latitude}';
      })
      .join(';');
  final uri = Uri.https(
    'router.project-osrm.org',
    '/route/v1/driving/$coordinates',
    {'overview': 'full', 'geometries': 'geojson', 'steps': 'false'},
  );

  late final http.Response response;
  try {
    response = await (client == null ? http.get(uri) : client.get(uri)).timeout(
      const Duration(seconds: 15),
    );
  } on TimeoutException {
    throw const RoutePreviewException(
      'Le calcul de l’itinéraire a expiré. Réessayez avec une connexion stable.',
    );
  } on http.ClientException {
    throw const RoutePreviewException(
      'Le service cartographique est momentanément inaccessible.',
    );
  }
  if (response.statusCode != 200) {
    throw RoutePreviewException(
      'Le service cartographique a répondu (${response.statusCode}). Réessayez.',
    );
  }

  final decoded = jsonDecode(response.body);
  if (decoded is! Map<String, dynamic> || decoded['routes'] is! List) {
    throw const RoutePreviewException(
      'Le service n’a pas fourni un itinéraire exploitable.',
    );
  }
  final routes = decoded['routes'] as List;
  if (routes.isEmpty || routes.first is! Map<String, dynamic>) {
    throw const RoutePreviewException(
      'Aucun itinéraire routier n’a été trouvé pour ce trajet.',
    );
  }
  final route = routes.first as Map<String, dynamic>;
  final geometry = route['geometry'];
  final coordinatesData = geometry is Map<String, dynamic>
      ? geometry['coordinates']
      : null;
  final distance = route['distance'];
  final duration = route['duration'];
  if (coordinatesData is! List || distance is! num || duration is! num) {
    throw const RoutePreviewException(
      'Le service a renvoyé un itinéraire incomplet.',
    );
  }
  final points = <LatLng>[];
  for (final coordinate in coordinatesData) {
    if (coordinate is! List ||
        coordinate.length < 2 ||
        coordinate[0] is! num ||
        coordinate[1] is! num) {
      throw const RoutePreviewException(
        'La géométrie de l’itinéraire est illisible.',
      );
    }
    points.add(
      LatLng(
        (coordinate[1] as num).toDouble(),
        (coordinate[0] as num).toDouble(),
      ),
    );
  }
  if (points.length < 2) {
    throw const RoutePreviewException(
      'La géométrie de l’itinéraire est trop courte pour être affichée.',
    );
  }
  return RouteLine(
    points: points,
    waypoints: waypoints,
    distanceMeters: distance.toDouble(),
    durationSeconds: duration.toDouble(),
  );
}

class RouteMapPreview extends StatelessWidget {
  const RouteMapPreview({super.key, required this.route});

  final RouteLine route;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 260,
          child: FlutterMap(
            options: MapOptions(
              initialCameraFit: CameraFit.bounds(
                bounds: LatLngBounds.fromPoints(route.points),
                padding: const EdgeInsets.all(36),
              ),
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.fasocovoit.app',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: route.points,
                    color: Theme.of(context).colorScheme.primary,
                    strokeWidth: 5,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  for (var index = 0; index < route.waypoints.length; index++)
                    Marker(
                      point: route.waypoints[index].location,
                      width: 132,
                      height: 52,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            index == 0 || index == route.waypoints.length - 1
                                ? Icons.location_on
                                : Icons.trip_origin,
                            color: index == 0
                                ? Colors.green.shade800
                                : index == route.waypoints.length - 1
                                ? Colors.red.shade700
                                : Colors.orange.shade800,
                            size: 28,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              route.waypoints[index].name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('© OpenStreetMap contributors'),
                ],
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 10),
      Wrap(
        spacing: 16,
        runSpacing: 4,
        children: [
          Text('Distance estimée : ${route.distanceLabel}'),
          Text('Durée routière estimée : ${route.durationLabel}'),
        ],
      ),
      const SizedBox(height: 6),
      const Text(
        'Itinéraire indicatif entre les villes. Le point exact de rendez-vous reste celui indiqué dans l’annonce.',
        style: TextStyle(fontSize: 12, color: Colors.black54),
      ),
    ],
  );
}
