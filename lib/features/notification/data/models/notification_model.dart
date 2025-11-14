import 'package:equatable/equatable.dart';
import 'package:anonymous_hubs/features/user/data/models/user_simple_model.dart'; // Assuming UserSimple is available
import 'package:anonymous_hubs/core/enums/notification_enums.dart'; // New enums

class NotificationModel extends Equatable {
  final String id;
  final String recipientId;
  final String? senderId;
  final NotificationType notificationType;
  final String content;
  final String resourceId;
  final NotificationStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const NotificationModel({
    required this.id,
    required this.recipientId,
    this.senderId,
    required this.notificationType,
    required this.content,
    required this.resourceId,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['notification_id'] as String,
      recipientId: json['recipient_id'] as String,
      senderId: json['sender_id'] as String?,
      notificationType: NotificationType.values.firstWhere(
          (e) => e.value == json['notification_type'],
          orElse: () => NotificationType.unknown), // Handle unknown type
      content: json['content'] as String,
      resourceId: json['resource_id'] as String,
      status: NotificationStatus.values.firstWhere(
          (e) => e.value == json['status'],
          orElse: () => NotificationStatus.unread), // Handle unknown status
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notification_id': id,
      'recipient_id': recipientId,
      'sender_id': senderId,
      'notification_type': notificationType.value,
      'content': content,
      'resource_id': resourceId,
      'status': status.value,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? recipientId,
    String? senderId,
    NotificationType? notificationType,
    String? content,
    String? resourceId,
    NotificationStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      recipientId: recipientId ?? this.recipientId,
      senderId: senderId ?? this.senderId,
      notificationType: notificationType ?? this.notificationType,
      content: content ?? this.content,
      resourceId: resourceId ?? this.resourceId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        recipientId,
        senderId,
        notificationType,
        content,
        resourceId,
        status,
        createdAt,
        updatedAt,
      ];
}
