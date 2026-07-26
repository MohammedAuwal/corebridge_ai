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

  static const int _rawLengthThreshold = 600;
  static const int _rawLineThreshold = 15;

  bool _thinkingExpanded = false;

  @override
  void didUpdateWidget(covariant ChatMessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-expand while actively thinking, auto-collapse the moment the
    // real answer starts streaming — matches how thinking UIs elsewhere
    // behave: visible while reasoning, tucked away once there's an answer.
    if (widget.message.isThinkingStreaming && !oldWidget.message.isThinkingStreaming) {
      _thinkingExpanded = true;
    } else if (!widget.message.isThinkingStreaming && widget.message.content.isNotEmpty && oldWidget.message.content.isEmpty) {
      _thinkingExpanded = false;
    }
  }

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

  Widget _buildThinkingSection() {
    final thinking = widget.message.thinking;
    if (thinking.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(AppRadii.md),
              onTap: () => setState(() => _thinkingExpanded = !_thinkingExpanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    if (widget.message.isThinkingStreaming)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentBlue),
                      )
                    else
                      const Icon(Icons.psychology_outlined, size: 16, color: AppColors.accentBlue),
                    const SizedBox(width: 8),
                    Text(
                      widget.message.isThinkingStreaming ? 'Thinking…' : 'Thought process',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    Icon(
                      _thinkingExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
            if (_thinkingExpanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Text(
                  thinking,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.4, fontStyle: FontStyle.italic),
                ),
              ),
          ],
        ),
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

    if (!foundAnyFence && isUser) {
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
    final hasThinking = widget.message.thinking.isNotEmpty;

    if (content.isEmpty && !hasThinking && widget.message.isStreaming) {
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
          if (!isUser && hasThinking) _buildThinkingSection(),
          if (content.isNotEmpty || isUser)
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
          if (!isUser && !widget.message.isStreaming && !widget.isError && content.isNotEmpty)
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
