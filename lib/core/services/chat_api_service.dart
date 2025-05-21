import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:empathy_hub_app/core/config/api_config.dart';
import 'package:empathy_hub_app/features/chat/data/models/models.dart'; // Our barrel file for chat models

class ChatApiService {
  final http.Client _client;

  // Constructor, allowing for an http.Client to be injected for testing
  ChatApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<ChatRoom>?> getChatRooms(
    String token, {
    int skip = 0,
    int limit = 20,
  }) async {
    final Uri url = Uri.parse('${ApiConfig.baseUrl}/api/v1/chats/')
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
    final Uri url = Uri.parse('${ApiConfig.baseUrl}/api/v1/chats/requests/pending')
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
        '${ApiConfig.baseUrl}/api/v1/chat-requests/$requestAnonymousId/accept');

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
        return null;
      }
    } catch (e) {
      print('Error accepting chat request $requestAnonymousId: $e');
      return null;
    }
  }

  Future<ChatRequest?> declineChatRequest(
    String token,
    String requestAnonymousId,
  ) async {
    final Uri url = Uri.parse(
        '${ApiConfig.baseUrl}/api/v1/chat-requests/$requestAnonymousId/decline');

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
  /// Returns either a [ChatRoom] if a room is created/found,
  /// or a [ChatRequest] if a request is sent, or null on failure.
  /// The calling code will need to check the type of the returned object.
  Future<dynamic> initiateDirectChatOrRequest(
    String token,
    ChatInitiate chatInitiateData,
  ) async {
    final Uri url =
        Uri.parse('${ApiConfig.baseUrl}/api/v1/chats/initiate-direct');

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
        // Determine the type of response based on key presence.
        // ChatRoomRead has 'anonymous_room_id', ChatRequestRead has 'anonymous_request_id'.
        if (responseData.containsKey('anonymous_room_id')) {
          return ChatRoom.fromJson(responseData);
        } else if (responseData.containsKey('anonymous_request_id')) {
          return ChatRequest.fromJson(responseData);
        } else {
          // Should not happen if API conforms to docs
          print('Unknown response type from initiate-direct: $responseData');
          return null;
        }
      } else {
        print('Failed to initiate chat/request: ${response.statusCode} ${response.body}');
        // You could parse the error body here if it's structured
        // e.g., return response.body as String to show the error message.
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
    final Uri url = Uri.parse('${ApiConfig.baseUrl}/api/v1/chats/$roomAnonymousId/messages')
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

  // Helper to close the client when the service is disposed, if needed.
  void dispose() {
    _client.close();
  }
}