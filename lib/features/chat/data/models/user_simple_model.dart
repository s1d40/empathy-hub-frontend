import 'package:equatable/equatable.dart';

class UserSimple extends Equatable {
  final String anonymousId;
  final String username;

  const UserSimple({
    required this.anonymousId,
    required this.username,
  });

  factory UserSimple.fromJson(Map<String, dynamic> json) {
    return UserSimple(
      anonymousId: json['anonymous_id'] as String,
      username: json['username'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'anonymous_id': anonymousId,
      'username': username,
    };
  }

  @override
  List<Object?> get props => [anonymousId, username];
}