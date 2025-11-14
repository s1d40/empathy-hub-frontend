import 'package:anonymous_hubs/features/auth/presentation/auth_cubit.dart';
import 'package:anonymous_hubs/features/chat/data/models/chat_enums.dart'; // For ChatAvailability enum and extension
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:anonymous_hubs/features/settings/presentation/cubit/data_erasure_cubit.dart'; // Import DataErasureCubit
import 'package:anonymous_hubs/features/settings/presentation/pages/muted_users_page.dart'; // Import MutedUsersPage
import 'package:anonymous_hubs/features/settings/presentation/pages/blocked_users_page.dart'; // Import BlockedUsersPage
import 'package:anonymous_hubs/features/settings/presentation/widgets/chat_availability_setting_widget.dart'; // Import the new widget
import 'package:anonymous_hubs/core/services/auth_api_service.dart'; // Import AuthApiService

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: true,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
        ),
        body: MultiBlocListener(
          listeners: [
            BlocListener<AuthCubit, AuthState>(
              listener: (context, state) {
                final bool isModalRouteActive = ModalRoute.of(context)?.isCurrent == false;
                if (state is AuthDeletionInProgress) {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext dialogContext) {
                      return const AlertDialog(
                        content: Row(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(width: 20),
                            Text("Deleting account..."),
                          ],
                        ),
                      );
                    },
                  );
                } else if (state is AuthDeletionFailure) {
                  if (isModalRouteActive) Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message), backgroundColor: Colors.redAccent),
                  );
                } else if (state is Unauthenticated) {
                  if (isModalRouteActive) Navigator.of(context).pop();
                  print("SettingsPage: User is Unauthenticated. AuthGate will navigate.");
                } else if (state is AuthFailure) {
                  if (isModalRouteActive) Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('An error occurred: ${state.message}'), backgroundColor: Colors.redAccent),
                  );
                }
              },
            ),
            BlocListener<DataErasureCubit, DataErasureState>(
              listener: (context, state) {
                final bool isModalRouteActive = ModalRoute.of(context)?.isCurrent == false;
                if (state is DataErasureInProgress) {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext dialogContext) {
                      return AlertDialog(
                        content: Row(
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(width: 20),
                            Text("Erasing ${state.actionType.replaceAll('_', ' ')}..."),
                          ],
                        ),
                      );
                    },
                  );
                } else if (state is DataErasureSuccess) {
                  if (isModalRouteActive) Navigator.of(context).pop(); // Dismiss progress dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message), backgroundColor: Colors.green),
                  );
                } else if (state is DataErasureFailure) {
                  if (isModalRouteActive) Navigator.of(context).pop(); // Dismiss progress dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message), backgroundColor: Colors.redAccent),
                  );
                }
              },
            ),
          ],
          child: BlocProvider<DataErasureCubit>(
            create: (context) => DataErasureCubit(
              authCubit: context.read<AuthCubit>(),
              authApiService: context.read<AuthApiService>(),
            ),
            child: _buildSettingsList(context),
          ),
        ),
      ),
    );
  }

  ListView _buildSettingsList(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        BlocBuilder<AuthCubit, AuthState>(
          builder: (context, authState) {
            if (authState is Authenticated) {
              final currentAvailabilityString = authState.user.chatAvailability;
              ChatAvailability currentAvailabilityEnum;
              try {
                currentAvailabilityEnum = ChatAvailabilityExtension.fromJson(currentAvailabilityString);
              } catch (e) {
                currentAvailabilityEnum = ChatAvailability.openToChat;
                print("Error parsing chat_availability '${currentAvailabilityString}': $e");
              }
              return ChatAvailabilitySettingWidget(
                currentAvailability: currentAvailabilityEnum,
                onAvailabilityChanged: (newAvailability) {
                  context.read<AuthCubit>().updateUserProfile(
                        chatAvailability: newAvailability.toJson(),
                      );
                },
              );
            }
            return const ListTile(
              leading: Icon(Icons.chat_bubble_outline),
              title: Text('Chat Availability'),
              subtitle: Text('Loading...'),
              enabled: false,
            );
          },
        ),
        const Divider(),
        _buildSectionHeader(context, "Content & Interaction Management"),
        ListTile(
          leading: const Icon(Icons.volume_off_outlined),
          title: const Text('Muted Users'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const MutedUsersPage()));
          },
        ),
        ListTile(
          leading: const Icon(Icons.block_outlined),
          title: const Text('Blocked Users'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const BlockedUsersPage()));
            // ScaffoldMessenger.of(context).showSnackBar(
            //   const SnackBar(content: Text('Blocked Users page (Not implemented yet)')),
            // );
          },
        ),
        ListTile(
          leading: const Icon(Icons.notifications_none),
          title: const Text('Notification Preferences'),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Notification settings (Not implemented yet)')),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.shield_outlined),
          title: const Text('Community Guidelines'),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Community Guidelines (Not implemented yet)')),
            );
          },
        ),
        const Divider(),
        _buildSectionHeader(context, "Data Management"),
        _buildErasureTile(
          context,
          title: 'Erase All My Posts',
          dialogTitle: 'Confirm Erase Posts',
          dialogContent: 'Are you sure you want to erase all your posts? This action is irreversible.',
          onConfirm: () => context.read<DataErasureCubit>().eraseMyPosts(),
        ),
        _buildErasureTile(
          context,
          title: 'Erase All My Comments',
          dialogTitle: 'Confirm Erase Comments',
          dialogContent: 'Are you sure you want to erase all your comments? This action is irreversible.',
          onConfirm: () => context.read<DataErasureCubit>().eraseMyComments(),
        ),
        _buildErasureTile(
          context,
          title: 'Erase All My Chats',
          dialogTitle: 'Confirm Erase Chats',
          dialogContent: 'Are you sure you want to erase all your chat messages? This action is irreversible.',
          onConfirm: () => context.read<DataErasureCubit>().eraseMyChats(),
        ),
        _buildErasureTile(
          context,
          title: 'Erase All Account Information',
          dialogTitle: 'Confirm Erase All Information',
          dialogContent: 'This will erase all your posts, comments, and chat messages. This action is irreversible. Type "ERASE" below to confirm.',
          onConfirm: () => context.read<DataErasureCubit>().eraseMyAccountInfo(),
          requireConfirmationText: "ERASE",
        ),
        const Divider(),
        _buildSectionHeader(context, "Account Actions"),
        ListTile(
          leading: Icon(Icons.bug_report, color: Theme.of(context).colorScheme.secondary),
          title: Text(
            'Clear Auth Data (Debug)',
            style: TextStyle(color: Theme.of(context).colorScheme.secondary),
          ),
          onTap: () {
            context.read<AuthCubit>().clearAllAuthDataForDebug();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Authentication data cleared.')),
            );
          },
        ),
        ListTile(
          leading: Icon(Icons.delete_forever, color: Theme.of(context).colorScheme.error),
          title: Text(
            'Delete Account',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          onTap: () => _showDeleteAccountConfirmationDialog(context),
        ),
      ],
    );
  }

  Padding _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.primary)),
    );
  }

  ListTile _buildErasureTile(
    BuildContext context, {
    required String title,
    required String dialogTitle,
    required String dialogContent,
    required VoidCallback onConfirm,
    String? requireConfirmationText,
  }) {
    return ListTile(
      leading: Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
      title: Text(title, style: TextStyle(color: Colors.orange.shade900)),
      onTap: () => _showErasureConfirmationDialog(
        context,
        dialogTitle: dialogTitle,
        dialogContent: dialogContent,
        onConfirm: onConfirm,
        requireConfirmationText: requireConfirmationText,
      ),
    );
  }

  void _showErasureConfirmationDialog(
    BuildContext context, {
    required String dialogTitle,
    required String dialogContent,
    required VoidCallback onConfirm,
    String? requireConfirmationText,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return _ErasureConfirmationDialogContent(
          dialogTitle: dialogTitle,
          dialogContent: dialogContent,
          onConfirm: onConfirm,
          requireConfirmationText: requireConfirmationText,
        );
      },
    );
  }

  void _showDeleteAccountConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Account Deletion'),
          content: const Text('Are you sure you want to delete your account? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.read<AuthCubit>().deleteAccount();
              },
              child: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          ],
        );
      },
    );
  }
}

class _ErasureConfirmationDialogContent extends StatefulWidget {
  final String dialogTitle;
  final String dialogContent;
  final VoidCallback onConfirm;
  final String? requireConfirmationText;

  const _ErasureConfirmationDialogContent({
    required this.dialogTitle,
    required this.dialogContent,
    required this.onConfirm,
    this.requireConfirmationText,
  });

  @override
  State<_ErasureConfirmationDialogContent> createState() => _ErasureConfirmationDialogContentState();
}

class _ErasureConfirmationDialogContentState extends State<_ErasureConfirmationDialogContent> {
  late final TextEditingController? _confirmationController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.requireConfirmationText != null) {
      _confirmationController = TextEditingController();
    } else {
      _confirmationController = null;
    }
  }

  @override
  void dispose() {
    _confirmationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.dialogTitle),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.dialogContent),
              if (widget.requireConfirmationText != null && _confirmationController != null) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmationController,
                  decoration: InputDecoration(labelText: 'Type "${widget.requireConfirmationText}" to confirm'),
                  validator: (value) {
                    if (value != widget.requireConfirmationText) {
                      return 'Confirmation text does not match.';
                    }
                    return null;
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (widget.requireConfirmationText != null) {
              if (_formKey.currentState!.validate()) {
                Navigator.of(context).pop();
                widget.onConfirm();
              }
            } else {
              Navigator.of(context).pop();
              widget.onConfirm();
            }
          },
          child: Text('Confirm', style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ),
      ],
    );
  }
}