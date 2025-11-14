import 'package:anonymous_hubs/core/enums/app_enums.dart';
import 'package:anonymous_hubs/features/user/data/models/user_models.dart'; // For AuthorRead
import 'package:equatable/equatable.dart';

class ReportRead extends Equatable {
  final ReportedItemType reportedItemType;
  final String reportedItemAnonymousId;
  final String reason;
  final String anonymousReportId;
  final String reporterAnonymousId;
  final ReportStatus status;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? adminNotes;
  final AuthorRead reporter;

  const ReportRead({
    required this.reportedItemType,
    required this.reportedItemAnonymousId,
    required this.reason,
    required this.anonymousReportId,
    required this.reporterAnonymousId,
    required this.status,
    required this.createdAt,
    this.reviewedAt,
    this.adminNotes,
    required this.reporter,
  });

  factory ReportRead.fromJson(Map<String, dynamic> json) {
    return ReportRead(
      reportedItemType: ReportedItemType.values.firstWhere(
        (e) => e.backendValue == json['reported_item_type'],
        orElse: () => throw FormatException(
            'Invalid reported_item_type: ${json['reported_item_type']}'),
      ),
      reportedItemAnonymousId: json['reported_item_anonymous_id'] as String,
      reason: json['reason'] as String,
      anonymousReportId: json['anonymous_report_id'] as String,
      reporterAnonymousId: json['reporter_anonymous_id'] as String,
      status: ReportStatus.values.firstWhere(
        (e) => e.backendValue == json['status'],
        orElse: () =>
            throw FormatException('Invalid status: ${json['status']}'),
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      reviewedAt: json['reviewed_at'] == null
          ? null
          : DateTime.parse(json['reviewed_at'] as String),
      adminNotes: json['admin_notes'] as String?,
      reporter: AuthorRead.fromJson(json['reporter'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reported_item_type': reportedItemType.backendValue,
      'reported_item_anonymous_id': reportedItemAnonymousId,
      'reason': reason,
      'anonymous_report_id': anonymousReportId,
      'reporter_anonymous_id': reporterAnonymousId,
      'status': status.backendValue,
      'created_at': createdAt.toIso8601String(),
      'reviewed_at': reviewedAt?.toIso8601String(),
      'admin_notes': adminNotes,
      'reporter': reporter.toJson(),
    };
  }

  @override
  List<Object?> get props => [
        reportedItemType,
        reportedItemAnonymousId,
        reason,
        anonymousReportId,
        reporterAnonymousId,
        status,
        createdAt,
        reviewedAt,
        adminNotes,
        reporter,
      ];
}