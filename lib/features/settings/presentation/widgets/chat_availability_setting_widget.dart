import 'package:anonymous_hubs/features/chat/data/models/chat_enums.dart';
import 'package:flutter/material.dart';

class ChatAvailabilitySettingWidget extends StatelessWidget {
  final ChatAvailability currentAvailability;
  final ValueChanged<ChatAvailability> onAvailabilityChanged;

  const ChatAvailabilitySettingWidget({
    super.key,
    required this.currentAvailability,
    required this.onAvailabilityChanged,
  });

  String _getDisplayString(ChatAvailability availability) {
    switch (availability) {
      case ChatAvailability.openToChat:
        return 'Open to Chat';
      case ChatAvailability.requestOnly:
        return 'Requests Only';
      case ChatAvailability.doNotDisturb:
        return 'Do Not Disturb';
    }
  }

  Color _getDisplayColor(ChatAvailability availability, BuildContext context) {
    switch (availability) {
      case ChatAvailability.openToChat:
        return Colors.green.shade600;
      case ChatAvailability.requestOnly:
        return Colors.orange.shade600;
      case ChatAvailability.doNotDisturb:
        return Colors.red.shade600;
    }
  }

  ChatAvailability _getNextAvailability(ChatAvailability current) {
    const values = ChatAvailability.values;
    final currentIndex = values.indexOf(current);
    final nextIndex = (currentIndex + 1) % values.length;
    return values[nextIndex];
  }

  @override
  Widget build(BuildContext context) {
    final displayString = _getDisplayString(currentAvailability);
    final displayColor = _getDisplayColor(currentAvailability, context);

    return ListTile(
      leading: const Icon(Icons.chat_bubble_outline),
      title: const Text('Chat Availability'),
      subtitle: Text(
        displayString,
        style: TextStyle(color: displayColor, fontWeight: FontWeight.w500),
      ),
      trailing: Chip(
        label: Text(
          displayString,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
        backgroundColor: displayColor,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      onTap: () {
        final nextAvailability = _getNextAvailability(currentAvailability);
        onAvailabilityChanged(nextAvailability);
      },
    );
  }
}