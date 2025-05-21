import 'package:empathy_hub_app/features/feed/presentation/models/post_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:empathy_hub_app/features/feed/presentation/cubit/comments_cubit/comments_cubit.dart';
import 'package:empathy_hub_app/core/services/comment_api_service.dart';
import 'package:empathy_hub_app/features/auth/presentation/auth_cubit.dart';
import 'package:empathy_hub_app/features/feed/presentation/widgets/comment_item_widget.dart';
import 'package:empathy_hub_app/features/user_profile/presentation/pages/user_profile_page.dart'; // Added import
import 'package:empathy_hub_app/features/feed/presentation/cubit/post_item_cubit/post_item_cubit.dart'; // Import PostItemCubit
import 'package:empathy_hub_app/core/services/post_api_service.dart'; // Import PostApiService
import 'package:empathy_hub_app/core/enums/app_enums.dart'; // For ReportedItemType
import 'package:empathy_hub_app/features/report/presentation/cubit/report_cubit.dart'; // Import ReportCubit
import 'package:empathy_hub_app/features/report/presentation/widgets/report_dialog_widget.dart'; // Import ReportDialogWidget

class PostDetailsPage extends StatefulWidget {
  final Post post;
  const PostDetailsPage({super.key, required this.post});

  @override
  State<PostDetailsPage> createState() => _PostDetailsPageState();
}

class _PostDetailsPageState extends State<PostDetailsPage> {
  final _commentTextController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PostItemCubit>(
      create: (context) => PostItemCubit(
        postApiService: context.read<PostApiService>(),
        authCubit: context.read<AuthCubit>(),
        initialPost: widget.post, // Pass the specific post to the cubit
      ),
      child: BlocListener<PostItemCubit, PostItemState>(
        listener: (context, state) {
          if (state is PostItemDeleted) { // Actual success state for deletion
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Post deleted successfully')),
            );
            // Pop the page and optionally return a value (true) to indicate success,
            // which can be used by the previous page (e.g., feed) to refresh.
            if (Navigator.canPop(context)) {
              Navigator.of(context).pop(true); // true indicates a successful deletion
            }
          } else if (state is PostItemActionFailure && state.actionType == 'deleting') { // Actual failure state for deletion
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to delete post: ${state.errorMessage}')),
            );
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.post.title ?? "Post Details"),
            actions: <Widget>[
              BlocBuilder<PostItemCubit, PostItemState>(
                builder: (cubitContext, postItemState) { // cubitContext has PostItemCubit
                  final authState = cubitContext.watch<AuthCubit>().state;
                  if (authState is Authenticated &&
                      authState.user.anonymousId == widget.post.author.anonymousId) {
                    // Show loading indicator if deletion is in progress
                    if (postItemState is PostItemActionInProgress &&
                        postItemState.actionType == 'deleting') { // Actual in-progress state for deletion
                      return const Padding(
                        padding: EdgeInsets.only(right: 16.0), // Adjust padding as needed
                        child: Center(
                          child: SizedBox(
                            width: 24, // Standard icon size
                            height: 24, // Standard icon size
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white), // For visibility on AppBar
                            ),
                          ),
                        ),
                      );
                    }
                    // Show delete button if user is the author and not currently deleting
                    return IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Delete Post',
                      onPressed: () {
                        // Pass cubitContext which has PostItemCubit in its scope
                        // The cubit's deletePost method knows which post to delete (the one it was initialized with)
                        _showDeleteConfirmationDialog(cubitContext);
                      },
                    );
                  } else if (authState is Authenticated) {
                    // If authenticated but NOT the author, show Report button
                    return IconButton(
                      icon: Icon(Icons.report_problem_outlined, color: Colors.orangeAccent.shade700),
                      tooltip: 'Report Post',
                      onPressed: () {
                        showDialog(
                          context: context, // Use the page's context
                          builder: (dialogContext) => BlocProvider.value(
                            value: BlocProvider.of<ReportCubit>(context), // Pass ReportCubit from page's context
                            child: ReportDialogWidget(
                              itemType: ReportedItemType.post,
                              itemAnonymousId: widget.post.id, // Use post's ID
                            ),
                          ),
                        );
                      },
                    );
                  }
                  // If not authenticated, or any other case, show nothing
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
          body: BlocProvider(
            create: (context) => CommentsCubit( // This context is from BlocListener's child
              postId: widget.post.id,
              commentApiService: context.read<CommentApiService>(),
              authCubit: context.read<AuthCubit>(),
            )..loadComments(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Author Info
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => createUserProfilePageWithCubit(widget.post.author.anonymousId)),
                      );
                    },
                    child: Row(
                      children: <Widget>[
                        CircleAvatar(
                          backgroundImage: widget.post.author.avatarUrl != null && widget.post.author.avatarUrl!.startsWith('http')
                              ? NetworkImage(widget.post.author.avatarUrl!)
                              : null,
                          radius: 40,
                          child: (widget.post.author.avatarUrl == null || !widget.post.author.avatarUrl!.startsWith('http'))
                              ? Text(widget.post.author.username.isNotEmpty ? widget.post.author.username[0].toUpperCase() : '?')
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column( // Use widget.post.author
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                widget.post.author.username,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                              ),
                              Text(
                                "${widget.post.createdAt.toLocal().year}-${widget.post.createdAt.toLocal().month.toString().padLeft(2, '0')}-${widget.post.createdAt.toLocal().day.toString().padLeft(2, '0')} ${widget.post.createdAt.toLocal().hour.toString().padLeft(2, '0')}:${widget.post.createdAt.toLocal().minute.toString().padLeft(2, '0')}",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Post Content
                  if (widget.post.title != null && widget.post.title!.isNotEmpty) ...[
                    Text(
                      widget.post.title!,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    widget.post.content ?? '', // Keep this as post content can be null
                    style: const TextStyle(fontSize: 16, height: 1.4),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Comments Section
                  Text('Comments (${widget.post.commentCount})', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 10),
                  _buildCommentsSection(),
                  const SizedBox(height: 20),
                  _buildAddCommentSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext cubitContext) {
    // Use the page's context (`this.context`) to show the dialog
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) { // This is the dialog's own context
        return AlertDialog(
          title: const Text('Delete Post'),
          content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                // Use cubitContext, which has PostItemCubit in its scope, to dispatch the delete action
                // The PostItemCubit's deletePost method doesn't require parameters here
                cubitContext.read<PostItemCubit>().deletePost();
                Navigator.of(dialogContext).pop(); // Close the dialog after dispatching
              },
            ),
          ],
        );
      },
    );
  }
  Widget _buildCommentsSection() {
    return BlocBuilder<CommentsCubit, CommentsState>(
      builder: (context, state) {
        if (state is CommentsLoading && (state is! CommentsLoaded || (state as CommentsLoaded).comments.isEmpty)) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is CommentsLoaded) {
          if (state.comments.isEmpty) {
            return const Text('No comments yet. Be the first to comment!');
          }
          return ListView.builder(
            shrinkWrap: true, // Important for ListView inside SingleChildScrollView
            physics: const NeverScrollableScrollPhysics(), // Disable scrolling for inner ListView
            itemCount: state.comments.length + (state.hasReachedMax ? 0 : 1),
            itemBuilder: (context, index) {
              if (index >= state.comments.length) {
                // TODO: Implement a "Load More Comments" button or auto-load on scroll
                return TextButton(
                  onPressed: () => context.read<CommentsCubit>().loadMoreComments(),
                  child: const Text('Load More Comments'),
                );
              }
              final comment = state.comments[index];
              // Determine if this specific comment is currently being voted on
              final bool isCurrentlyVoting = state.commentsBeingVotedOn.contains(comment.id);
              return CommentItemWidget(
                comment: comment,
                isVoting: isCurrentlyVoting, // Pass the voting status
              );
            },
          );
        }
        if (state is CommentsError) {
          return Text('Error loading comments: ${state.message}');
        }
        return const Text('Start the conversation!'); // Initial or other states
      },
    );
  }

  Widget _buildAddCommentSection() {
    return BlocConsumer<CommentsCubit, CommentsState>(
      listener: (context, state) {
        if (state is CommentSubmitSuccess) {
          _commentTextController.clear();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Comment posted!')),
          );
          // Comments list will refresh due to loadComments(isRefresh: true) in cubit
        } else if (state is CommentSubmitFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to post comment: ${state.message}')),
          );
        }
      },
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _commentTextController,
              decoration: const InputDecoration(
                hintText: 'Add a comment...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              enabled: state is! CommentSubmitting, // Disable while submitting
            ),
            const SizedBox(height: 10),
            if (state is CommentSubmitting)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton(
                onPressed: () {
                  if (_commentTextController.text.trim().isNotEmpty) {
                    context.read<CommentsCubit>().submitComment(_commentTextController.text.trim());
                  }
                },
                child: const Text('Submit Comment'),
              ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _commentTextController.dispose();
    super.dispose();
  }

}