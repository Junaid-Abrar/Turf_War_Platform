import 'package:flutter/material.dart';
import '../features/home/services/venue_service.dart';
import '../models/venue_model.dart';

class VenueProvider extends ChangeNotifier {
  final VenueService _venueService = VenueService();
  
  List<VenueModel> _venues = [];
  bool _isLoading = false;
  String? _error;

  List<VenueModel> get venues => _venues;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchVenues() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _venues = await _venueService.getVenues();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
