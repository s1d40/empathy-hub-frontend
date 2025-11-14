import 'package:equatable/equatable.dart';

class WebSocketChatMessage extends Equatable {
  final String content;
  final String? anonymousMessageId; // New field for client-generated ID

  const WebSocketChatMessage({
    required this.content,
    this.anonymousMessageId,
  });

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'client_message_id': anonymousMessageId, // Map to client_message_id for backend
    };
  }

  // fromJson is not typically needed for a model that is only sent.

  @override
  List<Object?> get props => [content, anonymousMessageId];
}