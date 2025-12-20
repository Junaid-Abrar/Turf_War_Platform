import 'dart:convert';
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
}
