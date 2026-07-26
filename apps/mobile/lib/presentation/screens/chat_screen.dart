import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/providers.dart';
import '../../core/providers/conversation_provider.dart';
import '../../core/providers/selected_model_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/message_entity.dart';
import '../widgets/geo_mesh_background.dart';
import '../widgets/chat_composer.dart';
import '../widgets/model_selector_bar.dart';
import '../widgets/chat_message_bubble.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final List<MessageEntity> _messages = [];
  final Set<String> _errorMessageIds = {};
  bool _isSending = false;
  bool _isLoadingHistory = false;
  String? _conversationId;

  @override
  void initState() {
    super.initState();
    _conversationId = ref.read(activeConversationIdProvider);

    if (_conversationId != null) {
      _loadExistingConversation(_conversationId!);
    }

    final draft = ref.read(draftMessageProvider);
    if (draft.trim().isNotEmpty) {
      ref.read(draftMessageProvider.notifier).state = '';
      WidgetsBinding.instance.addPostFrameCallback((_) => _send(draft));
    }
  }

  Future<void> _loadExistingConversation(String conversationId) async {
    setState(() => _isLoadingHistory = true);
    try {
      final messages = await ref
          .read(conversationRepositoryProvider)
          .watchMessages(conversationId)
          .first;
      if (mounted) {
        setState(() {
          _messages.clear();
          _messages.addAll(messages);
        });
      }
    } finally {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  /// Creates a title from the first user message: short, human-readable,
  /// truncated so it fits nicely in the History and drawer lists.
  String _titleFrom(String firstMessage) {
    final oneLine = firstMessage.replaceAll('\n', ' ').trim();
    if (oneLine.length <= 48) return oneLine;
    return '${oneLine.substring(0, 48).trim()}…';
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty || _isSending) return;

    final uid = ref.read(firebaseServiceProvider).currentUserId;
    if (uid == null) return;

    final selectedModel = ref.read(selectedModelProvider);

    // Lazily create the real Firestore conversation on the very first
    // message — this is what was missing before, causing History to
    // always be empty.
    if (_conversationId == null) {
      final result = await ref.read(conversationRepositoryProvider).createConversation(
            ownerId: uid,
            title: _titleFrom(text),
          );
      result.when(
        success: (conversation) {
          _conversationId = conversation.id;
          ref.read(activeConversationIdProvider.notifier).state = conversation.id;
        },
        error: (failure) {
          // Fall back to a local-only id so the chat still works even
          // if Firestore write failed (e.g. offline) — it just won't
          // show in History until connectivity returns and a retry
          // succeeds on a future message.
          _conversationId = 'local-${DateTime.now().millisecondsSinceEpoch}';
        },
      );
    }

    final userMessageId = DateTime.now().millisecondsSinceEpoch.toString();

    setState(() {
      _isSending = true;
      _messages.add(MessageEntity(
        id: userMessageId,
        conversationId: _conversationId!,
        role: MessageRole.user,
        content: text,
        createdAt: DateTime.now(),
      ));
    });

    final placeholderId = '${DateTime.now().millisecondsSinceEpoch}-assistant';
    setState(() {
      _messages.add(MessageEntity(
        id: placeholderId,
        conversationId: _conversationId!,
        role: MessageRole.assistant,
        content: '',
        isStreaming: true,
        createdAt: DateTime.now(),
      ));
    });

    final cleanHistory = _messages
        .where((m) => m.id != placeholderId && m.id != userMessageId && !_errorMessageIds.contains(m.id))
        .toList();

    final sendMessageUseCase = ref.read(sendMessageUseCaseProvider);

    try {
      await for (final partial in sendMessageUseCase(
        uid: uid,
        conversationId: _conversationId!,
        userMessage: text,
        history: cleanHistory,
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
      final index = _messages.indexWhere((m) => m.id == placeholderId);
      final errorText = _friendlyError(e);
      if (index != -1) {
        setState(() {
          _messages[index] = _messages[index].copyWith(content: errorText, isStreaming: false);
          _errorMessageIds.add(placeholderId);
        });
      }
    } finally {
      final index = _messages.indexWhere((m) => m.id == placeholderId);
      if (index != -1 && !_errorMessageIds.contains(placeholderId)) {
        setState(() {
          _messages[index] = _messages[index].copyWith(isStreaming: false);
        });
      }
      setState(() => _isSending = false);
    }
  }

  void _rewrite(MessageEntity assistantMessage) {
    final index = _messages.indexWhere((m) => m.id == assistantMessage.id);
    if (index <= 0) return;

    final userMessage = _messages[index - 1];
    if (userMessage.role != MessageRole.user) return;

    setState(() {
      _messages.removeRange(index - 1, _messages.length);
    });

    _send(userMessage.content);
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('No API key set') || msg.contains('No API key provided')) {
      return 'No API key set for this provider. Open the menu → API Providers to add one.';
    }
    return msg
        .replaceFirst('Exception: ', '')
        .replaceFirst('StateError: ', '')
        .replaceFirst('HttpException: ', '');
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
                child: _isLoadingHistory
                    ? const Center(child: CircularProgressIndicator(color: AppColors.accentBlue))
                    : _messages.isEmpty
                        ? const _EmptyChatState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final message = _messages[index];
                              final isError = _errorMessageIds.contains(message.id);

                              return ChatMessageBubble(
                                message: message,
                                isError: isError,
                                onRewrite: (!isError && message.role == MessageRole.assistant && !message.isStreaming)
                                    ? () => _rewrite(message)
                                    : null,
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
