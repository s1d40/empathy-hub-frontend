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
    try {
      final id = (json['id'] as String?) ?? 'error_unknown_post_id';
      final title = json['title'] as String?;
      final content = json['content'] as String?;
      final author = UserSimple.fromJson(json['author'] as Map<String, dynamic>);
      final commentCount = (json['comment_count'] as num?)?.toInt() ?? 0;
      final isActive = (json['is_active'] as bool?) ?? true;
      final isEdited = (json['is_edited'] as bool?) ?? false;
      final upvotes = (json['upvotes'] as num?)?.toInt() ?? 0;
      final downvotes = (json['downvotes'] as num?)?.toInt() ?? 0;
      final createdAt = DateTime.parse((json['created_at'] as String?) ?? DateTime(1970).toIso8601String());
      final updatedAt = json['updated_at'] == null ? null : DateTime.parse(json['updated_at'] as String);

      return Post(
        id: id,
        title: title,
        content: content,
        author: author,
        commentCount: commentCount,
        isActive: isActive,
        isEdited: isEdited,
        upvotes: upvotes,
        downvotes: downvotes,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
    } catch (e, s) {
      print('[Post.fromJson] Exception: $e');
      print('[Post.fromJson] Stacktrace: $s');
      rethrow;
    }
  }

  @override
  List<Object?> get props => [id, title, content, author, commentCount, isActive, isEdited, upvotes, downvotes, createdAt, updatedAt];
}