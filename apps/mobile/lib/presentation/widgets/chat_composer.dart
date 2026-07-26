import 'dart:ui';
import 'package:flutter/material.dart';

class CodeArtifact {
  final String id;
  final String fileName;
  final String code;
  final int lineCount;

  CodeArtifact({required this.id, required this.fileName, required this.code, required this.lineCount});
}

class ChatComposer extends StatefulWidget {
  final Function(String message) onSend;
  final bool isSending;

  const ChatComposer({super.key, required this.onSend, required this.isSending});

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  final TextEditingController _controller = TextEditingController();
  final List<CodeArtifact> _artifacts = [];
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (_hasText != _controller.text.isNotEmpty) {
        setState(() => _hasText = _controller.text.isNotEmpty);
      }
      _checkForCodePaste();
    });
  }

  void _checkForCodePaste() {
    final text = _controller.text;
    final lines = text.split('\n');
    if (lines.length >= 15) {
      setState(() {
        _artifacts.add(CodeArtifact(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          fileName: 'pasted_file.txt',
          code: text,
          lineCount: lines.length,
        ));
        _controller.clear();
      });
    }
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty && _artifacts.isEmpty) return;

    StringBuffer finalMessage = StringBuffer();
    for (var artifact in _artifacts) {
      finalMessage.writeln('```${artifact.fileName}');
      finalMessage.writeln(artifact.code);
      finalMessage.writeln('```\n');
    }
    if (text.isNotEmpty) finalMessage.writeln(text);

    widget.onSend(finalMessage.toString().trim());

    setState(() {
      _controller.clear();
      _artifacts.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_artifacts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0, left: 40),
              child: Wrap(
                spacing: 8,
                children: _artifacts.map((a) => Chip(
                  label: Text('${a.fileName} (${a.lineCount} lines)', style: const TextStyle(color: Colors.white, fontSize: 12)),
                  backgroundColor: Colors.white.withOpacity(0.2),
                  deleteIcon: const Icon(Icons.close, size: 14, color: Colors.white),
                  onDeleted: () => setState(() => _artifacts.remove(a)),
                )).toList(),
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.add, color: Colors.white, size: 28),
                onPressed: () {},
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              maxLines: 5,
                              minLines: 1,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                hintText: 'Message...',
                                hintStyle: TextStyle(color: Colors.white54),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: widget.isSending
                                ? const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: SizedBox(
                                      width: 24, height: 24,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent),
                                    ),
                                  )
                                : GestureDetector(
                                    onTap: _hasText || _artifacts.isNotEmpty ? _handleSend : null,
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _hasText || _artifacts.isNotEmpty ? Colors.white : Colors.transparent,
                                      ),
                                      child: Icon(
                                        _hasText || _artifacts.isNotEmpty ? Icons.arrow_upward_rounded : Icons.mic_none_rounded,
                                        color: _hasText || _artifacts.isNotEmpty ? Colors.black : Colors.white70,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
