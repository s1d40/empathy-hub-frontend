import 'package:bloc/bloc.dart';
import 'package:empathy_hub_app/core/enums/app_enums.dart';
import 'package:empathy_hub_app/core/services/post_api_service.dart';
import 'package:empathy_hub_app/features/auth/presentation/auth_cubit.dart';
import 'package:empathy_hub_app/features/feed/presentation/models/post_model.dart';
import 'package:equatable/equatable.dart';

part 'post_item_state.dart';

class PostItemCubit extends Cubit<PostItemState> {
  final AuthCubit _authCubit;
  final PostApiService _postApiService;
  final Post _initialPost; // Keep a reference to the initial post if needed for resets

  PostItemCubit({
    required AuthCubit authCubit,
    required PostApiService postApiService,
    required Post initialPost,
  })  : _authCubit = authCubit,
        _postApiService = postApiService,
        _initialPost = initialPost, // Store the initial post
        super(PostItemInitial(initialPost));

  Future<void> vote(VoteType voteType) async {
    final currentPost = (state is PostItemInitial)
        ? (state as PostItemInitial).post
        : (state is PostItemActionSuccess)
            ? (state as PostItemActionSuccess).post
            : (state is PostItemActionFailure)
                ? (state as PostItemActionFailure).post
                : (state is PostItemActionInProgress)
                    ? (state as PostItemActionInProgress).post
                    : _initialPost; // Fallback, though should ideally always have a post in state

    final currentAuthState = _authCubit.state;
    if (currentAuthState is! Authenticated) {
      emit(PostItemActionFailure(currentPost, 'User not authenticated to vote.'));
      return;
    }
    final String token = currentAuthState.token;

    emit(PostItemActionInProgress(currentPost, actionType: 'voting'));

    try {
      final updatedPostData = await _postApiService.voteOnPost(token, currentPost.id, voteType);
      if (updatedPostData != null) {
        final updatedPost = Post.fromJson(updatedPostData);
        emit(PostItemActionSuccess(updatedPost));
      } else {
        emit(PostItemActionFailure(currentPost, 'Failed to vote on post. API returned null.'));
      }
    } catch (e) {
      emit(PostItemActionFailure(currentPost, 'Error voting on post: ${e.toString()}'));
    }
  }

  Future<void> deletePost() async {
    final currentPost = (state is PostItemInitial)
        ? (state as PostItemInitial).post
        : (state is PostItemActionSuccess)
            ? (state as PostItemActionSuccess).post
            : (state is PostItemActionFailure)
                ? (state as PostItemActionFailure).post
                : (state is PostItemActionInProgress)
                    ? (state as PostItemActionInProgress).post
                    : _initialPost;

    final currentAuthState = _authCubit.state;
    if (currentAuthState is! Authenticated) {
      emit(PostItemActionFailure(currentPost, 'User not authenticated to delete post.', actionType: 'deleting'));
      return;
    }
    final String token = currentAuthState.token;

    emit(PostItemActionInProgress(currentPost, actionType: 'deleting'));

    try {
      // According to api_docs.json, deletePost returns the PostRead schema (the deleted post)
      final deletedPostData = await _postApiService.deletePost(token, currentPost.id);
      if (deletedPostData != null) {
        // Even though the post is deleted, the API returns its data.
        // We emit PostItemDeleted to signal removal from UI.
        emit(const PostItemDeleted());
      } else {
        emit(PostItemActionFailure(currentPost, 'Failed to delete post. API returned null or error.', actionType: 'deleting'));
      }
    } catch (e) {
      emit(PostItemActionFailure(currentPost, 'Error deleting post: ${e.toString()}', actionType: 'deleting'));
    }
  }
}