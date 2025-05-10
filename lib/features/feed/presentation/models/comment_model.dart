class Comment {
  final String id;
  final String postId; // To link back to the post
  final String userId;
  final String username;
  final String? avatarUrl;
  final String content;
  final DateTime timestamp;
  final int upvotes;
  final int downvotes;

  const Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.content,
    required this.timestamp,
    this.upvotes = 0,
    this.downvotes = 0,
  });

  // Later, you might add methods like:
  // factory Comment.fromJson(Map<String, dynamic> json) => ...
  // Map<String, dynamic> toJson() => ...
  // Comment copyWith(...) => ...
}