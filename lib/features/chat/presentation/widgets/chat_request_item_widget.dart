import 'package:empathy_hub_app/features/chat/data/models/models.dart';
import 'package:flutter/material.dart';

class ChatRequestItemWidget extends StatelessWidget {
  final ChatRequest request;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const ChatRequestItemWidget({
    super.key,
    required this.request,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final requester = request.requester;
    final avatarUrl = 'https://i.pravatar.cc/150?u=${requester.anonymousId}'; // Use requester's ID
    final initialMessage = request.initialMessage;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: <Widget>[
            CircleAvatar(
              backgroundImage: NetworkImage(avatarUrl),
              // Or placeholder if no avatar
              // backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
              // child: avatarUrl == null ? const Icon(Icons.person) : null,
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    requester.username,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  if (initialMessage != null && initialMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        initialMessage,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12.0),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ElevatedButton(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    minimumSize: const Size(0, 36), // Minimum height
                  ),
                  child: const Text('Accept'),
                ),
                const SizedBox(height: 8.0),
                OutlinedButton(
                  onPressed: onDecline,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    minimumSize: const Size(0, 36), // Minimum height
                  ),
                  child: const Text('Decline'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}