import 'package:flutter/material.dart';

import '../formats.dart';
import '../model.dart';
import '../painters.dart';
import '../photo.dart';
import '../theme.dart';
import '../ui.dart';
import 'conducteur.dart';
import 'messages_profil.dart';

// ---------------------------------------------------------------------------
// 36 · Pas encore conducteur
// ---------------------------------------------------------------------------

class DevenirIntroEcran extends StatelessWidget {
  const DevenirIntroEcran({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final haut = MediaQuery.paddingOf(context).top;
    final enCours = s.etapeConducteur == EtapeConducteur.documentsEnvoyes || s.etapeConducteur == EtapeConducteur.valide;
    Widget numero(String n, String titre, String sous) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: C.laterite, shape: BoxShape.circle),
          child: Text(n, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Text(titre, style: T.gras), const SizedBox(height: 4), Doux(sous, taille: 14)],
          ),
        ),
      ],
    );
    return Ecran(
      children: [
        Container(
          color: C.encre,
          padding: EdgeInsets.fromLTRB(20, 18 + haut, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Transform.translate(
                offset: const Offset(-10, 0),
                child: IconeBtn(
                  icon: Icons.chevron_left_rounded,
                  label: 'Retour',
                  taille: 30,
                  couleur: Colors.white,
                  onTap: () => Navigator.maybePop(context),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                enCours ? 'Votre inscription est en cours' : "Vous n'avez pas encore de compte conducteur",
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: C.etoile),
              ),
              const SizedBox(height: 10),
              Text('Vous roulez déjà ? Partagez vos frais.', style: T.titre(34, color: Colors.white)),
              const SizedBox(height: 10),
              const Text(
                'Votre compte conducteur est séparé de votre compte passager : sa propre note, son véhicule, ses gains.',
                style: TextStyle(fontSize: 15, height: 1.5, color: C.beige),
              ),
            ],
          ),
        ),
        Zone(
          children: [
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Carte(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.account_balance_wallet_outlined, color: C.vert),
                        SizedBox(height: 4),
                        Text("Jusqu'à 10 000 F", style: T.gras),
                        Doux('par Ouaga–Koudougou plein, carburant partagé'),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Carte(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.verified_user_outlined, color: C.laterite),
                        SizedBox(height: 4),
                        Text('Passagers vérifiés', style: T.gras),
                        Doux('numéro confirmé, notes, code de départ'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const Etiq('Comment ça marche'),
            Carte(
              child: Column(
                children: espacer([
                  numero('1', 'Envoyez vos documents', 'CNIB, permis, carte grise, assurance, photo du véhicule'),
                  numero('2', "L'équipe vous valide", 'Sous 48 h, avec un court entretien'),
                  numero('3', 'Choisissez votre abonnement', 'Premier mois offert, sans engagement'),
                ], 12),
              ),
            ),
            const Doux('Conditions : 21 ans minimum, permis depuis 2 ans au moins.'),
            Btn.lat(
              enCours ? 'Suivre ma validation' : 'Commencer mon inscription',
              onPressed: () => ouvrir(context, enCours ? const ValidationEcran() : const DocumentsEcran()),
            ),
            Lien(
              "Voir les abonnements d'abord",
              souligne: false,
              onTap: () => ouvrir(context, const OffresEcran()),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 23 · Documents (A4)
// ---------------------------------------------------------------------------

class DocumentsEcran extends StatefulWidget {
  const DocumentsEcran({super.key});

  @override
  State<DocumentsEcran> createState() => _DocumentsEcranState();
}

class _DocumentsEcranState extends State<DocumentsEcran> {
  bool _charte = false;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final total = documentsConducteur.length;
    final faits = s.documentsEnvoyes.length;
    final complet = faits == total;
    return Ecran(
      children: [
        Piste(
          retour: true,
          paddingBas: 30,
          children: [
            Titre(s.femme ? 'Devenir conductrice' : 'Devenir conducteur'),
            const Text('21 ans minimum · permis depuis 2 ans au moins', style: T.petit),
          ],
        ),
        Zone(
          gap: 14,
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('$faits documents sur $total', style: T.etiq)),
                    Doux('${faits * 100 ~/ total} %', taille: 14, gras: true),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: faits / total,
                    minHeight: 10,
                    color: C.vert,
                    backgroundColor: C.sable2,
                  ),
                ),
              ],
            ),
            ListeCarte(
              children: [
                for (final e in documentsConducteur.entries)
                  LigneListe(
                    children: [
                      s.photosDocuments[e.key] != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.memory(
                                s.photosDocuments[e.key]!,
                                width: 36,
                                height: 36,
                                fit: BoxFit.cover,
                                semanticLabel: 'Photo : ${e.key}',
                                errorBuilder: (_, _, _) => const Icon(Icons.check_rounded, color: C.vertF),
                              ),
                            )
                          : s.documentsEnvoyes.contains(e.key)
                          ? Container(
                              width: 36,
                              height: 36,
                              decoration: const BoxDecoration(color: C.vertC, shape: BoxShape.circle),
                              child: const Icon(Icons.check_rounded, color: C.vertF, size: 20),
                            )
                          : Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: C.laterite, width: 2.5),
                              ),
                            ),
                      Bloc(e.key, e.value),
                      s.documentsEnvoyes.contains(e.key)
                          ? const Text('Envoyé', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: C.vertF))
                          : BtnP(
                              'Photo',
                              icon: Icons.photo_camera_outlined,
                              couleur: C.laterite,
                              onPressed: () async {
                                final choix = await demanderPhoto(context, titre: e.key);
                                final octets = choix?.octets;
                                if (octets != null) s.envoyerDocument(e.key, photo: octets);
                              },
                            ),
                    ],
                  ),
              ],
            ),
            LigneCase(
              carte: false,
              value: _charte,
              onChanged: (v) => setState(() => _charte = v),
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text("J'accepte la ", style: T.petit),
                    Lien('charte du conducteur', onTap: () => ouvrir(context, const PageTexteEcran.charte())),
                    const Text(' : pas d’alcool, respect des passagers, documents à jour.', style: T.petit),
                  ],
                ),
              ),
            ),
            const Doux("Vos documents sont stockés dans un espace privé, visible seulement par l'équipe de validation."),
            Btn(
              'Envoyer pour validation',
              onPressed: complet && _charte
                  ? () {
                      if (essayer(context, s.envoyerPourValidation)) {
                        remplacer(context, const ValidationEcran());
                      }
                    }
                  : null,
            ),
            if (!complet || !_charte)
              Doux(
                !complet ? 'Ajoutez les ${total - faits} documents manquants.' : 'Acceptez la charte pour continuer.',
                align: TextAlign.center,
              ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 24 · Suivi de validation (A5)
// ---------------------------------------------------------------------------

class ValidationEcran extends StatelessWidget {
  const ValidationEcran({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final valide = s.etapeConducteur == EtapeConducteur.valide || s.estConducteur;
    final limite = s.maintenant.add(const Duration(hours: 48));
    return Ecran(
      children: [
        const Barre(titre: 'Ma validation'),
        Zone(
          gap: 14,
          children: [
            Titre(valide ? 'Votre compte est validé' : "C'est en bonne voie"),
            Carte(
              child: Column(
                children: [
                  const Etape(EtatEtape.fait, 'Documents envoyés', '5 documents sur 5', taille: 32),
                  Etape(
                    valide ? EtatEtape.fait : EtatEtape.encours,
                    "Vérification par l'équipe",
                    valide ? 'Documents conformes' : 'Réponse sous 48 h, avant ${jourCourt(limite)} ${heureCourte(limite)}',
                    taille: 32,
                  ),
                  Etape(
                    valide ? EtatEtape.fait : EtatEtape.afaire,
                    'Entretien',
                    'En personne ou en vidéo, 15 minutes',
                    taille: 32,
                  ),
                  Etape(
                    s.estConducteur ? EtatEtape.fait : (valide ? EtatEtape.encours : EtatEtape.afaire),
                    'Abonnement',
                    'Premier mois offert, sans engagement',
                    taille: 32,
                  ),
                  Etape(
                    s.estConducteur ? EtatEtape.fait : EtatEtape.afaire,
                    'Compte conducteur activé',
                    'Vous pourrez publier vos trajets',
                    taille: 32,
                  ),
                ],
              ),
            ),
            if (!valide)
              const Bandeau(
                "Prototype : dans l'application réelle, l'équipe vous appelle pour l'entretien puis valide votre compte.",
                icon: Icons.info_outline_rounded,
                ton: TonPastille.etoile,
              ),
          ],
          bas: [
            if (!valide)
              Btn('Simuler la validation par l’équipe', onPressed: s.simulerValidation)
            else if (!s.estConducteur)
              Btn('Compte validé : choisir mon abonnement', onPressed: () => ouvrir(context, const OffresEcran()))
            else
              Btn('Aller au mode conducteur', onPressed: () {
                s.basculerMode(Mode.conducteur);
                retourAccueil(context);
              }),
            BtnClair('Revenir au mode passager', onPressed: () => retourAccueil(context)),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 37 · Choisir l'abonnement
// ---------------------------------------------------------------------------

class OffresEcran extends StatefulWidget {
  const OffresEcran({super.key});

  @override
  State<OffresEcran> createState() => _OffresEcranState();
}

class _OffresEcranState extends State<OffresEcran> {
  Formule _f = Formule.trimestriel;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final valide = s.etapeConducteur == EtapeConducteur.valide;
    Widget atout(IconData i, String t) => Row(
      children: [Icon(i, size: 18), const SizedBox(width: 8), Expanded(child: Text(t, style: T.petit))],
    );
    return Ecran(
      children: [
        const Barre(titre: 'Abonnement conducteur'),
        Zone(
          gap: 12,
          children: [
            valide
                ? const Bandeau(
                    '',
                    icon: Icons.check_rounded,
                    riche: TextSpan(
                      children: [
                        TextSpan(text: 'Votre compte est validé. ', style: T.gras),
                        TextSpan(text: 'Choisissez une formule : le premier mois est offert.'),
                      ],
                    ),
                  )
                : const Bandeau(
                    'Vous choisirez votre formule une fois votre compte validé. Le premier mois est offert.',
                    icon: Icons.info_outline_rounded,
                    ton: TonPastille.etoile,
                  ),
            for (final f in Formule.values)
              Choix(
                on: _f == f,
                anneau: false,
                padding: const EdgeInsets.all(16),
                vertical: true,
                onTap: () => setState(() => _f = f),
                children: [
                  Row(
                    children: [
                      Text(f.nom, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 8),
                      if (f == Formule.trimestriel)
                        const Pastille('Recommandé', ton: TonPastille.etoile, icon: Icons.star_rounded),
                      const Spacer(),
                      Anneau(_f == f),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Expanded(child: Titre(fcfa(f.prix))),
                      Doux(f.duree, taille: 14),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(f.economie, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: C.vertF)),
                  ),
                ],
              ),
            Carte(
              child: Column(
                children: espacer([
                  atout(Icons.check_rounded, 'Trajets illimités en ville et entre villes'),
                  atout(Icons.check_rounded, 'Sans engagement : arrêtez quand vous voulez'),
                  atout(Icons.confirmation_number_outlined, "En plus : 10 % sur les places payées dans l'appli, rien sur les espèces (0 % pendant le pilote)"),
                ], 8),
              ),
            ),
            const Carte.sombre(
              child: Row(
                children: [
                  Etoile(size: 26),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: TextStyle(fontSize: 14, color: Colors.white),
                        children: [
                          TextSpan(text: 'Offre Fondateurs', style: T.gras),
                          TextSpan(text: ' · 50 premiers conducteurs : avantage à confirmer. Il reste 23 places.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Pied(
          child: Btn(
            valide ? 'Continuer avec le ${_f.nom.toLowerCase()}' : 'Commencer mon inscription',
            onPressed: () => valide
                ? ouvrir(context, PaiementAboEcran(formule: _f))
                : remplacer(context, const DocumentsEcran()),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 38 · Confirmer l'abonnement
// ---------------------------------------------------------------------------

class PaiementAboEcran extends StatefulWidget {
  const PaiementAboEcran({super.key, required this.formule});
  final Formule formule;

  @override
  State<PaiementAboEcran> createState() => _PaiementAboEcranState();
}

class _PaiementAboEcranState extends State<PaiementAboEcran> {
  bool _conditions = true;
  Paiement _op = Paiement.orange;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final f = widget.formule;
    final debut = s.maintenant;
    final fin = ajouterMois(debut, 1);
    final masque = '${s.telephone.substring(0, 2)} •• •• ${s.telephone.substring(s.telephone.length - 2)}';
    return Ecran(
      children: [
        Barre(titre: "Confirmer l'abonnement", sousTitre: '${f.nom} · ${fcfa(f.prix)} ${f.duree}'),
        Zone(
          gap: 14,
          children: [
            Carte.sombre(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("À payer aujourd'hui", style: TextStyle(fontSize: 14, color: C.beige)),
                  Text('0 F', style: T.titre(40, color: C.etoile)),
                  const Text('Premier mois offert', style: TextStyle(fontSize: 14, color: C.beige)),
                ],
              ),
            ),
            Carte(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(child: Doux('Du ${dateCourte(debut)} au ${dateCourte(fin)}', taille: 16)),
                      const Text('Offert', style: TextStyle(fontWeight: FontWeight.w700, color: C.vertF)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: Doux('Le ${dateCourte(fin)} · ${pluriel(f.mois, 'mois', 'mois')}', taille: 16)),
                      Text(fcfa(f.prix), style: T.gras),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Sep(),
                  const SizedBox(height: 8),
                  const Doux('Pas de prélèvement automatique : nous vous rappelons 3 jours avant, vous payez en un geste.'),
                ],
              ),
            ),
            const Etiq('Paiement du renouvellement'),
            Choix(
              on: _op == Paiement.orange,
              onTap: () => setState(() => _op = Paiement.orange),
              children: [const LogoPaiement(Paiement.orange), Bloc('Orange Money', masque)],
            ),
            Choix(
              on: _op == Paiement.moov,
              onTap: () => setState(() => _op = Paiement.moov),
              children: [const LogoPaiement(Paiement.moov), const Bloc('Moov Money', 'Ajouter un numéro')],
            ),
            LigneCase(
              carte: false,
              value: _conditions,
              onChanged: (v) => setState(() => _conditions = v),
              child: const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text("J'accepte les conditions de l'abonnement.", style: T.petit),
              ),
            ),
          ],
        ),
        Pied(
          child: Btn(
            'Activer mon abonnement',
            onPressed: _conditions
                ? () {
                    if (essayer(context, () => s.activerAbonnement(f))) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const AboActifEcran()),
                        (r) => r.isFirst,
                      );
                    }
                  }
                : null,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 39 · Compte conducteur activé
// ---------------------------------------------------------------------------

class AboActifEcran extends StatelessWidget {
  const AboActifEcran({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final a = s.abonnement;
    final haut = MediaQuery.paddingOf(context).top;
    final bas = MediaQuery.paddingOf(context).bottom;
    Widget ligne(String l, String v) => Row(
      children: [
        Expanded(child: Text(l, style: const TextStyle(color: Colors.white))),
        Text(v, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ],
    );
    return Scaffold(
      backgroundColor: C.vert,
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: MediaQuery.sizeOf(context).height),
          child: IntrinsicHeight(
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 40 + haut, 24, 28 + bas),
              child: Column(
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: C.etoile, shape: BoxShape.circle),
                    child: const Etoile(size: 64, color: C.encre),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Bienvenue parmi les ${s.femme ? 'conductrices' : 'conducteurs'}, ${s.prenom} !',
                    textAlign: TextAlign.center,
                    style: T.titre(34, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Votre compte ${s.femme ? 'conductrice' : 'conducteur'} est actif. Il a sa propre note : elle démarre à zéro, votre note de passag${s.femme ? 'ère' : 'er'} ne change pas.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: C.vertF, borderRadius: BorderRadius.circular(22)),
                    child: Column(
                      children: espacer([
                        ligne('Formule', a?.formule.nom ?? '—'),
                        ligne('Offert jusqu’au', a == null ? '—' : dateLongue(a.offertJusquau)),
                        ligne('Véhicule', 'Corolla · 11 HH 2345'),
                      ], 8),
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(height: 16),
                  Btn(
                    'Publier mon premier trajet',
                    icon: Icons.add_rounded,
                    couleur: Colors.white,
                    texte: C.vertF,
                    onPressed: () {
                      final nav = Navigator.of(context);
                      s.basculerMode(Mode.conducteur);
                      nav.popUntil((r) => r.isFirst);
                      nav.push(MaterialPageRoute(builder: (_) => const PublierEcran()));
                    },
                  ),
                  Lien(
                    'Revenir au mode passager',
                    couleur: Colors.white,
                    souligne: false,
                    taille: 16,
                    onTap: () => retourAccueil(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
