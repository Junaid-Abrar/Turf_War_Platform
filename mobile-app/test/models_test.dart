import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/models/booking_model.dart';
import 'package:mobile_app/models/review_model.dart';
import 'package:mobile_app/models/user_model.dart';
import 'package:mobile_app/models/venue_model.dart';

void main() {
  group('BookingModel', () {
    // The reason `venue` was split into `venueId` + nullable `venue`: the same
    // field arrives in two shapes depending on the endpoint.
    test('reads a populated venue into both venueId and venue', () {
      final BookingModel booking = BookingModel.fromJson(<String, dynamic>{
        '_id': 'b1',
        'user': 'u1',
        'venue': <String, dynamic>{
          '_id': 'v1',
          'name': 'Green Field',
          'pricePerHour': 25,
          'owner': 'o1',
        },
        'date': '2026-08-20',
        'startTime': '18:00',
        'endTime': '19:00',
        'price': 25,
        'status': 'confirmed',
        'paymentStatus': 'paid',
      });

      expect(booking.venueId, 'v1');
      expect(booking.venue, isNotNull);
      expect(booking.venueName, 'Green Field');
      expect(booking.isConfirmed, isTrue);
      expect(booking.isPaid, isTrue);
    });

    test('reads an unpopulated venue id with a null venue', () {
      final BookingModel booking = BookingModel.fromJson(<String, dynamic>{
        '_id': 'b2',
        'venue': 'v9',
        'date': '2026-08-20',
        'startTime': '18:00',
        'endTime': '19:00',
        'price': 30,
      });

      expect(booking.venueId, 'v9');
      expect(booking.venue, isNull);
      // Falls back rather than crashing the way `booking.venue as VenueModel`
      // used to.
      expect(booking.venueName, 'Venue');
      expect(booking.isPending, isTrue);
      expect(booking.isPaid, isFalse);
    });

    test('tolerates a missing venue entirely', () {
      final BookingModel booking =
          BookingModel.fromJson(<String, dynamic>{'_id': 'b3'});
      expect(booking.venueId, '');
      expect(booking.venue, isNull);
    });

    test('copyWith replaces only the given fields', () {
      final BookingModel booking = BookingModel.fromJson(<String, dynamic>{
        '_id': 'b4',
        'venue': 'v1',
        'status': 'pending',
        'paymentStatus': 'unpaid',
        'price': 40,
      });

      final BookingModel paid = booking.copyWith(paymentStatus: 'paid');
      expect(paid.isPaid, isTrue);
      expect(paid.status, 'pending');
      expect(paid.price, 40);
      expect(paid.id, 'b4');
    });
  });

  group('VenueModel', () {
    test('handles a populated owner object', () {
      final VenueModel venue = VenueModel.fromJson(<String, dynamic>{
        '_id': 'v1',
        'name': 'Turf One',
        'owner': <String, dynamic>{'_id': 'o1', 'name': 'Owner'},
        'images': <String>['https://example.com/a.jpg'],
        'amenities': <String>['Wifi'],
        'pricePerHour': 20.5,
        'averageRating': 4.5,
      });

      expect(venue.ownerId, 'o1');
      expect(venue.primaryImage, 'https://example.com/a.jpg');
      expect(venue.pricePerHour, 20.5);
    });

    test('handles a raw owner id and missing lists', () {
      final VenueModel venue = VenueModel.fromJson(<String, dynamic>{
        '_id': 'v2',
        'owner': 'o2',
      });

      expect(venue.ownerId, 'o2');
      expect(venue.images, isEmpty);
      expect(venue.primaryImage, isNull);
      expect(venue.name, 'Unknown Venue');
    });
  });

  group('UserModel', () {
    test('accepts both id and _id', () {
      expect(
        UserModel.fromJson(<String, dynamic>{'id': 'u1'}).id,
        'u1',
      );
      expect(
        UserModel.fromJson(<String, dynamic>{'_id': 'u2'}).id,
        'u2',
      );
    });

    test('role helpers gate venue management', () {
      const UserModel player = UserModel(
        id: 'u1',
        name: 'ana',
        email: 'a@b.c',
        role: 'user',
      );
      const UserModel owner = UserModel(
        id: 'u2',
        name: 'Bo',
        email: 'b@b.c',
        role: 'venue_owner',
      );
      const UserModel admin = UserModel(
        id: 'u3',
        name: '',
        email: 'c@b.c',
        role: 'admin',
      );

      expect(player.canManageVenues, isFalse);
      expect(owner.canManageVenues, isTrue);
      expect(admin.canManageVenues, isTrue);
      expect(player.initial, 'A');
      expect(admin.initial, '?');
    });
  });

  group('ReviewModel', () {
    test('falls back to Anonymous when the author is not populated', () {
      // A review whose user was deleted comes back as a bare id; indexing into
      // it used to throw while building the reviews list.
      final ReviewModel review = ReviewModel.fromJson(<String, dynamic>{
        '_id': 'r1',
        'user': 'u-deleted',
        'rating': 4,
        'comment': 'Good',
      });

      expect(review.userName, 'Anonymous');
      expect(review.rating, 4.0);
    });

    test('reads a populated author', () {
      final ReviewModel review = ReviewModel.fromJson(<String, dynamic>{
        '_id': 'r2',
        'user': <String, dynamic>{'name': 'Sam'},
        'rating': 5,
        'comment': 'Great',
        'createdAt': '2026-08-01T10:00:00.000Z',
      });

      expect(review.userName, 'Sam');
      expect(review.createdAt.year, 2026);
    });
  });
}
