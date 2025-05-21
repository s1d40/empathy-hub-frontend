part of 'feed_cubit.dart';

abstract class FeedState extends Equatable {
  const FeedState();

  @override
  List<Object> get props => [];
}

class FeedInitial extends FeedState {}

class FeedLoading extends FeedState {}

class FeedLoaded extends FeedState {
  final List<Post> posts;
  final bool hasReachedMax;
  final Set<String> postsBeingVotedOn; // IDs of posts currently having a vote processed
  final Set<String> postsBeingDeleted; // IDs of posts currently being deleted

  const FeedLoaded(
    this.posts, {
    this.hasReachedMax = false,
    this.postsBeingVotedOn = const {},
    this.postsBeingDeleted = const {},
  });

  @override
  List<Object> get props => [posts, hasReachedMax, postsBeingVotedOn, postsBeingDeleted];

  FeedLoaded copyWith({
    List<Post>? posts,
    bool? hasReachedMax,
    Set<String>? postsBeingVotedOn,
    Set<String>? postsBeingDeleted,
  }) {
    return FeedLoaded(
      posts ?? this.posts,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      postsBeingVotedOn: postsBeingVotedOn ?? this.postsBeingVotedOn,
      postsBeingDeleted: postsBeingDeleted ?? this.postsBeingDeleted,
    );
  }
}

class FeedError extends FeedState {
  final String message;

  const FeedError(this.message);

  @override
  List<Object> get props => [message];
}