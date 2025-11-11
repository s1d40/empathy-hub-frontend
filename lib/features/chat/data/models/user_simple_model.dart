import 'package:equatable/equatable.dart';

class UserSimple extends Equatable {
  final String anonymousId;
  final String username;
  final String? avatarUrl;

  const UserSimple({
    required this.anonymousId,
    required this.username,
    this.avatarUrl,
  });

  factory UserSimple.fromJson(Map<String, dynamic> json) {
    return UserSimple(
      anonymousId: json['anonymous_id'] as String,
      username: json['username'] as String,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'anonymous_id': anonymousId,
      'username': username,
      'avatar_url': avatarUrl,
    };
  }

  @override
  List<Object?> get props => [anonymousId, username, avatarUrl];
}