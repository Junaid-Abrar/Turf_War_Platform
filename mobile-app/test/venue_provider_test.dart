import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/core/network/api_exception.dart';
import 'package:mobile_app/features/venues/providers/venue_provider.dart';
import 'package:mobile_app/features/venues/services/venue_service.dart';
import 'package:mobile_app/models/venue_model.dart';
import 'package:mocktail/mocktail.dart';

class MockVenueService extends Mock implements VenueService {}

void main() {
  late MockVenueService service;
  late VenueProvider provider;

  const VenueModel venueA = VenueModel(
    id: 'v1',
    name: 'Riverside Pitch',
    description: 'A pitch',
    location: 'Camden',
    pricePerHour: 40,
    images: <String>[],
    amenities: <String>[],
    ownerId: 'o1',
  );

  setUp(() {
    service = MockVenueService();
    provider = VenueProvider(service);
  });

  group('fetchVenues', () {
    test('transitions loading -> success and populates venues', () async {
      when(() => service.getVenues())
          .thenAnswer((_) async => <VenueModel>[venueA]);

      final List<bool> loadingStates = <bool>[];
      provider.addListener(() => loadingStates.add(provider.isLoading));

      final Future<void> future = provider.fetchVenues();
      expect(provider.isLoading, isTrue);

      await future;

      expect(provider.isLoading, isFalse);
      expect(provider.venues, <VenueModel>[venueA]);
      expect(provider.hasError, isFalse);
      expect(loadingStates.first, isTrue);
      expect(loadingStates.last, isFalse);
    });

    test('transitions loading -> error and surfaces the ApiException message',
        () async {
      when(() => service.getVenues()).thenThrow(
        const ApiException('Server unavailable', kind: ApiExceptionKind.network),
      );

      await provider.fetchVenues();

      expect(provider.isLoading, isFalse);
      expect(provider.hasError, isTrue);
      expect(provider.error, 'Server unavailable');
      expect(provider.venues, isEmpty);
    });

    test('clears a previous error on a subsequent successful fetch', () async {
      when(() => service.getVenues()).thenThrow(
        const ApiException('boom', kind: ApiExceptionKind.unknown),
      );
      await provider.fetchVenues();
      expect(provider.hasError, isTrue);

      when(() => service.getVenues())
          .thenAnswer((_) async => <VenueModel>[venueA]);
      await provider.fetchVenues();

      expect(provider.hasError, isFalse);
      expect(provider.venues, <VenueModel>[venueA]);
    });
  });

  group('searchVenues', () {
    test('an unfiltered call delegates to fetchVenues rather than /search',
        () async {
      when(() => service.getVenues())
          .thenAnswer((_) async => <VenueModel>[venueA]);

      await provider.searchVenues();

      verify(() => service.getVenues()).called(1);
      verifyNever(() => service.searchVenues(
            query: any(named: 'query'),
            minPrice: any(named: 'minPrice'),
            maxPrice: any(named: 'maxPrice'),
            amenities: any(named: 'amenities'),
          ));
      expect(provider.venues, <VenueModel>[venueA]);
    });

    test('an empty query string with no other filters still counts as unfiltered',
        () async {
      when(() => service.getVenues())
          .thenAnswer((_) async => <VenueModel>[venueA]);

      await provider.searchVenues(query: '');

      verify(() => service.getVenues()).called(1);
      verifyNever(() => service.searchVenues(
            query: any(named: 'query'),
            minPrice: any(named: 'minPrice'),
            maxPrice: any(named: 'maxPrice'),
            amenities: any(named: 'amenities'),
          ));
    });

    test('a query string hits /search and the loading/success transition runs',
        () async {
      when(() => service.searchVenues(
            query: any(named: 'query'),
            minPrice: any(named: 'minPrice'),
            maxPrice: any(named: 'maxPrice'),
            amenities: any(named: 'amenities'),
          )).thenAnswer((_) async => <VenueModel>[venueA]);

      final Future<void> future = provider.searchVenues(query: 'green');
      expect(provider.isLoading, isTrue);
      await future;

      expect(provider.isLoading, isFalse);
      verify(() => service.searchVenues(
            query: 'green',
            minPrice: null,
            maxPrice: null,
            amenities: null,
          )).called(1);
      verifyNever(() => service.getVenues());
    });

    test('price filters alone also route to /search', () async {
      when(() => service.searchVenues(
            query: any(named: 'query'),
            minPrice: any(named: 'minPrice'),
            maxPrice: any(named: 'maxPrice'),
            amenities: any(named: 'amenities'),
          )).thenAnswer((_) async => <VenueModel>[]);

      await provider.searchVenues(minPrice: 10, maxPrice: 100);

      verify(() => service.searchVenues(
            query: null,
            minPrice: 10,
            maxPrice: 100,
            amenities: null,
          )).called(1);
    });

    test('search error is surfaced the same way as fetch error', () async {
      when(() => service.searchVenues(
            query: any(named: 'query'),
            minPrice: any(named: 'minPrice'),
            maxPrice: any(named: 'maxPrice'),
            amenities: any(named: 'amenities'),
          )).thenThrow(
        const ApiException('No matches', kind: ApiExceptionKind.badResponse),
      );

      await provider.searchVenues(query: 'nowhere');

      expect(provider.hasError, isTrue);
      expect(provider.error, 'No matches');
    });
  });
}
