import 'package:anonymous_hubs/features/auth/presentation/widgets/auth_gate.dart';
import 'package:flutter/material.dart';

class AnonymousHubsApp extends StatelessWidget {
  const AnonymousHubsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Anonymous Hubs',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const AuthGate(),
    );
  }
}
