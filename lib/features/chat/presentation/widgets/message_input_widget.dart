import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart' as foundation;

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
  bool _isEmojiPickerVisible = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() {
          _isEmojiPickerVisible = false;
        });
      }
    });
  }

  void _handleSend() {
    final text = _textController.text.trim();
    if (text.isNotEmpty && !widget.isSending) {
      widget.onSendMessage(text);
      _textController.clear();
    }
  }

  void _toggleEmojiPicker() {
    if (_isEmojiPickerVisible) {
      _focusNode.requestFocus();
    } else {
      _focusNode.unfocus();
    }
    setState(() {
      _isEmojiPickerVisible = !_isEmojiPickerVisible;
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: <Widget>[
              IconButton(
                icon: Icon(
                  _isEmojiPickerVisible ? Icons.keyboard : Icons.emoji_emotions_outlined,
                ),
                onPressed: _toggleEmojiPicker,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8.0),
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
        ),
        Offstage(
          offstage: !_isEmojiPickerVisible,
          child: SizedBox(
            height: 250,
            child: EmojiPicker(
              textEditingController: _textController,
              onBackspacePressed: () {
                // Backspace-Button tapped logic
                // Remove this logic to use the default implementation of the backspace button
              },
              config: Config(
                emojiViewConfig: EmojiViewConfig(
                  emojiSizeMax: 32 * (foundation.defaultTargetPlatform == TargetPlatform.iOS ? 1.30 : 1.0),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}