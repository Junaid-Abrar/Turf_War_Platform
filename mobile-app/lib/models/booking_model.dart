import 'venue_model.dart';

/// A slot reserved on a venue.
///
/// The backend returns `venue` either as a raw ObjectId string (`POST /bookings`)
/// or as a populated document (`GET /bookings/my`). This used to be modelled as a
/// single `dynamic venue` field, which pushed an unchecked `as VenueModel` cast
/// into the UI. It is now split: [venueId] is always present, and [venue] is
/// non-null only when the response was populated.
class BookingModel {
  final String id;
  final String user;
  final String venueId;
  final VenueModel? venue;
  final String date;
  final String startTime;
  final String endTime;
  final double price;
  final String status;
  final String paymentStatus;
  final DateTime createdAt;

  const BookingModel({
    required this.id,
    required this.user,
    required this.venueId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.price,
    required this.status,
    required this.paymentStatus,
    required this.createdAt,
    this.venue,
  });

  bool get isCancelled => status == 'cancelled';
  bool get isConfirmed => status == 'confirmed';
  bool get isPending => status == 'pending';
  bool get isPaid => paymentStatus == 'paid';

  /// Name to show when the venue was not populated into the response.
  String get venueName => venue?.name ?? 'Venue';

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    final dynamic rawVenue = json['venue'];
    final VenueModel? venue =
        rawVenue is Map<String, dynamic> ? VenueModel.fromJson(rawVenue) : null;

    return BookingModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      user: json['user'] as String? ?? '',
      venueId: venue?.id ?? (rawVenue is String ? rawVenue : ''),
      venue: venue,
      date: json['date'] as String? ?? '',
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      price: (json['price'] as num? ?? 0).toDouble(),
      status: json['status'] as String? ?? 'pending',
      paymentStatus: json['paymentStatus'] as String? ?? 'unpaid',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  /// Returns a copy with selected fields replaced — used for optimistic updates
  /// (e.g. flipping status to `cancelled` before the list is refetched).
  BookingModel copyWith({String? status, String? paymentStatus}) {
    return BookingModel(
      id: id,
      user: user,
      venueId: venueId,
      venue: venue,
      date: date,
      startTime: startTime,
      endTime: endTime,
      price: price,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      createdAt: createdAt,
    );
  }
}
