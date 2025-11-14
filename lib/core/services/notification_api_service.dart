import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:anonymous_hubs/core/config/api_config.dart';
import 'package:anonymous_hubs/features/notification/data/models/notification_model.dart'; // Import Notification model
import 'package:anonymous_hubs/core/enums/notification_enums.dart'; // Import enums

class NotificationApiService {
  final http.Client _client;

  NotificationApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<NotificationModel>?> getNotifications(
    String token, {
    NotificationStatus? status,
    int limit = 100,
  }) async {
    final Map<String, String> queryParameters = {
      'limit': limit.toString(),
    };
    if (status != null) {
      queryParameters['status'] = status.value;
    }

    final Uri url = Uri.parse('${ApiConfig.baseUrl}/api/v1/notifications/notifications/')
        .replace(queryParameters: queryParameters);

    try {
      final response = await _client.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        return responseData
            .map((data) => NotificationModel.fromJson(data as Map<String, dynamic>))
            .toList();
      } else {
        print('Failed to load notifications: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error fetching notifications: $e');
      return null;
    }
  }

  Future<NotificationModel?> markNotificationAsRead(
    String token,
    String notificationId,
  ) async {
    final Uri url = Uri.parse(
        '${ApiConfig.baseUrl}/api/v1/notifications/$notificationId/read');

    try {
      final response = await _client.put( // Changed to PUT
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return NotificationModel.fromJson(responseData);
      } else {
        print('Failed to mark notification $notificationId as read: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error marking notification $notificationId as read: $e');
      return null;
    }
  }

  Future<bool> markAllNotificationsAsRead(String token) async {
    final Uri url = Uri.parse('${ApiConfig.baseUrl}/api/v1/notifications/mark_all_read');

    try {
      final response = await _client.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        print('Successfully marked all notifications as read.');
        return true;
      } else {
        print('Failed to mark all notifications as read: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error marking all notifications as read: $e');
      return false;
    }
  }

  void dispose() {
    _client.close();
  }
}

