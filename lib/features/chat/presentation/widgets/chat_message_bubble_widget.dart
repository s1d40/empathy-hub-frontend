import 'package:empathy_hub_app/features/chat/data/models/models.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting

class ChatMessageBubbleWidget extends StatelessWidget {
  final ChatMessage message;
  final bool isCurrentUser;
  // final bool showSenderName; // Useful for group chats or if always showing sender

  const ChatMessageBubbleWidget({
    super.key,
    required this.message,
    required this.isCurrentUser,
    // this.showSenderName = false, // Default to false for 1-on-1, true for group
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alignment = isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor = isCurrentUser ? theme.colorScheme.primaryContainer : theme.colorScheme.secondaryContainer;
    final textColor = isCurrentUser ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSecondaryContainer;

    // Simple time formatting
    final String messageTime = DateFormat.jm().format(message.timestamp.toLocal()); // e.g., 5:08 PM

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Column(
        crossAxisAlignment: alignment,
        children: <Widget>[
          // Optionally display sender's name above the bubble
          // if (!isCurrentUser && showSenderName) // Or just !isCurrentUser for 1-on-1
          if (!isCurrentUser) // Show sender name for received messages
            Padding(
              padding: const EdgeInsets.only(bottom: 2.0, left: 8.0, right: 8.0),
              child: Text(
                message.sender.username,
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
            ),
          Row(
            mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: <Widget>[
              Flexible( // Ensures the bubble doesn't overflow
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(12.0),
                      topRight: const Radius.circular(12.0),
                      bottomLeft: isCurrentUser ? const Radius.circular(12.0) : const Radius.circular(0),
                      bottomRight: isCurrentUser ? const Radius.circular(0) : const Radius.circular(12.0),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, // Text within bubble aligns left
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message.content,
                        style: TextStyle(color: textColor),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2.0, left: 8.0, right: 8.0),
            child: Text(
              messageTime,
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600], fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}