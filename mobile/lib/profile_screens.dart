import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.onPublish});

  final VoidCallback onPublish;

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Text(
        'Mon espace',
        style: Theme.of(
          context,
        ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 16),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: const Text(
                  'FC',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profil de démonstration',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text('Compte non connecté · identité non vérifiée'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 20),
      const _SectionTitle('DÉCOUVRIR'),
      _ProfileAction(
        icon: Icons.route_outlined,
        title: 'Comment ça marche ?',
        subtitle: 'Les étapes d’un trajet partagé',
        onTap: () => _open(context, const HowItWorksScreen()),
      ),
      const _SectionTitle('AIDE ET SÉCURITÉ'),
      _ProfileAction(
        icon: Icons.help_outline,
        title: 'Centre d’aide',
        subtitle: 'Questions fréquentes et informations',
        onTap: () => _open(context, const HelpCenterScreen()),
      ),
      _ProfileAction(
        icon: Icons.shield_outlined,
        title: 'Centre de sécurité',
        subtitle: 'Conseils et limites de la démonstration',
        onTap: () => _open(context, const SafetyCenterScreen()),
      ),
      const _SectionTitle('ESPACE CONDUCTEUR'),
      _ProfileAction(
        icon: Icons.directions_car_outlined,
        title: 'Proposer un trajet',
        subtitle: 'Publication fictive, sans compte conducteur',
        onTap: onPublish,
      ),
      const _SectionTitle('CONFIDENTIALITÉ'),
      _ProfileAction(
        icon: Icons.privacy_tip_outlined,
        title: 'Données et confidentialité',
        subtitle: 'Ce que cette maquette enregistre — ou non',
        onTap: () => _open(context, const PrivacyScreen()),
      ),
      const SizedBox(height: 16),
      const Center(
        child: Text(
          'FasoCovoit · version de démonstration',
          style: TextStyle(color: Colors.black54, fontSize: 12),
        ),
      ),
    ],
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 6, left: 4),
    child: Text(
      title,
      style: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.bold,
        fontSize: 12,
        letterSpacing: 0.6,
      ),
    ),
  );
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    ),
  );
}

class HowItWorksScreen extends StatefulWidget {
  const HowItWorksScreen({super.key});

  @override
  State<HowItWorksScreen> createState() => _HowItWorksScreenState();
}

class _HowItWorksScreenState extends State<HowItWorksScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _steps = [
    (
      icon: Icons.search,
      title: 'Trouvez un trajet',
      description:
          'Choisissez les villes, la date et le nombre de places souhaités.',
    ),
    (
      icon: Icons.fact_check_outlined,
      title: 'Vérifiez les détails',
      description:
          'Comparez les horaires, le point de rendez-vous, les places et le prix affiché.',
    ),
    (
      icon: Icons.people_outline,
      title: 'Préparez le voyage',
      description:
          'Dans un vrai service, les informations du conducteur et les règles de réservation devront être vérifiées.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final finalPage = _page == _steps.length - 1;
    return Scaffold(
      appBar: AppBar(title: const Text('Comment ça marche ?')),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: _steps.length,
              onPageChanged: (page) => setState(() => _page = page),
              itemBuilder: (context, index) {
                final step = _steps[index];
                return Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        step.icon,
                        size: 76,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 32),
                      Text(
                        '${index + 1} / ${_steps.length}',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        step.title,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        step.description,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              children: [
                Text(
                  'Maquette uniquement : aucun trajet ni paiement réel.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      if (finalPage) {
                        Navigator.pop(context);
                      } else {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                        );
                      }
                    },
                    child: Text(finalPage ? 'Terminer' : 'Suivant'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  static const _questions = [
    (
      question: 'Comment trouver un trajet ?',
      answer:
          'Dans Rechercher, indiquez le départ, la destination, la date et le nombre de passagers, puis consultez les trajets proposés.',
    ),
    (
      question: 'Une réservation est-elle réelle ?',
      answer:
          'Non. Cette version est une démonstration locale. Elle ne contacte aucun conducteur et ne réserve aucune place réelle.',
    ),
    (
      question: 'Comment publier un trajet ?',
      answer:
          'Ouvrez Publier, indiquez un itinéraire, une date, l’heure, les places et un prix fictif. La publication ne sera visible que dans cette session.',
    ),
    (
      question: 'Les conducteurs et leurs documents sont-ils vérifiés ?',
      answer:
          'Non. Les profils sont des exemples et aucune pièce d’identité, assurance ou carte grise n’est vérifiée dans cette maquette.',
    ),
    (
      question: 'Puis-je payer avec Orange Money ou Moov Money ?',
      answer:
          'Non. Aucun paiement, transfert d’argent ou remboursement n’est connecté. Ne communiquez pas de code secret ni d’information financière.',
    ),
    (
      question: 'Quelles sont les règles d’annulation ?',
      answer:
          'Les règles de remboursement restent à définir. Annuler ici supprime seulement une réservation de démonstration.',
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Centre d’aide')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Questions fréquentes',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text('Informations sur la maquette FasoCovoit.'),
        const SizedBox(height: 16),
        ..._questions.map(
          (item) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ExpansionTile(
              title: Text(
                item.question,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [Text(item.answer)],
            ),
          ),
        ),
        const SizedBox(height: 8),
        const _DemoCallout(
          text:
              'Le support n’est pas connecté dans cette version. N’utilisez pas la maquette pour organiser un vrai trajet.',
        ),
      ],
    ),
  );
}

class SafetyCenterScreen extends StatelessWidget {
  const SafetyCenterScreen({super.key});

  void _report(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const IncidentReportScreen()),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Centre de sécurité')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const _DemoCallout(
          text:
              'Cette maquette n’est pas surveillée : elle ne peut pas recevoir d’alerte, localiser un trajet ou appeler les secours.',
        ),
        const SizedBox(height: 16),
        const _SafetyTip(
          icon: Icons.verified_user_outlined,
          title: 'Vérifiez les informations',
          text:
              'Avant un vrai trajet, il faudrait pouvoir contrôler le profil du conducteur, son véhicule et le point de rendez-vous.',
        ),
        const _SafetyTip(
          icon: Icons.share_outlined,
          title: 'Prévenez un proche',
          text:
              'Dans un service opérationnel, un partage de trajet devrait expliquer qui reçoit le lien et pendant combien de temps il fonctionne.',
        ),
        const _SafetyTip(
          icon: Icons.lock_outline,
          title: 'Gardez vos informations privées',
          text:
              'Ne partagez pas de pièce d’identité, d’adresse, de numéro de téléphone ni de code de paiement dans cette démonstration.',
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => _report(context),
          icon: const Icon(Icons.flag_outlined),
          label: const Text('Signaler un problème (démo)'),
        ),
        const SizedBox(height: 12),
        const Text(
          'En cas de danger immédiat, ne comptez pas sur cette application : contactez directement les services d’urgence compétents ou une personne de confiance.',
          style: TextStyle(fontSize: 13),
        ),
      ],
    ),
  );
}

class _SafetyTip extends StatelessWidget {
  const _SafetyTip({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Text(text),
      ),
      isThreeLine: true,
    ),
  );
}

class IncidentReportScreen extends StatefulWidget {
  const IncidentReportScreen({super.key});

  @override
  State<IncidentReportScreen> createState() => _IncidentReportScreenState();
}

class _IncidentReportScreenState extends State<IncidentReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _description = TextEditingController();
  String _category = 'Problème dans la maquette';
  bool _sent = false;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _sent = true;
      _description.clear();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Signaler un problème')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const _DemoCallout(
          text:
              'Formulaire de démonstration : rien n’est transmis ni conservé. Pour un danger immédiat, contactez directement les services compétents.',
        ),
        if (_sent) ...[
          const SizedBox(height: 16),
          const _DemoCallout(
            text:
                'Essai terminé. Aucun signalement n’a été envoyé à une équipe.',
          ),
        ],
        const SizedBox(height: 20),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Sujet'),
                items: const [
                  DropdownMenuItem(
                    value: 'Problème dans la maquette',
                    child: Text('Problème dans la maquette'),
                  ),
                  DropdownMenuItem(
                    value: 'Question sur la sécurité',
                    child: Text('Question sur la sécurité'),
                  ),
                  DropdownMenuItem(
                    value: 'Autre question',
                    child: Text('Autre question'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _category = value);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _description,
                maxLength: 500,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Décrivez le problème',
                  hintText:
                      'Sans nom, téléphone, adresse ni document personnel',
                  alignLabelWithHint: true,
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Décrivez le problème pour tester le formulaire.'
                    : null,
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submit,
                  child: const Text('Tester l’envoi (aucun envoi réel)'),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Données et confidentialité')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        _DemoCallout(
          text:
              'Cette application est une démonstration publique. N’y saisissez aucune information réelle ou confidentielle.',
        ),
        SizedBox(height: 18),
        _PrivacySection(
          title: 'Pas de compte réel',
          text:
              'La connexion par téléphone et les profils persistants ne sont pas encore activés.',
        ),
        _PrivacySection(
          title: 'Données temporaires',
          text:
              'Les trajets publiés et réservations simulées restent en mémoire pendant la session et disparaissent à la fermeture ou au rechargement.',
        ),
        _PrivacySection(
          title: 'Pas de transmission',
          text:
              'La démonstration n’envoie pas de documents, position, paiement ni signalement à FasoCovoit.',
        ),
        _PrivacySection(
          title: 'Avant un vrai lancement',
          text:
              'Les règles de collecte, de conservation, de suppression et de partage des données devront être définies et validées avant l’ouverture du service.',
        ),
      ],
    ),
  );
}

class _PrivacySection extends StatelessWidget {
  const _PrivacySection({required this.title, required this.text});
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 6),
        Text(text),
      ],
    ),
  );
}

class _DemoCallout extends StatelessWidget {
  const _DemoCallout({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xfffff2d5),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(text, style: const TextStyle(fontSize: 13)),
  );
}
