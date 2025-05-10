import 'package:empathy_hub_app/features/auth/presentation/auth_cubit.dart';
import 'package:empathy_hub_app/features/auth/presentation/widgets/auth_gate.dart'; // Import the separated AuthGate
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences

Future<void> main() async { // Make main async
  // Ensure Flutter bindings are initialized, especially if you do async work before runApp.
  WidgetsFlutterBinding.ensureInitialized();

  // --- DEVELOPMENT ONLY: Clear SharedPreferences on app start ---
  // TODO: Remove this or make it conditional for release builds!
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  print("DEV_MODE: SharedPreferences cleared for fresh start.");
  // --- END DEVELOPMENT ONLY ---

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthCubit()..checkAuthenticationStatus(),
      // The ..checkAuthenticationStatus() immediately calls the method
      // after the AuthCubit is created, initiating the auth flow.
      child: MaterialApp(
        title: 'Empathy Hub',
        theme: ThemeData(
          // Using a modern color scheme setup with Material 3
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        debugShowCheckedModeBanner: false, // Optional: to hide the debug banner
        home: const AuthGate(), // AuthGate will decide which page to show initially
      ),
    );
  }
}