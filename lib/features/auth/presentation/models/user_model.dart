import 'package:empathy_hub_app/features/feed/presentation/models/comment_model.dart';
import 'package:empathy_hub_app/features/feed/presentation/models/post_model.dart';

class User {
  final String id; // Unique user ID (e.g., from backend)
  final String username;
  final String? avatarUrl;
  final List<Post> posts;
  final List<Comment> comments;
  // You could add other fields later, like email, bio, etc.

  const User({
    required this.id,
    required this.username,
    this.avatarUrl,
    this.posts = const [],
    this.comments = const [],
  });

  // Represents an uninitialized or unauthenticated user state.
  static const empty = User(id: '', username: '', posts: [], comments: []);

  // factory User.fromJson(Map<String, dynamic> json) => ...
  // Map<String, dynamic> toJson() => ...
  // User copyWith(...) => ...
}