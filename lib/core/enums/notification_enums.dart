enum NotificationType {
  newCommentOnPost('new_comment_on_post'),
  newChatMessage('new_chat_message'),
  chatRequestReceived('chat_request_received'),
  chatRequestAccepted('chat_request_accepted'),
  chatRequestDeclined('chat_request_declined'),
  unknown('unknown');

  final String value;
  const NotificationType(this.value);
}

enum NotificationStatus {
  unread('unread'),
  read('read'),
  archived('archived'),
  unknown('unknown');

  final String value;
  const NotificationStatus(this.value);
}
