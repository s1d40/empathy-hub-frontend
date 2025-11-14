import 'package:anonymous_hubs/core/services/comment_api_service.dart';
import 'package:anonymous_hubs/features/auth/presentation/auth_cubit.dart';
import 'package:anonymous_hubs/features/feed/presentation/models/comment_model.dart';
import 'package:anonymous_hubs/features/feed/presentation/widgets/comment_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:anonymous_hubs/features/feed/presentation/cubit/comments_cubit/comments_cubit.dart';

class UserProfileCommentsListWidget extends StatelessWidget {
  final List<Comment> comments;
  final bool isLoading;
  final String? error;

  const UserProfileCommentsListWidget({
    super.key,
    required this.comments,
    required this.isLoading,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(child: Text('Error loading comments: $error'));
    }
    if (comments.isEmpty) {
      return const Center(child: Text('This user has not made any comments yet.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8.0), // Keep padding from original
      itemCount: comments.length,
      itemBuilder: (context, index) {
        final commentItem = comments[index];
        return BlocProvider<CommentsCubit>(
          create: (_) => CommentsCubit(
            postId: commentItem.postId, // Each comment knows its post ID
            commentApiService: context.read<CommentApiService>(),
            authCubit: context.read<AuthCubit>(),
            // No initial loadComments() here, as this cubit is for item-specific actions
            // like delete/vote on this specific comment if it were enabled.
          ),
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CommentItemWidget(comment: commentItem, isVoting: false),
            ),
          ),
        );
      },
    );
  }
}