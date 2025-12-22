import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../features/home/services/venue_service.dart';
import '../models/venue_model.dart';

class VenueProvider extends ChangeNotifier {
  final VenueService _venueService = VenueService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
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

  Future<void> createVenue({
    required String name,
    required String description,
    required String location,
    required double price,
    required File imageFile,
  }) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) throw Exception('No auth token found');

      // Call Service
      final newVenue = await _venueService.createVenue(
        token, name, description, location, price, imageFile
      );

      // Add to local list immediately (Optimistic UI update)
      _venues.add(newVenue);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
}
