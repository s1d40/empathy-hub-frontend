part of 'user_interaction_lists_cubit.dart';

abstract class UserInteractionListsState extends Equatable {
  const UserInteractionListsState();

  @override
  List<Object?> get props => [];
}

class UserInteractionListsInitial extends UserInteractionListsState {}

// States for Muted Users
class MutedUsersLoading extends UserInteractionListsState {}

class MutedUsersLoaded extends UserInteractionListsState {
  final List<UserSimple> users;
  const MutedUsersLoaded(this.users);

  @override
  List<Object?> get props => [users];
}

class MutedUsersError extends UserInteractionListsState {
  final String message;
  const MutedUsersError(this.message);

  @override
  List<Object?> get props => [message];
}

// States for Blocked Users
class BlockedUsersLoading extends UserInteractionListsState {}

class BlockedUsersLoaded extends UserInteractionListsState {
  final List<UserSimple> users;
  const BlockedUsersLoaded(this.users);

  @override
  List<Object?> get props => [users];
}

class BlockedUsersError extends UserInteractionListsState {
  final String message;
  const BlockedUsersError(this.message);

  @override
  List<Object?> get props => [message];
}

// States for Unmuting User
class UserUnmuting extends UserInteractionListsState {
  final String targetUserId;
  const UserUnmuting(this.targetUserId);

  @override
  List<Object?> get props => [targetUserId];
}

class UserUnmuteSuccess extends UserInteractionListsState {
  final String targetUserId;
  final String username; // To show in success message
  const UserUnmuteSuccess(this.targetUserId, this.username);

  @override
  List<Object?> get props => [targetUserId, username];
}

class UserUnmuteFailure extends UserInteractionListsState {
  final String targetUserId;
  final String username;
  final String message;
  const UserUnmuteFailure(this.targetUserId, this.username, this.message);

  @override
  List<Object?> get props => [targetUserId, username, message];
}

// States for Unblocking User
class UserUnblocking extends UserInteractionListsState {
  final String targetUserId;
  const UserUnblocking(this.targetUserId);
  @override
  List<Object?> get props => [targetUserId];
}

class UserUnblockSuccess extends UserInteractionListsState {
  final String targetUserId;
  final String username; // To show in success message
  const UserUnblockSuccess(this.targetUserId, this.username);
  @override
  List<Object?> get props => [targetUserId, username];
}

class UserUnblockFailure extends UserInteractionListsState {
  final String targetUserId;
  final String username;
  final String message;
  const UserUnblockFailure(this.targetUserId, this.username, this.message);
  @override
  List<Object?> get props => [targetUserId, username, message];
}