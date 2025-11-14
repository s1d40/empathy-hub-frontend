import 'package:bloc/bloc.dart';
import 'package:anonymous_hubs/core/services/report_api_service.dart';
import 'package:anonymous_hubs/features/auth/presentation/auth_cubit.dart';
import 'package:anonymous_hubs/features/report/data/models/report_models.dart';
import 'package:equatable/equatable.dart';

part 'report_state.dart';

class ReportCubit extends Cubit<ReportState> {
  final ReportApiService _reportApiService;
  final AuthCubit _authCubit;

  ReportCubit({
    required ReportApiService reportApiService,
    required AuthCubit authCubit,
  })  : _reportApiService = reportApiService,
        _authCubit = authCubit,
        super(ReportInitial());

  Future<void> submitReport(ReportCreate reportData) async {
    emit(ReportSubmitting());

    final authState = _authCubit.state;
    if (authState is! Authenticated) {
      emit(const ReportFailure(message: 'User not authenticated.'));
      return;
    }

    final token = authState.token;
    if (token == null) {
      emit(const ReportFailure(message: 'Authentication token not found.'));
      return;
    }

    try {
      final report = await _reportApiService.submitReport(token, reportData);
      if (report != null) {
        emit(ReportSuccess(report: report));
      } else {
        emit(const ReportFailure(message: 'Failed to submit report. Please try again.'));
      }
    } catch (e) {
      print('ReportCubit - Error submitting report: $e');
      emit(ReportFailure(message: 'An unexpected error occurred: ${e.toString()}'));
    }
  }
}