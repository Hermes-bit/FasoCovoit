import 'package:flutter/material.dart';

import '../formats.dart';
import '../painters.dart';
import '../theme.dart';
import '../ui.dart';

const _v2 = Pastille('Bientôt · version 2', fond: C.etoile, texte: C.encre);

void _bientot(BuildContext context) =>
    message(context, 'Le transport de colis arrive en version 2.');

// ---------------------------------------------------------------------------
// 55 · Envoyer un colis
// ---------------------------------------------------------------------------

class ColisEnvoyerEcran extends StatefulWidget {
  const ColisEnvoyerEcran({super.key});

  @override
  State<ColisEnvoyerEcran> createState() => _ColisEnvoyerEcranState();
}

class _ColisEnvoyerEcranState extends State<ColisEnvoyerEcran> {
  static const _tailles = [
    ('S', 'Enveloppe, documents', 1000),
    ('M', 'Sac, 10 kg max', 2000),
    ('L', 'Carton, 25 kg max', 3500),
  ];
  int _taille = 0;
  bool _inter = true;
  final _contenu = TextEditingController(text: 'Documents');
  final _valeur = TextEditingController(text: '20 000 F');
  final _nom = TextEditingController(text: 'Paul Yaméogo');
  final _tel = TextEditingController(text: '+226 76 •• •• 18');

  @override
  void dispose() {
    for (final c in [_contenu, _valeur, _nom, _tel]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Ecran(
    children: [
      const Piste(
        retour: true,
        trailing: _v2,
        paddingBas: 30,
        children: [
          Titre('Envoyer un colis'),
          Text('Confié à un conducteur vérifié qui fait déjà le trajet', style: T.petit),
        ],
      ),
      Zone(
        gap: 12,
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
        children: [
          Onglets(
            labels: const ['En ville', 'Vers une autre ville'],
            index: _inter ? 1 : 0,
            onChanged: (i) => setState(() => _inter = i == 1),
          ),
          Carte(
            child: RouteRail(
              haut: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ouagadougou · Gounghin', style: T.gras),
                  const Doux('Vous le remettez au conducteur'),
                ],
              ),
              bas: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_inter ? 'Koudougou · Secteur 7' : 'Ouagadougou · Ouaga 2000', style: T.gras),
                  const Doux('Le destinataire le récupère'),
                ],
              ),
            ),
          ),
          const Etiq('Taille'),
          Row(
            children: [
              for (var i = 0; i < _tailles.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: Choix(
                    on: _taille == i,
                    anneau: false,
                    vertical: true,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                    onTap: () => setState(() => _taille = i),
                    children: [
                      Text(_tailles[i].$1, style: T.gras),
                      Doux(_tailles[i].$2, align: TextAlign.center),
                    ],
                  ),
                ),
              ],
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [const Etiq('Contenu'), const SizedBox(height: 8), Champ(controller: _contenu, label: 'Contenu')],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Etiq('Valeur déclarée'),
                    const SizedBox(height: 8),
                    Champ(controller: _valeur, label: 'Valeur déclarée'),
                  ],
                ),
              ),
            ],
          ),
          Carte(
            pointillee: true,
            bord: C.laterite,
            onTap: () => _bientot(context),
            child: const Row(
              children: [
                Icon(Icons.photo_camera_outlined, size: 22),
                SizedBox(width: 12),
                Bloc('Photo du colis ouvert, puis fermé', 'Obligatoire, le conducteur la verra'),
              ],
            ),
          ),
          Carte(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Destinataire', style: T.gras),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: Champ(controller: _nom, hauteur: 48, label: 'Nom du destinataire')),
                    const SizedBox(width: 8),
                    Expanded(child: Champ(controller: _tel, hauteur: 48, label: 'Téléphone du destinataire')),
                  ],
                ),
                const SizedBox(height: 8),
                const Doux('Il recevra un code par SMS, à donner au conducteur.'),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Lien(
              'Objets interdits : argent liquide, armes, produits dangereux…',
              onTap: () => informer(
                context,
                'Objets interdits',
                'Argent liquide, armes, produits dangereux ou inflammables, médicaments sans ordonnance, '
                    'animaux vivants, denrées périssables non emballées.',
              ),
            ),
          ),
        ],
      ),
      Pied(
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Titre(fcfa(_tailles[_taille].$3)),
                const Doux("Prix d'exemple"),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Btn('Trouver un conducteur', onPressed: () => ouvrir(context, const ColisSuiviEcran())),
            ),
          ],
        ),
      ),
    ],
  );
}

// ---------------------------------------------------------------------------
// 56 · Suivi du colis
// ---------------------------------------------------------------------------

class ColisSuiviEcran extends StatelessWidget {
  const ColisSuiviEcran({super.key});

  @override
  Widget build(BuildContext context) => Ecran(
    children: [
      const Barre(
        titre: 'Colis CL-4KM7-PQ2',
        sousTitre: 'Documents · Ouaga → Koudougou',
        actions: [_v2],
      ),
      Zone(
        gap: 14,
        children: [
          const Carte(
            child: Column(
              children: [
                Etape(EtatEtape.fait, 'Colis créé et payé', 'Exemple · 1 000 F'),
                Etape(EtatEtape.fait, 'Remis au conducteur', 'QR scanné par le conducteur · photo vérifiée'),
                Etape(EtatEtape.encours, 'En route', 'Arrivée prévue vers 8 h 30 · suivi en direct', icone: Icons.directions_car_outlined),
                Etape(EtatEtape.afaire, 'Livré au destinataire', 'Quand il donne son code au conducteur'),
              ],
            ),
          ),
          const Carte(
            child: Column(
              children: [
                Doux('QR À MONTRER À LA REMISE', taille: 14, gras: true),
                SizedBox(height: 8),
                Qr(graine: 'CL-4KM7-PQ2', taille: 140, label: 'QR du colis'),
                SizedBox(height: 8),
                Doux('Déjà scanné à la remise'),
              ],
            ),
          ),
          const Bandeau(
            "Le conducteur ne touche le paiement qu'à la livraison. Colis perdu ou abîmé : remboursement "
            "jusqu'à la valeur déclarée, dans la limite d'un plafond à fixer.",
          ),
          Row(
            children: [
              Expanded(
                child: BtnClair('Écrire au conducteur', icon: Icons.chat_bubble_outline_rounded, onPressed: () => _bientot(context)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: BtnClair('Partager le suivi', icon: Icons.share_outlined, onPressed: () => _bientot(context)),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

// ---------------------------------------------------------------------------
// 57 · Colis côté conducteur
// ---------------------------------------------------------------------------

class ColisConducteurEcran extends StatefulWidget {
  const ColisConducteurEcran({super.key});

  @override
  State<ColisConducteurEcran> createState() => _ColisConducteurEcranState();
}

class _ColisConducteurEcranState extends State<ColisConducteurEcran> {
  bool? _accepte;

  @override
  Widget build(BuildContext context) {
    return Ecran(
      children: [
        const Piste(
          couleur: C.encre,
          retour: true,
          trailing: _v2,
          paddingBas: 30,
          children: [
            Text(
              'Exemple : votre trajet Ouaga → Koudougou',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: C.etoile),
            ),
            Titre('2 colis proposés'),
          ],
        ),
        Zone(
          gap: 12,
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
          children: [
            Carte.sel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Row(
                    children: [
                      Expanded(child: Text('Documents · taille S', style: T.gras)),
                      Text('+ 1 000 F', style: TextStyle(fontWeight: FontWeight.w700, color: C.vertF)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(color: C.sable2, borderRadius: BorderRadius.circular(14)),
                        child: const Icon(Icons.description_outlined, size: 28, color: C.doux),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Remise : Gounghin, 6 h 45', style: T.petit),
                            Text('Livraison : Koudougou, Secteur 7', style: T.petit),
                            Doux('Photo du contenu : enveloppe kraft, 3 dossiers'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_accepte == null)
                    Row(
                      children: [
                        Expanded(child: BtnClair('Refuser', hauteur: 48, onPressed: () => setState(() => _accepte = false))),
                        const SizedBox(width: 8),
                        Expanded(child: Btn('Accepter', hauteur: 48, onPressed: () => setState(() => _accepte = true))),
                      ],
                    )
                  else
                    Pastille(
                      _accepte! ? 'Accepté (aperçu)' : 'Refusé (aperçu)',
                      ton: _accepte! ? TonPastille.vert : TonPastille.neutre,
                    ),
                ],
              ),
            ),
            const Carte(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text('Sac · taille M · 6 kg', style: T.gras)),
                      Text('+ 2 000 F', style: T.gras),
                    ],
                  ),
                  SizedBox(height: 4),
                  Doux('Vêtements · valeur déclarée 30 000 F', taille: 14),
                ],
              ),
            ),
            const Doux('Au moment de la remise et de la livraison', taille: 14, gras: true),
            Row(
              children: [
                Expanded(
                  child: Btn.lat('Scanner à la remise', icon: Icons.photo_camera_outlined, hauteur: 56, taille: 15, onPressed: () => _bientot(context)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Btn('Code du destinataire', icon: Icons.check_rounded, hauteur: 56, taille: 15, onPressed: () => _bientot(context)),
                ),
              ],
            ),
            const Doux(
              "Vérifiez le contenu avant d'accepter : vous pouvez refuser un colis. Ne transportez jamais un colis fermé que vous n'avez pas vu.",
            ),
          ],
        ),
      ],
    );
  }
}
