import 'package:anonymous_hubs/core/enums/app_enums.dart';
import 'package:equatable/equatable.dart';

class ReportCreate extends Equatable {
  final ReportedItemType reportedItemType;
  final String reportedItemAnonymousId;
  final String reason;

  const ReportCreate({
    required this.reportedItemType,
    required this.reportedItemAnonymousId,
    required this.reason,
  });

  factory ReportCreate.fromJson(Map<String, dynamic> json) {
    return ReportCreate(
      reportedItemType: ReportedItemType.values.firstWhere(
        (e) => e.backendValue == json['reported_item_type'],
        orElse: () => throw FormatException(
            'Invalid reported_item_type: ${json['reported_item_type']}'),
      ),
      reportedItemAnonymousId: json['reported_item_anonymous_id'] as String,
      reason: json['reason'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reported_item_type': reportedItemType.backendValue,
      'reported_item_anonymous_id': reportedItemAnonymousId,
      'reason': reason,
    };
  }

  @override
  List<Object?> get props =>
      [reportedItemType, reportedItemAnonymousId, reason];
}