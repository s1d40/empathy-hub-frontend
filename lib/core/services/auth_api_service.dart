import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:empathy_hub_app/core/config/api_config.dart';
import 'package:empathy_hub_app/features/user/data/models/user_models.dart'; // For UserSimple

class AuthApiService {
  final http.Client _client;

  AuthApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<String?> createAnonymousUser({String? username, String? avatarUrl}) async {
    // Path from OpenAPI: /api/v1/users/
    final Uri url = Uri.parse('${ApiConfig.baseUrl}/api/v1/users/');
    try {
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          // Send an empty username to let backend generate "AnonymousX"
          // Or send a specific username if the user provided one
          'username': username, 
          'avatar_url': avatarUrl,
          // bio, pronouns can be null or omitted
          // chat_availability will use backend default
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['access_token'] as String?;
      } else {
        // Handle error, e.g., log it or throw a custom exception
        print('Failed to create user: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error during user creation: $e');
      return null;
    }
  }

  Future<List<String>> getDefaultAvatarUrls() async {
    // Path from backend message: /api/v1/avatars/defaults
    final Uri url = Uri.parse('${ApiConfig.baseUrl}/api/v1/avatars/defaults');
    try {
      final response = await _client.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final baseUri = Uri.parse(ApiConfig.baseUrl);
        return data.map((item) {
          String path = item.toString();
          // Uri.resolve will correctly handle if path is already an absolute URL,
          // or if it's a server-relative path (e.g., "/static/foo.jpg")
          return baseUri.resolve(path).toString();
        }).toList();
      } else {
        print('Failed to get default avatar URLs: ${response.statusCode} ${response.body}');
        return []; // Return empty list on error
      }
    } catch (e) {
      print('Error fetching default avatar URLs: $e');
      return []; // Return empty list on exception
    }
  }

  Future<Map<String, dynamic>?> getUserProfile(String token) async {
    // Path from OpenAPI: /api/v1/users/me
    final Uri url = Uri.parse('${ApiConfig.baseUrl}/api/v1/users/me');
    try {
      final response = await _client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Crucial: Send the token
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        // Handle error, e.g., log it or throw a custom exception
        // This could happen if the token is expired or invalid
        print('Failed to get user profile: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  Future<String?> getTokenByAnonymousId(String anonymousId) async {
    // Path from OpenAPI: /api/v1/auth/token
    final Uri url = Uri.parse('${ApiConfig.baseUrl}/api/v1/auth/token');
    try {
      // OpenAPI spec for this endpoint:
      // Request Content-Type: application/x-www-form-urlencoded
      // Request Body Description: "Expects an existing anonymous_id to be provided in the 'username' form field."
      // Note: The schema 'Body_login_for_access_token_api_v1_auth_token_post' lists 'identifier',
      // but we're following the more specific description and common OAuth2 practice.
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'username': anonymousId}, // 'username' field carries the anonymous_id
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['access_token'] as String?;
      } else {
        // Handle error, e.g., user not found, invalid UUID
        print(
            'Failed to get token by anonymous_id: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error during getTokenByAnonymousId: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> updateUserProfile(
    String token, {
    // Fields based on UserUpdate schema from OpenAPI
    String? username,
    String? bio,
    String? pronouns,
    String? chatAvailability, // Should match ChatAvailabilityEnum string values from backend
    String? avatarUrl,
    bool? isActive,
  }) async {
    // Path from OpenAPI: /api/v1/users/me (PUT)
    final Uri url = Uri.parse('${ApiConfig.baseUrl}/api/v1/users/me');
    
    final Map<String, dynamic> body = {};
    // Only include fields in the body if they are provided (not null)
    if (username != null) body['username'] = username;
    if (bio != null) body['bio'] = bio;
    if (pronouns != null) body['pronouns'] = pronouns;
    if (chatAvailability != null) body['chat_availability'] = chatAvailability;
    if (avatarUrl != null) body['avatar_url'] = avatarUrl;
    if (isActive != null) body['is_active'] = isActive;

    if (body.isEmpty) {
      // Avoid making a request if there's nothing to update
      print('updateUserProfile called with no fields to update.');
      // Optionally, you could return the current profile by calling getUserProfile,
      // or simply return null indicating no update was performed.
      return null; 
    }

    try {
      final response = await _client.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>; // Returns UserRead schema
      } else {
        print('Failed to update user profile: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error updating user profile: $e');
      return null;
    }
  }
/// Deletes the currently authenticated user's profile.
  ///
  /// Requires an authentication [token].
  /// Returns true on successful deletion (HTTP 204), false otherwise.
  Future<bool> deleteCurrentUser(String token) async {
    // Path from OpenAPI: DELETE /api/v1/users/me
    final Uri url = Uri.parse('${ApiConfig.baseUrl}/api/v1/users/me');

    try {
      final response = await _client.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 204) { // Successful deletion, no content
        return true;
      } else {
        print('Failed to delete current user: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error deleting current user: $e');
      return false;
    }
  }

  /// Lists users muted by the current authenticated user.
  ///
  /// Requires an authentication [token].
  /// Optional [skip] and [limit] for pagination.
  /// Returns a list of [UserSimple] objects or null on failure.
  Future<List<UserSimple>?> listMutedUsers(
    String token, {
    int skip = 0,
    int limit = 20,
  }) async {
    // Path from OpenAPI: GET /api/v1/users/me/muted
    final Map<String, String> queryParameters = {
      'skip': skip.toString(),
      'limit': limit.toString(),
    };
    final Uri url = Uri.parse('${ApiConfig.baseUrl}/api/v1/users/me/muted')
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
            .map((data) => UserSimple.fromJson(data as Map<String, dynamic>))
            .toList();
      } else {
        print('Failed to list muted users: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error listing muted users: $e');
      return null;
    }
  }

  /// Lists users blocked by the current authenticated user.
  ///
  /// Requires an authentication [token].
  /// Optional [skip] and [limit] for pagination.
  /// Returns a list of [UserSimple] objects or null on failure.
  Future<List<UserSimple>?> listBlockedUsers(
    String token, {
    int skip = 0,
    int limit = 20,
  }) async {
    // Path from OpenAPI: GET /api/v1/users/me/blocked
    final Map<String, String> queryParameters = {
      'skip': skip.toString(),
      'limit': limit.toString(),
    };
    final Uri url = Uri.parse('${ApiConfig.baseUrl}/api/v1/users/me/blocked')
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
            .map((data) => UserSimple.fromJson(data as Map<String, dynamic>))
            .toList();
      } else {
        print('Failed to list blocked users: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error listing blocked users: $e');
      return null;
    }
  }

  /// Erases all posts for the currently authenticated user.
  ///
  /// Requires an authentication [token].
  /// Returns true on successful deletion (HTTP 204), false otherwise.
  Future<bool> eraseAllMyPosts(String token) async {
    // Assumed Endpoint: DELETE /api/v1/users/me/posts
    final Uri url = Uri.parse('${ApiConfig.baseUrl}/api/v1/users/me/posts');
    try {
      final response = await _client.delete(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 204) {
        return true;
      } else {
        print('Failed to erase all posts: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error erasing all posts: $e');
      return false;
    }
  }

  /// Erases all comments for the currently authenticated user.
  ///
  /// Requires an authentication [token].
  /// Returns true on successful deletion (HTTP 204), false otherwise.
  Future<bool> eraseAllMyComments(String token) async {
    // Assumed Endpoint: DELETE /api/v1/users/me/comments
    final Uri url = Uri.parse('${ApiConfig.baseUrl}/api/v1/users/me/comments');
    try {
      final response = await _client.delete(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 204) {
        return true;
      } else {
        print('Failed to erase all comments: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error erasing all comments: $e');
      return false;
    }
  }

  /// Erases all chat messages for the currently authenticated user.
  ///
  /// Requires an authentication [token].
  /// Returns true on successful deletion (HTTP 204), false otherwise.
  Future<bool> eraseAllMyChatMessages(String token) async {
    // Assumed Endpoint: DELETE /api/v1/users/me/chat-messages
    final Uri url = Uri.parse('${ApiConfig.baseUrl}/api/v1/users/me/chat-messages');
    try {
      final response = await _client.delete(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 204) {
        return true;
      } else {
        print('Failed to erase all chat messages: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error erasing all chat messages: $e');
      return false;
    }
  }

  /// Erases all account information (posts, comments, chats) for the currently authenticated user.
  ///
  /// Requires an authentication [token].
  /// Returns true on successful deletion (HTTP 204), false otherwise.
  Future<bool> eraseAllMyAccountInfo(String token) async {
    // Assumed Endpoint: DELETE /api/v1/users/me/all-content
    final Uri url = Uri.parse('${ApiConfig.baseUrl}/api/v1/users/me/all-content');
    try {
      final response = await _client.delete(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 204) {
        return true;
      } else {
        print('Failed to erase all account info: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error erasing all account info: $e');
      return false;
    }
  }
}