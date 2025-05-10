import 'package:empathy_hub_app/features/auth/presentation/models/user_model.dart';
import 'package:flutter/material.dart';

class UserProfilePage extends StatelessWidget {
  final User user;

  const UserProfilePage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(user.username),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // User Header
            Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 40,
                  backgroundImage: user.avatarUrl != null
                      ? NetworkImage(user.avatarUrl!)
                      : null,
                  child: user.avatarUrl == null
                      ? Text(
                          user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                          style: const TextStyle(fontSize: 30),
                        )
                      : null,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.username,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      // Placeholder for reputation or other info
                      Text(
                        'Reputation: Coming soon', // Placeholder
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Text('User\'s Posts', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('List of user\'s posts will appear here... (Not implemented yet)'),
            const SizedBox(height: 24),
            Text('User\'s Comments', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('List of user\'s comments will appear here... (Not implemented yet)'),
          ],
        ),
      ),
    );
  }
}