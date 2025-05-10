import 'package:empathy_hub_app/features/auth/presentation/auth_cubit.dart';
import 'package:empathy_hub_app/features/auth/presentation/models/user_model.dart'; // Import the User model
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UsernameSelectionPage extends StatefulWidget {
  final String anonymousId; // Passed from AuthGate when AuthRequiresUsername state occurs

  const UsernameSelectionPage({super.key, required this.anonymousId});

  @override
  State<UsernameSelectionPage> createState() => _UsernameSelectionPageState();
}

class _UsernameSelectionPageState extends State<UsernameSelectionPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  void _submitCustomUsername() {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      // If the field is blank, use the auto-generated username
      _useDefaultUsername();
    } else {
      // If field is not blank, validate (e.g., for length) and submit
      if (_formKey.currentState!.validate()) {
        final user = User(
          id: widget.anonymousId, // Use anonymousId as the user's unique ID for now
          username: username,
        );
        context.read<AuthCubit>().completeUsernameSelection(user);
      }
    }
  }

  void _useDefaultUsername() {
    // Generate a default username, e.g., "Anonymous" + first 4 chars of anonymousId
    // Ensure anonymousId is long enough, though UUIDs typically are.
    final idSuffix = widget.anonymousId.length >= 4
        ? widget.anonymousId.substring(0, 4).toUpperCase() // Make it stand out a bit
        : widget.anonymousId.toUpperCase();
    final defaultUsername = 'Anonymous$idSuffix';
    final user = User(
      id: widget.anonymousId,
      username: defaultUsername,
    );
    context.read<AuthCubit>().completeUsernameSelection(user);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Username'),
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
                  'Please choose a username to continue, or leave it blank to use a default one.',
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
                  onFieldSubmitted: (_) => _submitCustomUsername(),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _submitCustomUsername,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Set Username and Continue', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 15),
                TextButton(
                  onPressed: _useDefaultUsername,
                  child: const Text('Or, use a default name (e.g., AnonymousABCD)'),
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