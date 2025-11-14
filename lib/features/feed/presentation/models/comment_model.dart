import 'dart:convert';
import 'package:anonymous_hubs/core/config/api_config.dart';
import 'package:equatable/equatable.dart';

class Comment extends Equatable {
  final String id;
  final String postId;
  final String authorAnonymousId;
  final String username;
  final String? avatarUrl;
  final String? content;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int upvotes;
  final int downvotes;

  const Comment({
    required this.id,
    required this.postId,
    required this.authorAnonymousId,
    required this.username,
    this.avatarUrl,
    this.content,
    required this.createdAt,
    this.updatedAt,
    required this.upvotes,
    required this.downvotes,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    final authorJson = json['author'] as Map<String, dynamic>? ?? {};
    
    return Comment(
      id: (json['anonymous_comment_id'] as String?) ?? 'error_unknown_comment_id',
      postId: (json['post_id'] as String?) ?? 'error_unknown_post_id',
      authorAnonymousId: (authorJson['id'] as String?) ?? 'error_unknown_author_id',
      username: (authorJson['username'] as String?) ?? 'Anonymous',
      avatarUrl: _resolveAvatarUrl(authorJson['avatar_url'] as String?),
      content: json['content'] as String?,
      createdAt: DateTime.parse((json['created_at'] as String?) ?? DateTime(1970).toIso8601String()),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      upvotes: (json['upvotes'] as int?) ?? 0,
      downvotes: (json['downvotes'] as int?) ?? 0,
    );
  }

  static String? _resolveAvatarUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.isEmpty) {
      return null;
    }
    if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
      return rawUrl;
    }
    final baseUri = Uri.parse(ApiConfig.baseUrl);
    return baseUri.resolve(rawUrl).toString();
  }

  @override
  List<Object?> get props => [
        id,
        postId,
        authorAnonymousId,
        username,
        avatarUrl,
        content,
        createdAt,
        updatedAt,
        upvotes,
        downvotes,
      ];
}