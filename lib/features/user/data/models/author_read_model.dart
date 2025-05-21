import 'package:equatable/equatable.dart';

class AuthorRead extends Equatable {
  final String id; // Corresponds to anonymous_id
  final String username;
  final String? avatarUrl;

  const AuthorRead({
    required this.id,
    required this.username,
    this.avatarUrl,
  });

  factory AuthorRead.fromJson(Map<String, dynamic> json) {
    return AuthorRead(
      id: json['id'] as String,
      username: json['username'] as String,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'avatar_url': avatarUrl,
    };
  }

  @override
  List<Object?> get props => [id, username, avatarUrl];
}