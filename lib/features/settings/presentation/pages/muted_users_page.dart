import 'package:empathy_hub_app/features/user/data/models/user_models.dart';
import 'package:empathy_hub_app/features/user_profile/presentation/cubit/user_interaction_lists_cubit.dart';
import 'package:empathy_hub_app/features/user_profile/presentation/pages/user_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MutedUsersPage extends StatefulWidget {
  const MutedUsersPage({super.key});

  @override
  State<MutedUsersPage> createState() => _MutedUsersPageState();
}

class _MutedUsersPageState extends State<MutedUsersPage> {
  @override
  void initState() {
    super.initState();
    // Fetch muted users when the page is initialized
    // Ensure UserInteractionListsCubit is provided globally or above this page.
    context.read<UserInteractionListsCubit>().fetchMutedUsers();
  }

  void _showUnmuteConfirmationDialog(BuildContext context, UserSimple user) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Unmute ${user.username}?'),
          content: Text('Are you sure you want to unmute ${user.username}? They will be able to interact with you again.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: Text('Unmute', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.read<UserInteractionListsCubit>().unmuteUser(user.anonymousId, user.username);
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
        title: const Text('Muted Users'),
      ),
      body: BlocConsumer<UserInteractionListsCubit, UserInteractionListsState>(
        listener: (context, state) {
          if (state is UserUnmuteSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${state.username} has been unmuted.'), backgroundColor: Colors.green),
            );
            // Refresh the list after unmuting
            context.read<UserInteractionListsCubit>().fetchMutedUsers();
          } else if (state is UserUnmuteFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to unmute ${state.username}: ${state.message}'), backgroundColor: Colors.redAccent),
            );
          }
        },
        builder: (context, state) {
          if (state is MutedUsersLoading && !(state is MutedUsersLoaded)) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is MutedUsersError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error: ${state.message}', textAlign: TextAlign.center),
              ),
            );
          }

          if (state is MutedUsersLoaded) {
            if (state.users.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text("You haven't muted anyone yet.", style: TextStyle(fontSize: 16)),
                ),
              );
            }
            return ListView.separated(
              itemCount: state.users.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final user = state.users[index];
                // Watch the cubit's state specifically for unmuting status
                final interactionState = context.watch<UserInteractionListsCubit>().state;
                bool isUnmutingThisUser = false;
                if (interactionState is UserUnmuting && interactionState.targetUserId == user.anonymousId) {
                  isUnmutingThisUser = true;
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
                    child: Text(user.username, style: const TextStyle(fontWeight: FontWeight.w500))
                  ),
                  trailing: isUnmutingThisUser
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                      : TextButton(
                          onPressed: () => _showUnmuteConfirmationDialog(context, user),
                          child: const Text('Unmute'),
                        ),
                );
              },
            );
          }

          // Fallback for other states or if UserInteractionListsInitial is the current state
          // after an action that doesn't directly lead to MutedUsersLoaded (e.g. unblock success from another page)
          // It's good practice to trigger fetchMutedUsers again if needed.
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("Loading muted users..."),
            ),
          );
        },
      ),
    );
  }
}