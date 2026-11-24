import 'package:flutter/widgets.dart';

/// Hors Web : pas de Google Maps, la carte dessinée s'affiche.
bool get pret => false;

Widget vueCarte({required String cle, required String options, required void Function() surErreur}) =>
    const SizedBox.shrink();

Future<String> suggestions(String cle, String texte) =>
    Future.error(UnsupportedError('Recherche Google réservée au Web'));

Future<String> details(String cle, String id) => Future.error(UnsupportedError('Recherche Google réservée au Web'));
