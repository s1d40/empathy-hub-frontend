import 'package:anonymous_hubs/features/auth/presentation/auth_cubit.dart';
import 'package:anonymous_hubs/features/auth/presentation/models/user_model.dart';
import 'package:anonymous_hubs/features/settings/presentation/pages/settings_page.dart';
import 'package:anonymous_hubs/features/user_profile/presentation/pages/user_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:anonymous_hubs/core/config/api_config.dart'; // For ApiConfig.baseUrl
import 'avatar_strip_selector.dart'; // Import the new widget

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String? _selectedDialogAvatarUrl;
  final _usernameEditController = TextEditingController();
  // PageController and related logic moved to AvatarStripSelector

  @override
  void initState() {
    super.initState();
    // Fetch default avatars if not already available or if an update is desired
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) { // Ensure widget is still mounted
        context.read<AuthCubit>().fetchDefaultAvatars(); // Default forceRefresh is false
      }
    });
  }

  @override
  void dispose() {
    _usernameEditController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    User? currentUser;
    if (authState is Authenticated) {
      currentUser = authState.user;
    }

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          _buildCustomDrawerHeader(context, authState, currentUser),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('My Profile'),
            onTap: currentUser != null ? () {
              // Since currentUser is checked for null, we can safely access its properties.
              Navigator.pop(context); // Close the drawer
              _navigateToUserProfile(context, currentUser!);
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

  void _navigateToUserProfile(BuildContext context, User user) {
     Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => createUserProfilePageWithCubit(user.anonymousId)),
    );
  }

  Widget _buildCustomDrawerHeader(BuildContext context, AuthState authState, User? currentUser) {
    final theme = Theme.of(context);
    final topPadding = MediaQuery.of(context).padding.top;

    // Define radii and spacing
    const double largeStaticAvatarRadius = 70.0; // Radius for the main, large, static avatar
    const double largeStaticAvatarBorderSize = 2.5;
    const double stripAvatarRadius = 22.0;      // Radius for avatars in the strip
    const double stripAvatarSpacing = 1.0;       // Spacing for avatars in the strip
    // Height for the AvatarStripSelector widget itself
    const double stripLayoutHeight = (stripAvatarRadius * 2) + 8.0; // e.g., 22*2 + 8 = 52
    const double stackHeight = largeStaticAvatarRadius * 2 + stripLayoutHeight * 0.5; // Approximate height for the Stack

    return Container(
      padding: EdgeInsets.fromLTRB(16.0, topPadding + 16.0, 16.0, 16.0),
      decoration: BoxDecoration(
        color: theme.primaryColor, // Or theme.colorScheme.primary
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (currentUser != null)
            SizedBox(
              height: stackHeight, // Give the Stack a defined height
              child: Stack(
                alignment: Alignment.bottomCenter, // Align strip to bottom, large avatar can be aligned separately
                children: <Widget>[
                  // Avatar Strip Selector (Bottom layer)
                  if (authState.defaultAvatarUrls.isNotEmpty)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: AvatarStripSelector(
                        allAvatarUrls: authState.defaultAvatarUrls,
                        currentSelectedAvatarUrl: currentUser.avatarUrl,
                        onAvatarSelectedBySwipe: (newAvatarUrl) {
                          context.read<AuthCubit>().updateUserProfile(avatarUrl: newAvatarUrl);
                        },
                        avatarRadius: stripAvatarRadius,
                        viewportFraction: 0.25, // Show more small items
                        stripLayoutHeight: stripLayoutHeight,
                        avatarHorizontalSpacing: stripAvatarSpacing,
                      ),
                    ),
                  
                  // Large Static Avatar (Top layer)
                  Align(
                    alignment: Alignment.topCenter, // Position large avatar at the top of the Stack
                    child: GestureDetector(
                      onTap: () {
                        _showAvatarSelectionDialog(context, authState.defaultAvatarUrls, currentUser);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.onPrimary.withOpacity(0.5),
                            width: largeStaticAvatarBorderSize,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: largeStaticAvatarRadius,
                          backgroundImage: currentUser.avatarUrl != null ? NetworkImage(currentUser.avatarUrl!) : null,
                          child: currentUser.avatarUrl == null ? Text(currentUser.username?[0].toUpperCase() ?? 'A', style: TextStyle(fontSize: largeStaticAvatarRadius * 0.8, color: Colors.white)) : null,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else // Fallback if currentUser is null (e.g., during sign out transition)
            const SizedBox(height: stackHeight), // Placeholder to maintain layout
          
          const SizedBox(height: 12), // Spacing between avatar area and username
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: currentUser != null ? () => _navigateToUserProfile(context, currentUser) : null,
                  child: Text(
                    currentUser?.username ?? 'Anonymous User',
                    style: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis, // Handle long usernames
                  ),
                ),
              ),
              if (currentUser != null)
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Color.fromARGB(179, 244, 237, 103), size: 20),
                  tooltip: 'Edit Username',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(), // Make it compact
                  onPressed: () => _showUsernameEditDialog(context, currentUser),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            currentUser != null ? 'Tap name to view profile' : 'Not signed in',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  void _showAvatarSelectionDialog(BuildContext context, List<String> allAvatarUrls, User currentUser) {
    _selectedDialogAvatarUrl = currentUser.avatarUrl; // Pre-select current avatar

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder( // Use StatefulBuilder for local state management in the dialog
          builder: (stfContext, stfSetState) {
            return AlertDialog(
              title: const Text('Select Avatar'),
              contentPadding: const EdgeInsets.all(8), // Reduce padding for GridView
              content: SizedBox(
                width: double.maxFinite,
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4, // Adjust number of avatars per row
                    crossAxisSpacing: 8.0,
                    mainAxisSpacing: 8.0,
                  ),
                  itemCount: allAvatarUrls.length,
                  itemBuilder: (gridContext, index) {
                    final avatarUrl = allAvatarUrls[index]; // Full URL
                    final isSelected = _selectedDialogAvatarUrl == avatarUrl;

                    return GestureDetector(
                      onTap: () {
                        stfSetState(() {
                          _selectedDialogAvatarUrl = avatarUrl;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Theme.of(stfContext).primaryColor, width: 3.0)
                              : null,
                        ),
                        child: CircleAvatar(
                          backgroundImage: NetworkImage(avatarUrl),
                          radius: 25, // Adjust size
                        ),
                      ),
                    );
                  },
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
                ElevatedButton(
                  child: const Text('Select'),
                  onPressed: _selectedDialogAvatarUrl != null ? () {
                    context.read<AuthCubit>().updateUserProfile(avatarUrl: _selectedDialogAvatarUrl);
                    Navigator.of(dialogContext).pop();
                  } : null, // Disable if no avatar is selected (though one is pre-selected)
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showUsernameEditDialog(BuildContext context, User currentUser) {
    _usernameEditController.text = currentUser.username ?? '';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Edit Username'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: _usernameEditController,
              autofocus: true,
              decoration: const InputDecoration(hintText: "Enter new username"),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Username cannot be empty';
                }
                if (value.trim().length < 3) {
                  return 'Username must be at least 3 characters';
                }
                return null;
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              child: const Text('Save'),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final newUsername = _usernameEditController.text.trim();
                  // Only update if the username has actually changed
                  if (newUsername != (currentUser.username ?? '')) {
                    context.read<AuthCubit>().updateUserProfile(username: newUsername);
                  }
                  Navigator.of(dialogContext).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }
}