import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:anonymous_hubs/core/config/api_config.dart';
import 'package:anonymous_hubs/core/enums/app_enums.dart'; // Import your enums

class PostApiService {
  final http.Client _client;

  PostApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Creates a new post.
  ///
  /// Requires an authentication [token], [content].
  /// Optional [title].
  /// Returns post data map (PostRead schema) or null on failure.
  Future<Map<String, dynamic>?> createPost(
    String token, {
    required String content,
    String? title,
  }) async {
    // Path from OpenAPI: POST /api/v1/posts/
    final Uri url = Uri.parse('${ApiConfig.baseUrl}/api/v1/posts/');
    final Map<String, dynamic> body = {'content': content};
    if (title != null) {
      body['title'] = title;
    }

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
        print('Failed to create post: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error creating post: $e');
      return null;
    }
  }

  /// Fetches a list of posts.
  ///
  /// Requires an authentication [token].
  /// Optional [skip] and [limit] for pagination.
  /// Returns a list of post data maps (PostRead schema) or null on failure.
  Future<List<Map<String, dynamic>>?> getPosts(
    String token, {
    int? skip,
    int? limit,
  }) async {
    // Path from OpenAPI: GET /api/v1/posts/
    final Map<String, String> queryParameters = {};
    if (skip != null) queryParameters['skip'] = skip.toString();
    if (limit != null) queryParameters['limit'] = limit.toString();

    final Uri url = Uri.parse('${ApiConfig.baseUrl}/api/v1/posts/')
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
        print('Failed to get posts: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error fetching posts: $e');
      return null;
    }
  }

  /// Fetches a specific post by its anonymous ID.
  ///
  /// Requires an authentication [token] and the [postAnonymousId].
  /// Returns post data map (PostRead schema) or null on failure.
  Future<Map<String, dynamic>?> getPostByAnonymousId(
      String token, String postAnonymousId) async {
    // Path from OpenAPI: GET /api/v1/posts/{post_anonymous_id}
    final Uri url =
        Uri.parse('${ApiConfig.baseUrl}/api/v1/posts/$postAnonymousId');

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
      } else {
        print('Failed to get post $postAnonymousId: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error fetching post $postAnonymousId: $e');
      return null;
    }
  }

  /// Updates an existing post.
  ///
  /// Requires an authentication [token], [postAnonymousId].
  /// Optional [title], [content], [isActive].
  /// Returns updated post data map (PostRead schema) or null on failure.
  Future<Map<String, dynamic>?> updatePost(
    String token,
    String postAnonymousId, {
    String? title,
    String? content,
    bool? isActive,
  }) async {
    // Path from OpenAPI: PUT /api/v1/posts/{post_anonymous_id}
    final Uri url =
        Uri.parse('${ApiConfig.baseUrl}/api/v1/posts/$postAnonymousId');
    final Map<String, dynamic> body = {};
    if (title != null) body['title'] = title;
    if (content != null) body['content'] = content;
    if (isActive != null) body['is_active'] = isActive;

    if (body.isEmpty) {
      print('updatePost called with no fields to update for $postAnonymousId.');
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
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        print('Failed to update post $postAnonymousId: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error updating post $postAnonymousId: $e');
      return null;
    }
  }

  /// Deletes a post by its anonymous ID.
  ///
  /// Requires an authentication [token] and the [postAnonymousId].
  /// Returns the deleted post data map (PostRead schema) or null on failure.
  /// Note: API docs specify returning PostRead on 200 for this DELETE endpoint.
  Future<Map<String, dynamic>?> deletePost(
      String token, String postAnonymousId) async {
    // Path from OpenAPI: DELETE /api/v1/posts/{post_anonymous_id}
    final Uri url =
        Uri.parse('${ApiConfig.baseUrl}/api/v1/posts/$postAnonymousId');

    try {
      final response = await _client.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) { // As per API docs for this endpoint
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        print('Failed to delete post $postAnonymousId: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error deleting post $postAnonymousId: $e');
      return null;
    }
  }

  /// Votes on a post (upvote or downvote).
  ///
  /// Requires an authentication [token], [postAnonymousId], and [voteType].
  /// Returns the updated post data map (PostRead schema) or null on failure.
  Future<Map<String, dynamic>?> voteOnPost(
    String token,
    String postAnonymousId,
    VoteType voteType,
  ) async {
    // Path from OpenAPI: POST /api/v1/posts/{post_anonymous_id}/vote
    final Uri url = Uri.parse(
        '${ApiConfig.baseUrl}/api/v1/posts/$postAnonymousId/vote');
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
        print('Failed to vote on post $postAnonymousId: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error voting on post $postAnonymousId: $e');
      return null;
    }
  }
}