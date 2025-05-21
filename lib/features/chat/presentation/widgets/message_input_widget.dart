import 'package:flutter/material.dart';

class MessageInputWidget extends StatefulWidget {
  final Function(String) onSendMessage;
  final bool isSending; // To disable input/button while a message is being sent

  const MessageInputWidget({
    super.key,
    required this.onSendMessage,
    this.isSending = false,
  });

  @override
  State<MessageInputWidget> createState() => _MessageInputWidgetState();
}

class _MessageInputWidgetState extends State<MessageInputWidget> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();

  void _handleSend() {
    final text = _textController.text.trim();
    if (text.isNotEmpty && !widget.isSending) {
      widget.onSendMessage(text);
      _textController.clear();
      // Optionally, keep focus or request focus again if desired
      // _focusNode.requestFocus(); 
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: widget.isSending ? null : (_) => _handleSend(),
              enabled: !widget.isSending,
            ),
          ),
          const SizedBox(width: 8.0),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: widget.isSending ? null : _handleSend,
            color: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }
}