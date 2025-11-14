import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:anonymous_hubs/core/config/api_config.dart';
import 'package:anonymous_hubs/features/chat/data/models/models.dart'; // Our barrel file for chat models
import 'package:anonymous_hubs/core/services/api_exception.dart'; // Import the new ApiException

class ChatApiService {
  final http.Client _client;

  // Constructor, allowing for an http.Client to be injected for testing
  ChatApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<ChatRoom>?> getChatRooms(
    String token, {
    int skip = 0,
    int limit = 20,
  }) async {
    final Uri url = Uri.parse('${ApiConfig.baseUrl}/api/v1/chat/')
        .replace(queryParameters: {
      'skip': skip.toString(),
      'limit': limit.toString(),
    });
    //print('[ChatApiService] Fetching chat rooms from URL: $url');
    //print('[ChatApiService] Using token for getChatRooms: $token');
    try {
      final response = await _client.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      //print('[ChatApiService] GetChatRooms Response Status: ${response.statusCode}');
      //print('[ChatApiService] GetChatRooms Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        return responseData
            .map((data) => ChatRoom.fromJson(data as Map<String, dynamic>))
            .toList();
      } else {
        // Log error or handle specific status codes
        print(
            'Failed to load chat rooms: ${response.statusCode} ${response.body}');
        // You might want to parse the error response body if your API provides structured errors
        return null;
      }
    } catch (e) {
      print('Error fetching chat rooms: $e');
      return null;
    }
  }

  Future<List<ChatRequest>?> getPendingChatRequests(
    String token, {
    int skip = 0,
    int limit = 20,
  }) async {
    final Uri url = Uri.parse('${ApiConfig.baseUrl}/api/v1/chat/requests/pending')
        .replace(queryParameters: {
      'skip': skip.toString(),
      'limit': limit.toString(),
    });

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
            .map((data) => ChatRequest.fromJson(data as Map<String, dynamic>))
            .toList();
      } else {
        print(
            'Failed to load pending chat requests: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error fetching pending chat requests: $e');
      return null;
    }
  }

  Future<ChatRoom?> acceptChatRequest(
    String token,
    String requestAnonymousId,
  ) async {
    final Uri url = Uri.parse(
        '${ApiConfig.baseUrl}/api/v1/chat/requests/$requestAnonymousId/accept');

    try {
      final response = await _client.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      // The backend doc says 200 OK or 201 Created
      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return ChatRoom.fromJson(responseData);
      } else {
        print('Failed to accept chat request $requestAnonymousId: ${response.statusCode} ${response.body}');
        throw ApiException(response.statusCode, response.body);
      }
    } catch (e) {
      print('Error accepting chat request $requestAnonymousId: $e');
      rethrow; // Rethrow to be caught by the Cubit
    }
  }

  Future<ChatRequest?> declineChatRequest(
    String token,
    String requestAnonymousId,
  ) async {
    final Uri url = Uri.parse(
        '${ApiConfig.baseUrl}/api/v1/chat/requests/$requestAnonymousId/decline');

    try {
      final response = await _client.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return ChatRequest.fromJson(responseData);
      } else {
        print('Failed to decline chat request $requestAnonymousId: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error declining chat request $requestAnonymousId: $e');
      return null;
    }
  }

  /// Initiates a direct chat or sends a chat request.
  ///
  /// Returns a [ChatInitiationResponse] object indicating whether a [ChatRoom]
  /// or [ChatRequest] was returned, and if the [ChatRequest] was an existing one.
  /// Returns null on failure.
  Future<ChatInitiationResponse?> initiateDirectChatOrRequest(
    String token,
    ChatInitiate chatInitiateData,
  ) async {
    final Uri url =
        Uri.parse('${ApiConfig.baseUrl}/api/v1/chat/initiate-direct');

    try {
      final response = await _client.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(chatInitiateData.toJson()),
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData.containsKey('anonymous_room_id')) {
          return ChatInitiationResponse(
            chatRoom: ChatRoom.fromJson(responseData),
            isExisting: true, // ChatRoom is always considered existing if returned
          );
        } else if (responseData.containsKey('anonymous_request_id')) {
          final bool isNewRequest = responseData['is_new_request'] ?? false; // Default to false if not present
          return ChatInitiationResponse(
            chatRequest: ChatRequest.fromJson(responseData),
            isExisting: !isNewRequest, // If it's NOT a new request, it's an existing one
          );
        } else {
          print('Unknown response type from initiate-direct: $responseData');
          return null;
        }
      } else {
        print('Failed to initiate chat/request: ${response.statusCode} ${response.body}');
        return null; 
      }
    } catch (e) {
      print('Error initiating chat/request: $e');
      return null;
    }
  }

  Future<List<ChatMessage>?> getChatMessages(
    String token,
    String roomAnonymousId, {
    int skip = 0,
    int limit = 20, // Or a higher default like 50 for messages
  }) async {
    final Uri url = Uri.parse('${ApiConfig.baseUrl}/api/v1/chat/$roomAnonymousId/messages')
        .replace(queryParameters: {
      'skip': skip.toString(),
      'limit': limit.toString(),
    });

    print('[ChatApiService] Fetching messages for room $roomAnonymousId from URL: $url');
    print('[ChatApiService] Using token for getChatMessages: $token');

    try {
      final response = await _client.get(url, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });

      print('[ChatApiService] GetChatMessages Response Status for room $roomAnonymousId: ${response.statusCode}');
      print('[ChatApiService] GetChatMessages Response Body for room $roomAnonymousId: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        return responseData.map((data) => ChatMessage.fromJson(data as Map<String, dynamic>)).toList();
      } else {
        print('Failed to load messages for room $roomAnonymousId: ${response.statusCode} ${response.body}');
        // You could potentially return the error body here if needed by the Cubit
        return null;
      }
    } catch (e) {
      print('Error fetching messages for room $roomAnonymousId: $e');
      return null;
    }
  }

  Future<ChatRoom?> markChatRoomAsRead(
    String token,
    String roomAnonymousId,
  ) async {
    final Uri url = Uri.parse(
        '${ApiConfig.baseUrl}/api/v1/chat/$roomAnonymousId/mark-read');

    try {
      final response = await _client.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return ChatRoom.fromJson(responseData);
      } else {
        print('Failed to mark chat room $roomAnonymousId as read: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error marking chat room $roomAnonymousId as read: $e');
      return null;
    }
  }

  // Helper to close the client when the service is disposed, if needed.
  void dispose() {
    _client.close();
  }
}