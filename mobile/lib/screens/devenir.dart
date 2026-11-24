import 'dart:typed_data';

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
                  numero(
                    '1',
                    'Photographiez vos documents',
                    'CNIB et selfie avec la carte, permis, carte grise, assurance, véhicule : avec l’appareil photo de l’application',
                  ),
                  numero('2', "L'équipe vous valide", 'Sous 48 h, avec un court entretien : apportez vos originaux'),
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
  late final AppState _s;
  late final Map<String, TextEditingController> _champs;

  @override
  void initState() {
    super.initState();
    _s = AppScope.read(context);
    final d = _s.dossier;
    _champs = {
      'cnib': TextEditingController(text: d.cnibNumero),
      'permis': TextEditingController(text: d.permisNumero),
      'plaque': TextEditingController(text: d.plaque),
      'vehicule': TextEditingController(text: d.vehicule),
      'assureur': TextEditingController(text: d.assureur),
      'police': TextEditingController(text: d.police),
      'plaqueAssurance': TextEditingController(text: d.plaqueAssurance),
    };
  }

  @override
  void dispose() {
    for (final c in _champs.values) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _champ(String label, String cle, void Function(DossierConducteur d, String v) maj, {String? hint}) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Doux(label, taille: 14),
      const SizedBox(height: 4),
      Champ(
        controller: _champs[cle],
        hint: hint,
        label: label,
        onChanged: (v) => _s.majDossier((d) => maj(d, v)),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final total = documentsConducteur.length;
    final faits = s.documentsEnvoyes.length;
    final d = s.dossier;
    final n = jour(s.maintenant);
    final controles = s.controlesDossier;
    final pret = controles.every((c) => c.ok);
    Widget sousTitre(String t) => Text(t, style: T.gras);
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
            if (s.motifRefus != null)
              Bandeau(
                'Dossier refusé par l’équipe : ${s.motifRefus!.toLowerCase()}. Corrigez puis renvoyez-le.',
                icon: Icons.error_outline_rounded,
                ton: TonPastille.sos,
              ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('${pluriel(faits, 'document')} sur $total', style: T.etiq)),
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
            const Etiq('1. Photos des documents'),
            const Doux(
              "Prises avec l'appareil photo de l'application, sans import depuis la galerie : "
              'une image retouchée ou trouvée ailleurs ne passe pas.',
              taille: 14,
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
                      BtnP(
                        s.documentsEnvoyes.contains(e.key) ? 'Refaire' : 'Photo',
                        icon: Icons.photo_camera_outlined,
                        couleur: s.documentsEnvoyes.contains(e.key) ? C.doux : C.laterite,
                        onPressed: () async {
                          final choix = await demanderPhoto(
                            context,
                            titre: e.key,
                            selfie: selfiesDocuments.contains(e.key),
                            galerie: false,
                          );
                          final octets = choix?.octets;
                          if (octets != null) s.envoyerDocument(e.key, photo: octets);
                        },
                      ),
                    ],
                  ),
              ],
            ),
            const Etiq('2. Ce que disent vos documents'),
            Carte(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: espacer([
                  sousTitre('CNIB'),
                  ChampDate(
                    label: 'Date de naissance',
                    valeur: d.naissance,
                    premiere: DateTime(1940),
                    derniere: n,
                    annees: true,
                    onChoisi: (v) => s.majDossier((d) => d.naissance = v),
                  ),
                  _champ('Numéro de la CNIB', 'cnib', (d, v) => d.cnibNumero = v),
                  ChampDate(
                    label: 'CNIB valable jusqu’au',
                    valeur: d.cnibExpire,
                    premiere: DateTime(n.year - 5),
                    derniere: DateTime(n.year + 15),
                    onChoisi: (v) => s.majDossier((d) => d.cnibExpire = v),
                  ),
                  const Sep(),
                  sousTitre('Permis de conduire'),
                  _champ('Numéro du permis', 'permis', (d, v) => d.permisNumero = v),
                  ChampDate(
                    label: 'Permis délivré le',
                    valeur: d.permisDelivre,
                    premiere: DateTime(1960),
                    derniere: n,
                    annees: true,
                    onChoisi: (v) => s.majDossier((d) => d.permisDelivre = v),
                  ),
                  const Sep(),
                  sousTitre('Carte grise'),
                  _champ('Plaque', 'plaque', (d, v) => d.plaque = v, hint: '11 HH 2345'),
                  _champ('Modèle et couleur', 'vehicule', (d, v) => d.vehicule = v, hint: 'Toyota Corolla grise'),
                  const Sep(),
                  sousTitre('Assurance'),
                  _champ('Assureur', 'assureur', (d, v) => d.assureur = v),
                  _champ('Numéro de police', 'police', (d, v) => d.police = v),
                  _champ('Plaque sur l’attestation', 'plaqueAssurance', (d, v) => d.plaqueAssurance = v, hint: '11 HH 2345'),
                  ChampDate(
                    label: 'Assurance valable jusqu’au',
                    valeur: d.assuranceFin,
                    premiere: DateTime(n.year - 2),
                    derniere: DateTime(n.year + 3),
                    onChoisi: (v) => s.majDossier((d) => d.assuranceFin = v),
                  ),
                ], 10),
              ),
            ),
            const Etiq('3. Contrôles automatiques'),
            Carte(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: espacer([for (final c in controles) LigneControle(c)], 10),
              ),
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
              onPressed: pret && _charte
                  ? () {
                      if (essayer(context, s.envoyerPourValidation)) {
                        remplacer(context, const ValidationEcran());
                      }
                    }
                  : null,
            ),
            if (!pret || !_charte)
              Doux(
                !pret
                    ? 'À corriger : ${controles.firstWhere((c) => !c.ok).libelle.toLowerCase()}.'
                    : 'Acceptez la charte pour continuer.',
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
    final n = documentsConducteur.length;
    if (s.etapeConducteur == EtapeConducteur.aucune) {
      // Dossier refusé (ou pas encore envoyé) : retour aux documents.
      return Ecran(
        children: [
          const Barre(titre: 'Ma validation'),
          Zone(
            gap: 14,
            children: [
              Titre(s.motifRefus == null ? 'Dossier pas encore envoyé' : 'Dossier à corriger'),
              if (s.motifRefus != null)
                Bandeau(
                  'L’équipe a refusé le dossier : ${s.motifRefus!.toLowerCase()}. Corrigez puis renvoyez-le.',
                  icon: Icons.error_outline_rounded,
                  ton: TonPastille.sos,
                ),
            ],
            bas: [Btn('Corriger mon dossier', onPressed: () => remplacer(context, const DocumentsEcran()))],
          ),
        ],
      );
    }
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
                  Etape(EtatEtape.fait, 'Documents envoyés', '$n documents sur $n · contrôles automatiques réussis', taille: 32),
                  Etape(
                    valide ? EtatEtape.fait : EtatEtape.encours,
                    "Vérification par l'équipe",
                    valide
                        ? 'Documents conformes${s.valideLe == null ? '' : ' · validé le ${dateCourte(s.valideLe!)}'}'
                        : 'Réponse sous 48 h, avant ${jourCourt(limite)} ${heureCourte(limite)}',
                    taille: 32,
                  ),
                  Etape(
                    valide ? EtatEtape.fait : EtatEtape.afaire,
                    'Entretien',
                    'En personne de préférence, 15 minutes : apportez vos originaux et la voiture',
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
                "Prototype : dans l'application réelle, l'équipe vous appelle pour l'entretien, vérifie chaque point "
                'de sa liste puis valide votre compte. Ici, vous pouvez ouvrir son écran.',
                icon: Icons.info_outline_rounded,
                ton: TonPastille.etoile,
              ),
          ],
          bas: [
            if (!valide)
              Btn(
                'Vérification par l’équipe (démo)',
                icon: Icons.fact_check_outlined,
                onPressed: () => ouvrir(context, const VerificationEquipeEcran()),
              )
            else if (!s.estConducteur)
              Btn('Compte validé : choisir mon abonnement', onPressed: () => ouvrir(context, const OffresEcran()))
            else
              Btn('Aller au mode conducteur', onPressed: () {
                s.basculerMode(Mode.conducteur);
                retourAccueil(context);
              }),
            BtnClair(
              s.mode == Mode.conducteur ? 'Retour à mon espace conducteur' : 'Revenir au mode passager',
              onPressed: () => retourAccueil(context),
            ),
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
                        ligne('Véhicule', '${s.dossier.vehicule} · ${s.dossier.plaque}'),
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
                    s.mode == Mode.conducteur ? 'Aller à mon espace conducteur' : 'Revenir au mode passager',
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

// ---------------------------------------------------------------------------
// Champs et contrôles du dossier
// ---------------------------------------------------------------------------

/// Date choisie dans un calendrier (naissance, validité d'un document…).
class ChampDate extends StatelessWidget {
  const ChampDate({
    super.key,
    required this.label,
    required this.valeur,
    required this.onChoisi,
    required this.premiere,
    required this.derniere,
    this.annees = false,
  });
  final String label;
  final DateTime? valeur;
  final ValueChanged<DateTime> onChoisi;
  final DateTime premiere;
  final DateTime derniere;

  /// Le calendrier s'ouvre sur les années (date de naissance, de permis).
  final bool annees;

  @override
  Widget build(BuildContext context) {
    final v = valeur;
    final texte = v == null ? 'Choisir une date' : '${dateLongue(v)} ${v.year}';
    Future<void> choisir() async {
      var initiale = v ?? (annees ? DateTime(derniere.year - 25) : derniere.subtract(Duration(days: derniere.difference(premiere).inDays ~/ 2)));
      if (initiale.isBefore(premiere)) initiale = premiere;
      if (initiale.isAfter(derniere)) initiale = derniere;
      final d = await showDatePicker(
        context: context,
        initialDate: initiale,
        firstDate: premiere,
        lastDate: derniere,
        initialDatePickerMode: annees && v == null ? DatePickerMode.year : DatePickerMode.day,
        helpText: label,
      );
      if (d != null) onChoisi(d);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Doux(label, taille: 14),
        const SizedBox(height: 4),
        Semantics(
          button: true,
          label: '$label : ${v == null ? 'à choisir' : texte}',
          excludeSemantics: true,
          child: Material(
            color: C.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: C.trait, width: 2),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: choisir,
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        texte,
                        style: v == null
                            ? const TextStyle(fontSize: 16, color: C.doux)
                            : const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const Icon(Icons.calendar_today_outlined, size: 20, color: C.doux),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Une ligne de contrôle automatique : réussi ou à corriger.
class LigneControle extends StatelessWidget {
  const LigneControle(this.c, {super.key});
  final Controle c;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '${c.libelle} : ${c.ok ? 'réussi' : 'à corriger'}${c.detail == null ? '' : ', ${c.detail}'}',
    excludeSemantics: true,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          c.ok ? Icons.check_circle_rounded : Icons.error_outline_rounded,
          size: 22,
          color: c.ok ? C.vert : C.sos,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(c.libelle, style: T.petit.copyWith(fontWeight: FontWeight.w700)),
              if (c.detail != null) Doux(c.detail!),
            ],
          ),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Écran de l'équipe : liste de vérification (futur back-office)
// ---------------------------------------------------------------------------

class VerificationEquipeEcran extends StatelessWidget {
  const VerificationEquipeEcran({super.key});

  Future<void> _refuser(BuildContext context, AppState s) async {
    final motif = await showModalBottomSheet<String>(
      context: context,
      builder: (c) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          children: [
            Text('Motif du refus', style: T.titre(22)),
            const SizedBox(height: 12),
            ListeCarte(
              children: [
                for (final m in motifsRefus)
                  LigneListe(
                    onTap: () => Navigator.pop(c, m),
                    children: [Bloc(m), const Icon(Icons.chevron_right_rounded, size: 20)],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
    if (motif == null || !context.mounted) return;
    s.refuserDossier(motif);
    Navigator.pop(context);
    message(context, 'Dossier refusé : le conducteur est prévenu du motif.');
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final d = s.dossier;
    final restants = s.pointsRestants;
    String date(DateTime? x) => x == null ? '—' : '${dateLongue(x)} ${x.year}';
    Widget info(String l, String v) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 96, child: Doux(l, taille: 14)),
          Expanded(child: Text(v, style: T.petit.copyWith(fontWeight: FontWeight.w700))),
        ],
      ),
    );
    return Ecran(
      children: [
        Barre(titre: 'Vérification du dossier', sousTitre: '${s.moi.complet} · +226 ${s.telephone}'),
        Zone(
          gap: 14,
          children: [
            const Bandeau(
              "Prototype : l'écran de l'équipe, dans le futur back-office. Cochez chaque point une fois vérifié : "
              "le compte ne peut être validé qu'avec la liste complète.",
              icon: Icons.admin_panel_settings_outlined,
              ton: TonPastille.etoile,
            ),
            const Etiq('Photos envoyées'),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [for (final doc in documentsConducteur.keys) _Vignette(doc, s.photosDocuments[doc])],
            ),
            const Etiq('Saisi par le conducteur'),
            Carte(
              child: Column(
                children: [
                  info('Né le', date(d.naissance)),
                  info('CNIB', '${d.cnibNumero} · jusqu’au ${date(d.cnibExpire)}'),
                  info('Permis', '${d.permisNumero} · délivré le ${date(d.permisDelivre)}'),
                  info('Véhicule', '${d.vehicule} · ${d.plaque}'),
                  info('Assurance', '${d.assureur} · n° ${d.police} · ${d.plaqueAssurance} · jusqu’au ${date(d.assuranceFin)}'),
                ],
              ),
            ),
            const Etiq('Contrôles automatiques'),
            Carte(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: espacer([for (final c in s.controlesDossier) LigneControle(c)], 10),
              ),
            ),
            for (final (groupe, points) in verificationEquipe) ...[
              Etiq(groupe),
              Carte(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: espacer([
                    for (final p in points)
                      LigneCase(
                        carte: false,
                        value: s.verificationsFaites.contains(p),
                        onChanged: (_) => s.cocherVerification(p),
                        child: Padding(padding: const EdgeInsets.only(top: 4), child: Text(p, style: T.petit)),
                      ),
                  ], 10),
                ),
              ),
            ],
          ],
          bas: [
            Doux(
              restants == 0 ? 'Tous les points sont vérifiés.' : 'Encore ${pluriel(restants, 'point')} à vérifier.',
              align: TextAlign.center,
            ),
            Btn(
              'Valider le conducteur',
              onPressed: restants == 0
                  ? () {
                      // L'écran de suivi affiche « Votre compte est validé ».
                      if (essayer(context, s.validerParEquipe)) Navigator.pop(context);
                    }
                  : null,
            ),
            BtnClair('Refuser le dossier', couleur: C.sos, onPressed: () => _refuser(context, s)),
          ],
        ),
      ],
    );
  }
}

class _Vignette extends StatelessWidget {
  const _Vignette(this.doc, this.photo);
  final String doc;
  final Uint8List? photo;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 96,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 96,
            height: 72,
            color: C.sable2,
            child: photo == null
                ? const Icon(Icons.image_not_supported_outlined, color: C.doux)
                : Image.memory(
                    photo!,
                    fit: BoxFit.cover,
                    semanticLabel: 'Photo : $doc',
                    errorBuilder: (_, _, _) => const Icon(Icons.image_outlined, color: C.doux),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(doc, style: T.mini, maxLines: 2),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Document qui expire : nouvelle photo et nouvelle date
// ---------------------------------------------------------------------------

class MajDocumentEcran extends StatefulWidget {
  const MajDocumentEcran({super.key, required this.doc});

  /// « Assurance » ou « CNIB ».
  final String doc;

  @override
  State<MajDocumentEcran> createState() => _MajDocumentEcranState();
}

class _MajDocumentEcranState extends State<MajDocumentEcran> {
  Uint8List? _photo;
  DateTime? _fin;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final n = jour(s.maintenant);
    final assurance = widget.doc == 'Assurance';
    return Ecran(
      children: [
        Barre(
          titre: assurance ? 'Nouvelle assurance' : 'Nouvelle CNIB',
          sousTitre: 'Photo et date de fin de validité',
        ),
        Zone(
          gap: 14,
          children: [
            Carte(
              child: Row(
                children: [
                  if (_photo != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(_photo!, width: 48, height: 48, fit: BoxFit.cover, semanticLabel: 'Photo du document'),
                    )
                  else
                    const Icon(Icons.photo_camera_outlined, size: 26),
                  const SizedBox(width: 12),
                  Bloc(
                    _photo == null ? 'Photo du nouveau document' : 'Photo prise',
                    "Avec l'appareil photo de l'application",
                  ),
                  BtnP(
                    _photo == null ? 'Photo' : 'Refaire',
                    icon: Icons.photo_camera_outlined,
                    couleur: C.laterite,
                    onPressed: () async {
                      final c = await demanderPhoto(context, titre: widget.doc, galerie: false);
                      final octets = c?.octets;
                      if (octets != null) setState(() => _photo = octets);
                    },
                  ),
                ],
              ),
            ),
            ChampDate(
              label: 'Valable jusqu’au',
              valeur: _fin,
              premiere: n,
              derniere: DateTime(n.year + (assurance ? 3 : 15)),
              onChoisi: (v) => setState(() => _fin = v),
            ),
            const Doux("L'équipe vérifie le nouveau document. Les passagers ne voient jamais vos documents."),
          ],
          bas: [
            Btn(
              'Envoyer',
              onPressed: _photo != null && _fin != null
                  ? () {
                      if (essayer(context, () => s.renouvelerDocument(widget.doc, fin: _fin!, photo: _photo!))) {
                        Navigator.pop(context);
                        message(context, 'Nouveau document envoyé. Merci !');
                      }
                    }
                  : null,
            ),
          ],
        ),
      ],
    );
  }
}
