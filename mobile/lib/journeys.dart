class Journey {
  Journey({
    required this.id,
    required this.departure,
    required this.destination,
    required this.when,
    required this.seats,
    required this.price,
    required this.driver,
    required this.vehicle,
    this.stop,
    this.own = false,
    this.luggage = false,
    this.airConditioning = false,
    this.automatic = false,
  });

  final String id;
  final String departure;
  final String destination;
  final DateTime when;
  final int seats;
  final int price;
  final String driver;
  final String vehicle;
  final String? stop;
  final bool own;
  final bool luggage;
  final bool airConditioning;
  final bool automatic;
}

class Booking {
  Booking({required this.journeyId, required this.seats});
  final String journeyId;
  final int seats;
}

class JourneyStore {
  JourneyStore({required List<Journey> journeys})
    : _journeys = List.of(journeys);

  factory JourneyStore.demo({DateTime? now}) {
    final current = now ?? DateTime.now();
    final tomorrow = DateTime(current.year, current.month, current.day + 1, 7);
    return JourneyStore(
      journeys: [
        Journey(
          id: 'demo-1',
          departure: 'Ouagadougou',
          destination: 'Bobo-Dioulasso',
          when: tomorrow,
          seats: 3,
          price: 5000,
          driver: 'Ibrahim O.',
          vehicle: 'Toyota Corolla',
          stop: 'Boromo',
          luggage: true,
        ),
        Journey(
          id: 'demo-2',
          departure: 'Ouagadougou',
          destination: 'Bobo-Dioulasso',
          when: tomorrow.add(const Duration(hours: 1, minutes: 15)),
          seats: 2,
          price: 5500,
          driver: 'Fatimata K.',
          vehicle: 'Hyundai Tucson',
          airConditioning: true,
        ),
      ],
    );
  }

  final List<Journey> _journeys;
  final List<Booking> _bookings = [];
  int _nextId = 0;

  List<Journey> get journeys => List.unmodifiable(_journeys);
  List<Booking> get bookings => List.unmodifiable(_bookings);

  int availableSeats(Journey journey) =>
      journey.seats -
      _bookings
          .where((booking) => booking.journeyId == journey.id)
          .fold(0, (total, booking) => total + booking.seats);

  Journey journeyById(String id) =>
      _journeys.firstWhere((journey) => journey.id == id);

  static String _normalize(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'\bouaga\b'), 'ouagadougou');

  List<Journey> search({
    required String departure,
    required String destination,
    required DateTime date,
    required int passengers,
  }) {
    if (passengers < 1) throw ArgumentError('Nombre de passagers invalide');
    final from = _normalize(departure);
    final to = _normalize(destination);
    return _journeys.where((journey) {
      return _normalize(journey.departure).contains(from) &&
          _normalize(journey.destination).contains(to) &&
          journey.when.year == date.year &&
          journey.when.month == date.month &&
          journey.when.day == date.day &&
          availableSeats(journey) >= passengers;
    }).toList()..sort((a, b) => a.when.compareTo(b.when));
  }

  Journey publish({
    required String departure,
    required String destination,
    required DateTime when,
    required int seats,
    required int price,
    required DateTime now,
    String? stop,
    bool luggage = false,
    bool airConditioning = false,
    bool automatic = false,
  }) {
    if (departure.trim().isEmpty ||
        destination.trim().isEmpty ||
        _normalize(departure) == _normalize(destination)) {
      throw ArgumentError('Saisissez deux villes différentes.');
    }
    if (!when.isAfter(now)) {
      throw ArgumentError('Choisissez une date et une heure futures.');
    }
    if (seats < 1 || seats > 8 || price < 1 || price > 1000000) {
      throw ArgumentError('Indiquez 1 à 8 places et un prix valide.');
    }
    final journey = Journey(
      id: 'local-${_nextId++}',
      departure: departure.trim(),
      destination: destination.trim(),
      when: when,
      seats: seats,
      price: price,
      driver: 'Vous',
      vehicle: 'Véhicule à renseigner',
      stop: stop?.trim(),
      own: true,
      luggage: luggage,
      airConditioning: airConditioning,
      automatic: automatic,
    );
    _journeys.add(journey);
    return journey;
  }

  void book(Journey journey, int seats) {
    final stored = _journeys.where((item) => item.id == journey.id);
    if (stored.isEmpty || !identical(stored.first, journey)) {
      throw StateError('Ce trajet n’existe plus.');
    }
    if (journey.own) {
      throw StateError('Vous ne pouvez pas réserver votre trajet.');
    }
    if (_bookings.any((booking) => booking.journeyId == journey.id)) {
      throw StateError('Vous avez déjà simulé une réservation pour ce trajet.');
    }
    if (seats < 1 || seats > availableSeats(journey)) {
      throw StateError('Nombre de places indisponible.');
    }
    _bookings.add(Booking(journeyId: journey.id, seats: seats));
  }

  void cancel(Booking booking) {
    if (!_bookings.remove(booking)) {
      throw StateError('Cette réservation n’existe plus.');
    }
  }
}
