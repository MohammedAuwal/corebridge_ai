import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class ChatComposer extends StatefulWidget {
  final void Function(String text) onSend;
  final bool isSending;

  const ChatComposer({super.key, required this.onSend, required this.isSending});

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  // If a single onChanged event adds more than this many characters,
  // treat it as a paste rather than typing.
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
      final lineCount = attachment.split('\n').length;
      final fenced = '```text\n$attachment\n```';
      message = typed.isEmpty ? fenced : '$typed\n\n$fenced';
      // ignore: unused_local_variable
      final _ = lineCount;
    } else {
      message = typed;
    }

    widget.onSend(message);
    _controller.clear();
    setState(() => _attachedContent = null);
    _previousLength = 0;
  }

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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_attachedContent != null) _buildAttachmentChip(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file_rounded, color: AppColors.textSecondary),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('File attachments are coming soon.')),
                      );
                    },
                  ),
                  Expanded(
                    // Hard cap on visible height: the field never grows
                    // past ~5 lines. Anything longer scrolls internally
                    // instead of pushing the whole screen around — and
                    // large pastes get intercepted above before they
                    // ever reach this state.
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 120),
                      child: Scrollbar(
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          minLines: 1,
                          maxLines: 5,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            hintText: _attachedContent != null ? 'Add a message (optional)…' : 'Ask anything or create something…',
                            hintStyle: const TextStyle(color: AppColors.textMuted),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) => _submit(),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    decoration: const BoxDecoration(gradient: AppColors.brandGradient, shape: BoxShape.circle),
                    child: IconButton(
                      icon: widget.isSending
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.arrow_upward_rounded, color: Colors.white),
                      onPressed: widget.isSending ? null : _submit,
                    ),
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
          border: Border.all(color: AppColors.border),
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
