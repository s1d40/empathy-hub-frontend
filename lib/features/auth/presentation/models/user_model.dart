import 'package:equatable/equatable.dart';
import 'package:empathy_hub_app/core/config/api_config.dart'; // For ApiConfig.baseUrl

class User extends Equatable {
  final String anonymousId; // Matches backend's anonymous_id (UUID string)
  final String? username; // Username can be null according to UserRead schema
  final String? avatarUrl;
  final String? bio;
  final String? pronouns;
  final String chatAvailability; // Corresponds to backend's ChatAvailabilityEnum
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt; // Made nullable

  const User({
    required this.anonymousId,
    this.username, // Made optional to match nullability
    this.avatarUrl,
    this.bio,
    this.pronouns,
    required this.chatAvailability,
    required this.isActive,
    required this.createdAt,
    this.updatedAt, // Made nullable
  });

  // Represents an uninitialized or unauthenticated user state.
  // For DateTime, using epoch as a placeholder.
  // For chatAvailability, assuming 'OPEN_TO_CHAT' is a common default string value.
  // For isActive, assuming true as per backend default.
  static final User empty = User(
    anonymousId: '',
    username: null, // Align with nullable username
    avatarUrl: null,
    bio: null,
    pronouns: null,
    chatAvailability: 'OPEN_TO_CHAT', // Or your backend's default enum string value
    isActive: true, // Backend default
    createdAt: DateTime.fromMillisecondsSinceEpoch(0),
    updatedAt: null, // Default for nullable DateTime
  );

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      anonymousId: json['id'] as String,
      username: json['username'] as String?, // Allow null username from JSON
      avatarUrl: _resolveAvatarUrl(json['avatar_url'] as String?),
      bio: json['bio'] as String?,
      pronouns: json['pronouns'] as String?,
      chatAvailability: json['chat_availability'] as String,
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null ? null : DateTime.parse(json['updated_at'] as String),

    );
  }
  
  static String? _resolveAvatarUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.isEmpty) {
      return null;
    }
    if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
      return rawUrl;
    }
    // If it's a relative path (e.g., "/static/avatars/user_avatar.jpg" or "static/avatars/user_avatar.jpg")
    // resolve it against the base URL.
    final baseUri = Uri.parse(ApiConfig.baseUrl);
    return baseUri.resolve(rawUrl).toString();
  }

  // It's good practice to have a toJson if you ever need to send this model to the backend,
  // though for UserRead, it's mostly for receiving.
  // Map<String, dynamic> toJson() => {
  //   'id': anonymousId, // Or 'anonymous_id' depending on backend expectation for updates
  //   'username': username,
  //   'avatar_url': avatarUrl,
  //   'bio': bio,
  //   'pronouns': pronouns,
  // };

  @override
  List<Object?> get props => [
        anonymousId,
        username,
        avatarUrl,
        bio,
        pronouns,
        chatAvailability,
        isActive,
        createdAt,
        updatedAt,
      ];
}