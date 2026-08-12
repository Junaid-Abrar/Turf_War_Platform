import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../../../models/review_model.dart';
import '../../../models/venue_model.dart';
import '../services/venue_service.dart';

class VenueProvider extends ChangeNotifier {
  final VenueService _venueService;

  VenueProvider(this._venueService);

  List<VenueModel> _venues = <VenueModel>[];
  bool _isLoading = false;
  String? _error;

  List<VenueModel> get venues => List<VenueModel>.unmodifiable(_venues);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;

  Future<void> fetchVenues() =>
      _load(() => _venueService.getVenues());

  Future<void> searchVenues({
    String? query,
    double? minPrice,
    double? maxPrice,
    List<String>? amenities,
  }) {
    final bool hasFilters = (query != null && query.isNotEmpty) ||
        minPrice != null ||
        maxPrice != null ||
        (amenities != null && amenities.isNotEmpty);

    // An empty search is just the full list — avoids hitting /search with no
    // criteria and getting a differently-sorted result set back.
    if (!hasFilters) return fetchVenues();

    return _load(
      () => _venueService.searchVenues(
        query: query,
        minPrice: minPrice,
        maxPrice: maxPrice,
        amenities: amenities,
      ),
    );
  }

  Future<List<ReviewModel>> getReviews(String venueId) =>
      _venueService.getReviews(venueId);

  Future<void> addReview(String venueId, double rating, String comment) async {
    await _venueService.addReview(venueId, rating, comment);
    notifyListeners();
  }

  Future<VenueModel> createVenue({
    required String name,
    required String description,
    required String location,
    required double pricePerHour,
    required File imageFile,
    List<String> amenities = const <String>[],
  }) async {
    final VenueModel venue = await _venueService.createVenue(
      name: name,
      description: description,
      location: location,
      pricePerHour: pricePerHour,
      imageFile: imageFile,
      amenities: amenities,
    );
    _venues = <VenueModel>[venue, ..._venues];
    notifyListeners();
    return venue;
  }

  /// Shared loading/error scaffolding for the list-producing calls.
  Future<void> _load(Future<List<VenueModel>> Function() request) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _venues = await request();
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
