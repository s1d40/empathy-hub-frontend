import 'package:empathy_hub_app/features/auth/presentation/auth_cubit.dart';
import 'package:empathy_hub_app/features/feed/presentation/widgets/feed_widget.dart'; // Import the FeedWidget
import 'package:empathy_hub_app/features/feed/presentation/pages/create_post_page.dart'; // Import the CreatePostPage
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    String currentUsername = "User"; // Default display name

    if (authState is AuthSuccess) {
      currentUsername = authState.user.username; // Use the User object
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Empathy Hub Feed - $currentUsername'),
        // You could add actions like a post button here later
      ),
      body: const FeedWidget(), // Display the FeedWidget here
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const CreatePostPage()),
        ), // Using 'edit' (pencil) as discussed
        tooltip: 'Create Post',
        child: const Icon(Icons.edit),
      ),
    );
  }
}