import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
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
  bool _isThoughtExpanded = true;

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

    // --- Dynamic Thinking Mode Parser ---
    String thinkingText = '';
    String finalText = widget.message.content;
    bool isStillThinking = false;

    if (!isUser) {
      if (finalText.contains('<think>')) {
        final thinkStartIndex = finalText.indexOf('<think>') + 7;
        final thinkEndIndex = finalText.indexOf('</think>');

        if (thinkEndIndex != -1) {
          // Finished thinking
          thinkingText = finalText.substring(thinkStartIndex, thinkEndIndex).trim();
          finalText = finalText.substring(thinkEndIndex + 8).trim();
        } else {
          // Currently streaming thought tokens!
          thinkingText = finalText.substring(thinkStartIndex).trim();
          finalText = '';
          isStillThinking = widget.message.isStreaming;
        }
      }
    }

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
            // Glass Container Box
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isUser ? 20 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 20),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: isUser
                        ? theme.colorScheme.primary.withOpacity(0.85)
                        : const Color(0xFF1E2230).withOpacity(0.65),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isUser ? 20 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 20),
                    ),
                    border: Border.all(
                      color: isUser
                          ? Colors.white.withOpacity(0.2)
                          : Colors.white.withOpacity(0.12),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Thinking Block (Claude/DeepSeek Style) ---
                      if (thinkingText.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12.0),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isStillThinking
                                  ? theme.colorScheme.primary.withOpacity(0.5)
                                  : Colors.white.withOpacity(0.08),
                            ),
                          ),
                          child: Theme(
                            data: theme.copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              initiallyExpanded: _isThoughtExpanded,
                              onExpansionChanged: (val) =>
                                  setState(() => _isThoughtExpanded = val),
                              leading: isStillThinking
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.amberAccent,
                                      ),
                                    )
                                  : const Icon(Icons.psychology,
                                      size: 20, color: Colors.amberAccent),
                              title: Text(
                                isStillThinking ? 'Thinking...' : 'Thought process',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.only(
                                      left: 16, right: 16, bottom: 14),
                                  child: Text(
                                    thinkingText,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      height: 1.4,
                                      color: Colors.white60,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // --- Main Message Markdown Content ---
                      if (finalText.isNotEmpty)
                        MarkdownBody(
                          data: finalText,
                          selectable: true,
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(
                              color: isUser ? Colors.white : Colors.white.withOpacity(0.9),
                              fontSize: 15.5,
                              height: 1.45,
                            ),
                            code: TextStyle(
                              backgroundColor: Colors.black.withOpacity(0.3),
                              color: Colors.cyanAccent,
                              fontFamily: 'monospace',
                              fontSize: 13,
                            ),
                            codeblockDecoration: BoxDecoration(
                              color: const Color(0xFF11141D),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white10),
                            ),
                          ),
                        ),

                      // Floating indicator if response is streaming without text yet
                      if (finalText.isEmpty && thinkingText.isEmpty && widget.message.isStreaming)
                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white70,
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Generating response...',
                              style: TextStyle(color: Colors.white54, fontSize: 13),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // --- Action Toolbar (Copy / Rewrite) ---
            if (!isUser && finalText.isNotEmpty && !widget.message.isStreaming)
              Padding(
                padding: const EdgeInsets.only(top: 4.0, left: 4.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      color: Colors.white54,
                      onPressed: () => _copyToClipboard(context, finalText),
                      tooltip: 'Copy message',
                    ),
                    if (widget.onRewrite != null)
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        color: Colors.white54,
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
