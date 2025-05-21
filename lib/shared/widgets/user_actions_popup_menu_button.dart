import 'package:empathy_hub_app/core/enums/app_enums.dart';
import 'package:empathy_hub_app/features/auth/presentation/auth_cubit.dart'; // Needed to check if it's own profile
import 'package:empathy_hub_app/features/chat/data/models/chat_initiate_model.dart'; // Assuming this model exists for chat initiation
import 'package:empathy_hub_app/features/chat/presentation/cubit/chat_initiation_cubit/chat_initiation_cubit.dart'; // Use ChatInitiationCubit
import 'package:empathy_hub_app/features/report/presentation/cubit/report_cubit.dart';
import 'package:empathy_hub_app/features/report/presentation/widgets/report_dialog_widget.dart';
import 'package:empathy_hub_app/features/chat/presentation/widgets/chat_request_message_dialog_widget.dart'; // Import the new dialog
import 'package:empathy_hub_app/features/user_profile/presentation/cubit/user_interaction_cubit.dart'; // Needed for mute/block actions
import 'package:empathy_hub_app/features/chat/presentation/pages/chat_room_page.dart'; // For navigation
import 'package:empathy_hub_app/features/user_profile/presentation/pages/user_profile_page.dart'; // Needed for navigation
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserActionsPopupMenuButton extends StatelessWidget {
  final String targetUserAnonymousId;
  final String targetUsername; // For display in confirmations or titles
  final String? targetUserChatAvailability; // Added
  final Widget child; // The widget that triggers the popup (e.g., username Text or Avatar)
  // isOwnProfile is determined by the parent widget for simplicity,
  // as the parent likely already has access to the current user ID.
  final bool isOwnProfile;

  const UserActionsPopupMenuButton({
    super.key,
    required this.targetUserAnonymousId,
    required this.targetUsername,
    required this.child,
    this.targetUserChatAvailability, // Added
    this.isOwnProfile = false, // Default to false
  });

  void _handleMenuSelection(BuildContext context, UserActionMenuItem item) {
    // Access Cubits from the context. They must be provided higher up.
    final userInteractionCubit = context.read<UserInteractionCubit>();
    final reportCubit = context.read<ReportCubit>();
    // Use ChatInitiationCubit
    final chatInitiationCubit = context.read<ChatInitiationCubit>();

    switch (item) {
      case UserActionMenuItem.viewProfile:
        // Navigate to the user's profile page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                createUserProfilePageWithCubit(targetUserAnonymousId),
          ),
        );
        break;
      case UserActionMenuItem.startChat:
        if (targetUserChatAvailability == 'request_only') {
          showDialog(
            context: context,
            // Provide ChatInitiationCubit to the dialog
            builder: (dialogContext) => BlocProvider.value(
              value: chatInitiationCubit,
              child: ChatRequestMessageDialogWidget(
                targetUserAnonymousId: targetUserAnonymousId,
                targetUsername: targetUsername,
              ),
            ),
          );
        } else if (targetUserChatAvailability == 'do_not_disturb') {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$targetUsername is not accepting messages now.')),
          );
        } else { // Defaults to open_to_chat or if availability is unknown
          chatInitiationCubit.initiateChat(ChatInitiate(targetUserAnonymousId: targetUserAnonymousId));
          // Feedback is handled by the BlocListener below
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Starting chat with $targetUsername...')),
          );
        }
        break;
      case UserActionMenuItem.muteUser:
        // Mute the target user
        userInteractionCubit.muteUser(targetUserAnonymousId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Muting $targetUsername...')),
        );
        break;
      case UserActionMenuItem.blockUser:
        // Block the target user
        userInteractionCubit.blockUser(targetUserAnonymousId);
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Blocking $targetUsername...')),
        );
        break;
      case UserActionMenuItem.reportUser:
        // Show the report dialog for the target user
        showDialog(
          context: context,
          builder: (dialogContext) => BlocProvider.value(
            value: reportCubit, // Pass the existing cubit instance
            child: ReportDialogWidget(
              itemType: ReportedItemType.user,
              itemAnonymousId: targetUserAnonymousId,
            ),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // The PopupMenuButton will be triggered by tapping the 'child' widget.
    // Wrap with BlocListener to handle navigation and feedback from ChatInitiationCubit.
    return BlocListener<ChatInitiationCubit, ChatInitiationState>(
      listener: (context, state) {
        // Only react if the state's targetUserAnonymousId matches this button's targetUserAnonymousId
        if (state is ChatInitiationSuccessRoom && state.targetUserAnonymousId == targetUserAnonymousId) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Hide "Starting chat..."
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Chat with $targetUsername started!')),
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatRoomPage(chatRoom: state.chatRoom),
            ),
          );
        } else if (state is ChatInitiationSuccessRequest && state.targetUserAnonymousId == targetUserAnonymousId) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Chat request sent to $targetUsername.')),
          );
        } else if (state is ChatInitiationFailure && state.targetUserAnonymousId == targetUserAnonymousId) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to start chat with $targetUsername: ${state.message}')),
          );
        }
      },
      child: PopupMenuButton<UserActionMenuItem>(
        padding: EdgeInsets.zero, // Remove default padding around the child
        iconSize: 0, // Make the icon area zero so the child fills the space
        child: child, // The child property is used instead of icon
        offset: const Offset(0, 25), // Example: 25 pixels below the child
        onSelected: (UserActionMenuItem item) =>
            _handleMenuSelection(context, item),
        itemBuilder: (BuildContext context) =>
            <PopupMenuEntry<UserActionMenuItem>>[
          // Always show "View Profile"
          const PopupMenuItem<UserActionMenuItem>(
            value: UserActionMenuItem.viewProfile,
            child: ListTile(leading: Icon(Icons.person_outline), title: Text('View Profile')),
          ),
          // Show other actions only if it's not the current user's profile
          if (!isOwnProfile) ...[
            const PopupMenuDivider(), // Separator
            const PopupMenuItem<UserActionMenuItem>(
              value: UserActionMenuItem.startChat,
              child: ListTile(leading: Icon(Icons.chat_bubble_outline), title: Text('Start Chat')),
            ),
            const PopupMenuDivider(), // Separator
            const PopupMenuItem<UserActionMenuItem>(
              value: UserActionMenuItem.muteUser,
              child: ListTile(leading: Icon(Icons.volume_off_outlined), title: Text('Mute User')),
            ),
            const PopupMenuItem<UserActionMenuItem>(
              value: UserActionMenuItem.blockUser,
              child: ListTile(leading: Icon(Icons.block_outlined), title: Text('Block User')),
            ),
            const PopupMenuDivider(), // Separator
            const PopupMenuItem<UserActionMenuItem>(
              value: UserActionMenuItem.reportUser,
              child: ListTile(leading: Icon(Icons.report_problem_outlined, color: Colors.orangeAccent), title: Text('Report User')),
            ),
          ]
        ],
      ),
    );
  }
}