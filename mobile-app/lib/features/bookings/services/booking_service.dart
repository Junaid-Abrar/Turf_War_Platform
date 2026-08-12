import '../../../core/network/api_client.dart';
import '../../../models/booking_model.dart';

class BookingService {
  final ApiClient _api;

  const BookingService(this._api);

  /// Creates a booking.
  ///
  /// Note there is no `price` parameter: since the Phase 1 backend fix the price
  /// is computed server-side from the venue rate and the slot duration, and a
  /// client-supplied price is ignored.
  Future<BookingModel> createBooking({
    required String venueId,
    required String date,
    required String startTime,
    required String endTime,
  }) async {
    final Map<String, dynamic> body = await _api.post(
      '/bookings',
      body: <String, dynamic>{
        'venueId': venueId,
        'date': date,
        'startTime': startTime,
        'endTime': endTime,
      },
    );
    return BookingModel.fromJson(unwrapObject(body));
  }

  Future<List<BookingModel>> getMyBookings({int page = 1, int limit = 50}) async {
    final Map<String, dynamic> body = await _api.get(
      '/bookings/my',
      queryParameters: <String, dynamic>{'page': page, 'limit': limit},
    );
    return unwrapList(body)
        .map((dynamic json) =>
            BookingModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Confirmed bookings for a venue — used to grey out taken slots. Public
  /// endpoint that returns only date/time, never user details.
  Future<List<BookingModel>> getVenueBookings(String venueId) async {
    final Map<String, dynamic> body =
        await _api.get('/bookings/venue/$venueId');
    return unwrapList(body)
        .map((dynamic json) =>
            BookingModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<BookingModel> cancelBooking(String bookingId) async {
    final Map<String, dynamic> body =
        await _api.patch('/bookings/$bookingId/cancel');
    return BookingModel.fromJson(unwrapObject(body));
  }
}
