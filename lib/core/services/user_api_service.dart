import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:anonymous_hubs/core/config/api_config.dart';
import 'package:anonymous_hubs/features/user/data/models/user_models.dart'; // For UserRelationshipRead

class UserApiService {
  final http.Client _client;

  UserApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetches a list of users.
  ///
  /// Requires an authentication [token].
  /// Optional [skip] and [limit] for pagination.
  /// Returns a list of user data maps (UserRead schema) or null on failure.
  Future<List<Map<String, dynamic>>?> getUsersList(
    String token, {
    int? skip,
    int? limit,
  }) async {
    // Path from OpenAPI: GET /api/v1/users/
    final Map<String, String> queryParameters = {};
    if (skip != null) queryParameters['skip'] = skip.toString();
    if (limit != null) queryParameters['limit'] = limit.toString();

    final Uri url = Uri.parse('${ApiConfig.baseUrl}/api/v1/users/')
        .replace(queryParameters: queryParameters.isNotEmpty ? queryParameters : null);

    try {
      final response = await _client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> decodedData = jsonDecode(response.body);
        return decodedData.cast<Map<String, dynamic>>();
      } else {
        print('Failed to get users list: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error fetching users list: $e');
      return null;
    }
  }

  /// Fetches a specific user by their public anonymous ID (UUID).
  ///
  /// Requires an authentication [token] and the [userAnonymousId] (String UUID).
  /// Returns user data map (UserRead schema) or null on failure.
  Future<Map<String, dynamic>?> getUserByAnonymousId(
      String token, String userAnonymousId) async {
    // Path from backend route: GET /api/v1/users/anonymous/{user_anonymous_id}
    final Uri url = Uri.parse(
        '${ApiConfig.baseUrl}/api/v1/users/anonymous/$userAnonymousId');

    try {
      final response = await _client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 404) {
        print('User with anonymous ID $userAnonymousId not found: ${response.statusCode} ${response.body}');
        return null;
      } else {
        print('Failed to get user by anonymous ID $userAnonymousId: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error fetching user by anonymous ID $userAnonymousId: $e');
      return null;
    }
  }

  /// Fetches posts by a specific author's anonymous ID.
  ///
  /// Requires an authentication [token], the [authorAnonymousId] (String UUID).
  /// Optional [skip] and [limit] for pagination.
  /// Returns a list of post data maps (PostRead schema) or null on failure.
  Future<List<Map<String, dynamic>>?> getPostsByAuthor(
    String token,
    String authorAnonymousId, {
    int? skip,
    int? limit,
  }) async {
    // Path from OpenAPI: GET /api/v1/users/{author_anonymous_id}/posts
    final Map<String, String> queryParameters = {};
    if (skip != null) queryParameters['skip'] = skip.toString();
    if (limit != null) queryParameters['limit'] = limit.toString();

    final Uri url = Uri.parse(
            '${ApiConfig.baseUrl}/api/v1/users/$authorAnonymousId/posts')
        .replace(queryParameters: queryParameters.isNotEmpty ? queryParameters : null);

    try {
      final response = await _client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> decodedData = jsonDecode(response.body);
        return decodedData.cast<Map<String, dynamic>>();
      } else {
        print('Failed to get posts by author $authorAnonymousId: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error fetching posts by author $authorAnonymousId: $e');
      return null;
    }
  }

  /// Fetches comments by a specific author's anonymous ID.
  ///
  /// Requires an authentication [token], the [authorAnonymousId] (String UUID).
  /// Optional [skip] and [limit] for pagination.
  /// Returns a list of comment data maps (CommentRead schema) or null on failure.
  Future<List<Map<String, dynamic>>?> getCommentsByAuthor(
    String token,
    String authorAnonymousId, {
    int? skip,
    int? limit,
  }) async {
    // Path from OpenAPI: GET /api/v1/users/{author_anonymous_id}/comments
    final Map<String, String> queryParameters = {};
    if (skip != null) queryParameters['skip'] = skip.toString();
    if (limit != null) queryParameters['limit'] = limit.toString();

    final Uri url = Uri.parse(
            '${ApiConfig.baseUrl}/api/v1/users/$authorAnonymousId/comments')
        .replace(queryParameters: queryParameters.isNotEmpty ? queryParameters : null);

    try {
      final response = await _client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> decodedData = jsonDecode(response.body);
        return decodedData.cast<Map<String, dynamic>>();
      } else {
        print('Failed to get comments by author $authorAnonymousId: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error fetching comments by author $authorAnonymousId: $e');
      return null;
    }
  }

  /// Mutes a target user.
  ///
  /// Requires an authentication [token] and the [targetUserAnonymousId].
  /// Returns [UserRelationshipRead] on success (HTTP 201), null otherwise.
  Future<UserRelationshipRead?> muteUser(
    String token,
    String targetUserAnonymousId,
  ) async {
    // Path from OpenAPI: POST /api/v1/users/{target_user_anonymous_id}/mute
    final Uri url = Uri.parse(
        '${ApiConfig.baseUrl}/api/v1/users/$targetUserAnonymousId/mute');

    try {
      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json', // Though no body, good practice
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return UserRelationshipRead.fromJson(responseData);
      } else {
        print('Failed to mute user $targetUserAnonymousId: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error muting user $targetUserAnonymousId: $e');
      return null;
    }
  }

  /// Unmutes a target user.
  ///
  /// Requires an authentication [token] and the [targetUserAnonymousId].
  /// Returns true on success (HTTP 204), false otherwise.
  Future<bool> unmuteUser(
    String token,
    String targetUserAnonymousId,
  ) async {
    // Path from OpenAPI: DELETE /api/v1/users/{target_user_anonymous_id}/unmute
    final Uri url = Uri.parse(
        '${ApiConfig.baseUrl}/api/v1/users/$targetUserAnonymousId/unmute');

    try {
      final response = await _client.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 204) {
        return true;
      } else {
        print('Failed to unmute user $targetUserAnonymousId: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error unmuting user $targetUserAnonymousId: $e');
      return false;
    }
  }

  /// Blocks a target user.
  ///
  /// Requires an authentication [token] and the [targetUserAnonymousId].
  /// Returns [UserRelationshipRead] on success (HTTP 201), null otherwise.
  Future<UserRelationshipRead?> blockUser(
    String token,
    String targetUserAnonymousId,
  ) async {
    // Path from OpenAPI: POST /api/v1/users/{target_user_anonymous_id}/block
    final Uri url = Uri.parse(
        '${ApiConfig.baseUrl}/api/v1/users/$targetUserAnonymousId/block');

    try {
      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json', // Though no body, good practice
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return UserRelationshipRead.fromJson(responseData);
      } else {
        print('Failed to block user $targetUserAnonymousId: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error blocking user $targetUserAnonymousId: $e');
      return null;
    }
  }

  /// Unblocks a target user.
  ///
  /// Requires an authentication [token] and the [targetUserAnonymousId].
  /// Returns true on success (HTTP 204), false otherwise.
  Future<bool> unblockUser(
    String token,
    String targetUserAnonymousId,
  ) async {
    // Path from OpenAPI: DELETE /api/v1/users/{target_user_anonymous_id}/unblock
    final Uri url = Uri.parse(
        '${ApiConfig.baseUrl}/api/v1/users/$targetUserAnonymousId/unblock');

    try {
      final response = await _client.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 204) {
        return true;
      } else {
        print('Failed to unblock user $targetUserAnonymousId: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error unblocking user $targetUserAnonymousId: $e');
      return false;
    }
  }
}