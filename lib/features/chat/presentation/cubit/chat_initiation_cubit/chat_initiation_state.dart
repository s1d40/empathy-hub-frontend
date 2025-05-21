part of 'chat_initiation_cubit.dart';

abstract class ChatInitiationState extends Equatable {
  const ChatInitiationState();

  @override
  List<Object?> get props => [];
}

class ChatInitiationInitial extends ChatInitiationState {}

class ChatInitiationInProgress extends ChatInitiationState {}

class ChatInitiationSuccessRoom extends ChatInitiationState {
  final ChatRoom chatRoom;
  final String targetUserAnonymousId; // Added

  const ChatInitiationSuccessRoom(this.chatRoom, this.targetUserAnonymousId);

  @override
  List<Object?> get props => [chatRoom, targetUserAnonymousId];
}

class ChatInitiationSuccessRequest extends ChatInitiationState {
  final ChatRequest chatRequest;
  final String targetUserAnonymousId; // Added

  const ChatInitiationSuccessRequest(this.chatRequest, this.targetUserAnonymousId);

  @override
  List<Object?> get props => [chatRequest, targetUserAnonymousId];
}

class ChatInitiationFailure extends ChatInitiationState {
  final String message;
  final String targetUserAnonymousId; // Added
  // Optional: could include a specific error code or type from backend
  // e.g., if user is DND, or target user not found.
  final String? errorCode; 

  const ChatInitiationFailure(
    this.message, {
    required this.targetUserAnonymousId, // Make required
    this.errorCode,
  });

  @override
  List<Object?> get props => [message, targetUserAnonymousId, errorCode];
}