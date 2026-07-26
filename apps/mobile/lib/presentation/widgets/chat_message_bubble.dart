import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/message_entity.dart';
import 'artifact_viewer_sheet.dart';

class ChatMessageBubble extends StatefulWidget {
  final MessageEntity message;
  final bool isError;
  final VoidCallback? onRewrite;

  const ChatMessageBubble({
    super.key,
    required this.message,
    this.isError = false,
    this.onRewrite,
  });

  @override
  State<ChatMessageBubble> createState() => _ChatMessageBubbleState();
}

class _ChatMessageBubbleState extends State<ChatMessageBubble> {
  static final RegExp _codeBlockRegex = RegExp(r'```(\w*)\n([\s\S]*?)```', multiLine: true);

  // Safety net for content that never got fenced (e.g. a raw paste that
  // slipped through, or an AI response that dumped a huge unfenced
  // block). Anything this long or with this many lines becomes a card
  // even without ``` markers.
  static const int _rawLengthThreshold = 600;
  static const int _rawLineThreshold = 15;

  void _openArtifact(String title, String code, String language) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ArtifactViewerSheet(
        title: title,
        content: code,
        language: language,
      ),
    );
  }

  List<Widget> _buildMessageContent(String text, BuildContext context, bool isUser) {
    final List<Widget> widgets = [];
    int lastEnd = 0;
    int codeBlockIndex = 0;
    bool foundAnyFence = false;

    for (final match in _codeBlockRegex.allMatches(text)) {
      foundAnyFence = true;

      if (match.start > lastEnd) {
        final plain = text.substring(lastEnd, match.start).trim();
        if (plain.isNotEmpty) {
          widgets.add(_buildMarkdownText(plain, isUser));
        }
      }

      final language = match.group(1)?.trim().isNotEmpty == true ? match.group(1)!.trim() : 'text';
      final code = match.group(2) ?? '';
      final lineCount = code.trim().isEmpty ? 0 : code.trim().split('\n').length;

      if (lineCount <= 8) {
        widgets.add(_buildInlineCode(code.trim(), language, isUser));
      } else {
        codeBlockIndex++;
        widgets.add(_buildArtifactCard(
          title: '$language snippet ${codeBlockIndex > 1 ? '#$codeBlockIndex' : ''}'.trim(),
          language: language,
          code: code.trim(),
          lineCount: lineCount,
        ));
      }

      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      final plain = text.substring(lastEnd).trim();
      if (plain.isNotEmpty) {
        widgets.add(_buildMarkdownText(plain, isUser));
      }
    }

    // Fallback: no fenced blocks were found at all, but the raw content
    // is large enough that dumping it as plain text would blow up the
    // bubble — wrap the whole thing as a card instead.
    if (!foundAnyFence) {
      final trimmed = text.trim();
      final lineCount = trimmed.isEmpty ? 0 : trimmed.split('\n').length;
      if (trimmed.length > _rawLengthThreshold || lineCount > _rawLineThreshold) {
        return [
          _buildArtifactCard(
            title: 'Attachment',
            language: 'text',
            code: trimmed,
            lineCount: lineCount,
          ),
        ];
      }
    }

    if (widgets.isEmpty) {
      widgets.add(_buildMarkdownText(text, isUser));
    }

    return widgets;
  }

  Widget _buildMarkdownText(String text, bool isUser) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: MarkdownBody(
        data: text,
        selectable: true,
        styleSheet: MarkdownStyleSheet(
          p: TextStyle(
            color: isUser ? Colors.white : (widget.isError ? Colors.redAccent.shade100 : AppColors.textPrimary),
            fontSize: 15,
            height: 1.4,
          ),
          strong: TextStyle(
            color: isUser ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
          code: const TextStyle(
            backgroundColor: Colors.black26,
            fontFamily: 'monospace',
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildInlineCode(String code, String language, bool isUser) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: AppColors.border),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Text(
          code,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 13, color: AppColors.textPrimary),
        ),
      ),
    );
  }

  Widget _buildArtifactCard({
    required String title,
    required String language,
    required String code,
    required int lineCount,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.md),
        onTap: () => _openArtifact(title.isEmpty ? 'Untitled snippet' : title, code, language),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.code_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.isEmpty ? 'Code artifact' : title,
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$language · $lineCount lines',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUser = widget.message.role == MessageRole.user;
    final content = widget.message.content;

    if (content.isEmpty && widget.message.isStreaming) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: AppColors.border),
          ),
          child: const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentBlue),
          ),
        ),
      );
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(14),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
            decoration: BoxDecoration(
              gradient: isUser ? AppColors.brandGradient : null,
              color: isUser ? null : (widget.isError ? Colors.red.withValues(alpha: 0.12) : AppColors.surface),
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: isUser
                  ? null
                  : Border.all(color: widget.isError ? Colors.redAccent.withValues(alpha: 0.4) : AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _buildMessageContent(content, context, isUser),
            ),
          ),
          if (!isUser && !widget.message.isStreaming && !widget.isError)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Row(
                children: [
                  _MiniIconButton(
                    icon: Icons.copy_rounded,
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: content));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied to clipboard'), duration: Duration(seconds: 1)),
                      );
                    },
                  ),
                  if (widget.onRewrite != null)
                    _MiniIconButton(icon: Icons.refresh_rounded, onTap: widget.onRewrite!),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MiniIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MiniIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 16, color: AppColors.textMuted),
      ),
    );
  }
}
