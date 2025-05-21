part of 'chat_request_cubit.dart';

abstract class ChatRequestState extends Equatable {
  const ChatRequestState();

  @override
  List<Object?> get props => [];
}

class ChatRequestInitial extends ChatRequestState {}

class ChatRequestLoading extends ChatRequestState {}

class ChatRequestLoaded extends ChatRequestState {
  final List<ChatRequest> requests;
  // Could add pagination flags like hasReachedMax if needed in the future

  const ChatRequestLoaded(this.requests);

  @override
  List<Object?> get props => [requests];
}

class ChatRequestError extends ChatRequestState {
  final String message;

  const ChatRequestError(this.message);

  @override
  List<Object?> get props => [message];
}

class ChatRequestActionInProgress extends ChatRequestState {
  final String requestAnonymousId; // ID of the request being acted upon

  const ChatRequestActionInProgress(this.requestAnonymousId);

  @override
  List<Object?> get props => [requestAnonymousId];
}

class ChatRequestAcceptSuccess extends ChatRequestState {
  final ChatRoom newChatRoom;
  final String acceptedRequestAnonymousId; // To identify which request was accepted

  const ChatRequestAcceptSuccess(this.newChatRoom, this.acceptedRequestAnonymousId);

  @override
  List<Object?> get props => [newChatRoom, acceptedRequestAnonymousId];
}

class ChatRequestDeclineSuccess extends ChatRequestState {
  final ChatRequest declinedChatRequest; // The request that was declined (with updated status)

  const ChatRequestDeclineSuccess(this.declinedChatRequest);

  @override
  List<Object?> get props => [declinedChatRequest];
}

class ChatRequestActionFailure extends ChatRequestState {
  final String message;
  final String requestAnonymousId; // ID of the request that failed action

  const ChatRequestActionFailure(this.message, this.requestAnonymousId);

  @override
  List<Object?> get props => [message, requestAnonymousId];
}