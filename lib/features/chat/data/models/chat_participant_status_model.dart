import 'package:equatable/equatable.dart';

class ChatParticipantStatus extends Equatable {
  final String anonymousId;
  final String username;
  final DateTime? lastReadAt;

  const ChatParticipantStatus({
    required this.anonymousId,
    required this.username,
    this.lastReadAt,
  });

  factory ChatParticipantStatus.fromJson(Map<String, dynamic> json) {
    return ChatParticipantStatus(
      anonymousId: json['anonymous_id'] as String,
      username: json['username'] as String,
      lastReadAt: json['last_read_at'] != null
          ? DateTime.parse(json['last_read_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'anonymous_id': anonymousId,
      'username': username,
      'last_read_at': lastReadAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [anonymousId, username, lastReadAt];
}
