part of 'chat_list_cubit.dart';

abstract class ChatListState extends Equatable {
  const ChatListState();

  @override
  List<Object?> get props => [];
}

class ChatListInitial extends ChatListState {}

class ChatListLoading extends ChatListState {}

class ChatListLoaded extends ChatListState {
  final List<ChatRoom> chatRooms;
  final bool hasReachedMax;

  const ChatListLoaded({
    required this.chatRooms,
    this.hasReachedMax = false,
  });

  ChatListLoaded copyWith({
    List<ChatRoom>? chatRooms,
    bool? hasReachedMax,
  }) {
    return ChatListLoaded(
      chatRooms: chatRooms ?? this.chatRooms,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }

  @override
  List<Object?> get props => [chatRooms, hasReachedMax];
}

class ChatListError extends ChatListState {
  final String message;

  const ChatListError(this.message);

  @override
  List<Object?> get props => [message];
}