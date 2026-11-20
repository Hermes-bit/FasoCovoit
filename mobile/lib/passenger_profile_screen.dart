import 'package:flutter/material.dart';

import 'journeys.dart';

class PassengerProfileScreen extends StatefulWidget {
  const PassengerProfileScreen({
    super.key,
    required this.store,
    required this.onFindTrip,
    required this.onShowBookings,
  });

  final JourneyStore store;
  final VoidCallback onFindTrip;
  final VoidCallback onShowBookings;

  @override
  State<PassengerProfileScreen> createState() => _PassengerProfileScreenState();
}

class _PassengerProfileScreenState extends State<PassengerProfileScreen> {
  String _name = 'Passager FasoCovoit';

  Future<void> _editProfile() async {
    final updatedName = await showDialog<String>(
      context: context,
      builder: (context) => _PassengerProfileEditDialog(initialName: _name),
    );
    if (updatedName == null || updatedName.isEmpty || !mounted) return;
    setState(() => _name = updatedName);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nom mis à jour pour cette session.')),
    );
  }

  Future<void> _showInfo(String title, String message) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final tripCount = widget.store.bookings.length;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Mon profil',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text('ESPACE PASSAGER'),
                      const SizedBox(height: 4),
                      const Text(
                        'Profil de démonstration · non vérifié',
                        style: TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Row(
          children: [
            Icon(Icons.star_outline, color: Color(0xffb7791f)),
            SizedBox(width: 6),
            Text('Nouveau profil · aucun avis reçu'),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _ProfileMetric(
                icon: Icons.route_outlined,
                label: 'Trajets réservés',
                value: '$tripCount',
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: _ProfileMetric(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Portefeuille',
                value: 'Non activé',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.stars_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Avantages FasoCovoit',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Les récompenses et réductions seront présentées après définition des règles du service.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const _ProfileSectionTitle('VOYAGER'),
        _ProfileAction(
          icon: Icons.search,
          title: 'Prendre un trajet',
          subtitle: 'Chercher un conducteur et consulter son itinéraire',
          onTap: widget.onFindTrip,
        ),
        _ProfileAction(
          icon: Icons.bookmark_outline,
          title: 'Mes réservations',
          subtitle: 'Consulter ou annuler une demande simulée',
          onTap: widget.onShowBookings,
        ),
        const _ProfileSectionTitle('MON ESPACE'),
        _ProfileAction(
          icon: Icons.person_outline,
          title: 'Mes informations',
          subtitle: 'Modifier le nom affiché dans cette session',
          onTap: _editProfile,
        ),
        _ProfileAction(
          icon: Icons.chat_bubble_outline,
          title: 'Mes avis',
          subtitle: 'Aucun avis tant qu’aucun trajet réel n’est effectué',
          onTap: () => _showInfo(
            'Mes avis',
            'Les avis ne sont pas collectés dans cette démonstration.',
          ),
        ),
        _ProfileAction(
          icon: Icons.credit_card_outlined,
          title: 'Moyens de paiement',
          subtitle: 'Paiement désactivé dans cette démonstration',
          onTap: () => _showInfo(
            'Moyens de paiement',
            'Aucun paiement ni portefeuille réel n’est disponible. Ne saisissez pas de coordonnées bancaires.',
          ),
        ),
        const _ProfileSectionTitle('OFFRES'),
        _ProfileAction(
          icon: Icons.sell_outlined,
          title: 'Code promotionnel',
          subtitle: 'Les promotions ne sont pas encore activées',
          onTap: () => _showInfo(
            'Code promotionnel',
            'Aucun code promotionnel n’est actif pour le moment.',
          ),
        ),
        _ProfileAction(
          icon: Icons.group_add_outlined,
          title: 'Parrainer des amis',
          subtitle: 'Le parrainage sera disponible plus tard',
          onTap: () => _showInfo(
            'Parrainage',
            'Le partage d’invitations n’est pas activé dans cette démonstration.',
          ),
        ),
        const _ProfileSectionTitle('AIDE ET SÉCURITÉ'),
        _ProfileAction(
          icon: Icons.shield_outlined,
          title: 'Conseils de sécurité',
          subtitle: 'Vérifier les informations du trajet avant de partir',
          onTap: () => _showInfo(
            'Conseils de sécurité',
            'Cette maquette ne vérifie ni les profils ni les trajets. Confirmez toujours les détails avec les personnes concernées et contactez les services locaux en cas d’urgence.',
          ),
        ),
        _ProfileAction(
          icon: Icons.help_outline,
          title: 'Centre d’aide',
          subtitle: 'Comprendre les limites de la démonstration',
          onTap: () => _showInfo(
            'Centre d’aide',
            'La recherche, les réservations et les trajets affichés sont des simulations locales. Aucun trajet réel ni paiement n’est organisé.',
          ),
        ),
        _ProfileAction(
          icon: Icons.description_outlined,
          title: 'Conditions et confidentialité',
          subtitle: 'Informations sur cette maquette',
          onTap: () => _showInfo(
            'Conditions et confidentialité',
            'Cette maquette ne crée pas de compte et ne transmet pas les informations du profil. Les règles contractuelles et de confidentialité devront être établies avant un service réel.',
          ),
        ),
        _ProfileAction(
          icon: Icons.delete_outline,
          title: 'Supprimer mon compte',
          subtitle: 'Aucun compte réel n’a été créé',
          onTap: () => _showInfo(
            'Supprimer mon compte',
            'Aucun compte réel n’existe dans cette démonstration. Les données de session disparaissent à la fermeture de l’application.',
          ),
        ),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            'FasoCovoit · profil passager de démonstration',
            style: TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _PassengerProfileEditDialog extends StatefulWidget {
  const _PassengerProfileEditDialog({required this.initialName});

  final String initialName;

  @override
  State<_PassengerProfileEditDialog> createState() =>
      _PassengerProfileEditDialogState();
}

class _PassengerProfileEditDialogState
    extends State<_PassengerProfileEditDialog> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Mon profil passager'),
    content: TextField(
      controller: _nameController,
      maxLength: 40,
      decoration: const InputDecoration(labelText: 'Nom affiché'),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Annuler'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, _nameController.text.trim()),
        child: const Text('Enregistrer'),
      ),
    ],
  );
}

class _ProfileMetric extends StatelessWidget {
  const _ProfileMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    ),
  );
}

class _ProfileSectionTitle extends StatelessWidget {
  const _ProfileSectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 8),
    child: Text(
      title,
      style: const TextStyle(
        color: Colors.black54,
        fontSize: 12,
        fontWeight: FontWeight.bold,
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
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
    leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
    subtitle: Text(subtitle),
    trailing: const Icon(Icons.chevron_right),
    onTap: onTap,
  );
}
