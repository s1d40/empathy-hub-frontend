part of 'chat_list_cubit.dart';

abstract class ChatListState extends Equatable {
  const ChatListState();

  @override
  List<Object> get props => [];
}

class ChatListInitial extends ChatListState {}

class ChatListLoading extends ChatListState {}

class ChatListLoaded extends ChatListState {
  final List<ChatRoom> chatRooms;

  const ChatListLoaded({required this.chatRooms});

  @override
  List<Object> get props => [chatRooms];

  ChatListLoaded copyWith({
    List<ChatRoom>? chatRooms,
  }) {
    return ChatListLoaded(
      chatRooms: chatRooms ?? this.chatRooms,
    );
  }
}

class ChatListError extends ChatListState {
  final String message;

  const ChatListError(this.message);

  @override
  List<Object> get props => [message];
}
