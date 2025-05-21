import 'package:empathy_hub_app/features/chat/data/models/chat_enums.dart';
import 'package:empathy_hub_app/features/chat/data/models/user_simple_model.dart';
import 'package:equatable/equatable.dart';

class ChatRequest extends Equatable {
  final String requesteeAnonymousId;
  final String? initialMessage;
  final String anonymousRequestId;
  final String requesterAnonymousId;
  final ChatRequestStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final UserSimple requester;
  final UserSimple requestee;

  const ChatRequest({
    required this.requesteeAnonymousId,
    this.initialMessage,
    required this.anonymousRequestId,
    required this.requesterAnonymousId,
    required this.status,
    required this.createdAt,
    this.respondedAt,
    required this.requester,
    required this.requestee,
  });

  factory ChatRequest.fromJson(Map<String, dynamic> json) {
    return ChatRequest(
      requesteeAnonymousId: json['requestee_anonymous_id'] as String,
      initialMessage: json['initial_message'] as String?,
      anonymousRequestId: json['anonymous_request_id'] as String,
      requesterAnonymousId: json['requester_anonymous_id'] as String,
      status: ChatRequestStatus.values.byName((json['status'] as String).toLowerCase()), // Assuming backend sends lowercase enum names
      createdAt: DateTime.parse(json['created_at'] as String),
      respondedAt: json['responded_at'] != null ? DateTime.parse(json['responded_at'] as String) : null,
      requester: UserSimple.fromJson(json['requester'] as Map<String, dynamic>),
      requestee: UserSimple.fromJson(json['requestee'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'requestee_anonymous_id': requesteeAnonymousId,
      'initial_message': initialMessage,
      'anonymous_request_id': anonymousRequestId,
      'requester_anonymous_id': requesterAnonymousId,
      'status': status.name, // Assumes direct enum name to string
      'created_at': createdAt.toIso8601String(),
      'responded_at': respondedAt?.toIso8601String(),
      'requester': requester.toJson(),
      'requestee': requestee.toJson(),
    };
  }

  @override
  List<Object?> get props => [
        anonymousRequestId, requesteeAnonymousId, initialMessage,
        requesterAnonymousId, status, createdAt, respondedAt,
        requester, requestee,
      ];
}