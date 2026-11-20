import 'package:fasocovoit/journeys.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 11, 20, 12);
  late JourneyStore store;
  setUp(() => store = JourneyStore.demo(now: now));

  test('recherche par villes, date et places disponibles', () {
    final date = now.add(const Duration(days: 1));
    expect(
      store.search(
        departure: 'Ouaga',
        destination: 'bobo',
        date: date,
        passengers: 3,
      ),
      hasLength(1),
    );
    expect(
      store.search(
        departure: 'Ouaga',
        destination: 'bobo',
        date: now,
        passengers: 1,
      ),
      isEmpty,
    );
    store.book(store.journeys.first, 2);
    expect(
      store.search(
        departure: 'Ouaga',
        destination: 'bobo',
        date: date,
        passengers: 3,
      ),
      isEmpty,
    );
  });

  test(
    'réservation refuse les doublons, les places invalides et libère les places',
    () {
      final journey = store.journeys.first;
      expect(() => store.book(journey, 4), throwsStateError);
      expect(() => store.book(journey, 0), throwsStateError);
      store.book(journey, 2);
      expect(() => store.book(journey, 1), throwsStateError);
      store.cancel(store.bookings.single);
      expect(store.availableSeats(journey), 3);
    },
  );

  test(
    'publication valide les données et interdit de réserver son propre trajet',
    () {
      Journey publish({
        String from = 'Ouaga',
        String to = 'Bobo',
        DateTime? when,
        int seats = 2,
        int price = 3000,
      }) => store.publish(
        departure: from,
        destination: to,
        when: when ?? now.add(const Duration(days: 1)),
        seats: seats,
        price: price,
        now: now,
      );
      expect(() => publish(to: 'Ouagadougou'), throwsArgumentError);
      expect(() => publish(when: now), throwsArgumentError);
      expect(() => publish(seats: 0), throwsArgumentError);
      expect(() => publish(price: 0), throwsArgumentError);
      final journey = publish();
      expect(() => store.book(journey, 1), throwsStateError);
    },
  );
}
