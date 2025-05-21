import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:empathy_hub_app/features/feed/presentation/cubit/create_post_cubit/create_post_cubit.dart';
import 'package:empathy_hub_app/features/auth/presentation/auth_cubit.dart';
import 'package:empathy_hub_app/core/services/post_api_service.dart';
import 'package:empathy_hub_app/features/feed/presentation/cubit/feed_cubit.dart'; // To refresh feed
import 'dart:async'; // Import for Timer

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _postTextController = TextEditingController();
  final _titleTextController = TextEditingController(); // For the title
  final _formKey = GlobalKey<FormState>();
  static const int _minPostLength = 20;
  static const int _postCooldownDurationSeconds = 20;

  bool _isPostOnCooldown = false;
  int _cooldownSecondsRemaining = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _postTextController.dispose();
    _titleTextController.dispose();
    _cooldownTimer?.cancel(); // Cancel the timer if the widget is disposed
    super.dispose();
  }

  void _submitPost(BuildContext cubitContext) { // Accept BuildContext
    if (_formKey.currentState!.validate()) {
      final postContent = _postTextController.text;
      final postTitle = _titleTextController.text.isEmpty ? null : _titleTextController.text;
      
      // Use context.read to access the CreatePostCubit provided by the BlocProvider
      cubitContext.read<CreatePostCubit>().submitNewPost( // Use the passed context
            content: postContent,
            title: postTitle,
          );
    }
  }

  void _startPostCooldown() {
    setState(() {
      _isPostOnCooldown = true;
      _cooldownSecondsRemaining = _postCooldownDurationSeconds;
    });
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownSecondsRemaining > 0) {
        setState(() => _cooldownSecondsRemaining--);
      } else {
        setState(() => _isPostOnCooldown = false);
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Provide the CreatePostCubit to this page's widget tree
    return BlocProvider<CreatePostCubit>(
      create: (context) => CreatePostCubit(
        // Read dependencies from the context provided higher up (e.g., in main.dart)
        authCubit: context.read<AuthCubit>(),
        postApiService: context.read<PostApiService>(),
      ),
      // Use BlocConsumer to listen for state changes (for side effects)
      // and rebuild the UI (for showing loading/error states)
      child: BlocConsumer<CreatePostCubit, CreatePostState>(
        listener: (context, state) {
    print("CreatePostPage listener received state: $state"); // Add this line
          print("CreatePostPage listener received state: $state"); 
          if (state is CreatePostSuccess) {
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Post "${state.newPost.title ?? ''}" created successfully!')),
            );
            print("[CreatePostPage] CreatePostSuccess detected. Attempting to pop route."); // <<< ADD THIS
            // Add a small delay before refreshing the feed to allow backend processing
            Future.delayed(const Duration(seconds: 1), () {
              // Ensure FeedCubit is accessible in the context where CreatePostPage is used
              context.read<FeedCubit>().refreshPosts();
              print("[CreatePostPage] Feed refresh initiated after delay.");
            });
            // Navigate back to the previous screen (HomePage)
            _startPostCooldown(); // Start cooldown
            // Schedule the pop to occur after the current frame to avoid potential conflicts
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) { // Ensure the widget is still in the tree
                Navigator.of(context).pop();
              }
            });
          } else if (state is CreatePostFailure) {
            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${state.errorMessage}')),
            );
          }
        },
        builder: (context, state) {
          // Build the UI based on the current state
          return Scaffold(
            appBar: AppBar(
              title: const Text('Create New Post'),
            ),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: <Widget>[
                    TextFormField(
                      controller: _titleTextController,
                      decoration: const InputDecoration(
                        labelText: 'Title (Optional)',
                        hintText: 'Give your post a catchy title',
                      ),
                      maxLength: 100, // Optional: set a max length for title
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _postTextController,
                      decoration: const InputDecoration(
                        labelText: 'What\'s on your mind?',
                        hintText: 'Share your thoughts...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 7,
                      autofocus: true,
                      buildCounter: _buildCharacterCounter, // Use buildCounter for character count
                      validator: _validatePostContent, // Validator for content
                    ),
                    const SizedBox(height: 20),
                    // Show loading indicator while post is being created
                    if (state is CreatePostInProgress)
                      const CircularProgressIndicator(),
                    if (state is! CreatePostInProgress && _isPostOnCooldown)
                      ElevatedButton(
                        onPressed: null, // Disabled during cooldown
                        child: Text('Please wait ($_cooldownSecondsRemaining s)'),
                      ),
                    if (state is! CreatePostInProgress && !_isPostOnCooldown)
                      // Show the Post button
                      ElevatedButton(
                        onPressed: () => _submitPost(context), // Pass the builder's context
                        child: const Text('Post'),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Helper method to build the character counter for the content field
  Widget? _buildCharacterCounter(
      BuildContext context, {
      required int currentLength,
      required int? maxLength,
      required bool isFocused,
      }) {
    return Text(
      '$currentLength/${maxLength ?? '∞'}', // Display current length / max length
      semanticsLabel: '$currentLength characters',
    );
  }

  // Validator for the post content field
  String? _validatePostContent(String? value) {
    final trimmedValue = value?.trim() ?? '';
    if (trimmedValue.isEmpty) return 'Post cannot be empty';
    if (trimmedValue.length < _minPostLength) return 'Please write at least $_minPostLength characters.';
    return null;
  }
}