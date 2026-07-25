import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ArtifactViewerSheet extends StatelessWidget {
  final String title;
  final String content;
  final String language;

  const ArtifactViewerSheet({
    super.key,
    required this.title,
    required this.content,
    required this.language,
  });

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Artifact copied to clipboard!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.95,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              color: const Color(0xFF0F111A).withOpacity(0.85),
              child: Column(
                children: [
                  // --- Header Bar ---
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
                      color: Colors.black.withOpacity(0.2),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.code_rounded, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, color: Colors.white70, size: 20),
                          onPressed: () => _copyToClipboard(context),
                          tooltip: 'Copy Raw Content',
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 24),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  
                  // --- Content Area (No Wrapping, Horizontal Scroll) ---
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.all(16),
                        child: SelectableText(
                          content,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                            height: 1.5,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
