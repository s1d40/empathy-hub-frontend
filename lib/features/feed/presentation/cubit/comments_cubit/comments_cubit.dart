import 'package:bloc/bloc.dart';
import 'package:empathy_hub_app/core/services/comment_api_service.dart';
import 'package:empathy_hub_app/features/auth/presentation/auth_cubit.dart';
import 'package:empathy_hub_app/features/feed/presentation/models/comment_model.dart';
import 'package:equatable/equatable.dart';
import 'package:empathy_hub_app/core/enums/app_enums.dart';

part 'comments_state.dart';

class CommentsCubit extends Cubit<CommentsState> {
  final String postId; // The anonymous_id of the post
  final CommentApiService _commentApiService;
  final AuthCubit _authCubit;

  static const int _commentsLimit = 15;

  CommentsCubit({
    required this.postId,
    required CommentApiService commentApiService,
    required AuthCubit authCubit,
  })  : _commentApiService = commentApiService,
        _authCubit = authCubit,
        super(CommentsInitial());

  Future<void> loadComments({bool isRefresh = false}) async {
    if (state is CommentsLoading && !isRefresh) return;

    // API for listing comments for a post might not require auth token
    // as per api_docs.json (it's optional in CommentApiService).
    // However, submitting a comment will.
    List<Comment> currentComments = [];
    bool currentHasReachedMax = false;
    Set<String> currentVotingSet = {};

    final capturedState = state;
    if (capturedState is CommentsLoaded) { // Preserve data if we're refreshing
      currentComments = capturedState.comments;
      currentHasReachedMax = capturedState.hasReachedMax; // Though this will be recalculated
      currentVotingSet = capturedState.commentsBeingVotedOn;
    }

    String? token;
    if (_authCubit.state is Authenticated) {
      token = (_authCubit.state as Authenticated).token;
    }
    emit(CommentsLoading(comments: currentComments, hasReachedMax: currentHasReachedMax, commentsBeingVotedOn: currentVotingSet));
    try {
      final commentsData = await _commentApiService.getCommentsForPost(
        postId,
        skip: 0,
        limit: _commentsLimit,
        token: token, // Pass token if endpoint becomes protected
      );
      if (commentsData != null) {
        final comments = commentsData.map((json) => Comment.fromJson(json)).toList();
        emit(CommentsLoaded(comments: comments, hasReachedMax: comments.length < _commentsLimit));
      } else {
        emit(CommentsError(message: 'Failed to load comments.', comments: currentComments, hasReachedMax: currentHasReachedMax, commentsBeingVotedOn: currentVotingSet));
      }
    } catch (e) {
      emit(CommentsError(message: 'Error loading comments: ${e.toString()}', comments: currentComments, hasReachedMax: currentHasReachedMax, commentsBeingVotedOn: currentVotingSet));
    }
  }

  Future<void> loadMoreComments() async {
    if (state is! CommentsLoaded || (state as CommentsLoaded).hasReachedMax) return;

    final currentLoadedState = state as CommentsLoaded;
    String? token;
    if (_authCubit.state is Authenticated) {
      token = (_authCubit.state as Authenticated).token;
    }

    try {
      final commentsData = await _commentApiService.getCommentsForPost(
        postId,
        skip: currentLoadedState.comments.length,
        limit: _commentsLimit,
        token: token,
      );
      if (commentsData != null) {
        if (commentsData.isEmpty) {
          emit(currentLoadedState.copyWith(hasReachedMax: true));
        } else {
          final newComments = commentsData.map((json) => Comment.fromJson(json)).toList();
          emit(currentLoadedState.copyWith(
            comments: currentLoadedState.comments + newComments,
            hasReachedMax: newComments.length < _commentsLimit,
          ));
        }
      } else {
         emit(CommentsError(message: 'Failed to load more comments.', comments: currentLoadedState.comments, hasReachedMax: currentLoadedState.hasReachedMax, commentsBeingVotedOn: currentLoadedState.commentsBeingVotedOn));
      }
    } catch (e) {
      emit(CommentsError(message: 'Error loading more comments: ${e.toString()}', comments: currentLoadedState.comments, hasReachedMax: currentLoadedState.hasReachedMax, commentsBeingVotedOn: currentLoadedState.commentsBeingVotedOn));
    }
  }

  Future<void> submitComment(String content) async {
    List<Comment> currentCommentsList = [];
    bool currentHasReachedMaxVal = false;
    Set<String> currentVotingSet = {};

    final capturedState = state;
    if (capturedState is CommentsLoaded) {
        currentCommentsList = capturedState.comments;
        currentHasReachedMaxVal = capturedState.hasReachedMax;
        currentVotingSet = capturedState.commentsBeingVotedOn;
    }

    if (_authCubit.state is! Authenticated) {
      emit(CommentSubmitFailure(
        message: 'You must be logged in to comment.',
        comments: currentCommentsList,
        hasReachedMax: currentHasReachedMaxVal,
        commentsBeingVotedOn: currentVotingSet,
      ));
      return;
    }
    final token = (_authCubit.state as Authenticated).token;
    emit(CommentSubmitting(
      comments: currentCommentsList,
      hasReachedMax: currentHasReachedMaxVal,
      commentsBeingVotedOn: currentVotingSet,
    ));
    try {
      final newCommentData = await _commentApiService.createCommentForPost(token, postId, content);
      if (newCommentData != null) {
        final newComment = Comment.fromJson(newCommentData);
        emit(CommentSubmitSuccess(newComment));
        // After successful submission, refresh the comments list to include the new one
        loadComments(isRefresh: true);
      } else {
        emit(CommentSubmitFailure(message: 'Failed to submit comment.', comments: currentCommentsList, hasReachedMax: currentHasReachedMaxVal, commentsBeingVotedOn: currentVotingSet));
      }
    } catch (e) {
      emit(CommentSubmitFailure(message: 'Error submitting comment: ${e.toString()}', comments: currentCommentsList, hasReachedMax: currentHasReachedMaxVal, commentsBeingVotedOn: currentVotingSet));
    }
  }

  Future<void> voteOnComment(String commentId, VoteType voteType) async {
    if (state is! CommentsLoaded) return; // Can only vote if comments are loaded

    final currentLoadedState = state as CommentsLoaded;
    if (_authCubit.state is! Authenticated) {
      emit(CommentVoteFailure(
        message: "User not authenticated to vote on comment.",
        comments: currentLoadedState.comments,
        hasReachedMax: currentLoadedState.hasReachedMax,
        commentsBeingVotedOn: currentLoadedState.commentsBeingVotedOn,
      ));
      return;
    }
    final token = (_authCubit.state as Authenticated).token;

    // Indicate that this comment is being voted on
    emit(currentLoadedState.copyWith(
      commentsBeingVotedOn: {...currentLoadedState.commentsBeingVotedOn, commentId},
    ));

    try {
      final updatedCommentData = await _commentApiService.voteOnComment(token, commentId, voteType);

      if (updatedCommentData != null) {
        final updatedComment = Comment.fromJson(updatedCommentData);
        final updatedComments = currentLoadedState.comments.map((comment) {
          return comment.id == commentId ? updatedComment : comment;
        }).toList();
        emit(currentLoadedState.copyWith(
          comments: updatedComments,
          commentsBeingVotedOn: {...currentLoadedState.commentsBeingVotedOn}..remove(commentId),
        ));
      } else {
        emit(CommentVoteFailure(
          message: 'Failed to vote on comment $commentId. API returned null.',
          comments: currentLoadedState.comments,
          hasReachedMax: currentLoadedState.hasReachedMax,
          commentsBeingVotedOn: {...currentLoadedState.commentsBeingVotedOn}..remove(commentId),
        ));
      }
    } catch (e) {
      emit(CommentVoteFailure(
        message: 'Error voting on comment $commentId: ${e.toString()}',
        comments: currentLoadedState.comments,
        hasReachedMax: currentLoadedState.hasReachedMax,
        commentsBeingVotedOn: {...currentLoadedState.commentsBeingVotedOn}..remove(commentId),
      ));
    }
  }

  Future<void> deleteComment(String commentId) async {
    final capturedState = state;
    List<Comment> currentComments = [];
    bool currentHasReachedMax = false;
    Set<String> currentVotingSet = {};

    if (capturedState is CommentsLoaded) {
      currentComments = capturedState.comments;
      currentHasReachedMax = capturedState.hasReachedMax;
      currentVotingSet = capturedState.commentsBeingVotedOn;
    } else {
      // Should not happen if delete is only possible when comments are loaded,
      // but as a fallback, emit a generic error.
      emit(CommentsError(message: 'Cannot delete comment: comments not loaded.'));
      return;
    }

    final authState = _authCubit.state;
    if (authState is! Authenticated) {
      emit(CommentsError(message: 'User not authenticated. Cannot delete comment.', comments: currentComments, hasReachedMax: currentHasReachedMax, commentsBeingVotedOn: currentVotingSet));
      return;
    }
    final token = authState.token;

    emit(CommentDeleteInProgress(deletingCommentId: commentId, comments: currentComments, hasReachedMax: currentHasReachedMax, commentsBeingVotedOn: currentVotingSet));

    try {
      final success = await _commentApiService.deleteComment(commentId, token);
      if (success) {
        await loadComments(isRefresh: true); // Reload comments on success
      } else {
        emit(CommentsError(message: 'Failed to delete comment. API indicated failure.', comments: currentComments, hasReachedMax: currentHasReachedMax, commentsBeingVotedOn: currentVotingSet));
      }
    } catch (e) {
      emit(CommentsError(message: 'Error deleting comment: ${e.toString()}', comments: currentComments, hasReachedMax: currentHasReachedMax, commentsBeingVotedOn: currentVotingSet));
    }
  }
}