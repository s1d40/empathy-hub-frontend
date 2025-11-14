import 'package:anonymous_hubs/features/feed/presentation/models/post_model.dart'; // Changed import
import 'package:anonymous_hubs/features/feed/presentation/pages/post_details_page.dart'; // Import the PostDetailsPage
import 'package:anonymous_hubs/features/user_profile/presentation/pages/user_profile_page.dart'; // Import UserProfilePage
import 'package:anonymous_hubs/features/feed/presentation/cubit/post_item_cubit/post_item_cubit.dart';
import 'package:anonymous_hubs/core/enums/app_enums.dart'; // For VoteType
import 'package:anonymous_hubs/features/report/presentation/cubit/report_cubit.dart'; // Import ReportCubit
import 'package:anonymous_hubs/shared/widgets/user_actions_popup_menu_button.dart'; // Import the new widget
import 'package:anonymous_hubs/features/report/presentation/widgets/report_dialog_widget.dart'; // Import ReportDialogWidget
import 'package:anonymous_hubs/features/auth/presentation/auth_cubit.dart'; // Import AuthCubit
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

//Widget to displaty a single feed item

class FeedItemWidget extends StatelessWidget {
  const FeedItemWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    String? currentUserId;
    if (authState is Authenticated) currentUserId = authState.user.anonymousId;

    return BlocBuilder<PostItemCubit, PostItemState>(
      builder: (context, state) {
        // Determine the post data based on the current state
        Post? post;
        bool isLoadingVote = false;
        bool isLoadingDelete = false;

        if (state is PostItemInitial) {
          post = state.post;
        } else if (state is PostItemActionInProgress) {
          post = state.post;
          if (state.actionType == 'voting') isLoadingVote = true;
          if (state.actionType == 'deleting') isLoadingDelete = true; 
        } else if (state is PostItemActionSuccess) {
          post = state.post;
        } else if (state is PostItemActionFailure) {
          post = state.post;
          // Optionally show an error indication on the item, e.g., via a SnackBar in a BlocListener
        } else if (state is PostItemDeleted) { // PostItemDeleted does not have post or avatar
          // This state is handled by the BlocListener in HomePage to remove the item.
          // Return an empty container as it will be removed from the list.
          return const SizedBox.shrink();
        }

        if (post == null) {
          // Fallback, though ideally states should always provide a post object
          // or be handled before this builder (like PostItemDeleted).
          return const Card(
              child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text("Error: Post data unavailable.")));
        }

        final currentPost = post; // for clarity

        // Wrap the Card with GestureDetector to make the whole item tappable
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PostDetailsPage(post: currentPost),
              ),
            );
          },
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
            elevation: 2.0,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                Row( // This is the main row for author info and post actions
                  children: <Widget>[ // Use currentPost.author for UserActionsPopupMenuButton
                    UserActionsPopupMenuButton(
                      targetUserAnonymousId: currentPost.author.anonymousId,
                      targetUsername: currentPost.author.username,
                      targetUserChatAvailability: currentPost.author.chatAvailability, // Pass chat availability
                      isOwnProfile: currentUserId == currentPost.author.anonymousId,
                      child: CircleAvatar(
                        backgroundImage: currentPost.author.avatarUrl != null
                            ? NetworkImage(currentPost.author.avatarUrl!)
                            : null,
                        radius: 20,
                        child: currentPost.author.avatarUrl == null
                            ? Text(currentPost.author.username.isNotEmpty
                                  ? currentPost.author.username[0].toUpperCase()
                                  : '?')
                            : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column( // Use currentPost.author for UserActionsPopupMenuButton
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          UserActionsPopupMenuButton(
                            targetUserAnonymousId: currentPost.author.anonymousId,
                            targetUsername: currentPost.author.username,
                            targetUserChatAvailability: currentPost.author.chatAvailability, // Pass chat availability
                            isOwnProfile: currentUserId == currentPost.author.anonymousId,
                            child: Text(
                              currentPost.author.username,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                decoration: TextDecoration.underline, // Indicate tappable
                              ),
                            ),
                          ),
                          Text(
                            "${currentPost.createdAt.toLocal().year}-${currentPost.createdAt.toLocal().month.toString().padLeft(2, '0')}-${currentPost.createdAt.toLocal().day.toString().padLeft(2, '0')} ${currentPost.createdAt.toLocal().hour.toString().padLeft(2, '0')}:${currentPost.createdAt.toLocal().minute.toString().padLeft(2, '0')}",
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    // Action buttons (Delete or Report for the POST itself)
                    if (currentUserId == currentPost.author.anonymousId) ...[
                      if (isLoadingDelete)
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      else
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          tooltip: 'Delete Post',
                          onPressed: () {
                            _showDeleteConfirmationDialog(context, currentPost.id);
                          },
                        ),
                    ] else ...[
                      // If not the author, show report button for the post
                      if (currentUserId != null) // Only show report if a user is logged in
                          IconButton(
                            icon: Icon(Icons.report_problem_outlined, color: Colors.orangeAccent.shade700, size: 24), // Slightly larger icon for post? Or keep 20? Let's keep 24 for now.
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'Report Post',
                            onPressed: () {
                              // Ensure ReportCubit is available in the context where the dialog is shown.
                              // This usually means providing it higher up in the widget tree,
                              // or wrapping the dialog with a BlocProvider if it's specific to the dialog.
                              showDialog(
                                context: context,
                                builder: (dialogContext) => BlocProvider.value(
                                  value: BlocProvider.of<ReportCubit>(context), // Assuming ReportCubit is provided above
                                  child: ReportDialogWidget(
                                    itemType: ReportedItemType.post,
                                    itemAnonymousId: currentPost.id,
                                  ),
                                ),
                              );
                            },
                          ),
                    ]
                  ],
                ), // Closes the main Row for author info and post actions
                  const SizedBox(height: 10),
                  Text(
                    currentPost.content ?? '', // Keep this as post content can be null
                    style: const TextStyle(fontSize: 15, height: 1.3),
                    maxLines: 5, // Limit lines in feed view
                    overflow: TextOverflow.ellipsis, // Show ellipsis if content is too long
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          IconButton(
                            icon: const Icon(Icons.thumb_up_outlined),
                            iconSize: 20.0,
                            color: Colors.green, // TODO: Indicate if user has upvoted
                            onPressed: isLoadingVote ? null : () => context.read<PostItemCubit>().vote(VoteType.upvote),
                          ),
                          isLoadingVote ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : Text('${currentPost.upvotes}'),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: const Icon(Icons.thumb_down_outlined),
                            iconSize: 20.0,
                            color: Colors.red, // TODO: Indicate if user has downvoted
                            onPressed: isLoadingVote ? null : () => context.read<PostItemCubit>().vote(VoteType.downvote),
                          ),
                          isLoadingVote ? const SizedBox.shrink() : Text('${currentPost.downvotes}'),
                        ],
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.comment_outlined, size: 20.0),
                        label: Text('${currentPost.commentCount}'), // Use commentCount
                        onPressed: () {
                          // This will also trigger the Card's onTap due to gesture bubbling,
                          // which is fine as it should navigate to post details.
                          print('Comment button tapped for post: ${currentPost.id}');
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Moved delete dialog logic into a separate method for clarity
  void _showDeleteConfirmationDialog(BuildContext context, String postId) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Post?'),
        content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          TextButton(
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
            onPressed: () {
              Navigator.of(dialogContext).pop(); // Close dialog
              context.read<PostItemCubit>().deletePost(); // PostItemCubit knows its post ID
            },
          ),
        ],
      ),
    );
  }
}