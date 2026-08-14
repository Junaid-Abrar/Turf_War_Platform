import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../../../models/booking_model.dart';
import '../services/booking_service.dart';

class BookingProvider extends ChangeNotifier {
  final BookingService _bookingService;

  BookingProvider(this._bookingService);

  List<BookingModel> _myBookings = <BookingModel>[];
  bool _isLoading = false;
  String? _error;

  List<BookingModel> get myBookings =>
      List<BookingModel>.unmodifiable(_myBookings);
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<BookingModel> get upcomingBookings => _myBookings
      .where((BookingModel b) => !b.isCancelled && _isFuture(b))
      .toList();

  List<BookingModel> get pastBookings => _myBookings
      .where((BookingModel b) => !b.isCancelled && !_isFuture(b))
      .toList();

  List<BookingModel> get cancelledBookings =>
      _myBookings.where((BookingModel b) => b.isCancelled).toList();

  Future<void> fetchMyBookings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final List<BookingModel> fetched = await _bookingService.getMyBookings();
      // Guard against a refetch racing ahead of the backend's own payment
      // confirmation (e.g. the Stripe webhook not having landed yet): never
      // let a fresh read downgrade a booking `markPaid` already flipped
      // locally, since the paid card charge is already a fact by then.
      final Set<String> locallyPaidIds = _myBookings
          .where((BookingModel b) => b.paymentStatus == 'paid')
          .map((BookingModel b) => b.id)
          .toSet();
      _myBookings = fetched
          .map((BookingModel b) => locallyPaidIds.contains(b.id) && b.paymentStatus != 'paid'
              ? b.copyWith(paymentStatus: 'paid')
              : b)
          .toList();
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Creates a booking. Price is not passed — the backend computes it from the
  /// venue rate and slot duration.
  Future<BookingModel> bookVenue({
    required String venueId,
    required String date,
    required String startTime,
    required String endTime,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final BookingModel booking = await _bookingService.createBooking(
        venueId: venueId,
        date: date,
        startTime: startTime,
        endTime: endTime,
      );
      _myBookings = <BookingModel>[booking, ..._myBookings];
      return booking;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cancelBooking(String bookingId) async {
    final BookingModel updated =
        await _bookingService.cancelBooking(bookingId);
    _myBookings = _myBookings
        .map((BookingModel b) => b.id == updated.id ? updated : b)
        .toList();
    notifyListeners();
  }

  /// Confirmed bookings for a venue, used to mark slots unavailable.
  Future<List<BookingModel>> getVenueAvailability(String venueId) =>
      _bookingService.getVenueBookings(venueId);

  /// Marks a booking paid locally so the "Pay Now" button disappears without
  /// waiting for a refetch.
  void markPaid(String bookingId) {
    _myBookings = _myBookings
        .map((BookingModel b) =>
            b.id == bookingId ? b.copyWith(paymentStatus: 'paid') : b)
        .toList();
    notifyListeners();
  }

  bool _isFuture(BookingModel booking) {
    final DateTime? date = DateTime.tryParse(booking.date);
    if (date == null) return true;
    final DateTime today = DateTime.now();
    return !date.isBefore(DateTime(today.year, today.month, today.day));
  }
}
