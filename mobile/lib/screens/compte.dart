import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../model.dart';
import '../painters.dart';
import '../theme.dart';
import '../ui.dart';

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
                        Semantics(
                          header: true,
                          child: Text(
                            'On fait la route ensemble.',
                            style: T.titre(44, color: Colors.white).copyWith(height: 1.02),
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
            padding: EdgeInsets.fromLTRB(20, 22, 20, 26 + bas),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Btn('Commencer', onPressed: () => ouvrir(context, const NumeroEcran(nouveau: true))),
                const SizedBox(height: 12),
                BtnClair(
                  "J'ai déjà un compte",
                  onPressed: () => ouvrir(context, const NumeroEcran(nouveau: false)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 02 · Numéro de téléphone (A1)
class NumeroEcran extends StatefulWidget {
  const NumeroEcran({super.key, required this.nouveau});
  final bool nouveau;

  @override
  State<NumeroEcran> createState() => _NumeroEcranState();
}

class _NumeroEcranState extends State<NumeroEcran> {
  late final TextEditingController _tel;

  @override
  void initState() {
    super.initState();
    _tel = TextEditingController(text: AppScope.read(context).telephone);
  }

  @override
  void dispose() {
    _tel.dispose();
    super.dispose();
  }

  void _envoyer() {
    final chiffres = _tel.text.replaceAll(RegExp(r'\D'), '');
    if (chiffres.length != 8) {
      message(context, 'Saisissez les 8 chiffres de votre numéro.');
      return;
    }
    final formate = [for (var i = 0; i < 8; i += 2) chiffres.substring(i, i + 2)].join(' ');
    AppScope.read(context).telephone = formate;
    ouvrir(context, CodeEcran(nouveau: widget.nouveau, telephone: formate));
  }

  @override
  Widget build(BuildContext context) => Ecran(
    children: [
      const Piste(
        retour: true,
        children: [
          SizedBox(height: 8),
          Titre('Quel est votre numéro ?'),
          SizedBox(height: 8),
          Text('Pas de mot de passe : on vous envoie un code par SMS.', style: TextStyle(fontSize: 15)),
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
  const CodeEcran({super.key, required this.nouveau, required this.telephone});
  final bool nouveau;
  final String telephone;

  @override
  State<CodeEcran> createState() => _CodeEcranState();
}

class _CodeEcranState extends State<CodeEcran> {
  final _code = TextEditingController();
  int _restant = 42;
  Timer? _minuterie;

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

  void _valider() {
    if (_code.text.length != 6) {
      message(context, 'Saisissez les 6 chiffres reçus par SMS.');
      return;
    }
    if (widget.nouveau) {
      ouvrir(context, const ProfilEcran(inscription: true));
    } else {
      AppScope.read(context).connecter();
      retourAccueil(context);
    }
  }

  @override
  Widget build(BuildContext context) => Ecran(
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
          CodeCases(controller: _code, longueur: 6, label: 'Code reçu par SMS', autofocus: true),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: _restant > 0
                    ? Doux('Nouveau code dans 0:${_restant.toString().padLeft(2, '0')}', taille: 14)
                    : Lien(
                        'Renvoyer le code',
                        onTap: () {
                          setState(() => _restant = 60);
                          _demarrer();
                          message(context, 'Nouveau code envoyé.');
                        },
                      ),
              ),
              const SizedBox(width: 8),
              Flexible(child: Lien('Changer de numéro', onTap: () => Navigator.pop(context))),
            ],
          ),
          const Doux('Prototype : n’importe quel code à 6 chiffres est accepté.'),
        ],
        bas: [Btn('Valider', onPressed: _valider)],
      ),
    ],
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
  late bool _femme;

  @override
  void initState() {
    super.initState();
    _s = AppScope.read(context);
    _prenom = TextEditingController(text: _s.prenom);
    _nom = TextEditingController(text: _s.nom);
    _femme = _s.femme;
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
              Semantics(
                button: true,
                label: 'Prendre une photo',
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => message(context, 'La photo se prendra avec l’appareil photo du téléphone.'),
                  child: CustomPaint(
                    painter: _CerclePointille(),
                    child: const SizedBox(
                      width: 84,
                      height: 84,
                      child: Icon(Icons.photo_camera_outlined, size: 30),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Doux("Photo prise avec l'appli, visage bien visible", taille: 14),
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
    if (_nom.text.trim().isEmpty || _tel.text.replaceAll(RegExp(r'\D'), '').length < 8) {
      message(context, 'Indiquez le nom et le numéro de votre contact.');
      return;
    }
    _s.majUrgence(_nom.text, _tel.text, _lien);
    if (widget.inscription) {
      _s.connecter();
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
              Champ(controller: _tel, clavier: TextInputType.phone, label: 'Son numéro'),
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
                children: [
                  for (final l in _liens)
                    Puce(l, on: _lien == l, onTap: () => setState(() => _lien = l)),
                ],
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
                _s.connecter();
                retourAccueil(context);
              },
            ),
        ],
      ),
    ],
  );
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
      texte: 'Un code SMS vous sera demandé pour confirmer. Dans ce prototype, '
          'la suppression remet l’application à zéro.',
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
                              text: 'Paiements (durée légale comptable), signalements (1 an), pour la sécurité et la loi.',
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
