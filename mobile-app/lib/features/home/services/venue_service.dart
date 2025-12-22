import 'dart:convert';
import 'dart:io'; // Import File
import 'package:http/http.dart' as http;
import '../../../core/api_constants.dart';
import '../../../models/venue_model.dart';

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

  // Create Venue (Multipart)
  Future<VenueModel> createVenue(
    String token, 
    String name, 
    String description, 
    String location, 
    double price, 
    File imageFile
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
