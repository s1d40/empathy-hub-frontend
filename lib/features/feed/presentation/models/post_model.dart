import 'package:empathy_hub_app/features/feed/presentation/models/comment_model.dart';

class Post {
  final String id;
  final String userId; // ID of the user who created the post
  final String username;
  final String? avatarUrl;
  final String content;
  final DateTime timestamp;
  final int upvotes;
  final int downvotes;
  final List<Comment> comments;

  const Post({
    required this.id,
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.content,
    required this.timestamp,
    this.upvotes = 0,
    this.downvotes = 0,
    this.comments = const [], // Default to an empty list
  });

  // Later, you might add methods like:
  // factory Post.fromJson(Map<String, dynamic> json) => ...
  // Map<String, dynamic> toJson() => ...
  // Post copyWith(...) => ...

  // Helper for displaying relative time, if needed here or in a utility class
  // String get timeAgo => /* logic to convert timestamp to 'X time ago' */;
}