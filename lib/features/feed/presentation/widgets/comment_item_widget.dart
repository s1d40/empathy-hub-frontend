import 'package:anonymous_hubs/features/feed/presentation/models/comment_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:intl/intl.dart'; // For better date formatting
import 'package:anonymous_hubs/features/feed/presentation/cubit/comments_cubit/comments_cubit.dart';
import 'package:anonymous_hubs/core/enums/app_enums.dart';
import 'package:anonymous_hubs/features/user_profile/presentation/pages/user_profile_page.dart';
import 'package:anonymous_hubs/features/auth/presentation/auth_cubit.dart'; // Import AuthCubit
import 'package:anonymous_hubs/features/report/presentation/cubit/report_cubit.dart'; // Import ReportCubit
import 'package:anonymous_hubs/features/report/presentation/widgets/report_dialog_widget.dart'; // Import ReportDialogWidget


class CommentItemWidget extends StatelessWidget {
  final Comment comment;
  final bool isVoting;
  const CommentItemWidget({super.key, required this.comment, this.isVoting = false});
  void _navigateToUserProfile(BuildContext context, Comment commentWithAuthorDetails){
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => createUserProfilePageWithCubit(commentWithAuthorDetails.authorAnonymousId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    String? currentUserId;
    if (authState is Authenticated) currentUserId = authState.user.anonymousId;

    bool isLoadingDelete = false;
    final commentsCubitState = context.watch<CommentsCubit>().state;
    if (commentsCubitState is CommentDeleteInProgress && commentsCubitState.deletingCommentId == comment.id) {
      isLoadingDelete = true;
    }

    // final formattedDate = DateFormat('MMM d, yyyy hh:mm a').format(comment.createdAt.toLocal());
    final simpleFormattedDate =
        "${comment.createdAt.toLocal().year}-${comment.createdAt.toLocal().month.toString().padLeft(2, '0')}-${comment.createdAt.toLocal().day.toString().padLeft(2, '0')} ${comment.createdAt.toLocal().hour.toString().padLeft(2, '0')}:${comment.createdAt.toLocal().minute.toString().padLeft(2, '0')}";

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [ // Ensure this Row is correctly structured if more elements are added
                InkWell(
                  onTap: () => _navigateToUserProfile(context, comment), // Pass the comment object
                  child: CircleAvatar(
                    radius: 18,
                    backgroundImage: comment.avatarUrl != null // Use direct field from Comment
                        ? NetworkImage(comment.avatarUrl!)
                        : null,
                    child: comment.avatarUrl == null // Use direct field from Comment
                        ? Text(
                          comment.username.isNotEmpty ? comment.username[0].toUpperCase() : '?', // Use direct field
                          style: const TextStyle(fontSize: 16),
                        )
                        : null,
                  )
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () => _navigateToUserProfile(context, comment), // Pass the comment object
                        child: Text(
                          comment.username, // Use direct field from Comment
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        simpleFormattedDate, // Use formattedDate for more advanced formatting
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                if (currentUserId == comment.authorAnonymousId) ...[
                  if (isLoadingDelete)
                    const Padding(
                      padding: EdgeInsets.only(left: 8.0), // Align with IconButton
                      child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(), // To make it compact
                      tooltip: 'Delete Comment',
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: const Text('Delete Comment?'),
                            content: const Text('Are you sure you want to delete this comment? This action cannot be undone.'),
                            actions: [
                              TextButton(
                                child: const Text('Cancel'),
                                onPressed: () => Navigator.of(dialogContext).pop(),
                              ),
                              TextButton(
                                child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                onPressed: () {
                                  Navigator.of(dialogContext).pop(); // Close dialog
                                  context.read<CommentsCubit>().deleteComment(comment.id);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    )
                ] else ...[
                  // If not the author, show report button
                  IconButton(
                    icon: Icon(Icons.report_problem_outlined, color: Colors.orangeAccent.shade700, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Report Comment',
                    onPressed: () {
                      // Ensure ReportCubit is available in the context where the dialog is shown.
                      // This usually means providing it higher up in the widget tree,
                      // or wrapping the dialog with a BlocProvider if it's specific to the dialog.
                      showDialog(
                        context: context,
                        builder: (dialogContext) => BlocProvider.value(
                          value: BlocProvider.of<ReportCubit>(context), // Assuming ReportCubit is provided above
                          child: ReportDialogWidget(
                            itemType: ReportedItemType.comment,
                            itemAnonymousId: comment.id,
                          ),
                        ),
                      );
                    },
                  ),
                ]
              ],
            ),
            const SizedBox(height: 8),
            Text(comment.content ?? '', style: Theme.of(context).textTheme.bodyMedium), // Handle null content
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.thumb_up_alt_outlined, size: 18, color: Colors.green[700]),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: isVoting ? null : () {
                    context.read<CommentsCubit>().voteOnComment(comment.id, VoteType.upvote);
                  },
                ),
                const SizedBox(width: 2),
                isVoting 
                    ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5))
                    : Text('${comment.upvotes}', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                const SizedBox(width: 12),
                IconButton(
                  icon: Icon(Icons.thumb_down_alt_outlined, size: 18, color: Colors.red[700]),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: isVoting ? null : () {
                    context.read<CommentsCubit>().voteOnComment(comment.id, VoteType.downvote);
                  },
                ),
                const SizedBox(width: 2),
                isVoting
                    ? const SizedBox.shrink() // Don't show count if voting, or show previous count
                    : Text('${comment.downvotes}', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
              ],
            )
          ],
        ),
      ),
    );
  }
}