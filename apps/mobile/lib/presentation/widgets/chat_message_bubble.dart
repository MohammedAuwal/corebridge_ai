import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/message_entity.dart';

class ChatMessageBubble extends StatefulWidget {
  final MessageEntity message;
  final VoidCallback? onRewrite;

  const ChatMessageBubble({
    super.key,
    required this.message,
    this.onRewrite,
  });

  @override
  State<ChatMessageBubble> createState() => _ChatMessageBubbleState();
}

class _ChatMessageBubbleState extends State<ChatMessageBubble> {
  bool _isThoughtExpanded = false;

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUser = widget.message.role == MessageRole.user;
    final theme = Theme.of(context);

    // --- Thinking Mode Parser ---
    String thinkingText = '';
    String finalText = widget.message.content;

    if (!isUser && finalText.contains('<think>')) {
      final thinkStartIndex = finalText.indexOf('<think>') + 7;
      final thinkEndIndex = finalText.indexOf('</think>');
      
      if (thinkEndIndex != -1) {
        // The thought is finished
        thinkingText = finalText.substring(thinkStartIndex, thinkEndIndex).trim();
        finalText = finalText.substring(thinkEndIndex + 8).trim();
      } else {
        // The thought is currently streaming!
        thinkingText = finalText.substring(thinkStartIndex).trim();
        finalText = ''; // Nothing final yet
      }
    }
    // Remove standalone tags if they leak through
    finalText = finalText.replaceAll('<think>', '').replaceAll('</think>', '').trim();

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            
            // --- The Bubble ---
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: isUser ? theme.colorScheme.primary : theme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 0),
                  bottomRight: Radius.circular(isUser ? 0 : 20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  // 1. Thinking Process UI
                  if (thinkingText.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.colorScheme.outlineVariant),
                        ),
                        child: Theme(
                          data: theme.copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            initiallyExpanded: _isThoughtExpanded,
                            onExpansionChanged: (val) => setState(() => _isThoughtExpanded = val),
                            leading: const Icon(Icons.psychology, size: 20),
                            title: Text(
                              'Thinking process...',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontStyle: FontStyle.italic,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                                child: Text(
                                  thinkingText,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // 2. Main Final Text
                  if (finalText.isNotEmpty)
                    Text(
                      finalText,
                      style: TextStyle(
                        color: isUser ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                        fontSize: 16,
                      ),
                    ),
                ],
              ),
            ),

            // --- Action Buttons (Only for AI) ---
            if (!isUser && finalText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0, left: 8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      color: theme.colorScheme.onSurfaceVariant,
                      onPressed: () => _copyToClipboard(context, finalText),
                      tooltip: 'Copy message',
                    ),
                    if (widget.onRewrite != null)
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        color: theme.colorScheme.onSurfaceVariant,
                        onPressed: widget.onRewrite,
                        tooltip: 'Rewrite response',
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
