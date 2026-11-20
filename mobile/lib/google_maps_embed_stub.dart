import 'package:flutter/material.dart';

Widget buildGoogleMapsEmbed(Uri uri) => const Card(
  child: ListTile(
    leading: Icon(Icons.map_outlined),
    title: Text('Carte intégrée disponible sur le Web'),
    subtitle: Text(
      'Google Maps Embed n’est pas utilisé dans la version Flutter native.',
    ),
  ),
);
