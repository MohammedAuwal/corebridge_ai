import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'model_picker_chip.dart';

class ChatComposer extends StatefulWidget {
  final void Function(String text) onSend;
  final bool isSending;
  final void Function()? onVoiceInput;

  const ChatComposer({
    super.key,
    required this.onSend,
    required this.isSending,
    this.onVoiceInput,
  });

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  static const int _pasteCharThreshold = 300;
  static const int _pasteLineThreshold = 8;

  String? _attachedContent;
  int _previousLength = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleTextChange);
  }

  void _handleTextChange() {
    final current = _controller.text;
    final delta = current.length - _previousLength;
    _previousLength = current.length;

    final lineCount = current.split('\n').length;
    final looksLikeAPaste = delta >= _pasteCharThreshold || lineCount > _pasteLineThreshold;

    if (looksLikeAPaste && _attachedContent == null) {
      setState(() {
        _attachedContent = current.trim();
        _controller.clear();
        _previousLength = 0;
      });
    }
  }

  void _removeAttachment() {
    setState(() => _attachedContent = null);
  }

  void _submit() {
    final typed = _controller.text.trim();
    final attachment = _attachedContent;

    if (typed.isEmpty && attachment == null) return;

    final String message;
    if (attachment != null) {
      final fenced = '```text\n$attachment\n```';
      message = typed.isEmpty ? fenced : '$typed\n\n$fenced';
    } else {
      message = typed;
    }

    widget.onSend(message);
    _controller.clear();
    setState(() => _attachedContent = null);
    _previousLength = 0;
  }

  void _handleVoiceTap() {
    if (widget.onVoiceInput != null) {
      widget.onVoiceInput!();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Voice input is coming soon.')),
    );
  }

  bool get _hasText => _controller.text.trim().isNotEmpty || _attachedContent != null;

  @override
  void dispose() {
    _controller.removeListener(_handleTextChange);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_attachedContent != null) _buildAttachmentChip(),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(28),
                // No colored border — flat fill only.
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 120),
                    child: Scrollbar(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        minLines: 1,
                        maxLines: 5,
                        cursorColor: AppColors.accentBlue,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                        onChanged: (_) => setState(() {}), // refresh mic/send swap
                        decoration: InputDecoration(
                          hintText: _attachedContent != null ? 'Add a message (optional)…' : 'Message CoreBridge…',
                          hintStyle: const TextStyle(color: AppColors.textMuted),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        ),
                        onSubmitted: (_) => _submit(),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.textSecondary),
                        tooltip: 'Add files',
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('File attachments are coming soon.')),
                          );
                        },
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: ModelPickerChip(),
                      ),
                      const Spacer(),
                      // Voice input — shown whenever there's nothing typed
                      // yet, matching the sketch's waveform icon next to
                      // the send button.
                      if (!_hasText)
                        IconButton(
                          icon: const Icon(Icons.graphic_eq_rounded, color: AppColors.textSecondary),
                          tooltip: 'Voice input',
                          onPressed: _handleVoiceTap,
                        ),
                      Container(
                        decoration: const BoxDecoration(gradient: AppColors.brandGradient, shape: BoxShape.circle),
                        margin: const EdgeInsets.only(right: 2),
                        child: IconButton(
                          icon: widget.isSending
                              ? const SizedBox(
                                  width: 18, height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.arrow_upward_rounded, color: Colors.white),
                          onPressed: widget.isSending ? null : _submit,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentChip() {
    final lineCount = _attachedContent!.split('\n').length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(gradient: AppColors.brandGradient, borderRadius: BorderRadius.circular(AppRadii.sm)),
              alignment: Alignment.center,
              child: const Icon(Icons.description_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pasted content attached', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                  Text('$lineCount lines · will send as an artifact', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
              onPressed: _removeAttachment,
            ),
          ],
        ),
      ),
    );
  }
}
