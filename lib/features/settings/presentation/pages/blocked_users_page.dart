import 'package:empathy_hub_app/features/user/data/models/user_models.dart';
import 'package:empathy_hub_app/features/user_profile/presentation/cubit/user_interaction_lists_cubit.dart';
import 'package:empathy_hub_app/features/user_profile/presentation/pages/user_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BlockedUsersPage extends StatefulWidget {
  const BlockedUsersPage({super.key});

  @override
  State<BlockedUsersPage> createState() => _BlockedUsersPageState();
}

class _BlockedUsersPageState extends State<BlockedUsersPage> {
  @override
  void initState() {
    super.initState();
    // Fetch blocked users when the page is initialized
    context.read<UserInteractionListsCubit>().fetchBlockedUsers();
  }

  void _showUnblockConfirmationDialog(BuildContext context, UserSimple user) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Unblock ${user.username}?'),
          content: Text('Are you sure you want to unblock ${user.username}? They will be able to see your content and interact with you again.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: Text('Unblock', style: TextStyle(color: Theme.of(context).colorScheme.error)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.read<UserInteractionListsCubit>().unblockUser(user.anonymousId, user.username);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blocked Users'),
      ),
      body: BlocConsumer<UserInteractionListsCubit, UserInteractionListsState>(
        listener: (context, state) {
          if (state is UserUnblockSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${state.username} has been unblocked.'), backgroundColor: Colors.green),
            );
            // Refresh the list after unblocking
            context.read<UserInteractionListsCubit>().fetchBlockedUsers();
          } else if (state is UserUnblockFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to unblock ${state.username}: ${state.message}'), backgroundColor: Colors.redAccent),
            );
          }
        },
        builder: (context, state) {
          if (state is BlockedUsersLoading && !(state is BlockedUsersLoaded)) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is BlockedUsersError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error: ${state.message}', textAlign: TextAlign.center),
              ),
            );
          }

          if (state is BlockedUsersLoaded) {
            if (state.users.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text("You haven't blocked anyone yet.", style: TextStyle(fontSize: 16)),
                ),
              );
            }
            return ListView.separated(
              itemCount: state.users.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final user = state.users[index];
                // Watch the cubit's state specifically for unblocking status
                final interactionState = context.watch<UserInteractionListsCubit>().state;
                bool isUnblockingThisUser = false;
                if (interactionState is UserUnblocking && interactionState.targetUserId == user.anonymousId) {
                  isUnblockingThisUser = true;
                }

                return ListTile(
                  leading: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => createUserProfilePageWithCubit(user.anonymousId)),
                      );
                    },
                    child: CircleAvatar(
                      backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                          ? NetworkImage(user.avatarUrl!)
                          : null,
                      child: (user.avatarUrl == null || user.avatarUrl!.isEmpty)
                          ? Text(user.username.isNotEmpty ? user.username[0].toUpperCase() : '?')
                          : null,
                    ), // Use user.username?.isNotEmpty and user.username![0]
                  ),
                  title: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => createUserProfilePageWithCubit(user.anonymousId)),
                      );
                    },
                    child: Text(user.username, style: const TextStyle(fontWeight: FontWeight.w500)),
                  ),
                  trailing: isUnblockingThisUser
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                      : TextButton(
                          style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                          onPressed: () => _showUnblockConfirmationDialog(context, user),
                          child: const Text('Unblock'),
                        ),
                );
              },
            );
          }

          // Fallback for other states
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("Loading blocked users..."),
            ),
          );
        },
      ),
    );
  }
}