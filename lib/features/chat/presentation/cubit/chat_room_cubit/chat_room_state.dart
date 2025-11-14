part of 'chat_room_cubit.dart';

abstract class ChatRoomState extends Equatable {
  const ChatRoomState();

  @override
  List<Object?> get props => [];
}

class ChatRoomInitial extends ChatRoomState {}

class ChatRoomLoadingMessages extends ChatRoomState {}

class ChatRoomLoaded extends ChatRoomState {
  final List<ChatMessage> messages;
  final bool hasReachedMaxMessages;
  final ChatRoom? roomDetails; // Optional: if you fetch room details separately or pass them in
  final bool isWebSocketConnected;
  final bool isSendingMessage; // New field

  const ChatRoomLoaded({
    required this.messages,
    this.hasReachedMaxMessages = false,
    this.roomDetails,
    this.isWebSocketConnected = false,
    this.isSendingMessage = false, // Initialize new field
  });

  ChatRoomLoaded copyWith({
    List<ChatMessage>? messages,
    bool? hasReachedMaxMessages,
    ChatRoom? roomDetails,
    bool? isWebSocketConnected,
    bool? isSendingMessage, // Add to copyWith
  }) {
    return ChatRoomLoaded(
      messages: messages ?? this.messages,
      hasReachedMaxMessages: hasReachedMaxMessages ?? this.hasReachedMaxMessages,
      roomDetails: roomDetails ?? this.roomDetails,
      isWebSocketConnected: isWebSocketConnected ?? this.isWebSocketConnected,
      isSendingMessage: isSendingMessage ?? this.isSendingMessage, // Update new field
    );
  }

  @override
  List<Object?> get props => [messages, hasReachedMaxMessages, roomDetails, isWebSocketConnected, isSendingMessage];
}

class ChatRoomError extends ChatRoomState {
  final String message;

  const ChatRoomError(this.message);

  @override
  List<Object?> get props => [message];
}

class ChatRoomWebSocketConnecting extends ChatRoomState {}

class ChatRoomWebSocketReconnecting extends ChatRoomState {
  final int attempt;
  final Duration delay;

  const ChatRoomWebSocketReconnecting({required this.attempt, required this.delay});

  @override
  List<Object> get props => [attempt, delay];
}

// ChatRoomWebSocketConnected is now part of ChatRoomLoaded via isWebSocketConnected flag

class ChatRoomWebSocketDisconnected extends ChatRoomState {
  final String? reason;

  const ChatRoomWebSocketDisconnected({this.reason});

  @override
  List<Object?> get props => [reason];
}

class ChatRoomSendingMessage extends ChatRoomState {
  // You might want to include the optimistic message here if you add it to UI before confirmation
  const ChatRoomSendingMessage();
}

class ChatRoomMessageSendFailed extends ChatRoomState {
  final String failedMessageContent;
  final String error;

  const ChatRoomMessageSendFailed(this.failedMessageContent, this.error);

  @override
  List<Object?> get props => [failedMessageContent, error];
}