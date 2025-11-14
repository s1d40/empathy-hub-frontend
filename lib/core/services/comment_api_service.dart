import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:anonymous_hubs/core/config/api_config.dart';
import 'package:anonymous_hubs/core/enums/app_enums.dart'; // For VoteType

class CommentApiService {
  final http.Client _client;

  CommentApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Creates a comment for a specific post.
  ///
  /// Requires an authentication [token], the [postAnonymousId] of the post,
  /// and the comment [content].
  /// Returns the created comment data (CommentRead schema) or null on failure.
  Future<Map<String, dynamic>?> createCommentForPost(
    String token,
    String postAnonymousId,
    String content,
  ) async {
    // Path from OpenAPI: POST /api/v1/posts/{post_anonymous_id}/comments/
    final Uri url = Uri.parse(
        '${ApiConfig.baseUrl}/api/v1/posts/$postAnonymousId/comments/');
    final Map<String, dynamic> body = {'content': content};

    try {
      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        print('Failed to create comment for post $postAnonymousId: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error creating comment for post $postAnonymousId: $e');
      return null;
    }
  }

  /// Lists comments for a specific post with pagination.
  ///
  /// Requires the [postAnonymousId] of the post.
  /// Optional [skip] and [limit] for pagination.
  /// Note: This endpoint in api_docs.json does not explicitly list security,
  /// assuming it might be public or inherit from a parent. If it needs auth, add token param.
  Future<List<Map<String, dynamic>>?> getCommentsForPost(
    String postAnonymousId, {
    int? skip,
    int? limit,
    String? token, // Add token if endpoint is protected
  }) async {
    // Path from OpenAPI: GET /api/v1/posts/{post_anonymous_id}/comments/
    final Map<String, String> queryParameters = {};
    if (skip != null) queryParameters['skip'] = skip.toString();
    if (limit != null) queryParameters['limit'] = limit.toString();

    final Uri url = Uri.parse(
            '${ApiConfig.baseUrl}/api/v1/posts/$postAnonymousId/comments/')
        .replace(queryParameters: queryParameters.isNotEmpty ? queryParameters : null);
    
    final Map<String, String> headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final response = await _client.get(url, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> decodedData = jsonDecode(response.body);
        return decodedData.cast<Map<String, dynamic>>();
      } else {
        print('Failed to get comments for post $postAnonymousId: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error fetching comments for post $postAnonymousId: $e');
      return null;
    }
  }

  /// Updates an existing comment.
  ///
  /// Requires an authentication [token], the [commentId] (anonymous_comment_id),
  /// and the new [content].
  /// Returns the updated comment data (CommentRead schema) or null on failure.
  Future<Map<String, dynamic>?> updateComment(
    String token,
    String commentId, // This is the anonymous_comment_id
    String content,
  ) async {
    // Path from OpenAPI: PUT /api/v1/posts/comments/{comment_id}/
    final Uri url =
        Uri.parse('${ApiConfig.baseUrl}/api/v1/posts/comments/$commentId/');
    final Map<String, dynamic> body = {'content': content};

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
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        print('Failed to update comment $commentId: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error updating comment $commentId: $e');
      return null;
    }
  }

  /// Deletes a comment.
  ///
  /// Requires an authentication [token] and the [commentId] (anonymous_comment_id).
  /// Returns true on successful deletion (HTTP 204), false otherwise.
  Future<bool> deleteComment(String token, String commentId) async {
    // Path from OpenAPI: DELETE /api/v1/posts/comments/{comment_id}/
    final Uri url =
        Uri.parse('${ApiConfig.baseUrl}/api/v1/posts/comments/$commentId/');

    try {
      final response = await _client.delete(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 204) {
        return true;
      } else {
        print('Failed to delete comment $commentId: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error deleting comment $commentId: $e');
      return false;
    }
  }

  /// Votes on a comment (upvote or downvote).
  ///
  /// Requires an authentication [token], the [commentAnonymousId], and the [voteType].
  /// Returns the updated comment data (CommentRead schema) or null on failure.
  Future<Map<String, dynamic>?> voteOnComment(
    String token,
    String commentAnonymousId,
    VoteType voteType,
  ) async {
    // Path from OpenAPI: POST /api/v1/posts/comments/{comment_anonymous_id}/vote
    final Uri url = Uri.parse(
        '${ApiConfig.baseUrl}/api/v1/posts/comments/$commentAnonymousId/vote');
    final Map<String, dynamic> body = {'vote_type': voteType.value};

    try {
      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        print('Failed to vote on comment $commentAnonymousId: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error voting on comment $commentAnonymousId: $e');
      return null;
    }
  }
}