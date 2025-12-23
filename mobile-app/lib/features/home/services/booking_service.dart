import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/api_constants.dart';
import '../../../models/booking_model.dart';

class BookingService {
  final String _bookingsUrl = '${ApiConstants.baseUrl}${ApiConstants.bookingsEndpoint}';

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
    'bypass-tunnel-reminder': 'true',
  };

  // Create Booking
  Future<BookingModel> createBooking({
    required String token,
    required String venueId,
    required String date,
    required String startTime,
    required String endTime,
    required double price,
  }) async {
    final response = await http.post(
      Uri.parse(_bookingsUrl),
      headers: _headers(token),
      body: jsonEncode({
        'venueId': venueId,
        'date': date,
        'startTime': startTime,
        'endTime': endTime,
        'price': price,
      }),
    );

    final body = jsonDecode(response.body);
    if (response.statusCode == 201) {
      return BookingModel.fromJson(body['data']);
    } else {
      throw Exception(body['error'] ?? 'Failed to create booking');
    }
  }

  // Get My Bookings
  Future<List<BookingModel>> getMyBookings(String token) async {
    final response = await http.get(
      Uri.parse('$_bookingsUrl/my'),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final List<dynamic> data = body['data'];
      return data.map((json) => BookingModel.fromJson(json)).toList();
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Failed to fetch bookings');
    }
  }

  // Get Venue Bookings (Availability)
  Future<List<Map<String, dynamic>>> getVenueBookings(String venueId) async {
    final response = await http.get(
      Uri.parse('$_bookingsUrl/venue/$venueId'),
      headers: {
        'Content-Type': 'application/json',
        'bypass-tunnel-reminder': 'true',
      },
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final List<dynamic> data = body['data'];
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Failed to fetch availability');
    }
  }
}
