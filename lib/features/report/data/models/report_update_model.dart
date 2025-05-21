import 'package:empathy_hub_app/core/enums/app_enums.dart';
import 'package:equatable/equatable.dart';

class ReportUpdate extends Equatable {
  final ReportStatus status;
  final String? adminNotes;

  const ReportUpdate({
    required this.status,
    this.adminNotes,
  });

  factory ReportUpdate.fromJson(Map<String, dynamic> json) {
    return ReportUpdate(
      status: ReportStatus.values.firstWhere(
        (e) => e.backendValue == json['status'],
        orElse: () =>
            throw FormatException('Invalid status: ${json['status']}'),
      ),
      adminNotes: json['admin_notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status.backendValue,
      'admin_notes': adminNotes,
    };
  }
  @override
  List<Object?> get props => [status, adminNotes];
}