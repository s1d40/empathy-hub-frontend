import 'package:bloc/bloc.dart';
import 'package:empathy_hub_app/features/auth/presentation/auth_cubit.dart';
import 'package:empathy_hub_app/features/feed/presentation/models/post_model.dart';
import 'package:empathy_hub_app/core/services/post_api_service.dart';
import 'package:equatable/equatable.dart';
import 'package:empathy_hub_app/core/enums/app_enums.dart'; // For VoteType

part 'feed_state.dart';

class FeedCubit extends Cubit<FeedState> {
  final AuthCubit _authCubit;
  final PostApiService _postApiService;

  static const int _postsLimit = 20; // Define a limit for how many posts to fetch at a time

  FeedCubit({
    required AuthCubit authCubit,
    required PostApiService postApiService,
  })  : _authCubit = authCubit,
        _postApiService = postApiService,
        super(FeedInitial());

  /// Loads the initial set of posts or refreshes the existing list.
  Future<void> loadPosts({bool isRefresh = false}) async {
    // Prevent multiple simultaneous initial loads unless it's a refresh
    if (state is FeedLoading && !isRefresh) {
      return;
    }
    // Check current auth state to get the token
    final currentAuthState = _authCubit.state;
    if (currentAuthState is! Authenticated) {
      // Optionally, emit an error or specific state if user is not authenticated
      // For now, we'll just not proceed if not authenticated,
      // assuming the UI handles this (e.g., by not showing the feed tab or prompting login).
      // Or, emit an error:
      // emit(const FeedError("User not authenticated. Cannot load posts."));
      print("FeedCubit: User not authenticated. Cannot load posts.");
      return;
    }
    final String token = currentAuthState.token;

    try {
      emit(FeedLoading());
      final postsData = await _postApiService.getPosts(
        token, // Pass token as a positional argument
        skip: 0, // For initial load or refresh, always start from the beginning
        limit: _postsLimit,
      );

      if (postsData != null) {
        final List<Post> posts = postsData
            .map((postJson) => Post.fromJson(postJson))
            .toList();
        emit(FeedLoaded(
          posts,
          hasReachedMax: posts.length < _postsLimit,
        ));
      } else {
        emit(const FeedError('Failed to load posts. API returned null.'));
      }
    } catch (e) {
      emit(FeedError('Failed to load posts: ${e.toString()}'));
    }
  }

  /// Loads more posts for pagination.
  Future<void> loadMorePosts() async {
    if (state is! FeedLoaded) return; // Can only load more if posts are already loaded

    final currentLoadedState = state as FeedLoaded;
    if (currentLoadedState.hasReachedMax) return; // No more posts to load

    // Prevent multiple loadMore calls if one is already in progress (more complex state needed for this)
    // For now, we assume UI won't call this rapidly if it's already "loading more".

    final currentAuthState = _authCubit.state;
    if (currentAuthState is! Authenticated) {
      print("FeedCubit: User not authenticated. Cannot load more posts.");
      return;
    }
    final String token = currentAuthState.token;

    try {
      // The UI can show a loading indicator at the bottom of the list while this runs.
      // We don't emit FeedLoading here to avoid replacing the whole screen.
      final int currentSkip = currentLoadedState.posts.length;
      final postsData = await _postApiService.getPosts(
        token,
        skip: currentSkip,
        limit: _postsLimit,
      );

      if (postsData != null) {
        if (postsData.isEmpty) {
          emit(currentLoadedState.copyWith(hasReachedMax: true));
        } else {
          final List<Post> newPosts = postsData
              .map((postJson) => Post.fromJson(postJson))
              .toList();
          emit(currentLoadedState.copyWith(
            posts: currentLoadedState.posts + newPosts, // Append new posts
            hasReachedMax: newPosts.length < _postsLimit,
          ));
        }
      } else {
        // Handle API error for load more, maybe don't change hasReachedMax
        // Or emit a specific error that UI can show as a snackbar/toast
        print('FeedCubit: Failed to load more posts. API returned null.');
      }
    } catch (e) {
      print('FeedCubit: Error loading more posts: ${e.toString()}');
      // Handle error, maybe emit a temporary error state or log
    }
  }

  /// Refreshes the entire list of posts.
  Future<void> refreshPosts() async {
    await loadPosts(isRefresh: true);
  }

  // TODO: Add method for deleting a post (deletePostInFeed)
}