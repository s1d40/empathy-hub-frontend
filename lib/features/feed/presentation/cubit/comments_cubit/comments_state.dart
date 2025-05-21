part of 'comments_cubit.dart';

abstract class CommentsState extends Equatable {
  const CommentsState();

  @override
  List<Object?> get props => [];
}

class CommentsInitial extends CommentsState {}

class CommentsLoaded extends CommentsState {
  final List<Comment> comments;
  final bool hasReachedMax;
  final Set<String> commentsBeingVotedOn; // IDs of comments currently being voted on

  const CommentsLoaded({
    required this.comments,
    this.hasReachedMax = false,
    this.commentsBeingVotedOn = const {},
  });

  @override
  List<Object?> get props => [comments, hasReachedMax, commentsBeingVotedOn];

  CommentsLoaded copyWith({
    List<Comment>? comments,
    bool? hasReachedMax,
    Set<String>? commentsBeingVotedOn,
  }) {
    return CommentsLoaded(
      comments: comments ?? this.comments,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      commentsBeingVotedOn: commentsBeingVotedOn ?? this.commentsBeingVotedOn,
    );
  }
}

class CommentsError extends CommentsState {
  // Make it extend CommentsLoaded to preserve data
  final String message;
  final List<Comment> comments;
  final bool hasReachedMax;
  final Set<String> commentsBeingVotedOn;

  const CommentsError({
    required this.message,
    this.comments = const [],
    this.hasReachedMax = false,
    this.commentsBeingVotedOn = const {},
  });

  @override
  List<Object?> get props => [message, comments, hasReachedMax, commentsBeingVotedOn];
}

class CommentsLoading extends CommentsLoaded {
  CommentsLoading({
    List<Comment> comments = const [],
    bool hasReachedMax = false,
    Set<String> commentsBeingVotedOn = const {},
  }) : super(comments: comments, hasReachedMax: hasReachedMax, commentsBeingVotedOn: commentsBeingVotedOn);
}

class CommentSubmitting extends CommentsLoaded {
  CommentSubmitting({
    required List<Comment> comments,
    required bool hasReachedMax,
    required Set<String> commentsBeingVotedOn,
  }) : super(comments: comments, hasReachedMax: hasReachedMax, commentsBeingVotedOn: commentsBeingVotedOn);
}

class CommentSubmitSuccess extends CommentsState {
  final Comment newComment;
  const CommentSubmitSuccess(this.newComment);
  @override
  List<Object?> get props => [newComment];
  // This state is transient as the cubit reloads comments immediately after.
  // Keeping it simple without extending CommentsLoaded.
}

class CommentSubmitFailure extends CommentsLoaded {
  final String message;
  const CommentSubmitFailure({
    required this.message,
    required List<Comment> comments,
    required bool hasReachedMax,
    required Set<String> commentsBeingVotedOn,
  }) : super(comments: comments, hasReachedMax: hasReachedMax, commentsBeingVotedOn: commentsBeingVotedOn);

  @override
  List<Object?> get props => super.props..add(message);
}

class CommentDeleteInProgress extends CommentsLoaded {
  final String deletingCommentId;
  CommentDeleteInProgress({
    required this.deletingCommentId,
    required List<Comment> comments,
    required bool hasReachedMax,
    required Set<String> commentsBeingVotedOn,
  }) : super(comments: comments, hasReachedMax: hasReachedMax, commentsBeingVotedOn: commentsBeingVotedOn);

  @override
  List<Object?> get props => super.props..add(deletingCommentId);
}

// Using CommentsError for delete failure to keep it simple,
// as CommentsError now carries the list of comments.
// Alternatively, a specific CommentDeleteFailure state could be created.

class CommentVoteFailure extends CommentsLoaded {
  final String message;
  CommentVoteFailure({required this.message, required List<Comment> comments, required bool hasReachedMax, required Set<String> commentsBeingVotedOn}) : super(comments: comments, hasReachedMax: hasReachedMax, commentsBeingVotedOn: commentsBeingVotedOn);
  @override
  List<Object?> get props => super.props..add(message);
}