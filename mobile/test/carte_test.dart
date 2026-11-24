import 'package:fasocovoit/carte.dart';
import 'package:fasocovoit/model.dart';
import 'package:fasocovoit/painters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('hors Web, pas de Google Maps : la carte dessinée prend le relais', () {
    expect(googleMapsDisponible, isFalse);
  });

  test('une adresse Google Maps devient un lieu avec sa vraie position', () {
    final l = lieuGoogle({
      'lat': 12.3781,
      'lng': -1.4822,
      'nom': 'Pharmacie de Dassasgho',
      'adresse': 'Rue 29.12, Ouagadougou, Burkina Faso',
      'ville': 'Ouagadougou',
      'quartier': 'Dassasgho',
    })!;
    expect(l.ville, 'Ouagadougou');
    expect(l.quartier, 'Pharmacie de Dassasgho');
    expect(l.position, (12.3781, -1.4822));
    expect(l.rdv, 'Rue 29.12, Ouagadougou, Burkina Faso');
    expect(lieuGoogle({'nom': 'Sans position'}), isNull);
  });

  test('ville : une commune voisine compte pour la ville desservie', () {
    // Saaba, à une quinzaine de km du centre de Ouaga.
    expect(villeDepuis('Saaba', 12.3800, -1.4200), 'Ouagadougou');
    expect(villeDepuis('Koudougou', 12.2530, -2.3620), 'Koudougou');
    // Kaya, loin des villes desservies : on garde le nom de Google.
    expect(villeDepuis('Kaya', 13.0917, -1.0844), 'Kaya');
    expect(villeDepuis('', 13.0917, -1.0844), 'Burkina Faso');
  });

  testWidgets('la carte du trajet se dessine au style clair', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 390, height: 500, child: CarteRoute(depart: lOuagaGare, arrivee: lKoudCentre, progression: .4)),
        ),
      ),
    );
    final peint = tester.widgetList<CustomPaint>(find.byType(CustomPaint)).map((c) => c.painter).whereType<CarteTrajetPainter>();
    expect(peint, hasLength(1));
    expect(peint.single.villeArrivee, 'Koudougou');
    expect(peint.single.voiture, isTrue);
  });
}
