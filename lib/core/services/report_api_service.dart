import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:anonymous_hubs/core/config/api_config.dart';
import 'package:anonymous_hubs/core/enums/app_enums.dart';
import 'package:anonymous_hubs/features/report/data/models/report_models.dart'; // Our barrel file for report models

class ReportApiService {
  final http.Client _client;

  ReportApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Submits a new report.
  ///
  /// Requires an authentication [token] and the [reportData] (ReportCreate).
  /// Returns the created report data (ReportRead) or null on failure.
  Future<ReportRead?> submitReport(
    String token,
    ReportCreate reportData,
  ) async {
    // Path from OpenAPI: POST /api/v1/reports/
    final Uri url = Uri.parse('${ApiConfig.baseUrl}/api/v1/reports/');

    try {
      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(reportData.toJson()),
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return ReportRead.fromJson(responseData);
      } else {
        print('Failed to submit report: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error submitting report: $e');
      return null;
    }
  }

  /// Lists all reports (Admin endpoint).
  ///
  /// Requires an authentication [token] (presumably with admin privileges).
  /// Optional [skip], [limit] for pagination, and [status] for filtering.
  /// Returns a list of report data (ReportRead) or null on failure.
  Future<List<ReportRead>?> listReportsAdmin(
    String token, {
    int skip = 0,
    int limit = 20,
    ReportStatus? status,
  }) async {
    // Path from OpenAPI: GET /api/v1/reports/admin/
    final Map<String, String> queryParameters = {
      'skip': skip.toString(),
      'limit': limit.toString(),
    };
    if (status != null) {
      queryParameters['status'] = status.backendValue;
    }

    final Uri url = Uri.parse('${ApiConfig.baseUrl}/api/v1/reports/admin/')
        .replace(queryParameters: queryParameters);

    try {
      final response = await _client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        return responseData
            .map((data) => ReportRead.fromJson(data as Map<String, dynamic>))
            .toList();
      } else {
        print('Failed to list reports (Admin): ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error listing reports (Admin): $e');
      return null;
    }
  }

  /// Gets details for a specific report (Admin endpoint).
  ///
  /// Requires an authentication [token] (presumably with admin privileges)
  /// and the [reportAnonymousId].
  /// Returns the report data (ReportRead) or null on failure.
  Future<ReportRead?> getReportAdmin(
    String token,
    String reportAnonymousId,
  ) async {
    // Path from OpenAPI: GET /api/v1/reports/admin/{report_anonymous_id}
    final Uri url = Uri.parse(
        '${ApiConfig.baseUrl}/api/v1/reports/admin/$reportAnonymousId');

    try {
      final response = await _client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return ReportRead.fromJson(responseData);
      } else {
        print('Failed to get report $reportAnonymousId (Admin): ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error getting report $reportAnonymousId (Admin): $e');
      return null;
    }
  }

  /// Updates a report's status and admin notes (Admin endpoint).
  ///
  /// Requires an authentication [token] (presumably with admin privileges),
  /// the [reportAnonymousId], and the [reportUpdateData] (ReportUpdate).
  /// Returns the updated report data (ReportRead) or null on failure.
  Future<ReportRead?> updateReportAdmin(
    String token,
    String reportAnonymousId,
    ReportUpdate reportUpdateData,
  ) async {
    // Path from OpenAPI: PUT /api/v1/reports/admin/{report_anonymous_id}
    final Uri url = Uri.parse(
        '${ApiConfig.baseUrl}/api/v1/reports/admin/$reportAnonymousId');

    try {
      final response = await _client.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(reportUpdateData.toJson()),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return ReportRead.fromJson(responseData);
      } else {
        print('Failed to update report $reportAnonymousId (Admin): ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error updating report $reportAnonymousId (Admin): $e');
      return null;
    }
  }

  void dispose() {
    _client.close();
  }
}