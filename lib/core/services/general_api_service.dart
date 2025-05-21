import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:empathy_hub_app/core/config/api_config.dart';

class GeneralApiService {
  final http.Client _client;

  GeneralApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetches the root endpoint of the API.
  ///
  /// Returns a map of the response data or null on failure.
  Future<Map<String, dynamic>?> getApiRoot() async {
    // Path from OpenAPI: GET /
    final Uri url = Uri.parse('${ApiConfig.baseUrl}/');

    try {
      final response = await _client.get(url);

      if (response.statusCode == 200) {
        // Assuming the root returns a JSON object
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        print('Failed to get API root: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error fetching API root: $e');
      return null;
    }
  }

  /// Performs a health check on the API.
  ///
  /// Returns a map of the health status or null on failure.
  Future<Map<String, dynamic>?> healthCheck() async {
    // Path from OpenAPI: GET /health
    final Uri url = Uri.parse('${ApiConfig.baseUrl}/health');

    try {
      final response = await _client.get(url);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        print('Health check failed: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error during health check: $e');
      return null;
    }
  }
}