import 'package:empathy_hub_app/features/feed/presentation/models/post_model.dart'; // Changed import
import 'package:empathy_hub_app/features/feed/presentation/pages/post_details_page.dart'; // Import the PostDetailsPage
import 'package:empathy_hub_app/features/user_profile/presentation/pages/user_profile_page.dart'; // Import UserProfilePage
import 'package:empathy_hub_app/features/auth/presentation/models/user_model.dart'; // Import User model for creating a User object
import 'package:flutter/material.dart';

//Widget to displaty a single feed item

class FeedItemWidget extends StatelessWidget {
  final Post item; // Changed type to Post

  const FeedItemWidget({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    // Wrap the Card with GestureDetector to make the whole item tappable
    return GestureDetector(
      onTap: () { 
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostDetailsPage(post: item),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
        elevation: 2.0,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              GestureDetector(
                onTap: () { 
                  // Create a User object from the post's author details
                  final postAuthor = User(id: item.userId, username: item.username, avatarUrl: item.avatarUrl);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserProfilePage(user: postAuthor),
                    ),
                  );
                },
                child: Row(
                  children: <Widget>[
                    CircleAvatar(
                      backgroundImage: item.avatarUrl != null
                          ? NetworkImage(item.avatarUrl!)
                          : null,
                      radius: 20, //Handle null avatar
                      child: item.avatarUrl == null
                          ? Text(item.username.isNotEmpty ? item.username[0].toUpperCase() : '?')
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            item.username,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            // Basic date formatting, consider using 'intl' package for better formatting
                            "${item.timestamp.toLocal().year}-${item.timestamp.toLocal().month.toString().padLeft(2, '0')}-${item.timestamp.toLocal().day.toString().padLeft(2, '0')} ${item.timestamp.toLocal().hour.toString().padLeft(2, '0')}:${item.timestamp.toLocal().minute.toString().padLeft(2, '0')}",
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                item.content,
                style: const TextStyle(fontSize: 15, height: 1.3),
                maxLines: 5, // Limit lines in feed view
                overflow: TextOverflow.ellipsis, // Show ellipsis if content is too long
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      IconButton(
                        icon: const Icon(Icons.thumb_up_outlined),
                        iconSize: 20.0,
                        color: Colors.green,
                        onPressed: () {
                          // TODO: Implement upvote logic
                          print('Upvoted post: ${item.id}');
                           ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Upvoted post: ${item.id} (Not implemented yet)')),
                          );
                        },
                      ),
                      Text('${item.upvotes}'), // Display upvote count
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.thumb_down_outlined),
                        iconSize: 20.0,
                        color: Colors.red,
                        onPressed: () {
                          // TODO: Implement downvote logic
                          print('Downvoted post: ${item.id}');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Downvoted post: ${item.id} (Not implemented yet)')),
                          );
                        },
                      ),
                      Text('${item.downvotes}'), // Display downvote count
                    ],
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.comment_outlined, size: 20.0),
                    label: Text('${item.comments.length}'), // Display comment count
                    onPressed: () {
                      // This will also trigger the Card's onTap due to gesture bubbling,
                      // which is fine as it should navigate to post details.
                      print('Comment button tapped for post: ${item.id}');
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}