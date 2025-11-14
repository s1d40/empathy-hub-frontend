import 'package:anonymous_hubs/features/chat/data/models/user_simple_model.dart';
import 'package:equatable/equatable.dart';
import 'package:anonymous_hubs/features/chat/data/models/message_status_enum.dart'; // Import the new enum

class ChatMessage extends Equatable {
  final String content;
  final String? anonymousMessageId; // Made nullable for pending messages
  final String chatroomAnonymousId;
  final String senderAnonymousId;
  final DateTime timestamp;
  final UserSimple sender;
  final MessageStatus status; // New status field
  final String? clientMessageId; // For optimistic UI updates

  const ChatMessage({
    required this.content,
    this.anonymousMessageId, // Now optional
    required this.chatroomAnonymousId,
    required this.senderAnonymousId,
    required this.timestamp,
    required this.sender,
    this.status = MessageStatus.sent, // Default to sent
    this.clientMessageId,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      content: json['content'] as String,
      anonymousMessageId: json['anonymous_message_id'] as String?, // Handle nullable
      chatroomAnonymousId: json['chatroom_anonymous_id'] as String,
      senderAnonymousId: json['sender_anonymous_id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      sender: UserSimple.fromJson(json['sender'] as Map<String, dynamic>),
      status: MessageStatus.sent, // Messages from backend are always 'sent'
      clientMessageId: json['client_message_id'] as String?,
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
      'client_message_id': clientMessageId,
      // Status is not sent to backend, it's a frontend-only concern
    };
  }

  ChatMessage copyWith({
    String? content,
    String? anonymousMessageId,
    String? chatroomAnonymousId,
    String? senderAnonymousId,
    DateTime? timestamp,
    UserSimple? sender,
    MessageStatus? status,
    String? clientMessageId,
  }) {
    return ChatMessage(
      content: content ?? this.content,
      anonymousMessageId: anonymousMessageId ?? this.anonymousMessageId,
      chatroomAnonymousId: chatroomAnonymousId ?? this.chatroomAnonymousId,
      senderAnonymousId: senderAnonymousId ?? this.senderAnonymousId,
      timestamp: timestamp ?? this.timestamp,
      sender: sender ?? this.sender,
      status: status ?? this.status,
      clientMessageId: clientMessageId ?? this.clientMessageId,
    );
  }

  @override
  List<Object?> get props => [anonymousMessageId, content, chatroomAnonymousId, senderAnonymousId, timestamp, sender, status, clientMessageId];
}