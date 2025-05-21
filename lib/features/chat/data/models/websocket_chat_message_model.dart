import 'package:equatable/equatable.dart';

class WebSocketChatMessage extends Equatable {
  final String content;

  const WebSocketChatMessage({
    required this.content,
  });

  Map<String, dynamic> toJson() {
    return {
      'content': content,
    };
  }

  // fromJson is not typically needed for a model that is only sent.

  @override
  List<Object?> get props => [content];
}