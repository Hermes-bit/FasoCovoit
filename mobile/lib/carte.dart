import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import 'carte_stub.dart' if (dart.library.js_interop) 'carte_web.dart' as plateforme;
import 'model.dart';
import 'painters.dart';

/// Clé Google Maps, fournie à la compilation (`--dart-define`), jamais dans le
/// dépôt. Sur le Web, elle doit autoriser Maps JavaScript API, Places API (New)
/// et Routes API.
const cleGoogleMaps = String.fromEnvironment('GOOGLE_MAPS_EMBED_API_KEY');

/// Vrai quand la carte et la recherche Google peuvent servir : sur le Web,
/// avec une clé et le script `web/carte.js` chargé.
bool get googleMapsDisponible => cleGoogleMaps.trim().isNotEmpty && plateforme.pret;

/// Carte d'un trajet : Google Maps au style clair et coloré (proche de Plans)
/// quand c'est possible, sinon carte dessinée dans le même style.
class CarteRoute extends StatefulWidget {
  const CarteRoute({
    super.key,
    required this.depart,
    required this.arrivee,
    this.progression,
    this.interactive = true,
    this.margeHaut = 48,
    this.margeBas = 48,
  });
  final Lieu depart;
  final Lieu arrivee;

  /// Part du trajet effectuée (0 à 1) : position de la voiture. Null : aucune.
  final double? progression;

  /// Carte plein écran (déplacement libre) ou aperçu dans une page.
  final bool interactive;

  /// Place laissée en haut et en bas pour les bandeaux posés sur la carte.
  final double margeHaut;
  final double margeBas;

  @override
  State<CarteRoute> createState() => _CarteRouteState();
}

class _CarteRouteState extends State<CarteRoute> {
  bool _erreur = false;

  @override
  Widget build(BuildContext context) {
    final inter = widget.depart.ville != widget.arrivee.ville;
    final dessin = Semantics(
      image: true,
      label: 'Carte : de ${widget.depart.complet} à ${widget.arrivee.complet}',
      child: CustomPaint(
        size: Size.infinite,
        painter: CarteTrajetPainter(
          villeDepart: inter ? widget.depart.ville : widget.depart.quartier,
          villeArrivee: inter ? widget.arrivee.ville : widget.arrivee.quartier,
          etape: inter && widget.arrivee.ville == 'Koudougou' ? 'Sabou' : '',
          progression: widget.progression ?? 0,
          voiture: widget.progression != null,
        ),
      ),
    );
    if (!googleMapsDisponible || _erreur) return dessin;
    final (la, lo) = widget.depart.position;
    final (lb, lob) = widget.arrivee.position;
    final options = jsonEncode({
      'depart': {'lat': la, 'lng': lo},
      'arrivee': {'lat': lb, 'lng': lob},
      'progression': widget.progression,
      'interactif': widget.interactive,
      'marges': {'haut': widget.margeHaut, 'bas': widget.margeBas},
    });
    return Semantics(
      label: 'Carte Google Maps : de ${widget.depart.complet} à ${widget.arrivee.complet}',
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Le dessin reste dessous pendant le chargement.
          dessin,
          KeyedSubtree(
            key: ValueKey(options),
            child: plateforme.vueCarte(
              cle: cleGoogleMaps,
              options: options,
              // Clé refusée ou réseau absent : on garde la carte dessinée.
              surErreur: () => scheduleMicrotask(() {
                if (mounted) setState(() => _erreur = true);
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recherche d'adresses dans la base de Google Maps
// ---------------------------------------------------------------------------

class SuggestionAdresse {
  const SuggestionAdresse(this.id, this.principal, this.secondaire);
  final String id;
  final String principal;
  final String secondaire;
}

/// Adresses Google Maps au Burkina Faso qui correspondent à [texte].
/// Null si la recherche Google n'est pas disponible.
Future<List<SuggestionAdresse>?> suggestionsAdresses(String texte) async {
  if (!googleMapsDisponible) return null;
  try {
    final brut = jsonDecode(await plateforme.suggestions(cleGoogleMaps, texte)) as List<dynamic>;
    return [
      for (final m in brut.cast<Map<String, dynamic>>())
        SuggestionAdresse(m['id'] as String, m['principal'] as String? ?? '', m['secondaire'] as String? ?? ''),
    ];
  } catch (_) {
    return null;
  }
}

/// Le lieu choisi, avec ses vraies coordonnées. Null en cas d'échec.
Future<Lieu?> lieuAdresse(String id) async {
  if (!googleMapsDisponible) return null;
  try {
    return lieuGoogle(jsonDecode(await plateforme.details(cleGoogleMaps, id)) as Map<String, dynamic>);
  } catch (_) {
    return null;
  }
}

/// Lieu de l'application à partir des détails d'une adresse Google Maps.
Lieu? lieuGoogle(Map<String, dynamic> d) {
  final lat = (d['lat'] as num?)?.toDouble();
  final lng = (d['lng'] as num?)?.toDouble();
  if (lat == null || lng == null) return null;
  final nom = (d['nom'] as String? ?? '').trim();
  final adresse = (d['adresse'] as String? ?? '').trim();
  final quartier = (d['quartier'] as String? ?? '').trim();
  final titre = nom.isNotEmpty ? nom : (quartier.isNotEmpty ? quartier : adresse.split(',').first.trim());
  if (titre.isEmpty) return null;
  return Lieu(
    villeDepuis((d['ville'] as String? ?? '').trim(), lat, lng),
    titre,
    lat: lat,
    lng: lng,
    rdv: adresse.isEmpty ? null : adresse,
  );
}

/// Ville de l'application : une ville desservie si l'adresse est à moins de
/// 25 km de son centre (Saaba compte pour Ouagadougou), sinon le nom donné
/// par Google.
String villeDepuis(String google, double lat, double lng) {
  final ici = Lieu('', '', lat: lat, lng: lng);
  String? proche;
  var min = double.infinity;
  for (final e in centresVilles.entries) {
    final d = distanceKm(ici, Lieu(e.key, '', lat: e.value.$1, lng: e.value.$2));
    if (d < min) {
      min = d;
      proche = e.key;
    }
  }
  if (proche != null && min <= 25) return proche;
  return google.isEmpty ? 'Burkina Faso' : google;
}
