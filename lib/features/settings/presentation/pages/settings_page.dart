import 'package:empathy_hub_app/features/auth/presentation/auth_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.chat_bubble_outline),
            title: const Text('Chat Availability'),
            subtitle: const Text('Manage who can chat with you'),
            onTap: () {
              // TODO: Navigate to Chat Availability Settings Page
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chat Availability settings (Not implemented yet)')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications_none),
            title: const Text('Notification Preferences'),
            onTap: () {
              // TODO: Navigate to Notification Settings Page
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notification settings (Not implemented yet)')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.shield_outlined),
            title: const Text('Community Guidelines'),
            onTap: () {
              // TODO: Navigate to Community Guidelines Page (static content)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Community Guidelines (Not implemented yet)')),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
            title: Text(
              'Sign Out',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () {
              // Perform sign out
              context.read<AuthCubit>().deleteAnonymousAccount();
              // AuthGate will handle navigation back to the auth flow
            },
          ),
        ],
      ),
    );
  }
}