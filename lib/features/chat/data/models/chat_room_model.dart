import 'package:anonymous_hubs/features/chat/data/models/chat_message_model.dart';
import 'package:anonymous_hubs/features/chat/data/models/user_simple_model.dart';
import 'package:equatable/equatable.dart';
import 'package:anonymous_hubs/features/chat/data/models/chat_participant_status_model.dart';

class ChatRoom extends Equatable {
  final String? name;
  final bool isGroup;
  final String anonymousRoomId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<ChatParticipantStatus> participants;
  final ChatMessage? lastMessage;

  const ChatRoom({
    this.name,
    required this.isGroup,
    required this.anonymousRoomId,
    required this.createdAt,
    this.updatedAt,
    required this.participants,
    this.lastMessage,
  });

  int unreadCount(String currentUserId) {
    if (lastMessage == null) {
      return 0;
    }
    final currentUserParticipant = participants.firstWhere(
      (p) => p.anonymousId == currentUserId,
      orElse: () => ChatParticipantStatus(anonymousId: '', username: ''),
    );
    if (currentUserParticipant.lastReadAt == null) {
      return 1;
    }
    if (lastMessage!.timestamp.isAfter(currentUserParticipant.lastReadAt!)) {
      return 1;
    }
    return 0;
  }

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      name: json['name'] as String?,
      isGroup: json['is_group'] as bool? ?? false,
      anonymousRoomId: json['anonymous_room_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
      participants: (json['participants'] as List<dynamic>? ?? [])
          .map((participantJson) => ChatParticipantStatus.fromJson(participantJson as Map<String, dynamic>))
          .toList(),
      lastMessage: json['last_message'] != null
          ? ChatMessage.fromJson(json['last_message'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'is_group': isGroup,
      'anonymous_room_id': anonymousRoomId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'participants': participants.map((p) => p.toJson()).toList(),
      'last_message': lastMessage?.toJson(),
    };
  }

  @override
  List<Object?> get props => [
        name,
        isGroup,
        anonymousRoomId,
        createdAt,
        updatedAt,
        participants,
        lastMessage,
      ];
}