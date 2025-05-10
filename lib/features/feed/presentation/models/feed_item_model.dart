class FeedItem{
  final String id;
  final String username;
  final String content;
  final String timestamp;
  final String? avatarUrl;


  const FeedItem({
    required this.id,
    required this.username,
    required this.content,
    required this.timestamp,
    this.avatarUrl,
  });
}

// You could add Equatable here if you plan to compare FeedItem objects,
// or methods like fromJson/toJson when you connect to a backend.
