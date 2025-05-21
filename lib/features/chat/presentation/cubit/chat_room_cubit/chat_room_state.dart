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

  const ChatRoomLoaded({
    required this.messages,
    this.hasReachedMaxMessages = false,
    this.roomDetails,
    this.isWebSocketConnected = false,
  });

  ChatRoomLoaded copyWith({
    List<ChatMessage>? messages,
    bool? hasReachedMaxMessages,
    ChatRoom? roomDetails,
    bool? isWebSocketConnected,
  }) {
    return ChatRoomLoaded(
      messages: messages ?? this.messages,
      hasReachedMaxMessages: hasReachedMaxMessages ?? this.hasReachedMaxMessages,
      roomDetails: roomDetails ?? this.roomDetails,
      isWebSocketConnected: isWebSocketConnected ?? this.isWebSocketConnected,
    );
  }

  @override
  List<Object?> get props => [messages, hasReachedMaxMessages, roomDetails, isWebSocketConnected];
}

class ChatRoomError extends ChatRoomState {
  final String message;

  const ChatRoomError(this.message);

  @override
  List<Object?> get props => [message];
}

class ChatRoomWebSocketConnecting extends ChatRoomState {}

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