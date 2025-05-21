part of 'user_profile_cubit.dart';

abstract class UserProfileState extends Equatable {
  const UserProfileState();

  @override
  List<Object?> get props => [];
}

class UserProfileInitial extends UserProfileState {}

class UserProfileLoading extends UserProfileState {}

class UserProfileLoaded extends UserProfileState {
  final User user;
  final List<Post> posts;
  final List<Comment> comments;
  final bool postsLoading;
  final bool commentsLoading;
  final String? postsError;
  final String? commentsError;

  const UserProfileLoaded({
    required this.user,
    this.posts = const [],
    this.comments = const [],
    this.postsLoading = false,
    this.commentsLoading = false,
    this.postsError,
    this.commentsError,
  });

  @override
  List<Object?> get props => [
        user,
        posts,
        comments,
        postsLoading,
        commentsLoading,
        postsError,
        commentsError,
      ];

  UserProfileLoaded copyWith({
    User? user,
    List<Post>? posts,
    List<Comment>? comments,
    bool? postsLoading,
    bool? commentsLoading,
    String? postsError,
    String? commentsError,
  }) {
    return UserProfileLoaded(
      user: user ?? this.user,
      posts: posts ?? this.posts,
      comments: comments ?? this.comments,
      postsLoading: postsLoading ?? this.postsLoading,
      commentsLoading: commentsLoading ?? this.commentsLoading,
      postsError: postsError ?? this.postsError,
      commentsError: commentsError ?? this.commentsError,
    );
  }
}

class UserProfileError extends UserProfileState {
  final String message;

  const UserProfileError(this.message);

  @override
  List<Object> get props => [message];
}