import 'package:empathy_hub_app/core/config/api_config.dart';
import 'package:equatable/equatable.dart';

class UserSimple extends Equatable {
  final String anonymousId;
  final String username; // Reverted to non-nullable
  final String? avatarUrl;
  final String? chatAvailability; // Added chatAvailability

  const UserSimple({
    required this.anonymousId,
    required this.username, // Reverted to required
    this.avatarUrl, // Made optional to align with User model
    this.chatAvailability, // Added to constructor
  });

  factory UserSimple.fromJson(Map<String, dynamic> json) {
    return UserSimple(
      // Safely parse anonymousId, providing a fallback
      anonymousId: (json['id'] as String?) ?? 'error_unknown_user_id',
      // Safely parse username, providing a default if null or not present
      username: (json['username'] as String?) ?? 'Anonymous',

      // Ensure robust parsing for avatar_url, it might be null or not present
      avatarUrl: _resolveAvatarUrl(json['avatar_url'] as String?),
      chatAvailability: json['chat_availability'] as String?, // Parse chat_availability
    );
  }
  
  static String? _resolveAvatarUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.isEmpty) {
      return null;
    }
    if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
      return rawUrl;
    }
    final baseUri = Uri.parse(ApiConfig.baseUrl);
    return baseUri.resolve(rawUrl).toString();
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'anonymous_id': anonymousId,
      'username': username, // Correctly add username to the map
    };
    if (avatarUrl != null) map['avatar_url'] = avatarUrl;
    if (chatAvailability != null) map['chat_availability'] = chatAvailability;
    return map;
  }

  
  @override
  List<Object?> get props => [
        anonymousId, 
        username, 
        avatarUrl, 
        chatAvailability]; // Added to props
}