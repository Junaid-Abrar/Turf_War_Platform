import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../features/home/services/booking_service.dart';
import '../models/booking_model.dart';

class BookingProvider extends ChangeNotifier {
  final BookingService _bookingService = BookingService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  List<BookingModel> _myBookings = [];
  bool _isLoading = false;
  String? _error;

  List<BookingModel> get myBookings => _myBookings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch User's Bookings
  Future<void> fetchMyBookings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) throw Exception('Authentication required');

      _myBookings = await _bookingService.getMyBookings(token);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create a new booking
  Future<void> bookVenue({
    required String venueId,
    required String date,
    required String startTime,
    required String endTime,
    required double price,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) throw Exception('Authentication required');

      final newBooking = await _bookingService.createBooking(
        token: token,
        venueId: venueId,
        date: date,
        startTime: startTime,
        endTime: endTime,
        price: price,
      );

      _myBookings.insert(0, newBooking); // Add to top of list
      notifyListeners();
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get availability for a specific venue
  Future<List<Map<String, dynamic>>> getVenueAvailability(String venueId) async {
    return await _bookingService.getVenueBookings(venueId);
  }
}
