import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/core/network/api_exception.dart';
import 'package:mobile_app/features/bookings/providers/booking_provider.dart';
import 'package:mobile_app/features/bookings/services/booking_service.dart';
import 'package:mobile_app/models/booking_model.dart';
import 'package:mocktail/mocktail.dart';

class MockBookingService extends Mock implements BookingService {}

void main() {
  late MockBookingService service;
  late BookingProvider provider;

  final DateTime now = DateTime.now();
  final DateTime today = DateTime(now.year, now.month, now.day);
  String isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  BookingModel booking({
    required String id,
    required String date,
    String status = 'confirmed',
    String paymentStatus = 'unpaid',
  }) {
    return BookingModel(
      id: id,
      user: 'u1',
      venueId: 'v1',
      date: date,
      startTime: '10:00',
      endTime: '11:00',
      price: 40,
      status: status,
      paymentStatus: paymentStatus,
      createdAt: DateTime(2026, 1, 1),
    );
  }

  setUp(() {
    service = MockBookingService();
    provider = BookingProvider(service);
  });

  group('fetchMyBookings', () {
    test('transitions loading -> success and populates myBookings', () async {
      final BookingModel b = booking(id: 'b1', date: isoDate(today));
      when(() => service.getMyBookings())
          .thenAnswer((_) async => <BookingModel>[b]);

      final Future<void> future = provider.fetchMyBookings();
      expect(provider.isLoading, isTrue);
      await future;

      expect(provider.isLoading, isFalse);
      expect(provider.myBookings, <BookingModel>[b]);
      expect(provider.error, isNull);
    });

    test('transitions loading -> error and keeps the message', () async {
      when(() => service.getMyBookings()).thenThrow(
        const ApiException('Not authorized', kind: ApiExceptionKind.badResponse),
      );

      await provider.fetchMyBookings();

      expect(provider.isLoading, isFalse);
      expect(provider.error, 'Not authorized');
      expect(provider.myBookings, isEmpty);
    });
  });

  group('derived booking lists', () {
    test('splits bookings into upcoming, past and cancelled', () async {
      final DateTime tomorrow = today.add(const Duration(days: 1));
      final DateTime yesterday = today.subtract(const Duration(days: 1));

      final BookingModel upcoming =
          booking(id: 'up', date: isoDate(tomorrow));
      final BookingModel todayBooking =
          booking(id: 'today', date: isoDate(today));
      final BookingModel past = booking(id: 'past', date: isoDate(yesterday));
      final BookingModel cancelled = booking(
        id: 'cancelled',
        date: isoDate(tomorrow),
        status: 'cancelled',
      );

      when(() => service.getMyBookings()).thenAnswer(
        (_) async => <BookingModel>[upcoming, todayBooking, past, cancelled],
      );
      await provider.fetchMyBookings();

      // `_isFuture` treats "today" as not-yet-past (it isn't before midnight
      // today), so today's booking counts as upcoming.
      expect(
        provider.upcomingBookings.map((BookingModel b) => b.id),
        containsAll(<String>['up', 'today']),
      );
      expect(
        provider.pastBookings.map((BookingModel b) => b.id),
        <String>['past'],
      );
      expect(
        provider.cancelledBookings.map((BookingModel b) => b.id),
        <String>['cancelled'],
      );
      // A cancelled booking must not double up in upcoming/past regardless of
      // its date.
      expect(
        provider.upcomingBookings.any((BookingModel b) => b.id == 'cancelled'),
        isFalse,
      );
    });

    test('a booking with an unparseable date is treated as future', () async {
      final BookingModel malformed = booking(id: 'bad', date: 'not-a-date');
      when(() => service.getMyBookings())
          .thenAnswer((_) async => <BookingModel>[malformed]);
      await provider.fetchMyBookings();

      expect(provider.upcomingBookings.single.id, 'bad');
      expect(provider.pastBookings, isEmpty);
    });
  });

  group('bookVenue', () {
    test('prepends the new booking and toggles isLoading', () async {
      final BookingModel existing = booking(id: 'existing', date: isoDate(today));
      final BookingModel created = booking(id: 'new', date: isoDate(today));

      when(() => service.getMyBookings())
          .thenAnswer((_) async => <BookingModel>[existing]);
      await provider.fetchMyBookings();

      when(() => service.createBooking(
            venueId: any(named: 'venueId'),
            date: any(named: 'date'),
            startTime: any(named: 'startTime'),
            endTime: any(named: 'endTime'),
          )).thenAnswer((_) async => created);

      final Future<BookingModel> future = provider.bookVenue(
        venueId: 'v1',
        date: isoDate(today),
        startTime: '10:00',
        endTime: '11:00',
      );
      expect(provider.isLoading, isTrue);
      final BookingModel result = await future;

      expect(provider.isLoading, isFalse);
      expect(result.id, 'new');
      expect(provider.myBookings.first.id, 'new');
      expect(provider.myBookings.length, 2);
    });

    test('rethrows on failure and still clears isLoading', () async {
      when(() => service.createBooking(
            venueId: any(named: 'venueId'),
            date: any(named: 'date'),
            startTime: any(named: 'startTime'),
            endTime: any(named: 'endTime'),
          )).thenThrow(
        const ApiException('Slot already booked', kind: ApiExceptionKind.badResponse),
      );

      await expectLater(
        provider.bookVenue(
          venueId: 'v1',
          date: isoDate(today),
          startTime: '10:00',
          endTime: '11:00',
        ),
        throwsA(isA<ApiException>()),
      );
      expect(provider.isLoading, isFalse);
    });
  });

  group('cancelBooking', () {
    test('replaces the matching booking with the cancelled version', () async {
      final BookingModel original = booking(id: 'b1', date: isoDate(today));
      when(() => service.getMyBookings())
          .thenAnswer((_) async => <BookingModel>[original]);
      await provider.fetchMyBookings();

      final BookingModel cancelled = original.copyWith(status: 'cancelled');
      when(() => service.cancelBooking('b1')).thenAnswer((_) async => cancelled);

      await provider.cancelBooking('b1');

      expect(provider.myBookings.single.isCancelled, isTrue);
    });
  });

  group('markPaid', () {
    test('marks only the matching booking as paid, locally, without a service call',
        () async {
      final BookingModel b1 = booking(id: 'b1', date: isoDate(today));
      final BookingModel b2 = booking(id: 'b2', date: isoDate(today));
      when(() => service.getMyBookings())
          .thenAnswer((_) async => <BookingModel>[b1, b2]);
      await provider.fetchMyBookings();
      clearInteractions(service);

      provider.markPaid('b1');

      expect(
        provider.myBookings.firstWhere((BookingModel b) => b.id == 'b1').isPaid,
        isTrue,
      );
      expect(
        provider.myBookings.firstWhere((BookingModel b) => b.id == 'b2').isPaid,
        isFalse,
      );
      verifyZeroInteractions(service);
    });
  });
}
