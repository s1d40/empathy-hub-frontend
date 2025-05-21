import 'package:empathy_hub_app/features/chat/data/models/user_simple_model.dart';
import 'package:equatable/equatable.dart';

class ChatMessage extends Equatable {
  final String content;
  final String anonymousMessageId;
  final String chatroomAnonymousId;
  final String senderAnonymousId;
  final DateTime timestamp;
  final UserSimple sender;

  const ChatMessage({
    required this.content,
    required this.anonymousMessageId,
    required this.chatroomAnonymousId,
    required this.senderAnonymousId,
    required this.timestamp,
    required this.sender,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      content: json['content'] as String,
      anonymousMessageId: json['anonymous_message_id'] as String,
      chatroomAnonymousId: json['chatroom_anonymous_id'] as String,
      senderAnonymousId: json['sender_anonymous_id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      sender: UserSimple.fromJson(json['sender'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'anonymous_message_id': anonymousMessageId,
      'chatroom_anonymous_id': chatroomAnonymousId,
      'sender_anonymous_id': senderAnonymousId,
      'timestamp': timestamp.toIso8601String(),
      'sender': sender.toJson(),
    };
  }

  @override
  List<Object?> get props => [anonymousMessageId, content, chatroomAnonymousId, senderAnonymousId, timestamp, sender];
}