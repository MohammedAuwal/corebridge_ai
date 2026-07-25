import 'dart:ui';
import 'package:flutter/material.dart';

class CodeArtifact {
  final String id;
  final String fileName;
  final String code;
  final int lineCount;

  CodeArtifact({
    required this.id,
    required this.fileName,
    required this.code,
    required this.lineCount,
  });
}

class ChatComposer extends StatefulWidget {
  final Function(String message) onSend;
  final bool isSending;

  const ChatComposer({
    super.key,
    required this.onSend,
    required this.isSending,
  });

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  final TextEditingController _controller = TextEditingController();
  final List<CodeArtifact> _artifacts = [];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_checkForCodePaste);
  }

  @override
  void dispose() {
    _controller.removeListener(_checkForCodePaste);
    _controller.dispose();
    super.dispose();
  }

  // Detects if pasted text is long source code (>15 lines or multi-line code)
  void _checkForCodePaste() {
    final text = _controller.text;
    final lines = text.split('\n');

    if (lines.length >= 15 || (text.contains('class ') && text.contains('{') && lines.length > 5)) {
      final artifact = CodeArtifact(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        fileName: _inferFileName(text),
        code: text,
        lineCount: lines.length,
      );

      setState(() {
        _artifacts.add(artifact);
        _controller.clear();
      });
    }
  }

  String _inferFileName(String text) {
    if (text.contains('import \'package:flutter') || text.contains('Widget build')) return 'main.dart';
    if (text.contains('import React') || text.contains('export default')) return 'Component.jsx';
    if (text.contains('def ') || text.contains('import os')) return 'script.py';
    if (text.contains('function ') || text.contains('const ')) return 'index.ts';
    return 'source_code.txt';
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty && _artifacts.isEmpty) return;

    StringBuffer finalMessage = StringBuffer();

    // Attach artifacts to prompt payload cleanly
    for (var artifact in _artifacts) {
      finalMessage.writeln('```${artifact.fileName}');
      finalMessage.writeln(artifact.code);
      finalMessage.writeln('```\n');
    }

    if (text.isNotEmpty) {
      finalMessage.writeln(text);
    }

    widget.onSend(finalMessage.toString().trim());

    setState(() {
      _controller.clear();
      _artifacts.clear();
    });
  }

  void _showArtifactPreview(CodeArtifact artifact) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1D27),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.white10)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.code_rounded, color: Colors.cyanAccent, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '${artifact.fileName} (${artifact.lineCount} lines)',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white70),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    children: [
                      SelectableText(
                        artifact.code,
                        style: const TextStyle(
                          color: Colors.white90,
                          fontFamily: 'monospace',
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2230).withOpacity(0.75),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Code Artifact Chips Row ---
                if (_artifacts.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _artifacts.map((artifact) {
                        return GestureDetector(
                          onTap: () => _showArtifactPreview(artifact),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.cyan.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.cyanAccent.withOpacity(0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.description_outlined, color: Colors.cyanAccent, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  '${artifact.fileName} • ${artifact.lineCount} lines',
                                  style: const TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _artifacts.removeWhere((a) => a.id == artifact.id);
                                    });
                                  },
                                  child: const Icon(Icons.close_rounded, size: 14, color: Colors.cyanAccent),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                // --- Text Input & Action Button Row ---
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        maxLines: 4,
                        minLines: 1,
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                        decoration: const InputDecoration(
                          hintText: 'Type a message or paste code...',
                          hintStyle: TextStyle(color: Colors.white38),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // --- Continuous Loading Spinner / Send Button ---
                    GestureDetector(
                      onTap: widget.isSending ? null : _handleSend,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.isSending
                              ? Colors.white12
                              : Theme.of(context).colorScheme.primary,
                        ),
                        child: widget.isSending
                            ? const Padding(
                                padding: EdgeInsets.all(11.0),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.cyanAccent,
                                ),
                              )
                            : const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 22),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
