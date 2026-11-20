import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'google_maps_embed.dart';
import 'journeys.dart';
import 'passenger_profile_screen.dart';

String dateText(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
String timeText(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
String priceText(int price) =>
    '${price.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ' ')} FCFA';

class DemoNotice extends StatelessWidget {
  const DemoNotice({super.key});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    color: const Color(0xfffff2d5),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    child: const Text(
      'DÉMONSTRATION LOCALE · Aucun trajet ni paiement réel. Les données disparaissent à la fermeture.',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
    ),
  );
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, required this.store});
  final JourneyStore store;
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;
  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final pages = [
      SearchScreen(store: widget.store, onChanged: _refresh),
      MyJourneysScreen(store: widget.store, onChanged: _refresh),
      PassengerProfileScreen(
        store: widget.store,
        onFindTrip: () => setState(() => _index = 0),
        onShowBookings: () => setState(() => _index = 1),
      ),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'FasoCovoit',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          const DemoNotice(),
          Expanded(child: pages[_index]),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.search), label: 'Rechercher'),
          NavigationDestination(
            icon: Icon(Icons.bookmark_outline),
            label: 'Mes réservations',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, required this.store, required this.onChanged});
  final JourneyStore store;
  final VoidCallback onChanged;
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _departure = TextEditingController(text: 'Ouagadougou');
  final _destination = TextEditingController(text: 'Bobo-Dioulasso');
  late DateTime _date;
  int _passengers = 1;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _date = DateTime(now.year, now.month, now.day + 1);
  }

  @override
  void dispose() {
    _departure.dispose();
    _destination.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(today) ? today : _date,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
    );
    if (selected != null) setState(() => _date = selected);
  }

  void _search() {
    if (_departure.text.trim().isEmpty || _destination.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Renseignez le départ et la destination.'),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ResultsScreen(
          store: widget.store,
          departure: _departure.text,
          destination: _destination.text,
          date: _date,
          passengers: _passengers,
          onChanged: widget.onChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Text('Bonjour !', style: TextStyle(fontSize: 16)),
      const SizedBox(height: 4),
      Text(
        'Où allez-vous ?',
        style: Theme.of(
          context,
        ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      const Text('Partageons la route entre nos villes.'),
      const SizedBox(height: 24),
      const Text(
        'Entre villes',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _departure,
        decoration: const InputDecoration(
          labelText: 'Ville de départ',
          prefixIcon: Icon(Icons.trip_origin),
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _destination,
        decoration: const InputDecoration(
          labelText: 'Ville d’arrivée',
          prefixIcon: Icon(Icons.location_on_outlined),
        ),
      ),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: _selectDate,
        icon: const Icon(Icons.calendar_today),
        label: Text('Date : ${dateText(_date)}'),
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<int>(
        initialValue: _passengers,
        decoration: const InputDecoration(labelText: 'Passagers'),
        items: List.generate(
          8,
          (index) => DropdownMenuItem(
            value: index + 1,
            child: Text('${index + 1} passager${index == 0 ? '' : 's'}'),
          ),
        ),
        onChanged: (value) => setState(() => _passengers = value!),
      ),
      const SizedBox(height: 20),
      FilledButton.icon(
        onPressed: _search,
        icon: const Icon(Icons.search),
        label: const Text('Trouver un trajet'),
      ),
      const SizedBox(height: 24),
      const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Ligne pilote proposée : Ouagadougou ↔ Bobo-Dioulasso. Les trajets affichés sont des exemples.',
          ),
        ),
      ),
      const SizedBox(height: 8),
      const Text(
        'Les courses partagées en ville seront étudiées après le premier parcours interurbain.',
        style: TextStyle(color: Colors.black54),
      ),
    ],
  );
}

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({
    super.key,
    required this.store,
    required this.departure,
    required this.destination,
    required this.date,
    required this.passengers,
    required this.onChanged,
  });
  final JourneyStore store;
  final String departure;
  final String destination;
  final DateTime date;
  final int passengers;
  final VoidCallback onChanged;
  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  @override
  Widget build(BuildContext context) {
    final journeys = widget.store.search(
      departure: widget.departure,
      destination: widget.destination,
      date: widget.date,
      passengers: widget.passengers,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Trajets disponibles')),
      body: Column(
        children: [
          const DemoNotice(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  '${widget.departure} → ${widget.destination}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${dateText(widget.date)} · ${widget.passengers} passager(s)',
                ),
                const SizedBox(height: 20),
                if (journeys.isEmpty)
                  const Text(
                    'Aucun trajet disponible pour cette recherche dans la démonstration.',
                  ),
                ...journeys.map(
                  (journey) => JourneyCard(
                    journey: journey,
                    available: widget.store.availableSeats(journey),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => DetailScreen(
                            store: widget.store,
                            journey: journey,
                            initialSeats: widget.passengers,
                          ),
                        ),
                      );
                      if (!mounted) return;
                      setState(() {});
                      widget.onChanged();
                    },
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

class JourneyCard extends StatelessWidget {
  const JourneyCard({
    super.key,
    required this.journey,
    required this.available,
    this.onTap,
  });
  final Journey journey;
  final int available;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${timeText(journey.when)} · ${dateText(journey.when)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ),
                Text(
                  priceText(journey.price),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('${journey.departure} → ${journey.destination}'),
            const Divider(height: 24),
            Text('${journey.driver} · ${journey.vehicle}'),
            const SizedBox(height: 5),
            Text(
              '$available place(s) disponible(s)',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ],
        ),
      ),
    ),
  );
}

class DetailScreen extends StatefulWidget {
  const DetailScreen({
    super.key,
    required this.store,
    required this.journey,
    required this.initialSeats,
  });
  final JourneyStore store;
  final Journey journey;
  final int initialSeats;
  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late int _seats;
  @override
  void initState() {
    super.initState();
    _seats = widget.initialSeats;
  }

  void _book() {
    try {
      widget.store.book(widget.journey, _seats);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Réservation simulée, visible dans Mes trajets. Aucun paiement effectué.',
          ),
        ),
      );
    } on StateError catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final journey = widget.journey;
    final available = widget.store.availableSeats(journey);
    return Scaffold(
      appBar: AppBar(title: const Text('Détail du trajet')),
      body: Column(
        children: [
          const DemoNotice(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  '${journey.departure} → ${journey.destination}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Départ : ${dateText(journey.when)} à ${timeText(journey.when)}',
                        ),
                        if (journey.stop != null && journey.stop!.isNotEmpty)
                          Text('Arrêt : ${journey.stop}'),
                        const SizedBox(height: 12),
                        Text('Conducteur fictif : ${journey.driver}'),
                        Text(journey.vehicle),
                        if (journey.luggage) const Text('Bagages acceptés'),
                        if (journey.airConditioning)
                          const Text('Climatisation'),
                        if (journey.automatic)
                          const Text('Réservation automatique (exemple)'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                GoogleMapsRouteEmbed(
                  departure: journey.departure,
                  destination: journey.destination,
                  stop: journey.stop,
                ),
                const SizedBox(height: 16),
                if (!journey.own && available > 0) ...[
                  Row(
                    children: [
                      const Expanded(child: Text('Nombre de places')),
                      IconButton(
                        onPressed: _seats > 1
                            ? () => setState(() => _seats--)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        tooltip: 'Retirer une place',
                      ),
                      Text('$_seats'),
                      IconButton(
                        onPressed: _seats < available
                            ? () => setState(() => _seats++)
                            : null,
                        icon: const Icon(Icons.add_circle_outline),
                        tooltip: 'Ajouter une place',
                      ),
                    ],
                  ),
                  Text(
                    'Total fictif : ${priceText(journey.price * _seats)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _book,
                    child: const Text('Simuler la réservation'),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Aucun paiement ni contact avec un conducteur. Prix et identité fictifs.',
                    style: TextStyle(color: Colors.black54),
                  ),
                ] else
                  Text(
                    journey.own
                        ? 'Vous avez publié cet exemple.'
                        : 'Plus de place disponible.',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PublishScreen extends StatefulWidget {
  const PublishScreen({
    super.key,
    required this.store,
    required this.onPublished,
  });
  final JourneyStore store;
  final VoidCallback onPublished;
  @override
  State<PublishScreen> createState() => _PublishScreenState();
}

class _PublishScreenState extends State<PublishScreen> {
  final _form = GlobalKey<FormState>();
  final _from = TextEditingController(text: 'Ouagadougou');
  final _to = TextEditingController(text: 'Bobo-Dioulasso');
  final _stop = TextEditingController();
  final _price = TextEditingController();
  late DateTime _date;
  TimeOfDay _time = const TimeOfDay(hour: 7, minute: 0);
  int _seats = 3;
  bool _luggage = false, _air = false, _auto = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _date = DateTime(now.year, now.month, now.day + 1);
  }

  @override
  void dispose() {
    _from.dispose();
    _to.dispose();
    _stop.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(today) ? today : _date,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
    );
    if (date != null) setState(() => _date = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(context: context, initialTime: _time);
    if (time != null) setState(() => _time = time);
  }

  void _publish() {
    if (!_form.currentState!.validate()) return;
    try {
      widget.store.publish(
        departure: _from.text,
        destination: _to.text,
        stop: _stop.text,
        when: DateTime(
          _date.year,
          _date.month,
          _date.day,
          _time.hour,
          _time.minute,
        ),
        now: DateTime.now(),
        seats: _seats,
        price: int.parse(_price.text),
        luggage: _luggage,
        airConditioning: _air,
        automatic: _auto,
      );
      widget.onPublished();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trajet fictif publié dans cette session uniquement.'),
        ),
      );
    } on ArgumentError catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message.toString())));
    }
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _form,
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Publier un trajet',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text('Espace conducteur · simulation locale'),
        const SizedBox(height: 20),
        TextFormField(
          controller: _from,
          decoration: const InputDecoration(labelText: 'Ville de départ'),
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Renseignez la ville de départ.'
              : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _to,
          decoration: const InputDecoration(labelText: 'Ville d’arrivée'),
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Renseignez la ville d’arrivée.'
              : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _stop,
          decoration: const InputDecoration(
            labelText: 'Arrêt en route (facultatif)',
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _pickDate,
          icon: const Icon(Icons.calendar_today),
          label: Text('Date : ${dateText(_date)}'),
        ),
        OutlinedButton.icon(
          onPressed: _pickTime,
          icon: const Icon(Icons.schedule),
          label: Text(
            'Heure : ${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          initialValue: _seats,
          decoration: const InputDecoration(labelText: 'Places libres'),
          items: List.generate(
            8,
            (index) =>
                DropdownMenuItem(value: index + 1, child: Text('${index + 1}')),
          ),
          onChanged: (value) => setState(() => _seats = value!),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _price,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(7),
          ],
          decoration: const InputDecoration(labelText: 'Prix par place (FCFA)'),
          validator: (value) {
            final price = int.tryParse(value ?? '');
            return price == null || price < 1 || price > 1000000
                ? 'Saisissez un prix entre 1 et 1 000 000 FCFA.'
                : null;
          },
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Bagages acceptés'),
          value: _luggage,
          onChanged: (value) => setState(() => _luggage = value!),
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Climatisation'),
          value: _air,
          onChanged: (value) => setState(() => _air = value!),
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Réservation automatique'),
          value: _auto,
          onChanged: (value) => setState(() => _auto = value!),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _publish,
          child: const Text('Publier dans la démonstration'),
        ),
      ],
    ),
  );
}

class MyJourneysScreen extends StatefulWidget {
  const MyJourneysScreen({
    super.key,
    required this.store,
    required this.onChanged,
  });
  final JourneyStore store;
  final VoidCallback onChanged;
  @override
  State<MyJourneysScreen> createState() => _MyJourneysScreenState();
}

class _MyJourneysScreenState extends State<MyJourneysScreen> {
  @override
  Widget build(BuildContext context) {
    final bookings = widget.store.bookings;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Mes réservations',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text('Vos demandes de réservation dans cette démonstration.'),
        const SizedBox(height: 20),
        if (bookings.isEmpty)
          const Text('Aucune réservation simulée pour le moment.'),
        if (bookings.isNotEmpty)
          const Text(
            'Réservations simulées',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ...bookings.map((booking) {
          final journey = widget.store.journeyById(booking.journeyId);
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${journey.departure} → ${journey.destination}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${dateText(journey.when)} · ${booking.seats} place(s) · ${priceText(journey.price * booking.seats)}',
                  ),
                  TextButton(
                    onPressed: () {
                      widget.store.cancel(booking);
                      setState(() {});
                      widget.onChanged();
                    },
                    child: const Text('Annuler la simulation'),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
