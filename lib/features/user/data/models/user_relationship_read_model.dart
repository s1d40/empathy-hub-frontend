import 'package:anonymous_hubs/core/enums/app_enums.dart';
import 'package:equatable/equatable.dart';

class UserRelationshipRead extends Equatable {
  final String actorAnonymousId;
  final String targetAnonymousId;
  final RelationshipType relationshipType;
  final DateTime createdAt;

  const UserRelationshipRead({
    required this.actorAnonymousId,
    required this.targetAnonymousId,
    required this.relationshipType,
    required this.createdAt,
  });

  factory UserRelationshipRead.fromJson(Map<String, dynamic> json) {
    return UserRelationshipRead(
      actorAnonymousId: json['actor_anonymous_id'] as String,
      targetAnonymousId: json['target_anonymous_id'] as String,
      relationshipType: RelationshipType.values.firstWhere(
        (e) => e.backendValue == json['relationship_type'],
        orElse: () => throw FormatException(
            'Invalid relationship_type: ${json['relationship_type']}'),
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'actor_anonymous_id': actorAnonymousId,
      'target_anonymous_id': targetAnonymousId,
      'relationship_type': relationshipType.backendValue,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props =>
      [actorAnonymousId, targetAnonymousId, relationshipType, createdAt];
}