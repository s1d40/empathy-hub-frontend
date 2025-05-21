import 'package:empathy_hub_app/features/auth/presentation/auth_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:empathy_hub_app/core/config/api_config.dart'; // For ApiConfig.baseUrl

class UsernameSelectionPage extends StatefulWidget {
  // No longer needs anonymousId as it's handled by the backend now

  const UsernameSelectionPage({super.key});

  @override
  State<UsernameSelectionPage> createState() => _UsernameSelectionPageState();
}

class _UsernameSelectionPageState extends State<UsernameSelectionPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  String? _selectedAvatarUrl; // To store the selected avatar URL

  @override
  void initState() {
    super.initState();
    // Fetch default avatars when the page loads
    context.read<AuthCubit>().fetchDefaultAvatars();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }
  void _signIn() {
    final username = _usernameController.text.trim();
    // Validate only if a username is entered.
    // If empty, backend will generate one.
    if (username.isNotEmpty && !_formKey.currentState!.validate()) {
      return; // Don't proceed if validation fails for non-empty username
    }

    // _selectedAvatarUrl is already a full URL if selected.

    // Call signInAnonymously from AuthCubit.
    // If username is empty, pass null so backend generates one.
    // Otherwise, pass the preferred username.
    context.read<AuthCubit>().signInAnonymously(
      preferredUsername: username.isEmpty ? null : username,
      avatarUrl: _selectedAvatarUrl, // Pass the full avatar URL or null
    );
  }

  Widget _buildAvatarGrid(List<String> avatarUrls) {
    if (avatarUrls.isEmpty) {
      return const Text("No avatars available at the moment.", textAlign: TextAlign.center);
    }
    return GridView.builder(
      shrinkWrap: true, // Important to make GridView work inside SingleChildScrollView
      physics: const NeverScrollableScrollPhysics(), // Disable GridView's own scrolling
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5, // Adjust number of avatars per row
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
      ),
      itemCount: avatarUrls.length,
      itemBuilder: (context, index) {
        final avatarUrl = avatarUrls[index];
        // Assuming avatarUrls from state are already full URLs
        final isSelected = _selectedAvatarUrl == avatarUrl; 

        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedAvatarUrl = null; // Deselect if tapped again
              } else {
                // Store the full URL
                _selectedAvatarUrl = avatarUrl;
              }
            });
          },
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: Theme.of(context).primaryColor, width: 3.0)
                  : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 4,
                      )
                    ]
                  : [],
            ),
            child: CircleAvatar( // Use the full URL directly
              backgroundImage: NetworkImage(avatarUrl),
              radius: 30, // Adjust size as needed
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to Empathy Hub'),
        automaticallyImplyLeading: false, // No back button on this screen
      ),
      body: Center(
        child: SingleChildScrollView( // In case of small screens
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  'Welcome to Empathy Hub!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Choose a username and an avatar to get started. Or leave them blank for auto-generated defaults.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    hintText: 'Enter your desired username',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final trimmedValue = value?.trim() ?? '';
                    // Only validate length if the user actually typed something.
                    // Emptiness is handled by defaulting to an auto-generated name.
                    if (trimmedValue.isNotEmpty && trimmedValue.length < 3) {
                      return 'Username must be at least 3 characters long';
                    }
                    // Future: Add regex for allowed characters if needed
                    return null;
                  },
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _signIn(),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _signIn,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Continue Anonymously', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 20), // Spacing after button
                const Text(
                  'Pick an avatar:',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 30), // Spacing before avatar grid
                // Avatar Selection Section - Moved Here
                BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, state) {
                    if (state.isLoadingAvatars) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state.avatarFetchError != null) {
                      return Center(
                        child: Text(
                          'Error loading avatars: ${state.avatarFetchError}',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    if (state.defaultAvatarUrls.isNotEmpty) {
                      return _buildAvatarGrid(state.defaultAvatarUrls);
                    }
                    return const SizedBox.shrink(); 
                  },
                ),
                // BlocListener to show SnackBars for AuthFailure
                BlocListener<AuthCubit, AuthState>(
                  listener: (context, state) {
                    if (state is AuthFailure) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.message),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  },
                  // This child is necessary for BlocListener but doesn't render anything itself.
                  // If you had other widgets reacting to state changes, they'd go here or be separate BlocBuilders.
                  child: const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}