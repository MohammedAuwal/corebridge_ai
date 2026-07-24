import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../core/constants/ai_models.dart';
import '../../core/di/providers.dart';
import '../../domain/entities/message_entity.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final List<MessageEntity> _messages = [];
  bool _isSending = false;

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
      _messages.add(MessageEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        conversationId: 'local-draft',
        role: MessageRole.user,
        content: text,
        createdAt: DateTime.now(),
      ));
      _controller.clear();
    });

    final placeholderId = '${DateTime.now().millisecondsSinceEpoch}-assistant';
    setState(() {
      _messages.add(MessageEntity(
        id: placeholderId,
        conversationId: 'local-draft',
        role: MessageRole.assistant,
        content: '',
        isStreaming: true,
        createdAt: DateTime.now(),
      ));
    });

    final sendMessageUseCase = ref.read(sendMessageUseCaseProvider);
    final uid = ref.read(firebaseAuthProvider).currentUser?.uid ?? 'local-draft-user';

    // Provider + model both come from AiModels, not a hardcoded string —
    // update apps/mobile/lib/core/constants/ai_models.dart when a
    // provider ships a new release, and every screen picks it up.
    const provider = 'claude';
    final model = AiModels.defaultFor(provider);

    try {
      await for (final partial in sendMessageUseCase(
        uid: uid,
        conversationId: 'local-draft',
        userMessage: text,
        history: _messages.where((m) => m.id != placeholderId).toList(),
        provider: provider,
        model: model,
      )) {
        final index = _messages.indexWhere((m) => m.id == placeholderId);
        if (index != -1) {
          setState(() {
            _messages[index] = _messages[index].copyWith(content: partial);
          });
        }
      }
    } finally {
      final index = _messages.indexWhere((m) => m.id == placeholderId);
      if (index != -1) {
        setState(() {
          _messages[index] = _messages[index].copyWith(isStreaming: false);
        });
      }
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message.role == MessageRole.user;
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isUser
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: MarkdownBody(data: message.content.isEmpty ? '…' : message.content),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Message CoreBridge...',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _isSending ? null : _send,
                    icon: const Icon(Icons.arrow_upward),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
