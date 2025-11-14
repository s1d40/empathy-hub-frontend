import 'package:anonymous_hubs/features/chat/data/models/chat_request_model.dart';
import 'package:anonymous_hubs/features/chat/data/models/chat_room_model.dart';

/// A wrapper class for the response from chat initiation,
/// indicating whether a ChatRoom or ChatRequest was returned,
/// and if it was an existing entity.
class ChatInitiationResponse {
  final ChatRoom? chatRoom;
  final ChatRequest? chatRequest;
  final bool isExisting;

  ChatInitiationResponse({
    this.chatRoom,
    this.chatRequest,
    required this.isExisting,
  }) : assert(chatRoom != null || chatRequest != null); // Ensure at least one is present
}
