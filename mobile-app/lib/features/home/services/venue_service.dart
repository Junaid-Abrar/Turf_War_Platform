import 'dart:convert';
import 'dart:io'; // Import File
import 'package:http/http.dart' as http;
import '../../../core/api_constants.dart';
import '../../../models/venue_model.dart';
import '../../../models/review_model.dart'; // Add

class VenueService {
  final String _venuesUrl = '${ApiConstants.baseUrl}${ApiConstants.venuesEndpoint}';

  // Helper for headers (Bypass LocalTunnel if needed)
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'bypass-tunnel-reminder': 'true',
  };

  // Get All Venues
  Future<List<VenueModel>> getVenues() async {
    final response = await http.get(
      Uri.parse(_venuesUrl),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final List<dynamic> data = body['data'];
      return data.map((json) => VenueModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load venues');
    }
  }

  // Search Venues
  Future<List<VenueModel>> searchVenues({
    String? query,
    double? minPrice,
    double? maxPrice,
    List<String>? amenities,
  }) async {
    final queryParams = <String, String>{};
    if (query != null && query.isNotEmpty) queryParams['query'] = query;
    if (minPrice != null) queryParams['minPrice'] = minPrice.toString();
    if (maxPrice != null) queryParams['maxPrice'] = maxPrice.toString();
    if (amenities != null && amenities.isNotEmpty) {
      queryParams['amenities'] = amenities.join(',');
    }

    final uri = Uri.parse('$_venuesUrl/search').replace(queryParameters: queryParams);

    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final List<dynamic> data = body['data'];
      return data.map((json) => VenueModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to search venues');
    }
  }

  // Get Reviews
  Future<List<ReviewModel>> getReviews(String venueId) async {
    final response = await http.get(
      Uri.parse('$_venuesUrl/$venueId/reviews'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final List<dynamic> data = body['data'];
      return data.map((json) => ReviewModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load reviews');
    }
  }

  // Add Review
  Future<ReviewModel> addReview(String token, String venueId, double rating, String comment) async {
    final response = await http.post(
      Uri.parse('$_venuesUrl/$venueId/reviews'),
      headers: {
        'Authorization': 'Bearer $token',
        ..._headers,
      },
      body: jsonEncode({
        'rating': rating,
        'comment': comment,
      }),
    );

    final body = jsonDecode(response.body);
    if (response.statusCode == 201) {
      return ReviewModel.fromJson(body['data']);
    } else {
      throw Exception(body['error'] ?? 'Failed to add review');
    }
  }

  // Create Venue (Multipart)
  Future<VenueModel> createVenue(
    String token, 
    String name, 
    String description, 
    String location, 
    double price, 
    File imageFile,
    [List<String> amenities = const []]
  ) async {
    final uri = Uri.parse(_venuesUrl);
    final request = http.MultipartRequest('POST', uri);

    // Headers
    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'bypass-tunnel-reminder': 'true',
    });

    // Text Fields
    request.fields['name'] = name;
    request.fields['description'] = description;
    request.fields['location'] = location;
    request.fields['pricePerHour'] = price.toString();
    // Send amenities as JSON array string
    if (amenities.isNotEmpty) {
      request.fields['amenities'] = jsonEncode(amenities);
    }

    // File
    final pic = await http.MultipartFile.fromPath('photo', imageFile.path);
    request.files.add(pic);

    // Send
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      final body = jsonDecode(response.body);
      return VenueModel.fromJson(body['data']);
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Failed to create venue');
    }
  }
}
