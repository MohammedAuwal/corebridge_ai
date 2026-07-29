import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/di/providers.dart';
import '../../core/providers/conversation_provider.dart';
import '../../core/providers/selected_model_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/cancel_token.dart';
import '../../domain/entities/ai_stream_event.dart';
import '../../domain/entities/chat_attachment.dart';
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
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  bool _isLoadingHistory = false;
  bool _showScrollToBottom = false;
  String? _conversationId;
  Future<void>? _conversationCreation;
  CancelToken? _activeCancelToken;

  static const double _scrollButtonThreshold = 200;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);

    _conversationId = ref.read(activeConversationIdProvider);

    if (_conversationId != null) {
      _loadExistingConversation(_conversationId!);
    }

    if (!ref.read(defaultProviderAppliedProvider)) {
      _applyDefaultProviderIfSet();
    }

    final draft = ref.read(draftMessageProvider);
    if (draft.trim().isNotEmpty) {
      ref.read(draftMessageProvider.notifier).state = '';
      WidgetsBinding.instance.addPostFrameCallback((_) => _send(draft, []));
    }
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final distanceFromBottom = _scrollController.position.maxScrollExtent - _scrollController.offset;
    final shouldShow = distanceFromBottom > _scrollButtonThreshold;
    if (shouldShow != _showScrollToBottom) {
      setState(() => _showScrollToBottom = shouldShow);
    }
  }

  void _scrollToBottom({bool animate = true}) {
    if (!_scrollController.hasClients) return;
    final target = _scrollController.position.maxScrollExtent;
    if (animate) {
      _scrollController.animateTo(target, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      _scrollController.jumpTo(target);
    }
  }

  /// If the user set a default provider in API Providers, switch the
  /// picker to it once per app session. Runs regardless of whether a
  /// default is found, so we don't keep re-fetching on every ChatScreen
  /// visit — see defaultProviderAppliedProvider's doc comment.
  Future<void> _applyDefaultProviderIfSet() async {
    final uid = ref.read(firebaseServiceProvider).currentUserId;
    if (uid == null) return;

    try {
      final apiKeys = await ref.read(userSettingsRepositoryProvider).getApiKeys(uid);
      final defaultProvider = apiKeys.defaultProvider;
      if (defaultProvider != null && defaultProvider.isNotEmpty) {
        final match = availableModels.where((m) => m.provider == defaultProvider);
        if (match.isNotEmpty) {
          ref.read(selectedModelProvider.notifier).state = match.first;
        }
      }
    } finally {
      ref.read(defaultProviderAppliedProvider.notifier).state = true;
    }
  }

  Future<void> _loadExistingConversation(String conversationId) async {
    setState(() => _isLoadingHistory = true);
    try {
      final messages = await ref.read(conversationRepositoryProvider).watchMessages(conversationId).first;
      if (mounted) {
        setState(() {
          _messages.clear();
          _messages.addAll(messages);
        });
        // Resuming from History should land on the last message, not
        // the top of a long conversation — jump (no animation) since
        // this is an initial load, not a live update.
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom(animate: false));
      }
    } finally {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  String _titleFrom(String firstMessage) {
    final oneLine = firstMessage.replaceAll('\n', ' ').trim();
    if (oneLine.length <= 48) return oneLine;
    return '${oneLine.substring(0, 48).trim()}…';
  }

  Future<void> _send(String text, List<ChatAttachment> attachments) async {
    if (text.trim().isEmpty && attachments.isEmpty) return;
    if (_isSending) return;

    final uid = ref.read(firebaseServiceProvider).currentUserId;
    if (uid == null) return;

    final selectedModel = ref.read(selectedModelProvider);
    final thinkingEnabled = selectedModel.supportsThinking && ref.read(thinkingModeEnabledProvider);

    if (_conversationId == null) {
      if (_conversationCreation != null) {
        await _conversationCreation;
      } else {
        _conversationCreation = ref.read(conversationRepositoryProvider).createConversation(
              ownerId: uid,
              title: _titleFrom(text.isEmpty ? 'Image' : text),
            ).then((result) {
          result.when(
            success: (conversation) {
              _conversationId = conversation.id;
              ref.read(activeConversationIdProvider.notifier).state = conversation.id;
            },
            error: (failure) {
              _conversationId = 'local-${DateTime.now().millisecondsSinceEpoch}';
            },
          );
        });
        await _conversationCreation;
      }
    }

    final userMessageId = DateTime.now().millisecondsSinceEpoch.toString();

    setState(() {
      _isSending = true;
      _messages.add(MessageEntity(
        id: userMessageId,
        conversationId: _conversationId!,
        role: MessageRole.user,
        content: text,
        attachments: attachments,
        createdAt: DateTime.now(),
      ));
    });
    // Sending is a deliberate user action — always follow to the bottom
    // for it, regardless of where they'd scrolled to.
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

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

    final cancelToken = CancelToken();
    _activeCancelToken = cancelToken;

    final sendMessageUseCase = ref.read(sendMessageUseCaseProvider);

    try {
      await for (final AiStreamEvent event in sendMessageUseCase(
        uid: uid,
        conversationId: _conversationId!,
        userMessage: text,
        history: cleanHistory,
        provider: selectedModel.provider,
        attachments: attachments,
        thinkingEnabled: thinkingEnabled,
        cancelToken: cancelToken,
      )) {
        final index = _messages.indexWhere((m) => m.id == placeholderId);
        if (index == -1) continue;

        if (event.type == AiStreamEventType.thinking) {
          setState(() {
            _messages[index] = _messages[index].copyWith(
              thinking: _messages[index].thinking + event.text,
              isThinkingStreaming: true,
            );
          });
        } else {
          setState(() {
            _messages[index] = _messages[index].copyWith(
              content: _messages[index].content + event.text,
              isThinkingStreaming: false,
            );
          });
        }

        // Only auto-follow the streaming reply if the user is already
        // near the bottom — if they've scrolled up to reread something
        // earlier, we shouldn't yank them back down mid-response.
        if (!_showScrollToBottom) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom(animate: false));
        }
      }
    } catch (e) {
      final index = _messages.indexWhere((m) => m.id == placeholderId);
      final errorText = _friendlyError(e);
      if (index != -1) {
        setState(() {
          _messages[index] = _messages[index].copyWith(content: errorText, isStreaming: false, isThinkingStreaming: false);
          _errorMessageIds.add(placeholderId);
        });
      }
    } finally {
      final index = _messages.indexWhere((m) => m.id == placeholderId);
      if (index != -1) {
        setState(() {
          _messages[index] = _messages[index].copyWith(
            isStreaming: false,
            isThinkingStreaming: false,
            wasStopped: cancelToken.isCancelled && !_errorMessageIds.contains(placeholderId),
          );
        });
      }
      _activeCancelToken = null;
      setState(() => _isSending = false);
    }
  }

  void _stopGenerating() {
    _activeCancelToken?.cancel();
  }

  void _rewrite(MessageEntity assistantMessage) {
    final index = _messages.indexWhere((m) => m.id == assistantMessage.id);
    if (index <= 0) return;

    final userMessage = _messages[index - 1];
    if (userMessage.role != MessageRole.user) return;

    setState(() {
      _messages.removeRange(index - 1, _messages.length);
    });

    _send(userMessage.content, userMessage.attachments);
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('No API key set') || msg.contains('No API key provided')) {
      return 'No API key set for this provider. Open the menu → API Providers to add one.';
    }
    return msg.replaceFirst('Exception: ', '').replaceFirst('StateError: ', '').replaceFirst('HttpException: ', '');
  }

  @override
  void dispose() {
    _activeCancelToken?.cancel();
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
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
                child: Stack(
                  children: [
                    _isLoadingHistory
                        ? const Center(child: CircularProgressIndicator(color: AppColors.accentBlue))
                        : _messages.isEmpty
                            ? const _EmptyChatState()
                            : ListView.builder(
                                controller: _scrollController,
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
                    if (_showScrollToBottom)
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: _ScrollToBottomButton(onTap: () => _scrollToBottom()),
                      ),
                  ],
                ),
              ),
              ChatComposer(
                onSend: _send,
                isSending: _isSending,
                onStop: _stopGenerating,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScrollToBottomButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ScrollToBottomButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceRaised,
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.accentBlue, size: 24),
        ),
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
            Text('Ask anything, attach an image, or pick a model above to get started.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
