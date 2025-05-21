part of 'post_item_cubit.dart';

abstract class PostItemState extends Equatable {
  const PostItemState();

  @override
  List<Object?> get props => [];
}

/// The initial state, holding the post data.
class PostItemInitial extends PostItemState {
  final Post post;

  const PostItemInitial(this.post);

  @override
  List<Object?> get props => [post];
}

/// State when an action (like voting or deleting) is in progress for this post.
class PostItemActionInProgress extends PostItemState {
  final Post post; // The current post data to display while loading
  final String? actionType; // Optional: e.g., "voting", "deleting" for specific UI

  const PostItemActionInProgress(this.post, {this.actionType});

  @override
  List<Object?> get props => [post, actionType];
}

/// State when an action on the post was successful.
class PostItemActionSuccess extends PostItemState {
  final Post post; // The updated post data (e.g., new vote counts)
  final String? successMessage; // Optional: for UI feedback

  const PostItemActionSuccess(this.post, {this.successMessage});

  @override
  List<Object?> get props => [post, successMessage];
}

/// State when an action on the post failed.
class PostItemActionFailure extends PostItemState {
  final Post post; // The post data before the failed action
  final String errorMessage;
  final String? actionType; // Optional: e.g., "voting", "deleting"

  const PostItemActionFailure(this.post, this.errorMessage, {this.actionType});

  @override
  List<Object?> get props => [post, errorMessage, actionType];
}

/// State indicating the post has been successfully deleted.
/// This signals the UI to remove the item.
class PostItemDeleted extends PostItemState {
  const PostItemDeleted();
}