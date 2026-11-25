import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../model.dart';
import '../painters.dart';
import '../photo.dart';
import '../theme.dart';
import '../ui.dart';
import 'espace_conducteur.dart';

/// 01 · Bienvenue
class BienvenueEcran extends StatelessWidget {
  const BienvenueEcran({super.key});

  @override
  Widget build(BuildContext context) {
    final haut = MediaQuery.paddingOf(context).top;
    final bas = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: C.sable,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              color: C.laterite,
              child: Stack(
                children: [
                  Positioned.fill(child: CustomPaint(painter: PaysagePainter())),
                  Padding(
                    padding: EdgeInsets.fromLTRB(24, 28 + haut, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Etoile(size: 28),
                            const SizedBox(width: 8),
                            Text('FasoCovoit', style: T.titre(24, color: Colors.white)),
                          ],
                        ),
                        const SizedBox(height: 36),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 560),
                          child: Semantics(
                            header: true,
                            child: Text(
                              'On fait la route ensemble.',
                              style: T.titre(44, color: Colors.white).copyWith(height: 1.02),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 300),
                          child: const Text(
                            "Dans Ouaga et jusqu'à Koudougou, partagez une voiture et ses frais avec des conducteurs vérifiés.",
                            style: TextStyle(color: Colors.white, fontSize: 17, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 22 + bas),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Btn('Commencer', onPressed: () => ouvrir(context, const NumeroEcran(nouveau: true))),
                const SizedBox(height: 12),
                BtnClair("J'ai déjà un compte", onPressed: () => ouvrir(context, const NumeroEcran(nouveau: false))),
                const SizedBox(height: 12),
                const BoutonGoogle(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Connexion avec un compte Google : prévue, pas encore branchée.
class BoutonGoogle extends StatelessWidget {
  const BoutonGoogle({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Continuer avec Google, bientôt disponible',
    excludeSemantics: true,
    child: Material(
      color: C.surface,
      shape: const StadiumBorder(side: BorderSide(color: C.trait, width: 2)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => informer(
          context,
          'Connexion avec Google',
          'La connexion avec votre compte Google (Gmail) arrivera avec les vrais comptes FasoCovoit. '
              'En attendant, connectez-vous avec votre numéro de téléphone.\n\n'
              'Compte de démonstration : ${AppState.formaterTel(AppState.numeroDemo)}.',
        ),
        child: SizedBox(
          height: 52,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: C.trait, width: 1.5),
                ),
                child: const Text(
                  'G',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF4285F4)),
                ),
              ),
              const SizedBox(width: 10),
              const Flexible(
                child: Text('Continuer avec Google', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
              const Pastille('Bientôt', ton: TonPastille.etoile),
            ],
          ),
        ),
      ),
    ),
  );
}

/// 02 · Numéro de téléphone (A1)
class NumeroEcran extends StatefulWidget {
  const NumeroEcran({super.key, required this.nouveau});

  /// Vrai depuis « Commencer », faux depuis « J'ai déjà un compte ».
  final bool nouveau;

  @override
  State<NumeroEcran> createState() => _NumeroEcranState();
}

class _NumeroEcranState extends State<NumeroEcran> {
  late final TextEditingController _tel;

  @override
  void initState() {
    super.initState();
    _tel = TextEditingController(text: widget.nouveau ? '' : AppState.formaterTel(AppState.numeroDemo));
  }

  @override
  void dispose() {
    _tel.dispose();
    super.dispose();
  }

  Future<void> _envoyer() async {
    final s = AppScope.read(context);
    final c = AppState.chiffres(_tel.text);
    if (c.length != 8) {
      message(context, 'Saisissez les 8 chiffres de votre numéro.');
      return;
    }
    final existe = s.compteExiste(c);
    if (!widget.nouveau && !existe) {
      final creer = await confirmer(
        context,
        titre: 'Aucun compte avec ce numéro',
        texte: 'Voulez-vous créer un compte avec le +226 ${AppState.formaterTel(c)} ?',
        oui: 'Créer un compte',
        non: 'Modifier le numéro',
      );
      if (!creer || !mounted) return;
    }
    if (!mounted) return;
    if (essayer(context, () => s.envoyerCode(c))) {
      ouvrir(context, CodeEcran(telephone: AppState.formaterTel(c), connexion: existe));
    }
  }

  @override
  Widget build(BuildContext context) => Ecran(
    children: [
      Piste(
        retour: true,
        children: [
          const SizedBox(height: 8),
          Titre(widget.nouveau ? 'Quel est votre numéro ?' : 'Content de vous revoir'),
          const SizedBox(height: 8),
          const Text('Pas de mot de passe : on vous envoie un code par SMS.', style: TextStyle(fontSize: 15)),
        ],
      ),
      Zone(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Etiq('Numéro de téléphone'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: C.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: C.trait, width: 2),
                    ),
                    child: const Text('+226', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Champ(
                      controller: _tel,
                      clavier: TextInputType.phone,
                      actif: true,
                      hint: '70 00 00 00',
                      label: 'Numéro de téléphone',
                      formatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
                        LengthLimitingTextInputFormatter(11),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Doux('Orange, Moov ou Telecel'),
            ],
          ),
          Bandeau(
            '',
            icon: Icons.info_outline_rounded,
            ton: TonPastille.etoile,
            riche: TextSpan(
              children: [
                const TextSpan(text: 'Compte de démonstration : '),
                TextSpan(text: AppState.formaterTel(AppState.numeroDemo), style: T.gras),
                const TextSpan(text: ' (Hermès Barry, avec son historique). Tout autre numéro crée un nouveau compte.'),
              ],
            ),
          ),
          const Carte(
            child: Row(
              children: [
                Icon(Icons.lock_outline_rounded, size: 22),
                SizedBox(width: 12),
                Expanded(
                  child: Doux(
                    "Votre numéro n'est jamais montré aux autres utilisateurs. Les appels passent par l'application.",
                    taille: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
        bas: [Btn('Recevoir le code', onPressed: _envoyer)],
      ),
    ],
  );
}

/// 03 · Code SMS (A1)
class CodeEcran extends StatefulWidget {
  const CodeEcran({super.key, required this.telephone, required this.connexion});
  final String telephone;

  /// Vrai si le numéro a déjà un compte : le code ouvre la session.
  final bool connexion;

  @override
  State<CodeEcran> createState() => _CodeEcranState();
}

class _CodeEcranState extends State<CodeEcran> {
  final _code = TextEditingController();
  int _restant = 60;
  Timer? _minuterie;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _demarrer();
  }

  void _demarrer() {
    _minuterie?.cancel();
    _minuterie = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_restant <= 0) {
        t.cancel();
      } else {
        setState(() => _restant--);
      }
    });
  }

  @override
  void dispose() {
    _minuterie?.cancel();
    _code.dispose();
    super.dispose();
  }

  void _renvoyer() {
    final s = AppScope.read(context);
    if (essayer(context, () => s.envoyerCode(widget.telephone))) {
      _code.clear();
      setState(() {
        _restant = 60;
        _erreur = null;
      });
      _demarrer();
    }
  }

  void _valider() {
    final s = AppScope.read(context);
    if (_code.text.length != 6) {
      setState(() => _erreur = 'Saisissez les 6 chiffres reçus par SMS.');
      return;
    }
    final bool existe;
    try {
      existe = s.verifierCode(_code.text);
    } on ErreurMetier catch (e) {
      _code.clear();
      setState(() => _erreur = e.message);
      return;
    }
    setState(() => _erreur = null);
    if (existe) {
      message(context, 'Bon retour, ${s.prenom} !');
      retourAccueil(context);
    } else {
      ouvrir(context, const ProfilEcran(inscription: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final code = s.dernierCodeSms;
    return Ecran(
      children: [
        Piste(
          retour: true,
          children: [
            const SizedBox(height: 8),
            const Titre('Entrez le code reçu'),
            const SizedBox(height: 8),
            Text('Envoyé au +226 ${widget.telephone}', style: const TextStyle(fontSize: 15)),
          ],
        ),
        Zone(
          children: [
            if (code != null) _SmsSimule(code: code),
            if (widget.connexion)
              const Align(
                alignment: Alignment.centerLeft,
                child: Pastille(
                  'Ce numéro a déjà un compte : vous allez vous connecter',
                  ton: TonPastille.vert,
                  icon: Icons.check_rounded,
                ),
              ),
            CodeCases(controller: _code, longueur: 6, label: 'Code reçu par SMS', autofocus: true),
            if (_erreur != null)
              Semantics(
                liveRegion: true,
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: C.sos, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _erreur!,
                        style: const TextStyle(color: C.sos, fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: _restant > 0
                      ? Doux(
                          'Nouveau code dans ${_restant ~/ 60}:${(_restant % 60).toString().padLeft(2, '0')}',
                          taille: 14,
                        )
                      : Lien('Renvoyer le code', onTap: _renvoyer),
                ),
                const SizedBox(width: 8),
                Flexible(child: Lien('Changer de numéro', onTap: () => Navigator.pop(context))),
              ],
            ),
          ],
          bas: [Btn(widget.connexion ? 'Me connecter' : 'Valider', onPressed: _valider)],
        ),
      ],
    );
  }
}

/// SMS reçu, affiché tant qu'aucun fournisseur SMS n'est branché.
class _SmsSimule extends StatelessWidget {
  const _SmsSimule({required this.code});
  final String code;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    label: 'SMS reçu : votre code FasoCovoit est ${code.split('').join(' ')}',
    excludeSemantics: true,
    child: Carte.sombre(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.sms_outlined, color: C.etoile, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SMS · FasoCovoit',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: C.beige),
                ),
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    children: [
                      const TextSpan(text: 'Votre code FasoCovoit : '),
                      TextSpan(
                        text: '${code.substring(0, 3)} ${code.substring(3)}',
                        style: const TextStyle(fontWeight: FontWeight.w800, color: C.etoile, letterSpacing: 1),
                      ),
                      const TextSpan(text: '. Il expire dans 10 minutes. Ne le donnez à personne.'),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Simulation : aucun SMS réel n’est encore envoyé.',
                  style: TextStyle(fontSize: 12, color: C.beige2),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

/// 04 · Profil (A2) — aussi utilisé pour « Mes informations ».
class ProfilEcran extends StatefulWidget {
  const ProfilEcran({super.key, this.inscription = false});
  final bool inscription;

  @override
  State<ProfilEcran> createState() => _ProfilEcranState();
}

class _ProfilEcranState extends State<ProfilEcran> {
  late final AppState _s;
  late final TextEditingController _prenom;
  late final TextEditingController _nom;
  bool? _femme;

  @override
  void initState() {
    super.initState();
    _s = AppScope.read(context);
    _prenom = TextEditingController(text: _s.prenom);
    _nom = TextEditingController(text: _s.nom);
    _femme = widget.inscription && _s.prenom.isEmpty ? null : _s.femme;
  }

  @override
  void dispose() {
    _prenom.dispose();
    _nom.dispose();
    super.dispose();
  }

  void _continuer() {
    if (_prenom.text.trim().isEmpty) {
      message(context, 'Indiquez votre prénom.');
      return;
    }
    if (_femme == null) {
      message(context, 'Indiquez votre genre.');
      return;
    }
    _s.majProfil(prenom: _prenom.text, nom: _nom.text, femme: _femme);
    if (widget.inscription) {
      ouvrir(context, const UrgenceEcran(inscription: true));
    } else {
      Navigator.pop(context);
      message(context, 'Informations enregistrées.');
    }
  }

  Widget _genre(String label, bool femme) => Expanded(
    child: Choix(
      on: _femme == femme,
      anneau: false,
      onTap: () => setState(() => _femme = femme),
      children: [
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Ecran(
    children: [
      if (widget.inscription)
        const Piste(
          children: [
            Text('Étape 1 sur 2', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            SizedBox(height: 6),
            Titre('Faisons connaissance'),
          ],
        )
      else
        const Barre(titre: 'Mes informations'),
      Zone(
        children: [
          Column(
            children: [
              const BoutonPhotoProfil(),
              const SizedBox(height: 8),
              const Doux('Prenez ou importez une photo, visage bien visible', taille: 14),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Etiq('Prénom'),
              const SizedBox(height: 8),
              Champ(controller: _prenom, label: 'Prénom'),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Etiq('Nom'),
              const SizedBox(height: 8),
              Champ(controller: _nom, label: 'Nom'),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Etiq('Genre'),
              const SizedBox(height: 8),
              Row(children: [_genre('Femme', true), const SizedBox(width: 8), _genre('Homme', false)]),
              const SizedBox(height: 8),
              const Doux("Sert à l'option « Entre femmes ». Non affiché sur votre profil."),
            ],
          ),
          Btn(widget.inscription ? 'Continuer' : 'Enregistrer', onPressed: _continuer),
        ],
      ),
    ],
  );
}

/// Photo de profil : appuyer pour prendre, importer ou retirer la photo.
class BoutonPhotoProfil extends StatelessWidget {
  const BoutonPhotoProfil({super.key, this.taille = 84, this.initiales = false});
  final double taille;

  /// Sans photo : afficher les initiales plutôt que le cercle « ajouter ».
  final bool initiales;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    Future<void> changer() async {
      final choix = await demanderPhoto(context, titre: 'Photo de profil', selfie: true, peutRetirer: s.photo != null);
      if (choix == null) return;
      s.majPhoto(choix.octets);
    }

    return Semantics(
      button: true,
      label: s.photo == null ? 'Ajouter une photo de profil' : 'Changer la photo de profil',
      excludeSemantics: true,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: changer,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (s.photo != null || initiales)
              PhotoRonde(
                photo: s.photo,
                initiales: s.moi.initiales,
                taille: taille,
                fond: C.surface,
                texte: C.lateriteF,
              )
            else
              CustomPaint(
                painter: _CerclePointille(),
                child: SizedBox(width: taille, height: taille, child: const Icon(Icons.add_a_photo_outlined, size: 30)),
              ),
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: C.laterite,
                  shape: BoxShape.circle,
                  border: Border.all(color: C.surface, width: 2),
                ),
                child: const Icon(Icons.photo_camera_outlined, size: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CerclePointille extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    canvas.drawCircle(Offset(r, r), r, Paint()..color = C.surface);
    final p = Paint()
      ..color = C.laterite
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    const n = 20;
    for (var i = 0; i < n; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(r, r), radius: r - 1.5),
        i * 2 * 3.14159 / n,
        3.14159 / n,
        false,
        p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 05 · Contact d'urgence (A3) — aussi utilisé depuis le profil.
class UrgenceEcran extends StatefulWidget {
  const UrgenceEcran({super.key, this.inscription = false});
  final bool inscription;

  @override
  State<UrgenceEcran> createState() => _UrgenceEcranState();
}

class _UrgenceEcranState extends State<UrgenceEcran> {
  static const _liens = ['Maman', 'Papa', 'Frère / sœur', 'Conjoint(e)', 'Ami(e)'];
  late final AppState _s;
  late final TextEditingController _nom;
  late final TextEditingController _tel;
  late String _lien;

  @override
  void initState() {
    super.initState();
    _s = AppScope.read(context);
    _nom = TextEditingController(text: _s.urgenceNom);
    _tel = TextEditingController(text: _s.urgenceTel);
    _lien = _s.urgenceLien;
  }

  @override
  void dispose() {
    _nom.dispose();
    _tel.dispose();
    super.dispose();
  }

  void _terminer() {
    if (_nom.text.trim().isEmpty || AppState.chiffres(_tel.text).length < 8) {
      message(context, 'Indiquez le nom et le numéro de votre contact.');
      return;
    }
    _s.majUrgence(_nom.text, _tel.text, _lien);
    if (widget.inscription) {
      _s.connecter(choisirEspace: true);
      retourAccueil(context);
    } else {
      Navigator.pop(context);
      message(context, 'Contact d’urgence enregistré.');
    }
  }

  @override
  Widget build(BuildContext context) => Ecran(
    children: [
      if (widget.inscription)
        const Piste(
          children: [
            Text('Étape 2 sur 2', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            SizedBox(height: 6),
            Titre('Qui prévenir en cas de problème ?'),
          ],
        )
      else
        const Barre(titre: "Contact d'urgence"),
      Zone(
        children: [
          const Bandeau(
            'Si vous appuyez sur SOS pendant un trajet, cette personne reçoit un SMS avec votre position.',
            icon: Icons.warning_amber_rounded,
            ton: TonPastille.sos,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Etiq('Nom du contact'),
              const SizedBox(height: 8),
              Champ(controller: _nom, label: 'Nom du contact'),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Etiq('Son numéro'),
              const SizedBox(height: 8),
              Champ(controller: _tel, clavier: TextInputType.phone, hint: '+226 76 00 00 00', label: 'Son numéro'),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Etiq('Lien'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [for (final l in _liens) Puce(l, on: _lien == l, onTap: () => setState(() => _lien = l))],
              ),
            ],
          ),
        ],
        bas: [
          Btn(widget.inscription ? 'Terminer' : 'Enregistrer', onPressed: _terminer),
          if (widget.inscription)
            Lien(
              'Plus tard',
              couleur: C.doux,
              souligne: false,
              onTap: () {
                _s.connecter(choisirEspace: true);
                retourAccueil(context);
              },
            ),
        ],
      ),
    ],
  );
}

/// À l'entrée : passager ou conducteur. Être passager n'est pas obligatoire,
/// un conducteur va directement dans son espace.
class ChoixEspaceEcran extends StatelessWidget {
  const ChoixEspaceEcran({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    Widget option({
      required IconData icone,
      required String titre,
      required String sous,
      required Color fond,
      required Color encre,
      required Mode espace,
    }) => Semantics(
      button: true,
      label: '$titre. $sous',
      excludeSemantics: true,
      child: Carte(
        // Côté conducteur, la première fois : la fiche « Mode conducteur ».
        onTap: () =>
            espace == Mode.conducteur ? entrerModeConducteur(context) : changerEspace(context, Mode.passager),
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(color: fond, shape: BoxShape.circle),
              child: Icon(icone, size: 28, color: encre),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titre, style: T.titre(20)),
                  const SizedBox(height: 4),
                  Doux(sous, taille: 14),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
    return Ecran(
      children: [
        Piste(
          paddingBas: 30,
          children: [
            Text(
              s.prenom.isEmpty ? 'Bienvenue' : 'Bienvenue, ${s.prenom}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Titre('Comment utilisez-vous FasoCovoit ?'),
            const SizedBox(height: 8),
            const Text('Vous pourrez passer de l’un à l’autre à tout moment.', style: TextStyle(fontSize: 15)),
          ],
        ),
        Zone(
          children: [
            option(
              icone: Icons.person_outline_rounded,
              titre: 'Je cherche un trajet',
              sous: 'Passager : une place en ville ou entre villes, le jour et à l’heure de votre choix.',
              fond: C.lateriteC,
              encre: C.lateriteF,
              espace: Mode.passager,
            ),
            option(
              icone: Icons.directions_car_outlined,
              titre: 'Je propose mes trajets',
              sous: s.estConducteur
                  ? 'Conducteur : votre compte est actif.'
                  : 'Conducteur : partagez vos frais, sans avoir à être passager. Inscription en 3 étapes.',
              fond: C.etoile,
              encre: C.encre,
              espace: Mode.conducteur,
            ),
            const Bandeau(
              'Les passagers inscrits et leurs demandes sont visibles par les conducteurs. '
              'Ceux qui passent par là sont alertés et choisissent les courses qui leur conviennent.',
              icon: Icons.notifications_active_outlined,
              ton: TonPastille.etoile,
            ),
          ],
        ),
      ],
    );
  }
}

/// 22 · Supprimer le compte (A6)
class SupprimerEcran extends StatefulWidget {
  const SupprimerEcran({super.key});

  @override
  State<SupprimerEcran> createState() => _SupprimerEcranState();
}

class _SupprimerEcranState extends State<SupprimerEcran> {
  bool _compris = false;

  Future<void> _supprimer() async {
    final ok = await confirmer(
      context,
      titre: 'Supprimer définitivement ?',
      texte:
          'Un code SMS vous sera demandé pour confirmer. Dans ce prototype, le compte est '
          'effacé de la session ; le compte de démonstration est remis à zéro.',
      oui: 'Supprimer',
      non: 'Garder mon compte',
      danger: true,
    );
    if (!ok || !mounted) return;
    AppScope.read(context).supprimerCompte();
    retourAccueil(context);
  }

  @override
  Widget build(BuildContext context) => Ecran(
    children: [
      const Barre(titre: 'Supprimer mon compte'),
      Zone(
        gap: 14,
        children: [
          const Titre('Vous partez ? Voici ce qui se passe.'),
          const Carte(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.delete_outline_rounded, color: C.sos, size: 22),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: 'Supprimé tout de suite\n', style: T.gras),
                            TextSpan(
                              text: "Profil, photo, contact d'urgence, messages, trajets réguliers.",
                              style: TextStyle(fontSize: 14, color: C.doux),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Sep(),
                SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lock_outline_rounded, size: 22),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: 'Gardé puis effacé\n', style: T.gras),
                            TextSpan(
                              text:
                                  'Paiements (durée légale comptable), signalements (1 an), pour la sécurité et la loi.',
                              style: TextStyle(fontSize: 14, color: C.doux),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Bandeau(
            'Vos réservations à venir seront annulées selon les règles habituelles.',
            icon: Icons.warning_amber_rounded,
            ton: TonPastille.etoile,
          ),
          LigneCase(
            carte: false,
            value: _compris,
            onChanged: (v) => setState(() => _compris = v),
            child: const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text('Je comprends que cette action est définitive.', style: T.petit),
            ),
          ),
        ],
        bas: [
          const Doux('Un code SMS vous sera demandé pour confirmer.', align: TextAlign.center),
          Btn.sos('Supprimer définitivement', onPressed: _compris ? _supprimer : null),
          BtnClair('Garder mon compte', onPressed: () => Navigator.pop(context)),
        ],
      ),
    ],
  );
}
