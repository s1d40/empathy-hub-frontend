import 'package:anonymous_hubs/features/chat/data/models/chat_initiate_model.dart';
import 'package:anonymous_hubs/features/chat/presentation/cubit/chat_initiation_cubit/chat_initiation_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChatRequestMessageDialogWidget extends StatefulWidget {
  final String targetUserAnonymousId;
  final String targetUsername;

  const ChatRequestMessageDialogWidget({
    super.key,
    required this.targetUserAnonymousId,
    required this.targetUsername,
  });

  @override
  State<ChatRequestMessageDialogWidget> createState() =>
      _ChatRequestMessageDialogWidgetState();
}

class _ChatRequestMessageDialogWidgetState
    extends State<ChatRequestMessageDialogWidget> {
  final _messageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  static const int _minMessageLength = 20;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendRequest(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      final chatInitiateData = ChatInitiate(
        targetUserAnonymousId: widget.targetUserAnonymousId,
        initialMessage: _messageController.text.trim(),
      );
      // ChatInitiationCubit is expected to be provided by the caller of this dialog
      // (e.g., UserActionsPopupMenuButton or UserProfileChatButtonWidget)
      context.read<ChatInitiationCubit>().initiateChat(chatInitiateData);
      Navigator.of(context).pop(); // Close the dialog after initiating
    }
  }

  @override
  Widget build(BuildContext context) {
    // No BlocListener here, as feedback is handled by the calling widget's BlocListener
    return AlertDialog(
      title: Text('Send Chat Request to ${widget.targetUsername}'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _messageController,
          decoration: InputDecoration(
            labelText: 'Initial Message (Optional)',
            hintText:
                'Say hi! (min $_minMessageLength characters if provided)',
            border: const OutlineInputBorder(),
          ),
          maxLines: 4,
          minLines: 2,
          autofocus: true,
          validator: (value) {
            if (value != null && value.trim().isNotEmpty && value.trim().length < _minMessageLength) {
              return 'Message must be at least $_minMessageLength characters long if provided.';
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
        BlocBuilder<ChatInitiationCubit, ChatInitiationState>(
          builder: (context, state) {
            if (state is ChatInitiationInProgress) {
              return const ElevatedButton(
                onPressed: null,
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }
            return ElevatedButton(
              child: const Text('Send Request'),
              onPressed: () => _sendRequest(context),
            );
          },
        ),
      ],
    );
  }
}