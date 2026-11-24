import 'package:flutter/material.dart';

import '../formats.dart';
import '../model.dart';
import '../theme.dart';
import '../ui.dart';

/// Ligne « Départ / Destination » qui ouvre le choix du lieu.
class ChampLieu extends StatelessWidget {
  const ChampLieu({
    super.key,
    required this.label,
    required this.valeur,
    required this.indication,
    required this.onTap,
  });
  final String label;
  final Lieu? valeur;
  final String indication;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '$label : ${valeur?.complet ?? indication}',
    excludeSemantics: true,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Doux(label),
                  Text(
                    valeur?.complet ?? indication,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: valeur == null ? C.laterite : C.encre,
                    ),
                  ),
                ],
              ),
            ),
            Icon(valeur == null ? Icons.search_rounded : Icons.edit_outlined, size: 20, color: C.doux),
          ],
        ),
      ),
    ),
  );
}

/// Ouvre le choix d'un lieu et renvoie le lieu choisi (ou null).
Future<Lieu?> choisirLieu(BuildContext context, {required String titre, Lieu? actuel, Lieu? exclu}) =>
    ouvrir<Lieu>(context, ChoisirLieuEcran(titre: titre, actuel: actuel, exclu: exclu));

class ChoisirLieuEcran extends StatefulWidget {
  const ChoisirLieuEcran({super.key, required this.titre, this.actuel, this.exclu});
  final String titre;
  final Lieu? actuel;

  /// Lieu déjà choisi de l'autre côté (on ne peut pas aller au même endroit).
  final Lieu? exclu;

  @override
  State<ChoisirLieuEcran> createState() => _ChoisirLieuEcranState();
}

class _ChoisirLieuEcranState extends State<ChoisirLieuEcran> {
  final _recherche = TextEditingController();

  @override
  void initState() {
    super.initState();
    _recherche.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _recherche.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = normaliser(_recherche.text);
    final trouves = lieux
        .where((l) => l != widget.exclu)
        .where((l) => q.isEmpty || normaliser('${l.quartier} ${l.ville} ${l.rdv ?? ''}').contains(q))
        .toList();
    final saisie = _recherche.text.trim();
    final exact = trouves.any((l) => normaliser(l.quartier) == q);
    return Ecran(
      children: [
        Barre(titre: widget.titre),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Champ(
            controller: _recherche,
            autofocus: true,
            actif: true,
            hint: 'Adresse, quartier ou lieu connu',
            label: 'Rechercher un lieu',
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            children: [
              for (final ville in centresVilles.keys)
                if (trouves.any((l) => l.ville == ville)) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Doux(ville, taille: 14, gras: true),
                  ),
                  ListeCarte(
                    children: [
                      for (final l in trouves.where((l) => l.ville == ville))
                        LigneListe(
                          onTap: () => Navigator.pop(context, l),
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 22,
                              color: l == widget.actuel ? C.vert : C.laterite,
                            ),
                            Bloc(capitaliser(l.quartier), l.rdv),
                            if (l == widget.actuel) const Icon(Icons.check_rounded, color: C.vert),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
              if (saisie.length >= 2 && !exact) ...[
                Doux(
                  trouves.isEmpty ? 'Lieu absent de la liste : choisissez sa ville' : 'Autre lieu : choisissez sa ville',
                  taille: 14,
                  gras: true,
                ),
                const SizedBox(height: 8),
                ListeCarte(
                  children: [
                    for (final ville in centresVilles.keys)
                      LigneListe(
                        onTap: () => Navigator.pop(context, Lieu(ville, saisie)),
                        children: [
                          const Icon(Icons.add_location_alt_outlined, size: 22),
                          Bloc('« $saisie »', ville),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                const Doux(
                  'Pour un lieu hors liste, la distance est estimée depuis le centre de la ville.',
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
