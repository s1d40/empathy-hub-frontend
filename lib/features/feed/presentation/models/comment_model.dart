import 'package:equatable/equatable.dart';

class Comment extends Equatable {
  final String id; // Corresponds to anonymous_comment_id (UUID) from CommentRead.id
  final String postId; // Corresponds to post_id (UUID) from CommentRead.post_id
  final String authorAnonymousId; // Corresponds to author.id (UUID) from CommentRead.author
  final String username;
  final String? avatarUrl;
  final String? content; // Made content nullable
  final DateTime createdAt; // Corresponds to created_at from CommentRead
  final DateTime? updatedAt; // Corresponds to updated_at (nullable) from CommentRead
  final int upvotes;
  final int downvotes;

  const Comment({
    required this.id,
    required this.postId,
    required this.authorAnonymousId,
    required this.username,
    this.avatarUrl,
    this.content, // No longer required
    required this.createdAt,
    this.updatedAt,
    required this.upvotes,
    required this.downvotes,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    final authorJson = json['author'] as Map<String, dynamic>;
    return Comment(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      authorAnonymousId: authorJson['id'] as String,
      // Safely parse username from authorJson, providing a default if null or not present
      username: (authorJson['username'] as String?) ?? 'Anonymous',
      avatarUrl: authorJson['avatar_url'] as String?, // Ensure this is also robust if UserSimple's avatarUrl is
      content: json['content'] as String?, // Parse as nullable String
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      upvotes: json['upvotes'] as int,
      downvotes: json['downvotes'] as int,
    );
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