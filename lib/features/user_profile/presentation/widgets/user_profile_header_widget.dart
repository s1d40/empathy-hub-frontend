import 'package:empathy_hub_app/features/auth/presentation/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class UserProfileHeaderWidget extends StatelessWidget {
  final User user;

  const UserProfileHeaderWidget({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0), // Keep padding from original SliverToBoxAdapter
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              CircleAvatar(
                radius: 40,
                backgroundImage:
                    user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                child: user.avatarUrl == null
                    ? Text(
                        user.username != null && user.username!.isNotEmpty ? user.username![0].toUpperCase() : '?',
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
                      user.username ?? 'Anonymous User',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}