import 'package:anonymous_hubs/features/auth/presentation/auth_cubit.dart';
import 'package:anonymous_hubs/features/auth/presentation/pages/username_selection_page.dart';
import 'package:anonymous_hubs/features/navigation/presentation/pages/main_navigation_page.dart'; // Corrected: Navigate to MainNavigationPage
import 'package:flutter/material.dart'; // Added Material Design import
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // BlocBuilder listens to AuthState changes and rebuilds the UI accordingly.
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is Authenticated) {
          // If authentication is successful (token and user details are available)
          return const MainNavigationPage(); // Navigate to MainNavigationPage
        } else if (state is Unauthenticated) {
          // If the user is not authenticated, show the username selection/sign-in page
          return const UsernameSelectionPage();
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