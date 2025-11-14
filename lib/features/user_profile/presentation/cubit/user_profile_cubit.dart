import 'package:anonymous_hubs/features/auth/presentation/auth_cubit.dart';
import 'package:anonymous_hubs/features/auth/presentation/models/user_model.dart';
import 'package:anonymous_hubs/features/feed/presentation/models/comment_model.dart';
import 'package:anonymous_hubs/features/feed/presentation/models/post_model.dart';
import 'package:anonymous_hubs/core/services/user_api_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'user_profile_state.dart';

class UserProfileCubit extends Cubit<UserProfileState> {
  final UserApiService _userApiService;
  final AuthCubit _authCubit;

  UserProfileCubit({
    required UserApiService userApiService,
    required AuthCubit authCubit,
  })  : _userApiService = userApiService,
        _authCubit = authCubit,
        super(UserProfileInitial());

  Future<void> fetchUserProfileData(String userAnonymousId) async {
    if (_authCubit.state is! Authenticated) {
      emit(const UserProfileError("User not authenticated."));
      return;
    }
    final token = (_authCubit.state as Authenticated).token;

    emit(UserProfileLoading());

    try {
      final userData = await _userApiService.getUserByAnonymousId(token, userAnonymousId);
      if (userData == null) {
        emit(const UserProfileError("User not found."));
        return;
      }
      // Ensure userData is a Map<String, dynamic> before parsing
      if (userData is! Map<String, dynamic>) {
        emit(UserProfileError("Invalid user data format from API: ${userData.runtimeType}"));
        return;
      }
      final parsedUser = User.fromJson(userData);
      emit(UserProfileLoaded(user: parsedUser));

      // Concurrently fetch posts and comments or sequentially
      await fetchUserPosts(userAnonymousId, token);
      await fetchUserComments(userAnonymousId, token);
    } catch (e) {
      emit(UserProfileError("Failed to load user profile: ${e.toString()}"));
    }
  }

  Future<void> fetchUserPosts(String authorAnonymousId, String token) async {
    if (state is! UserProfileLoaded) return;
    final currentState = state as UserProfileLoaded;
    emit(currentState.copyWith(postsLoading: true, postsError: null));

    try {
      // Assuming getPostsByAuthor returns List<dynamic> or List<Map<String, dynamic>>
      final postsData = await _userApiService.getPostsByAuthor(token, authorAnonymousId);
      List<Post> parsedPosts = [];
      if (postsData != null) {
        parsedPosts = postsData.map<Post>((postData) { // Explicit type argument <Post>
          // Assuming postsData is List<Map<String, dynamic>>, so postData is Map<String, dynamic>
          return Post.fromJson(postData);
        }).toList();
      }

      emit(currentState.copyWith(posts: parsedPosts, postsLoading: false));
    } catch (e) {
      emit(currentState.copyWith(
        postsLoading: false,
        postsError: "Failed to load posts: ${e.toString()}",
      ));
    }
  }

  Future<void> fetchUserComments(String authorAnonymousId, String token) async {
    if (state is! UserProfileLoaded) return;
    final currentState = state as UserProfileLoaded;
    emit(currentState.copyWith(commentsLoading: true, commentsError: null));

    try {
      // Assuming getCommentsByAuthorId returns List<Comment>
      // You might need to adjust the service method if it returns List<dynamic>
      final commentsData = await _userApiService.getCommentsByAuthor(token, authorAnonymousId);
      List<Comment> comments = [];
      if (commentsData != null) {
        comments = commentsData.map<Comment>((commentData) { // Explicit type argument <Comment>
          // Assuming commentsData is List<Map<String, dynamic>>, so commentData is Map<String, dynamic>
          return Comment.fromJson(commentData);
        }).toList();
      }

      emit(currentState.copyWith(comments: comments, commentsLoading: false));
    } catch (e) {
      emit(currentState.copyWith(
        commentsLoading: false,
        commentsError: "Failed to load comments: ${e.toString()}",
      ));
    }
  }
}