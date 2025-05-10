import 'package:flutter/material.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _postTextController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  static const int _minPostLength = 20;

  @override
  void dispose() {
    _postTextController.dispose();
    super.dispose();
  }

  void _submitPost() {
    if (_formKey.currentState!.validate()) {
      final postContent = _postTextController.text;
      // TODO: Implement actual post submission logic (e.g., call a Cubit/Bloc method)
      print('Post submitted: $postContent');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Post created: "$postContent" (not yet saved)')),
      );
      Navigator.of(context).pop(); // Go back to the previous screen (HomePage)
    }
  }

  @override
  Widget build(BuildContext context) {
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
                controller: _postTextController,
                decoration: const InputDecoration(labelText: 'What\'s on your mind?'),
                maxLines: 5,
                autofocus: true, // So the keyboard appears immediately
                onChanged: (text) {
                  // We need to call setState to rebuild the counter if we're not using buildCounter
                  // However, buildCounter is more efficient as it's part of TextFormField's build.
                  // For this example, let's ensure the form updates if validation state might change.
                  // A simple setState here would work for a custom counter outside TextFormField.
                  // Since we'll use buildCounter, this onChanged is mostly for other potential side effects.
                  setState(() {}); // To update the character counter if not using buildCounter
                },
                buildCounter: _buildCharacterCounter,
                validator: _validatePost,
              ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _submitPost, child: const Text('Post')),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _buildCharacterCounter(
    BuildContext context, {
    required int currentLength,
    required bool isFocused,
    required int? maxLength, // We are not using maxLength for a hard limit
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(
        '$currentLength characters',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }

  String? _validatePost(String? value) {
    final trimmedValue = value?.trim() ?? '';
    if (trimmedValue.isEmpty) return 'Post cannot be empty';
    if (trimmedValue.length < _minPostLength) return 'Please write at least $_minPostLength characters.';
    return null;
  }
}