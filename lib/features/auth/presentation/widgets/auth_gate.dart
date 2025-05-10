import 'package:empathy_hub_app/features/auth/presentation/auth_cubit.dart';
import 'package:empathy_hub_app/features/auth/presentation/pages/username_selection_page.dart';
import 'package:empathy_hub_app/features/navigation/presentation/pages/main_navigation_page.dart'; // Corrected: Navigate to MainNavigationPage
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // BlocBuilder listens to AuthState changes and rebuilds the UI accordingly.
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is AuthSuccess) {
          // If authentication is successful (ID and username are set)
          return const MainNavigationPage(); // Navigate to MainNavigationPage
        } else if (state is AuthRequiresUsername) {
          // If an anonymous ID exists but a username is needed
          return UsernameSelectionPage(anonymousId: state.anonymousId);
        } else if (state is AuthLoading || state is AuthInitial) {
          // While checking auth status or in the initial state
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        } else if (state is AuthFailure) {
          // If an authentication error occurs
          return Scaffold(body: Center(child: Text('Error: ${state.message}')));
        }
        // Fallback for any unhandled state (should ideally not be reached)
        return const Scaffold(body: Center(child: Text('Unknown state')));
      },
    );
  }
}