import 'package:equatable/equatable.dart';

class ChatInitiate extends Equatable {
  final String targetUserAnonymousId;
  final String? initialMessage;

  const ChatInitiate({
    required this.targetUserAnonymousId,
    this.initialMessage,
  });

  // This model is primarily for sending data, so fromJson might not be strictly needed
  // unless you plan to deserialize it for some reason (e.g., local drafts).
  // For now, we'll focus on toJson.

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'target_user_anonymous_id': targetUserAnonymousId,
    };
    if (initialMessage != null) {
      data['initial_message'] = initialMessage;
    }
    return data;
  }

  @override
  List<Object?> get props => [targetUserAnonymousId, initialMessage];
}