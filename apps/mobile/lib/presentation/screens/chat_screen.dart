import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../core/di/providers.dart';
import '../../core/providers/selected_model_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/message_entity.dart';
import '../widgets/geo_mesh_background.dart';
import '../widgets/chat_composer.dart';
import '../widgets/model_selector_bar.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final List<MessageEntity> _messages = [];
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(draftMessageProvider);
    if (draft.trim().isNotEmpty) {
      ref.read(draftMessageProvider.notifier).state = '';
      WidgetsBinding.instance.addPostFrameCallback((_) => _send(draft));
    }
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty || _isSending) return;

    final uid = ref.read(firebaseServiceProvider).currentUserId;
    if (uid == null) return;

    final selectedModel = ref.read(selectedModelProvider);

    setState(() {
      _isSending = true;
      _messages.add(MessageEntity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        conversationId: 'local-draft',
        role: MessageRole.user,
        content: text,
        createdAt: DateTime.now(),
      ));
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

    try {
      await for (final partial in sendMessageUseCase(
        uid: uid,
        conversationId: 'local-draft',
        userMessage: text,
        history: _messages.where((m) => m.id != placeholderId && m.id != _messages.last.id).toList(),
        provider: selectedModel.provider,
        model: selectedModel.model,
      )) {
        final index = _messages.indexWhere((m) => m.id == placeholderId);
        if (index != -1) {
          setState(() {
            _messages[index] = _messages[index].copyWith(content: partial);
          });
        }
      }
    } catch (e) {
      // This is the fix: errors are now caught and shown, instead of
      // vanishing into a permanently-empty "..." bubble.
      final index = _messages.indexWhere((m) => m.id == placeholderId);
      final errorText = _friendlyError(e);
      if (index != -1) {
        setState(() {
          _messages[index] = _messages[index].copyWith(content: '⚠️ $errorText', isStreaming: false);
        });
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

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('No API key set')) {
      return 'No API key set for this provider. Open the menu → API Providers to add one.';
    }
    if (msg.contains('Unauthorized')) {
      return 'Session expired — please sign out and sign back in.';
    }
    return msg.replaceFirst('Exception: ', '').replaceFirst('StateError: ', '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: GeoMeshBackground()),
          Column(
            children: [
              const ModelSelectorBar(),
              Expanded(
                child: _messages.isEmpty
                    ? const _EmptyChatState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final isUser = message.role == MessageRole.user;
                          final isError = message.content.startsWith('⚠️');

                          return Align(
                            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              padding: const EdgeInsets.all(14),
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                              decoration: BoxDecoration(
                                gradient: isUser ? AppColors.brandGradient : null,
                                color: isUser ? null : (isError ? Colors.red.withValues(alpha: 0.12) : AppColors.surface),
                                borderRadius: BorderRadius.circular(AppRadii.lg),
                                border: isUser
                                    ? null
                                    : Border.all(color: isError ? Colors.redAccent.withValues(alpha: 0.4) : AppColors.border),
                              ),
                              child: message.content.isEmpty && message.isStreaming
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentBlue),
                                    )
                                  : MarkdownBody(
                                      data: message.content,
                                      styleSheet: MarkdownStyleSheet(
                                        p: TextStyle(
                                          color: isUser ? Colors.white : (isError ? Colors.redAccent.shade100 : AppColors.textPrimary),
                                        ),
                                      ),
                                    ),
                            ),
                          );
                        },
                      ),
              ),
              ChatComposer(
                onSend: _send,
                isSending: _isSending,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyChatState extends StatelessWidget {
  const _EmptyChatState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => AppColors.brandGradient.createShader(bounds),
              child: const Icon(Icons.auto_awesome_rounded, size: 48, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text('Start a conversation', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              'Ask anything, or pick a model above to get started.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
