import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'google_maps_embed_stub.dart'
    if (dart.library.html) 'google_maps_embed_web.dart'
    as platform;

const _googleMapsEmbedApiKey = String.fromEnvironment(
  'GOOGLE_MAPS_EMBED_API_KEY',
);

Uri googleMapsDirectionsUri({
  required String apiKey,
  required String departure,
  required String destination,
  String? stop,
}) => Uri.https('www.google.com', '/maps/embed/v1/directions', {
  'key': apiKey,
  'origin': departure,
  'destination': destination,
  'mode': 'driving',
  if (stop != null && stop.trim().isNotEmpty) 'waypoints': stop,
});

class GoogleMapsRouteEmbed extends StatelessWidget {
  const GoogleMapsRouteEmbed({
    super.key,
    required this.departure,
    required this.destination,
    this.stop,
    this.apiKey,
  });

  final String departure;
  final String destination;
  final String? stop;
  final String? apiKey;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.map_outlined),
          title: Text('Carte intégrée disponible sur le Web'),
          subtitle: Text(
            'Google Maps Embed n’est pas utilisé dans la version Flutter native.',
          ),
        ),
      );
    }

    final key = apiKey ?? _googleMapsEmbedApiKey;
    if (key.trim().isEmpty) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.map_outlined),
          title: Text('Carte Google Maps'),
          subtitle: Text(
            'Ajoutez une clé Maps Embed API pour afficher l’itinéraire sur le Web.',
          ),
        ),
      );
    }

    final uri = googleMapsDirectionsUri(
      apiKey: key,
      departure: departure,
      destination: destination,
      stop: stop,
    );
    return platform.buildGoogleMapsEmbed(uri);
  }
}
