part of 'chat_request_cubit.dart';

abstract class ChatRequestState extends Equatable {
  const ChatRequestState();

  @override
  List<Object> get props => [];
}

class ChatRequestInitial extends ChatRequestState {}

class ChatRequestLoading extends ChatRequestState {}

class ChatRequestLoaded extends ChatRequestState {
  final List<ChatRequest> pendingRequests;
  final int pendingRequestCount;

  const ChatRequestLoaded({
    required this.pendingRequests,
    required this.pendingRequestCount,
  });

  ChatRequestLoaded copyWith({
    List<ChatRequest>? pendingRequests,
    int? pendingRequestCount,
  }) {
    return ChatRequestLoaded(
      pendingRequests: pendingRequests ?? this.pendingRequests,
      pendingRequestCount: pendingRequestCount ?? this.pendingRequestCount,
    );
  }

  @override
  List<Object> get props => [pendingRequests, pendingRequestCount];
}

class ChatRequestError extends ChatRequestState {
  final String message;

  const ChatRequestError(this.message);

  @override
  List<Object> get props => [message];
}

class ChatRequestActionInProgress extends ChatRequestState {
  final String requestAnonymousId;

  const ChatRequestActionInProgress(this.requestAnonymousId);

  @override
  List<Object> get props => [requestAnonymousId];
}

class ChatRequestActionFailure extends ChatRequestState {
  final String message;

  const ChatRequestActionFailure(this.message);

  @override
  List<Object> get props => [message];
}

class ChatRequestAcceptSuccess extends ChatRequestState {
  final ChatRoom newChatRoom;

  const ChatRequestAcceptSuccess(this.newChatRoom);

  @override
  List<Object> get props => [newChatRoom];
}

class ChatRequestDeclineSuccess extends ChatRequestState {
  final ChatRequest declinedChatRequest;

  const ChatRequestDeclineSuccess(this.declinedChatRequest);

  @override
  List<Object> get props => [declinedChatRequest];
}