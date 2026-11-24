import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../formats.dart';
import '../model.dart';
import '../painters.dart';
import '../theme.dart';
import '../ui.dart';

/// Une ligne d'opération du portefeuille (passager ou conducteur).
class LigneOperation extends StatelessWidget {
  const LigneOperation(this.op, {super.key, this.onTap});
  final Operation op;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final attente = op.statut == StatutOp.enAttente;
    final (icone, fond, couleur) = switch (op.type) {
      TypeOp.depot when attente => (Icons.add_rounded, C.etoileC, C.etoileF),
      TypeOp.depot => (Icons.add_rounded, C.vertC, C.vertF),
      TypeOp.trajet when op.montant > 0 => (Icons.confirmation_number_outlined, C.vertC, C.vertF),
      TypeOp.trajet => (Icons.confirmation_number_outlined, C.lateriteC, C.lateriteF),
      TypeOp.remboursement => (Icons.sync_rounded, C.vertC, C.vertF),
      TypeOp.bonus => (Icons.star_outline_rounded, C.etoileC, C.etoileF),
      TypeOp.retrait => (Icons.account_balance_wallet_outlined, C.sable2, C.encre),
    };
    final couleurMontant = attente
        ? C.doux
        : op.type == TypeOp.bonus
        ? C.etoileF
        : (op.montant > 0 ? C.vertF : C.encre);
    return LigneListe(
      onTap: onTap,
      children: [
        IconeCarre(icone, fond: fond, couleur: couleur),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(op.titre, style: T.gras),
              Doux(op.detail),
              if (attente || op.statut == StatutOp.reclamation) ...[
                const SizedBox(height: 4),
                Pastille(
                  attente ? 'En confirmation' : 'Réclamation ouverte',
                  ton: TonPastille.etoile,
                  icon: Icons.schedule_rounded,
                ),
              ],
            ],
          ),
        ),
        Text(
          fcfaSigne(op.montant),
          style: TextStyle(fontWeight: FontWeight.w700, color: couleurMontant),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 43 · Mon portefeuille
// ---------------------------------------------------------------------------

class PortefeuilleEcran extends StatelessWidget {
  const PortefeuilleEcran({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    Widget sousSolde(String label, int montant, String note, {Color? couleur}) => Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: C.encre2, borderRadius: BorderRadius.circular(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, color: C.beige)),
            Text(fcfa(montant), style: TextStyle(fontWeight: FontWeight.w700, color: couleur)),
            Text(note, style: const TextStyle(fontSize: 13, color: C.beige2)),
          ],
        ),
      ),
    );
    return Ecran(
      children: [
        Barre(
          titre: 'Mon portefeuille',
          actions: [
            IconeBtn(
              icon: Icons.format_list_bulleted_rounded,
              label: 'Historique',
              onTap: () => ouvrir(context, const HistoriqueEcran()),
            ),
          ],
        ),
        Zone(
          gap: 14,
          children: [
            Carte.sombre(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Solde disponible', style: TextStyle(fontSize: 14, color: C.beige)),
                  Text(fcfa(s.solde), style: T.titre(44, color: C.etoile)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      sousSolde('Argent déposé', s.depose, 'Retirable'),
                      const SizedBox(width: 10),
                      sousSolde(
                        'Bonus',
                        s.bonus,
                        s.bonus > 0 ? 'Expire le ${dateCourte(s.bonusExpire)}' : 'Aucun bonus en cours',
                        couleur: C.etoile,
                      ),
                    ],
                  ),
                  if (s.bloque > 0) ...[
                    const SizedBox(height: 10),
                    Text(
                      '+ ${fcfa(s.bloque)} bloqués pour vos trajets à venir',
                      style: const TextStyle(fontSize: 13, color: C.beige),
                    ),
                  ],
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Btn('Déposer', icon: Icons.add_rounded, hauteur: 54, onPressed: () => ouvrir(context, const DeposerEcran())),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: BtnClair(
                    'Retirer',
                    icon: Icons.account_balance_wallet_outlined,
                    hauteur: 54,
                    onPressed: () => ouvrir(context, const RetirerEcran()),
                  ),
                ),
              ],
            ),
            const Bandeau(
              '',
              riche: TextSpan(
                children: [
                  TextSpan(text: "Payez vos trajets en un geste. En cas d'annulation, le remboursement arrive ici "),
                  TextSpan(text: 'tout de suite', style: T.gras),
                  TextSpan(text: '.'),
                ],
              ),
            ),
            Carte(
              bord: C.etoile,
              epaisseur: 2.5,
              onTap: () => ouvrir(context, const ParrainageEcran()),
              child: const Row(
                children: [
                  Etoile(size: 30),
                  SizedBox(width: 12),
                  Bloc('Invitez vos amis : 500 F chacun', 'Après leur premier trajet terminé'),
                  Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
            Row(
              children: [
                const Expanded(child: Doux('Dernières opérations', taille: 14, gras: true)),
                Lien('Tout voir', onTap: () => ouvrir(context, const HistoriqueEcran())),
              ],
            ),
            ListeCarte(children: [for (final op in s.operations.take(3)) LigneOperation(op)]),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 44 · Déposer (Orange / Moov)
// ---------------------------------------------------------------------------

class DeposerEcran extends StatefulWidget {
  const DeposerEcran({super.key});

  @override
  State<DeposerEcran> createState() => _DeposerEcranState();
}

class _DeposerEcranState extends State<DeposerEcran> {
  static const _montants = [1000, 2000, 5000, 10000];
  int _montant = 5000;
  Paiement _op = Paiement.orange;

  Future<void> _deposer(AppState s) async {
    final ok = await confirmer(
      context,
      titre: 'Confirmez sur votre téléphone',
      texte: 'Une demande de validation de ${fcfa(_montant)} arrive sur le ${s.telephone}. '
          'Confirmez avec votre code secret ${_op.label}.\n\nPrototype : le dépôt est simulé.',
      oui: "J'ai confirmé",
      non: 'Annuler',
    );
    if (!ok || !mounted) return;
    if (essayer(context, () => s.deposer(_montant, _op))) {
      remplacer(context, const HistoriqueEcran());
      message(context, '${fcfa(_montant)} ajoutés à votre portefeuille.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    Widget montant(int m) => Expanded(
      child: Choix(
        on: _montant == m,
        anneau: false,
        padding: const EdgeInsets.all(16),
        onTap: () => setState(() => _montant = m),
        children: [
          Expanded(
            child: Text(
              fcfa(m),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
    return Ecran(
      children: [
        Barre(titre: "Déposer de l'argent", sousTitre: 'Solde actuel : ${fcfa(s.solde)}'),
        Zone(
          gap: 14,
          children: [
            const Etiq('Montant'),
            Row(children: [montant(_montants[0]), const SizedBox(width: 10), montant(_montants[1])]),
            Row(children: [montant(_montants[2]), const SizedBox(width: 10), montant(_montants[3])]),
            const Etiq('Depuis'),
            for (final p in [Paiement.orange, Paiement.moov])
              Choix(
                on: _op == p,
                onTap: () => setState(() => _op = p),
                children: [LogoPaiement(p), Bloc(p.label, s.telephone)],
              ),
            Carte(
              child: Column(
                children: [
                  Row(
                    children: [
                      const Expanded(child: Text('Vous recevez sur le portefeuille', style: TextStyle(color: C.doux))),
                      Text(fcfa(_montant), style: T.gras),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Expanded(child: Text('Frais de dépôt', style: TextStyle(color: C.doux))),
                      Text('À confirmer', style: TextStyle(fontWeight: FontWeight.w700, color: C.doux)),
                    ],
                  ),
                ],
              ),
            ),
            Doux(
              'Une demande de validation arrive sur votre téléphone : confirmez avec votre code secret ${_op.label}. '
              'FasoCovoit ne vous demandera jamais ce code. Solde maximum : ${fcfa(AppState.soldeMax)}.',
            ),
          ],
        ),
        Pied(child: Btn('Déposer ${fcfa(_montant)}', onPressed: () => _deposer(s))),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 45 · Historique
// ---------------------------------------------------------------------------

class HistoriqueEcran extends StatefulWidget {
  const HistoriqueEcran({super.key});

  @override
  State<HistoriqueEcran> createState() => _HistoriqueEcranState();
}

class _HistoriqueEcranState extends State<HistoriqueEcran> {
  static const _filtres = ['Tout', 'Dépôts', 'Trajets', 'Bonus'];
  String _filtre = 'Tout';

  bool _garder(Operation o) => switch (_filtre) {
    'Dépôts' => o.type == TypeOp.depot || o.type == TypeOp.retrait,
    'Trajets' => o.type == TypeOp.trajet || o.type == TypeOp.remboursement,
    'Bonus' => o.type == TypeOp.bonus,
    _ => true,
  };

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final groupes = <String, List<Operation>>{};
    for (final o in s.operations.where(_garder)) {
      final cle = ecartJours(o.date, s.maintenant) == 0 ? "Aujourd'hui" : moisAnnee(o.date);
      groupes.putIfAbsent(cle, () => []).add(o);
    }
    final enAttente = s.operations.where((o) => o.type == TypeOp.depot && o.statut != StatutOp.confirme).toList();
    return Ecran(
      children: [
        Barre(titre: 'Historique', sousTitre: 'Solde : ${fcfa(s.solde)}'),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(
            children: espacer([
              for (final f in _filtres) Puce(f, on: _filtre == f, onTap: () => setState(() => _filtre = f)),
            ], 8),
          ),
        ),
        Zone(
          gap: 12,
          children: [
            if (groupes.isEmpty) const Carte(child: Text('Aucune opération.', style: T.petit)),
            for (final g in groupes.entries) ...[
              Doux(g.key, taille: 14, gras: true),
              ListeCarte(
                children: [
                  for (final o in g.value)
                    LigneOperation(
                      o,
                      onTap: o.type == TypeOp.depot && o.statut != StatutOp.confirme
                          ? () => ouvrir(context, ReclamationEcran(operation: o))
                          : null,
                    ),
                ],
              ),
            ],
            Carte(
              onTap: () => enAttente.isEmpty
                  ? informer(context, 'Tous vos dépôts sont crédités', 'Aucun dépôt n’est en attente de confirmation.')
                  : ouvrir(context, ReclamationEcran(operation: enAttente.first)),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 22),
                  SizedBox(width: 12),
                  Bloc("Un dépôt n'apparaît pas ?", "Nous vérifions avec l'opérateur et répondons sous 24 h"),
                  Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 46 · Parrainage et bonus
// ---------------------------------------------------------------------------

class ParrainageEcran extends StatelessWidget {
  const ParrainageEcran({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final p = s.parrainage;
    Widget etape(String n, String texte) => Row(
      children: [
        SizedBox(width: 24, child: Text(n, style: T.titre(20, color: C.laterite))),
        const SizedBox(width: 12),
        Expanded(child: Text(texte, style: T.petit)),
      ],
    );
    Widget stat(String valeur, String label, {Color? couleur}) => Expanded(
      child: Carte(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(valeur, style: T.titre(26, color: couleur)),
            const SizedBox(height: 4),
            Doux(label),
          ],
        ),
      ),
    );
    return Ecran(
      children: [
        Piste(
          couleur: C.encre,
          retour: true,
          children: [
            const Text('Parrainage', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: C.etoile)),
            Text('500 F pour vous, 500 F pour votre ami', style: T.titre(32, color: Colors.white)),
          ],
        ),
        Zone(
          gap: 14,
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
          children: [
            Carte(
              pointillee: true,
              bord: C.laterite,
              epaisseur: 2.5,
              child: Column(
                children: [
                  const Doux('Votre code', taille: 14),
                  const SizedBox(height: 4),
                  Text(s.codeParrainage, style: T.titre(36).copyWith(letterSpacing: 2.9)),
                  const SizedBox(height: 8),
                  Btn(
                    'Partager sur WhatsApp',
                    icon: Icons.share_outlined,
                    hauteur: 50,
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(
                          text: 'Inscris-toi sur FasoCovoit avec mon code ${s.codeParrainage} : '
                              'on reçoit chacun 500 F après ton premier trajet.',
                        ),
                      );
                      message(context, 'Message copié : collez-le dans WhatsApp.');
                    },
                  ),
                ],
              ),
            ),
            Carte(
              child: Column(
                children: espacer([
                  etape('1', "Votre ami s'inscrit avec votre code."),
                  etape('2', 'Il termine son premier trajet.'),
                  etape('3', 'Vous recevez chacun 500 F de bonus sur le portefeuille.'),
                ], 12),
              ),
            ),
            Row(
              children: [
                stat('${p.invites}', 'invités'),
                const SizedBox(width: 8),
                stat('${p.voyage}', 'ont voyagé'),
                const SizedBox(width: 8),
                stat(fcfa(p.gagne), 'gagnés', couleur: C.etoileF),
              ],
            ),
            const Doux(
              'Le bonus paie au plus la moitié d’une place, expire après 90 jours et ne se retire pas. 20 amis au maximum.',
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 47 · Retirer
// ---------------------------------------------------------------------------

class RetirerEcran extends StatefulWidget {
  const RetirerEcran({super.key});

  @override
  State<RetirerEcran> createState() => _RetirerEcranState();
}

class _RetirerEcranState extends State<RetirerEcran> {
  late final TextEditingController _montant;
  final _pin = TextEditingController();

  @override
  void initState() {
    super.initState();
    final depose = AppScope.read(context).depose;
    _montant = TextEditingController(text: milliers(depose >= 5000 ? 5000 : depose))
      ..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _montant.dispose();
    _pin.dispose();
    super.dispose();
  }

  int get _valeur => int.tryParse(_montant.text.replaceAll(RegExp(r'\D'), '')) ?? 0;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return Ecran(
      children: [
        Barre(
          titre: "Retirer de l'argent",
          sousTitre: 'Argent déposé : ${fcfa(s.depose)} · le bonus ne se retire pas',
        ),
        Zone(
          gap: 14,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Etiq('Montant'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Champ(
                        controller: _montant,
                        actif: true,
                        clavier: TextInputType.number,
                        label: 'Montant à retirer',
                        formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9  ]'))],
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('F', style: T.gras),
                  ],
                ),
                const SizedBox(height: 8),
                const Doux('Minimum 1 000 F'),
              ],
            ),
            const Etiq('Vers'),
            Choix(
              on: true,
              onTap: () {},
              children: [const LogoPaiement(Paiement.orange), Bloc('Orange Money', 'Votre numéro : ${s.telephone}')],
            ),
            const Doux('Uniquement vers le numéro de votre compte, pour votre sécurité.'),
            const Carte(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: Text('Frais de retrait', style: TextStyle(color: C.doux))),
                      Text('À confirmer', style: T.gras),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Text('Arrivée', style: TextStyle(color: C.doux)),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text('Sous 24 h, souvent en quelques minutes', textAlign: TextAlign.right, style: T.gras),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Etiq('Votre code FasoCovoit'),
                const SizedBox(height: 8),
                SizedBox(
                  width: 160,
                  child: Champ(
                    controller: _pin,
                    cache: true,
                    clavier: TextInputType.number,
                    label: 'Code FasoCovoit',
                    formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                    style: const TextStyle(fontSize: 22, letterSpacing: 8),
                  ),
                ),
                const SizedBox(height: 8),
                const Doux(
                  "Le code à 4 chiffres choisi à l'ouverture du portefeuille, pas votre code mobile money.",
                ),
              ],
            ),
          ],
          bas: [
            Btn(
              'Retirer ${fcfa(_valeur)}',
              onPressed: () {
                final m = _valeur;
                if (essayer(context, () => s.retirer(m, _pin.text))) {
                  Navigator.pop(context);
                  message(context, 'Retrait de ${fcfa(m)} en cours vers Orange Money.');
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 48 · Dépôt non reçu
// ---------------------------------------------------------------------------

class ReclamationEcran extends StatefulWidget {
  const ReclamationEcran({super.key, required this.operation});
  final Operation operation;

  @override
  State<ReclamationEcran> createState() => _ReclamationEcranState();
}

class _ReclamationEcranState extends State<ReclamationEcran> {
  final _detail = TextEditingController();

  @override
  void dispose() {
    _detail.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final op = widget.operation;
    final rec = s.reclamations.where((r) => r.operation == op).firstOrNull;
    final operateur = op.titre.replaceFirst('Dépôt ', '');
    final limite = (rec?.date ?? s.maintenant).add(const Duration(hours: 24));
    return Ecran(
      children: [
        const Barre(titre: "Un dépôt n'apparaît pas"),
        Zone(
          gap: 14,
          children: [
            Carte(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Doux('Opération concernée'),
                  Text('${op.titre} · ${fcfa(op.montant)}', style: T.gras),
                  Doux('${jourRelatif(op.date, s.maintenant)} ${heure(op.date)}${op.ref != null ? ' · réf. ${op.ref}' : ''}', taille: 14),
                ],
              ),
            ),
            Carte(
              child: Column(
                children: [
                  Etape(
                    rec == null ? EtatEtape.afaire : EtatEtape.fait,
                    rec == null ? 'Réclamation à envoyer' : 'Réclamation enregistrée',
                    rec == null ? 'Un numéro vous sera donné' : 'N° ${rec.numero}',
                  ),
                  Etape(
                    rec == null ? EtatEtape.afaire : EtatEtape.encours,
                    'Vérification auprès de $operateur',
                    'Automatique, toutes les 15 minutes',
                  ),
                  Etape(
                    EtatEtape.afaire,
                    "Réponse de l'équipe",
                    'Au plus tard ${jourRelatif(limite, s.maintenant).toLowerCase()} ${heure(limite)}',
                  ),
                ],
              ),
            ),
            Bandeau(
              "Si l'argent a quitté votre compte $operateur, il sera crédité ici. S'il n'a pas été prélevé, rien n'est perdu.",
            ),
            if (rec == null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Etiq('Un détail à ajouter ? (facultatif)'),
                  const SizedBox(height: 8),
                  Champ(controller: _detail, lignes: 3, hint: "J'ai bien reçu le SMS de l'opérateur.", label: 'Détail'),
                ],
              ),
          ],
          bas: [
            rec == null
                ? Btn(
                    'Envoyer',
                    onPressed: () {
                      final r = s.reclamer(op, _detail.text);
                      Navigator.pop(context);
                      message(context, 'Réclamation ${r.numero} enregistrée.');
                    },
                  )
                : BtnClair('Retour', onPressed: () => Navigator.pop(context)),
          ],
        ),
      ],
    );
  }
}
