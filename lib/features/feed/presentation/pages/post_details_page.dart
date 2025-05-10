import 'package:empathy_hub_app/features/feed/presentation/models/post_model.dart';
import 'package:flutter/material.dart';

class PostDetailsPage extends StatelessWidget {
  final Post post;

  const PostDetailsPage({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(post.username), // Or "Post Details"
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Author Info
            Row(
              children: <Widget>[
                CircleAvatar(
                  backgroundImage: post.avatarUrl != null
                      ? NetworkImage(post.avatarUrl!)
                      : null,
                  radius: 22,
                  child: post.avatarUrl == null
                      ? Text(post.username.isNotEmpty ? post.username[0].toUpperCase() : '?')
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        post.username,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      Text(
                        "${post.timestamp.toLocal().year}-${post.timestamp.toLocal().month.toString().padLeft(2, '0')}-${post.timestamp.toLocal().day.toString().padLeft(2, '0')} ${post.timestamp.toLocal().hour.toString().padLeft(2, '0')}:${post.timestamp.toLocal().minute.toString().padLeft(2, '0')}",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Post Content
            Text(
              post.content,
              style: const TextStyle(fontSize: 16, height: 1.4),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Placeholder for Comments Section
            Text('Comments (${post.comments.length})', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            const Text('Comments will be shown here... (Not implemented yet)'),
            const SizedBox(height: 20),
            // Placeholder for Add Comment
            const TextField(
              decoration: InputDecoration(
                hintText: 'Add a comment...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: () {}, child: const Text('Submit Comment')),
          ],
        ),
      ),
    );
  }
}