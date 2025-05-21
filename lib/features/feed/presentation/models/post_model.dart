import 'package:equatable/equatable.dart';
import 'package:empathy_hub_app/features/user/data/models/user_simple_model.dart'; // Import UserSimple

class Post extends Equatable {
  final String id;
  final String? title;
  final String? content; // Made content nullable
  final UserSimple author; // Changed to UserSimple
  final int commentCount;
  final bool isActive;
  final bool isEdited;
  final int upvotes;
  final int downvotes;
  final DateTime createdAt; // Renamed from timestamp
  final DateTime? updatedAt;

  const Post({
    required this.id,
    this.title,
    this.content, // No longer required, can be null
    required this.author, // Changed
    required this.commentCount,
    required this.isActive,
    required this.isEdited,
    required this.upvotes,
    required this.downvotes,
    required this.createdAt, // Renamed from timestamp
    this.updatedAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      // Safely parse id, providing a fallback or logging an error if critical
      id: (json['id'] as String?) ?? 'error_unknown_post_id', 
      title: json['title'] as String?,
      content: json['content'] as String?, // Parse as nullable String
      author: UserSimple.fromJson(json['author'] as Map<String, dynamic>), // Changed
      commentCount: json['comment_count'] as int,
      isActive: json['is_active'] as bool,
      isEdited: json['is_edited'] as bool,
      upvotes: json['upvotes'] as int,
      downvotes: json['downvotes'] as int,
      // Safely parse createdAt, providing a fallback
      createdAt: DateTime.parse((json['created_at'] as String?) ?? DateTime(1970).toIso8601String()),
      updatedAt: json['updated_at'] == null ? null : DateTime.parse(json['updated_at'] as String),
    );
  }

  @override
  List<Object?> get props => [id, title, content, author, commentCount, isActive, isEdited, upvotes, downvotes, createdAt, updatedAt];
}