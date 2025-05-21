import 'package:empathy_hub_app/core/enums/app_enums.dart';
import 'package:empathy_hub_app/features/report/data/models/report_models.dart';
import 'package:empathy_hub_app/features/report/presentation/cubit/report_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ReportDialogWidget extends StatefulWidget {
  final ReportedItemType itemType;
  final String itemAnonymousId;

  const ReportDialogWidget({
    super.key,
    required this.itemType,
    required this.itemAnonymousId,
  });

  @override
  State<ReportDialogWidget> createState() => _ReportDialogWidgetState();
}

class _ReportDialogWidgetState extends State<ReportDialogWidget> {
  final _reasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String get _dialogTitle {
    switch (widget.itemType) {
      case ReportedItemType.user:
        return 'Report User';
      case ReportedItemType.post:
        return 'Report Post';
      case ReportedItemType.comment:
        return 'Report Comment';
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _submitReport(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      final reportData = ReportCreate(
        reportedItemType: widget.itemType,
        reportedItemAnonymousId: widget.itemAnonymousId,
        reason: _reasonController.text.trim(),
      );
      context.read<ReportCubit>().submitReport(reportData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ReportCubit, ReportState>(
      listener: (context, state) {
        if (state is ReportSuccess) {
          Navigator.of(context).pop(); // Close the dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Report submitted successfully!')),
          );
        } else if (state is ReportFailure) {
          // Optionally, keep the dialog open and show error within it,
          // or close and show SnackBar. For now, SnackBar.
          // If keeping dialog open, you might want to reset button state.
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to submit report: ${state.message}')),
          );
        }
      },
      child: AlertDialog(
        title: Text(_dialogTitle),
        content: Form(
          key: _formKey,
          child: TextFormField(
            controller: _reasonController,
            decoration: const InputDecoration(
              labelText: 'Reason for reporting',
              hintText: 'Please provide details (min 10 characters)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            minLines: 1,
            autofocus: true,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Reason cannot be empty.';
              }
              if (value.trim().length < 10) {
                return 'Reason must be at least 10 characters long.';
              }
              return null;
            },
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          BlocBuilder<ReportCubit, ReportState>(
            builder: (context, state) {
              if (state is ReportSubmitting) {
                return const ElevatedButton(
                  onPressed: null,
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                );
              }
              return ElevatedButton(
                child: const Text('Submit Report'),
                onPressed: () => _submitReport(context),
              );
            },
          ),
        ],
      ),
    );
  }
}