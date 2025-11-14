import 'package:anonymous_hubs/features/auth/presentation/auth_cubit.dart';
import 'package:anonymous_hubs/features/auth/presentation/models/user_model.dart';
import 'package:anonymous_hubs/core/services/chat_api_service.dart';
import 'package:anonymous_hubs/features/chat/data/models/models.dart' as chat_models;
import 'package:anonymous_hubs/features/chat/presentation/cubit/chat_initiation_cubit/chat_initiation_cubit.dart';
import 'package:anonymous_hubs/features/chat/presentation/widgets/chat_request_message_dialog_widget.dart'; // Import the new dialog
import 'package:anonymous_hubs/features/chat/presentation/pages/chat_room_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserProfileChatButtonWidget extends StatelessWidget {
  final User profileUser;

  const UserProfileChatButtonWidget({
    super.key,
    required this.profileUser,
  });

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    if (authState is Authenticated) {
      if (authState.user.anonymousId == profileUser.anonymousId) {
        return const SizedBox.shrink();
      }

      if (profileUser.chatAvailability.toLowerCase() == 'do_not_disturb') {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            '${profileUser.username ?? 'This user'} is not accepting messages at this time.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
          ),
        );
      }

      return BlocConsumer<ChatInitiationCubit, ChatInitiationState>(
        listener: (context, state) {
          if (state is ChatInitiationSuccessRoom) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chat opened!'), backgroundColor: Colors.green,));
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ChatRoomPage(chatRoom: state.chatRoom),
            ));
          } else if (state is ChatInitiationSuccessRequest) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            if (state.isExistingRequest) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chat request already sent!'), backgroundColor: Colors.blue,));
            } else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chat request sent!'), backgroundColor: Colors.blue,));
              // The ChatRequestMessageDialogWidget is now shown proactively,
              // so we don't need to show it again here.
            }
          } else if (state is ChatInitiationFailure) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${state.message}'), backgroundColor: Colors.redAccent,));
          }
        },
        builder: (context, state) {
          if (state is ChatInitiationInProgress) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2.0));
          }
          return ElevatedButton.icon(
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('Start Chat'),
            onPressed: () {
              // Show the chat request message dialog first
              showDialog(
                context: context,
                builder: (dialogContext) => BlocProvider.value(
                  value: context.read<ChatInitiationCubit>(), // Pass the existing cubit instance
                  child: ChatRequestMessageDialogWidget(
                    targetUserAnonymousId: profileUser.anonymousId,
                    targetUsername: profileUser.username ?? 'User',
                  ),
                ),
              );
            },
          );
        },
      );
    }
    return const SizedBox.shrink();
  }
}