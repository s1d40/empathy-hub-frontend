class WebSocketMessage {
  final String type;
  final Map<String, dynamic> payload;

  WebSocketMessage({required this.type, required this.payload});

  factory WebSocketMessage.fromJson(Map<String, dynamic> json) {
    return WebSocketMessage(
      type: json['type'] as String,
      payload: json['payload'] as Map<String, dynamic>,
    );
  }
}
