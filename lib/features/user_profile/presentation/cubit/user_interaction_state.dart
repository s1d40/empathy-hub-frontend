part of 'user_interaction_cubit.dart';

abstract class UserInteractionState extends Equatable {
  const UserInteractionState();

  @override
  List<Object?> get props => [];
}

class UserInteractionInitial extends UserInteractionState {}

/// State when loading the initial mute/block status for a target user.
class UserInteractionStatusLoading extends UserInteractionState {}

/// State when the mute/block status for a target user has been loaded.
class UserInteractionStatusLoaded extends UserInteractionState {
  final bool isMuted;
  final bool isBlocked;
  final String targetUserAnonymousId; // Keep track of whose status this is

  const UserInteractionStatusLoaded({
    required this.isMuted,
    required this.isBlocked,
    required this.targetUserAnonymousId,
  });

  @override
  List<Object?> get props => [isMuted, isBlocked, targetUserAnonymousId];
}

/// State when a mute/block/unmute/unblock action is in progress.
class UserInteractionActionInProgress extends UserInteractionState {
  final bool wasMuted; // Previous state, useful for UI updates
  final bool wasBlocked;
  final String targetUserAnonymousId;

  const UserInteractionActionInProgress({
    required this.wasMuted,
    required this.wasBlocked,
    required this.targetUserAnonymousId,
  });

  @override
  List<Object?> get props => [wasMuted, wasBlocked, targetUserAnonymousId];
}

/// State when an action (mute/block/etc.) has failed.
class UserInteractionActionFailure extends UserInteractionState {
  final String message;
  final bool previousMuteStatus; // To revert UI if needed
  final bool previousBlockStatus;
  final String targetUserAnonymousId;

  const UserInteractionActionFailure({
    required this.message,
    required this.previousMuteStatus,
    required this.previousBlockStatus,
    required this.targetUserAnonymousId,
  });

  @override
  List<Object?> get props => [message, previousMuteStatus, previousBlockStatus, targetUserAnonymousId];
}

/// State when loading the initial mute/block status failed.
class UserInteractionStatusLoadFailure extends UserInteractionState {
  final String message;
  const UserInteractionStatusLoadFailure({required this.message});

  @override
  List<Object?> get props => [message];
}