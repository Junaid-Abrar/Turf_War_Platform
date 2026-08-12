import 'dart:convert';
import 'dart:io';

import '../../../core/network/api_client.dart';
import '../../../models/review_model.dart';
import '../../../models/venue_model.dart';

class VenueService {
  final ApiClient _api;

  const VenueService(this._api);

  Future<List<VenueModel>> getVenues({int page = 1, int limit = 20}) async {
    final Map<String, dynamic> body = await _api.get(
      '/venues',
      queryParameters: <String, dynamic>{'page': page, 'limit': limit},
    );
    return unwrapList(body)
        .map((dynamic json) =>
            VenueModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<VenueModel> getVenue(String id) async {
    final Map<String, dynamic> body = await _api.get('/venues/$id');
    return VenueModel.fromJson(unwrapObject(body));
  }

  Future<List<VenueModel>> searchVenues({
    String? query,
    double? minPrice,
    double? maxPrice,
    List<String>? amenities,
  }) async {
    final Map<String, dynamic> params = <String, dynamic>{};
    if (query != null && query.isNotEmpty) params['query'] = query;
    if (minPrice != null) params['minPrice'] = minPrice;
    if (maxPrice != null) params['maxPrice'] = maxPrice;
    if (amenities != null && amenities.isNotEmpty) {
      params['amenities'] = amenities.join(',');
    }

    final Map<String, dynamic> body =
        await _api.get('/venues/search', queryParameters: params);
    return unwrapList(body)
        .map((dynamic json) =>
            VenueModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<ReviewModel>> getReviews(String venueId) async {
    final Map<String, dynamic> body =
        await _api.get('/venues/$venueId/reviews');
    return unwrapList(body)
        .map((dynamic json) =>
            ReviewModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<ReviewModel> addReview(
    String venueId,
    double rating,
    String comment,
  ) async {
    final Map<String, dynamic> body = await _api.post(
      '/venues/$venueId/reviews',
      body: <String, dynamic>{'rating': rating, 'comment': comment},
    );
    return ReviewModel.fromJson(unwrapObject(body));
  }

  Future<VenueModel> createVenue({
    required String name,
    required String description,
    required String location,
    required double pricePerHour,
    required File imageFile,
    List<String> amenities = const <String>[],
  }) async {
    final Map<String, dynamic> body = await _api.postMultipart(
      '/venues',
      fields: <String, dynamic>{
        'name': name,
        'description': description,
        'location': location,
        'pricePerHour': pricePerHour.toString(),
        // Multipart fields are strings, so the list is JSON-encoded; the
        // backend parses it back (see `controllers/venues.js`).
        if (amenities.isNotEmpty) 'amenities': jsonEncode(amenities),
      },
      fileField: 'photo',
      filePath: imageFile.path,
    );
    return VenueModel.fromJson(unwrapObject(body));
  }
}
