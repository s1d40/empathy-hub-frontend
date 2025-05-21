part of 'data_erasure_cubit.dart';

abstract class DataErasureState extends Equatable {
  const DataErasureState();

  @override
  List<Object?> get props => [];
}

class DataErasureInitial extends DataErasureState {}

// Generic states for different erasure types
class DataErasureInProgress extends DataErasureState {
  final String actionType; // e.g., "posts", "comments", "chats", "all_info"
  const DataErasureInProgress(this.actionType);
  @override
  List<Object?> get props => [actionType];
}

class DataErasureSuccess extends DataErasureState {
  final String actionType;
  final String message;
  const DataErasureSuccess(this.actionType, this.message);
  @override
  List<Object?> get props => [actionType, message];
}

class DataErasureFailure extends DataErasureState {
  final String actionType;
  final String message;
  const DataErasureFailure(this.actionType, this.message);
  @override
  List<Object?> get props => [actionType, message];
}

// Specific states if more granularity is needed later, but generic ones are fine for now.
/*
class ErasePostsInProgress extends DataErasureState {}
class ErasePostsSuccess extends DataErasureState {
  final String message;
  const ErasePostsSuccess(this.message);
  @override List<Object?> get props => [message];
}
class ErasePostsFailure extends DataErasureState {
  final String message;
  const ErasePostsFailure(this.message);
  @override List<Object?> get props => [message];
}

// ... similar specific states for comments, chats, all_info
*/