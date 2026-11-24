import 'package:flutter/material.dart';

import '../formats.dart';
import '../model.dart';
import '../painters.dart';
import '../theme.dart';
import '../ui.dart';
import 'compte.dart';
import 'devenir.dart';
import 'passager.dart';
import 'portefeuille.dart';

String _horodatage(DateTime d, DateTime maintenant) {
  switch (ecartJours(d, maintenant)) {
    case 0:
      return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    case -1:
      return 'Hier';
    default:
      return dateCourte(d);
  }
}

// ---------------------------------------------------------------------------
// 18 · Messages (D1)
// ---------------------------------------------------------------------------

class MessagesOnglet extends StatelessWidget {
  const MessagesOnglet({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final convs = [...s.conversations]
      ..sort((a, b) {
        final da = a.messages.isEmpty ? DateTime(2000) : a.messages.last.date;
        final db = b.messages.isEmpty ? DateTime(2000) : b.messages.last.date;
        return db.compareTo(da);
      });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Piste(
          paddingBas: 30,
          children: [Titre('Messages'), Text('Votre numéro reste masqué', style: T.petit)],
        ),
        Zone(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
          children: [
            ListeCarte(
              children: [
                for (final c in convs)
                  LigneListe(
                    onTap: () => ouvrir(context, ConversationEcran(conversation: c)),
                    children: [
                      c.equipe ? const Ava('FC') : Ava(c.avec.initiales, ton: c.avec.ton),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(child: Text(c.equipe ? 'Équipe FasoCovoit' : c.avec.court, style: T.gras)),
                                if (c.messages.isNotEmpty) Doux(_horodatage(c.messages.last.date, s.maintenant)),
                              ],
                            ),
                            Text(
                              c.contexte,
                              style: const TextStyle(fontSize: 13, color: C.lateriteF, fontWeight: FontWeight.w700),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    c.messages.isEmpty ? 'Écrivez le premier message' : c.messages.last.texte,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 14, color: C.doux),
                                  ),
                                ),
                                if (c.nonLus > 0)
                                  Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    constraints: const BoxConstraints(minWidth: 22),
                                    height: 22,
                                    alignment: Alignment.center,
                                    decoration: const BoxDecoration(color: C.vert, shape: BoxShape.circle),
                                    child: Text(
                                      '${c.nonLus}',
                                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const Doux("Les messages s'ouvrent après une réservation et se ferment 72 h après le trajet."),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 19 · Conversation (D1)
// ---------------------------------------------------------------------------

class ConversationEcran extends StatefulWidget {
  const ConversationEcran({super.key, required this.conversation});
  final Conversation conversation;

  @override
  State<ConversationEcran> createState() => _ConversationEcranState();
}

class _ConversationEcranState extends State<ConversationEcran> {
  final _texte = TextEditingController();
  final _defil = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppScope.read(context).lireConversation(widget.conversation);
      _enBas();
    });
  }

  @override
  void dispose() {
    _texte.dispose();
    _defil.dispose();
    super.dispose();
  }

  void _enBas() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_defil.hasClients) _defil.jumpTo(_defil.position.maxScrollExtent);
    });
  }

  void _envoyer(String texte) {
    if (texte.trim().isEmpty) return;
    AppScope.read(context).envoyerMessage(widget.conversation, texte);
    _texte.clear();
    _enBas();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final c = widget.conversation;
    final rapides = c.equipe
        ? const ['Question sur un paiement', 'Question sur un trajet', 'Merci !']
        : [s.femme ? 'Je suis arrivée' : 'Je suis arrivé', "J'ai 5 min de retard", 'Où êtes-vous ?'];
    return Ecran(
      children: [
        Barre(
          titre: c.equipe ? 'Équipe FasoCovoit' : c.avec.court,
          sousTitre: c.contexte,
          leading: c.equipe ? const Ava('FC', taille: 40) : Ava(c.avec.initiales, ton: c.avec.ton, taille: 40),
          actions: [
            if (c.verifie) Verifie(femme: c.avec.femme),
            IconeBtn(
              icon: Icons.phone_outlined,
              label: "Appeler par l'application",
              onTap: () => informer(
                context,
                'Appel par l’application',
                'Votre numéro reste masqué. Prototype : l’appel n’est pas encore branché.',
              ),
            ),
          ],
        ),
        Expanded(
          child: ListView(
            controller: _defil,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            children: [
              if (c.messages.isEmpty)
                const Doux('Aucun message pour l’instant.', align: TextAlign.center),
              for (var i = 0; i < c.messages.length; i++) ...[
                if (i == 0 || ecartJours(c.messages[i].date, c.messages[i - 1].date) != 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Doux(jourRelatif(c.messages[i].date, s.maintenant), align: TextAlign.center),
                  ),
                _Bulle(c.messages[i]),
                const SizedBox(height: 10),
              ],
              if (c.messages.isNotEmpty) Doux(_horodatage(c.messages.last.date, s.maintenant)),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(12, 10, 12, 16 + MediaQuery.paddingOf(context).bottom),
          decoration: const BoxDecoration(
            color: C.surface,
            border: Border(top: BorderSide(color: C.trait, width: 1.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: espacer([
                    for (final r in rapides)
                      Material(
                        color: C.surface,
                        shape: const StadiumBorder(side: BorderSide(color: C.trait, width: 1.5)),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => _envoyer(r),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                            child: Text(r, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ),
                  ], 8),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Champ(
                      controller: _texte,
                      hint: 'Écrire un message',
                      rond: 999,
                      hauteur: 50,
                      label: 'Votre message',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: C.vert,
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => _envoyer(_texte.text),
                      child: const SizedBox(
                        width: 50,
                        height: 50,
                        child: Icon(Icons.send_rounded, color: Colors.white, size: 22, semanticLabel: 'Envoyer'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Bulle extends StatelessWidget {
  const _Bulle(this.m);
  final Message m;

  @override
  Widget build(BuildContext context) => Align(
    alignment: m.moi ? Alignment.centerRight : Alignment.centerLeft,
    child: FractionallySizedBox(
      widthFactor: .78,
      alignment: m.moi ? Alignment.centerRight : Alignment.centerLeft,
      child: Align(
        alignment: m.moi ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: m.moi ? C.vert : C.surface,
            border: m.moi ? null : Border.all(color: C.trait, width: 1.5),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(m.moi ? 18 : 4),
              bottomRight: Radius.circular(m.moi ? 4 : 18),
            ),
          ),
          child: Text(m.texte, style: TextStyle(color: m.moi ? Colors.white : C.encre)),
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// 20 · Notifications (D2)
// ---------------------------------------------------------------------------

class NotificationsEcran extends StatelessWidget {
  const NotificationsEcran({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final groupes = <String, List<Notif>>{};
    for (final n in s.notifications) {
      final e = ecartJours(n.date, s.maintenant);
      final cle = e >= 0 ? "Aujourd'hui" : (e >= -7 ? 'Cette semaine' : 'Plus tôt');
      groupes.putIfAbsent(cle, () => []).add(n);
    }
    return Ecran(
      children: [
        Barre(
          titre: 'Notifications',
          actions: [Lien('Tout lu', onTap: s.notificationsNonLues == 0 ? null : s.toutLu)],
        ),
        Zone(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          children: [
            if (s.notifications.isEmpty) const Carte(child: Text('Aucune notification.', style: T.petit)),
            for (final e in groupes.entries) ...[
              Doux(e.key, taille: 14, gras: true),
              ListeCarte(
                children: [
                  for (final n in e.value)
                    LigneListe(
                      haut: true,
                      children: [
                        _iconeNotif(n.type),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(n.titre, style: T.gras),
                              const SizedBox(height: 4),
                              Doux(n.texte, taille: 14),
                              const SizedBox(height: 4),
                              Doux(_horodatage(n.date, s.maintenant)),
                            ],
                          ),
                        ),
                        if (!n.lue)
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(color: C.laterite, shape: BoxShape.circle),
                          ),
                      ],
                    ),
                ],
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _iconeNotif(TypeNotif t) => switch (t) {
    TypeNotif.acceptee => const IconeCarre(Icons.check_rounded, fond: C.vertC, couleur: C.vertF),
    TypeNotif.rappel => const IconeCarre(Icons.schedule_rounded, fond: C.etoileC, couleur: C.etoileF),
    TypeNotif.arrive => const IconeCarre(Icons.directions_car_outlined, fond: C.lateriteC, couleur: C.lateriteF),
    TypeNotif.annulee => const IconeCarre(Icons.close_rounded),
    TypeNotif.rembourse => const IconeCarre(Icons.account_balance_wallet_outlined, fond: C.vertC, couleur: C.vertF),
    TypeNotif.info => const IconeCarre(Icons.info_outline_rounded),
  };
}

// ---------------------------------------------------------------------------
// 21 · Profil et réglages
// ---------------------------------------------------------------------------

class ProfilOnglet extends StatelessWidget {
  const ProfilOnglet({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    Widget ligne(IconData icon, String titre, {String? sous, VoidCallback? onTap, Color? couleur, int badge = 0}) =>
        LigneListe(
          onTap: onTap,
          children: [
            Icon(icon, size: 22, color: couleur),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titre, style: T.gras.copyWith(color: couleur)),
                  if (sous != null) Doux(sous),
                ],
              ),
            ),
            if (badge > 0) Pastille('$badge', ton: TonPastille.lat),
            if (couleur == null) const Icon(Icons.chevron_right_rounded, size: 20),
          ],
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Piste(
          paddingBas: 32,
          children: [
            Row(
              children: [
                Ava(s.moi.initiales, taille: 84, fond: C.surface, texte: C.lateriteF),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Titre(s.moi.complet),
                      const SizedBox(height: 4),
                      if (s.trajetsPassager == 0)
                        Text(s.femme ? 'Nouvelle membre' : 'Nouveau membre', style: T.petit)
                      else
                        Row(
                          children: [
                            NoteEtoile(s.notePassager, couleur: Colors.white),
                            Text(' · ${pluriel(s.trajetsPassager, 'trajet')}', style: T.petit),
                          ],
                        ),
                      const SizedBox(height: 4),
                      const Pastille(
                        'Numéro vérifié',
                        icon: Icons.verified_user_outlined,
                        fond: C.surface,
                        texte: C.vertF,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        Zone(
          gap: 12,
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
          children: [
            Carte.sombre(
              onTap: () => s.estConducteur
                  ? s.basculerMode(Mode.conducteur)
                  : ouvrir(context, const DevenirIntroEcran()),
              child: Row(
                children: [
                  const Icon(Icons.directions_car_outlined, color: C.etoile, size: 28),
                  const SizedBox(width: 12),
                  Bloc(
                    s.estConducteur ? 'Mode conducteur' : (s.femme ? 'Devenir conductrice' : 'Devenir conducteur'),
                    s.estConducteur ? 'Vos trajets publiés et vos gains' : 'Partagez vos trajets et vos frais',
                    C.beige,
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
            ListeCarte(
              children: [
                ligne(Icons.person_outline_rounded, 'Mes informations', sous: 'Nom, photo, genre', onTap: () => ouvrir(context, const ProfilEcran())),
                ligne(
                  Icons.warning_amber_rounded,
                  "Contact d'urgence",
                  sous: !s.aUrgence
                      ? 'À renseigner'
                      : (s.urgenceLien.isEmpty ? s.urgenceNom : '${s.urgenceNom} · ${s.urgenceLien}'),
                  onTap: () => ouvrir(context, const UrgenceEcran()),
                ),
                ligne(
                  Icons.notifications_none_rounded,
                  'Notifications',
                  badge: s.notificationsNonLues,
                  onTap: () => ouvrir(context, const NotificationsEcran()),
                ),
                ligne(
                  Icons.account_balance_wallet_outlined,
                  'Mon portefeuille',
                  sous: '${fcfa(s.solde)}${s.bonus > 0 ? ', dont ${fcfa(s.bonus)} de bonus' : ''}',
                  onTap: () => ouvrir(context, const PortefeuilleEcran()),
                ),
                ligne(
                  Icons.star_outline_rounded,
                  'Parrainage',
                  sous: 'Code ${s.codeParrainage} · 500 F par ami',
                  onTap: () => ouvrir(context, const ParrainageEcran()),
                ),
              ],
            ),
            ListeCarte(
              children: [
                ligne(Icons.description_outlined, "Règles d'annulation", onTap: () => ouvrir(context, const ReglesAnnulationEcran())),
                ligne(
                  Icons.verified_user_outlined,
                  'Conditions et confidentialité',
                  onTap: () => ouvrir(context, const PageTexteEcran.conditions()),
                ),
                ligne(
                  Icons.chat_bubble_outline_rounded,
                  "Aide : écrire à l'équipe",
                  onTap: () => ouvrir(context, ConversationEcran(conversation: s.conversationEquipe)),
                ),
              ],
            ),
            ListeCarte(
              children: [
                ligne(Icons.logout_rounded, 'Se déconnecter', onTap: () async {
                  final ok = await confirmer(
                    context,
                    titre: 'Se déconnecter ?',
                    texte: 'Vous pourrez revenir avec votre numéro et un code SMS.',
                    oui: 'Se déconnecter',
                  );
                  if (ok) s.deconnecter();
                }),
                ligne(
                  Icons.delete_outline_rounded,
                  'Supprimer mon compte',
                  couleur: C.sos,
                  onTap: () => ouvrir(context, const SupprimerEcran()),
                ),
              ],
            ),
            const Center(child: Etoile(size: 18, color: C.trait)),
          ],
        ),
      ],
    );
  }
}

/// Page de texte simple (conditions, charte du conducteur).
class PageTexteEcran extends StatelessWidget {
  const PageTexteEcran({super.key, required this.titre, required this.paragraphes});

  const PageTexteEcran.conditions({super.key})
    : titre = 'Conditions et confidentialité',
      paragraphes = const [
        ('Ce que nous gardons', 'Votre numéro, votre nom, votre photo et votre contact d’urgence. Vos documents de conducteur sont stockés dans un espace privé, visible seulement par l’équipe de validation.'),
        ('Ce que voient les autres', 'Votre prénom, l’initiale de votre nom, votre photo et votre note. Jamais votre numéro : les appels et messages passent par l’application.'),
        ('Prix plafonnés', 'Le conducteur partage ses frais de carburant, il ne fait pas de bénéfice. Les plafonds sont fixés par l’équipe.'),
        ('Prototype', 'Cette version est une démonstration : aucun paiement, SMS, appel ou alerte n’est réellement envoyé. Ne saisissez pas de données personnelles réelles.'),
      ];

  const PageTexteEcran.charte({super.key})
    : titre = 'Charte du conducteur',
      paragraphes = const [
        ('Zéro alcool', 'Pas d’alcool ni de produit qui altère la conduite, avant et pendant un trajet.'),
        ('Respect des passagers', 'Ponctualité, politesse, conduite prudente, pas de téléphone en conduisant.'),
        ('Documents à jour', 'Permis, assurance et carte grise valides. Un document expiré suspend le compte.'),
        ('Partage de frais', 'Le prix couvre vos frais : il reste sous le plafond fixé par FasoCovoit.'),
      ];

  final String titre;
  final List<(String, String)> paragraphes;

  @override
  Widget build(BuildContext context) => Ecran(
    children: [
      Barre(titre: titre),
      Zone(
        gap: 14,
        children: [
          for (final (t, p) in paragraphes)
            Carte(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [Text(t, style: T.gras), const SizedBox(height: 6), Doux(p, taille: 14)],
              ),
            ),
        ],
      ),
    ],
  );
}
