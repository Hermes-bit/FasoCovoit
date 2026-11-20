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
    this.meetingPoint,
    this.notes,
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
  final String? meetingPoint;
  final String? notes;
  final bool own;
  final bool luggage;
  final bool airConditioning;
  final bool automatic;
}

class Booking {
  Booking({
    required this.id,
    required this.journeyId,
    required this.seats,
    required this.passenger,
    required this.status,
  });

  final String id;
  final String journeyId;
  final int seats;
  final String passenger;
  BookingStatus status;
}

enum BookingStatus { pending, accepted, rejected, cancelled }

class JourneyStore {
  JourneyStore({required List<Journey> journeys})
    : _journeys = List.of(journeys);

  factory JourneyStore.demo({
    DateTime? now,
    bool includeDriverRequest = false,
  }) {
    final current = now ?? DateTime.now();
    final tomorrow = DateTime(current.year, current.month, current.day + 1, 7);
    final store = JourneyStore(
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
          meetingPoint: 'Rond-point de Gounghin',
          notes: 'Départ à l’heure ; pause prévue à Boromo.',
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
          meetingPoint: 'Gare routière de Ouagadougou',
          notes: 'Merci d’arriver 15 minutes avant le départ.',
          airConditioning: true,
        ),
      ],
    );
    if (includeDriverRequest) {
      final ownJourney = Journey(
        id: 'driver-demo',
        departure: 'Ouagadougou',
        destination: 'Koudougou',
        when: tomorrow.add(const Duration(hours: 2)),
        seats: 3,
        price: 2500,
        driver: 'Vous (démo)',
        vehicle: 'Véhicule à renseigner',
        meetingPoint: 'Lieu de rendez-vous à préciser',
        own: true,
      );
      store._journeys.add(ownJourney);
      store._bookings.add(
        Booking(
          id: 'booking-demo',
          journeyId: ownJourney.id,
          seats: 1,
          passenger: 'Passager démo',
          status: BookingStatus.pending,
        ),
      );
    }
    return store;
  }

  final List<Journey> _journeys;
  final List<Booking> _bookings = [];
  int _nextId = 0;

  List<Journey> get journeys => List.unmodifiable(_journeys);
  List<Booking> get bookings => List.unmodifiable(_bookings);

  int availableSeats(Journey journey) =>
      journey.seats -
      _bookings
          .where(
            (booking) =>
                booking.journeyId == journey.id &&
                (booking.status == BookingStatus.pending ||
                    booking.status == BookingStatus.accepted),
          )
          .fold(0, (total, booking) => total + booking.seats);

  Journey journeyById(String id) =>
      _journeys.firstWhere((journey) => journey.id == id);

  List<Booking> bookingsForJourney(String journeyId) => List.unmodifiable(
    _bookings.where((booking) => booking.journeyId == journeyId),
  );

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
          !journey.own &&
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
    String? meetingPoint,
    String? notes,
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
      meetingPoint: meetingPoint?.trim(),
      notes: notes?.trim(),
      own: true,
      luggage: luggage,
      airConditioning: airConditioning,
      automatic: automatic,
    );
    _journeys.add(journey);
    return journey;
  }

  Booking book(Journey journey, int seats) {
    final stored = _journeys.where((item) => item.id == journey.id);
    if (stored.isEmpty || !identical(stored.first, journey)) {
      throw StateError('Ce trajet n’existe plus.');
    }
    if (journey.own) {
      throw StateError('Vous ne pouvez pas réserver votre trajet.');
    }
    if (_bookings.any(
      (booking) =>
          booking.journeyId == journey.id &&
          (booking.status == BookingStatus.pending ||
              booking.status == BookingStatus.accepted),
    )) {
      throw StateError('Vous avez déjà simulé une réservation pour ce trajet.');
    }
    if (seats < 1 || seats > availableSeats(journey)) {
      throw StateError('Nombre de places indisponible.');
    }
    final booking = Booking(
      id: 'local-booking-${_nextId++}',
      journeyId: journey.id,
      seats: seats,
      passenger: 'Passager démo',
      status: journey.automatic
          ? BookingStatus.accepted
          : BookingStatus.pending,
    );
    _bookings.add(booking);
    return booking;
  }

  void acceptBooking(Booking booking) {
    _validateDriverRequest(booking);
    if (booking.status != BookingStatus.pending) {
      throw StateError('Cette demande n’est plus en attente.');
    }
    booking.status = BookingStatus.accepted;
  }

  void rejectBooking(Booking booking) {
    _validateDriverRequest(booking);
    if (booking.status != BookingStatus.pending) {
      throw StateError('Cette demande n’est plus en attente.');
    }
    booking.status = BookingStatus.rejected;
  }

  void _validateDriverRequest(Booking booking) {
    final exists = _bookings.any((item) => identical(item, booking));
    if (!exists || !journeyById(booking.journeyId).own) {
      throw StateError('Cette demande ne concerne pas un trajet conducteur.');
    }
  }

  void cancel(Booking booking) {
    if (!_bookings.any((item) => identical(item, booking)) ||
        (booking.status != BookingStatus.pending &&
            booking.status != BookingStatus.accepted)) {
      throw StateError('Cette réservation n’existe plus.');
    }
    booking.status = BookingStatus.cancelled;
  }
}
