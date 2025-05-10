import 'package:empathy_hub_app/features/auth/presentation/auth_cubit.dart';
import 'package:empathy_hub_app/features/auth/presentation/models/user_model.dart';
import 'package:empathy_hub_app/features/settings/presentation/pages/settings_page.dart';
import 'package:empathy_hub_app/features/user_profile/presentation/pages/user_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    // It's good practice to get the user details from AuthState
    // to display in the drawer header if needed.
    final authState = context.watch<AuthCubit>().state;
    User? currentUser;
    if (authState is AuthSuccess) {
      currentUser = authState.user;
    }

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          UserAccountsDrawerHeader(
            accountName: Text(
              currentUser?.username ?? 'Anonymous User',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(currentUser != null ? 'Tap to view profile' : 'Not signed in'),
            currentAccountPicture: CircleAvatar(
              backgroundImage: currentUser?.avatarUrl != null
                  ? NetworkImage(currentUser!.avatarUrl!)
                  : null,
              child: currentUser?.avatarUrl == null
                  ? Text(
                      currentUser?.username.isNotEmpty == true
                          ? currentUser!.username[0].toUpperCase()
                          : 'A',
                      style: const TextStyle(fontSize: 40.0),
                    )
                  : null,
            ),
            onDetailsPressed: currentUser != null ? () {
              Navigator.pop(context); // Close the drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UserProfilePage(user: currentUser!)),
              );
            } : null,
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('My Profile'),
            onTap: currentUser != null ? () {
              Navigator.pop(context); // Close the drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UserProfilePage(user: currentUser!)),
              );
            } : null, // Disable if no user
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.shield_outlined),
            title: const Text('Community Guidelines'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              // TODO: Navigate to Community Guidelines Page
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Community Guidelines (Not implemented yet)')),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About Empathy Hub'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              // TODO: Navigate to About Page
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('About Empathy Hub (Not implemented yet)')),
              );
            },
          ),
          // Sign Out is usually in SettingsPage, but can be duplicated here if desired.
          // For now, we'll keep it primarily in SettingsPage to avoid redundancy.
        ],
      ),
    );
  }
}