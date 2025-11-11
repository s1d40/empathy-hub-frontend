import 'package:empathy_hub_app/features/auth/presentation/auth_cubit.dart';
import 'package:empathy_hub_app/features/chat/data/models/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart'; // For date formatting

class ChatListItemWidget extends StatelessWidget {
  final ChatRoom chatRoom;
  final VoidCallback onTap;

  const ChatListItemWidget({
    super.key,
    required this.chatRoom,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Determine the other participant for 1-on-1 chats
    UserSimple? otherParticipant;
    final currentUserState = context.read<AuthCubit>().state;
    String currentUserId = '';

    if (currentUserState is Authenticated) {
      currentUserId = currentUserState.user.anonymousId;
    }

    if (!chatRoom.isGroup && chatRoom.participants.isNotEmpty) {
      otherParticipant = chatRoom.participants.firstWhere(
        (p) => p.anonymousId != currentUserId,
        orElse: () => chatRoom.participants.first, // Fallback, though should find other
      );
    }

    final String displayName = chatRoom.isGroup
        ? chatRoom.name ?? 'Group Chat'
        : otherParticipant?.username ?? 'Unknown User';

    final String? avatarUrl = chatRoom.isGroup
        ? null // Placeholder for group avatar
        : otherParticipant?.avatarUrl;

    String lastMessagePreview = chatRoom.lastMessage?.content ?? 'No messages yet';
    if (lastMessagePreview.length > 35) {
      lastMessagePreview = '${lastMessagePreview.substring(0, 32)}...';
    }

    String lastMessageTime = '';
    if (chatRoom.lastMessage != null) {
      final messageTime = chatRoom.lastMessage!.timestamp.toLocal();
      final now = DateTime.now();
      if (now.difference(messageTime).inDays == 0) {
        lastMessageTime = DateFormat.jm().format(messageTime); // e.g., 5:08 PM
      } else if (now.difference(messageTime).inDays == 1) {
        lastMessageTime = 'Yesterday';
      } else {
        lastMessageTime = DateFormat.MMMd().format(messageTime); // e.g., Sep 10
      }
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
        child: avatarUrl == null
            ? Text(displayName.isNotEmpty ? displayName[0].toUpperCase() : '?')
            : null,
      ),
      title: Text(
        displayName,
        style: const TextStyle(fontWeight: FontWeight.bold),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        lastMessagePreview,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (lastMessageTime.isNotEmpty)
            Text(lastMessageTime, style: Theme.of(context).textTheme.bodySmall),
          // TODO: Add unread message indicator here
        ],
      ),
      onTap: onTap,
    );
  }
}