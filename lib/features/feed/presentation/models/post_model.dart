import 'package:equatable/equatable.dart';
import 'package:anonymous_hubs/features/user/data/models/user_simple_model.dart'; // Import UserSimple

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
      print('[Post.fromJson] Raw JSON: $json');

      final id = (json['id'] as String?) ?? 'error_unknown_post_id';
      print('[Post.fromJson] id: $id, Type: ${id.runtimeType}');

      final title = json['title'] as String?;
      print('[Post.fromJson] title: $title, Type: ${title.runtimeType}');

      final content = json['content'] as String?;
      print('[Post.fromJson] content: $content, Type: ${content.runtimeType}');

      final author = UserSimple.fromJson(json['author'] as Map<String, dynamic>);
      print('[Post.fromJson] author: $author, Type: ${author.runtimeType}');

      final commentCount = (json['comment_count'] as num?)?.toInt() ?? 0;
      print('[Post.fromJson] commentCount: $commentCount, Type: ${commentCount.runtimeType}');

      final isActive = (json['is_active'] as bool?) ?? true;
      print('[Post.fromJson] isActive: $isActive, Type: ${isActive.runtimeType}');

      final isEdited = (json['is_edited'] as bool?) ?? false;
      print('[Post.fromJson] isEdited: $isEdited, Type: ${isEdited.runtimeType}');

      final upvotes = (json['upvotes'] as num?)?.toInt() ?? 0;
      print('[Post.fromJson] upvotes: $upvotes, Type: ${upvotes.runtimeType}');

      final downvotes = (json['downvotes'] as num?)?.toInt() ?? 0;
      print('[Post.fromJson] downvotes: $downvotes, Type: ${downvotes.runtimeType}');

      final createdAt = DateTime.parse((json['created_at'] as String?) ?? DateTime(1970).toIso8601String());
      print('[Post.fromJson] createdAt: $createdAt, Type: ${createdAt.runtimeType}');

      final updatedAt = json['updated_at'] == null ? null : DateTime.parse(json['updated_at'] as String);
      print('[Post.fromJson] updatedAt: $updatedAt, Type: ${updatedAt.runtimeType}');

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