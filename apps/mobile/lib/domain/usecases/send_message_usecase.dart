import '../../core/utils/cancel_token.dart';
import '../entities/ai_stream_event.dart';
import '../entities/chat_attachment.dart';
import '../entities/message_entity.dart';
import '../repositories/conversation_repository.dart';
import '../repositories/user_settings_repository.dart';

class SendMessageUseCase {
  final ConversationRepository _conversationRepository;
  final UserSettingsRepository _userSettingsRepository;

  SendMessageUseCase(this._conversationRepository, this._userSettingsRepository);

  Stream<AiStreamEvent> call({
    required String uid,
    required String conversationId,
    required String userMessage,
    required List<MessageEntity> history,
    required String provider,
    List<ChatAttachment> attachments = const [],
    bool thinkingEnabled = false,
    CancelToken? cancelToken,
  }) async* {
    final apiKeys = await _userSettingsRepository.getApiKeys(uid);
    final apiKey = apiKeys.forProvider(provider);

    if (apiKey == null || apiKey.trim().isEmpty) {
      throw StateError('No API key set for $provider. Add one in Settings → AI Providers.');
    }

    // Model resolution is entirely user-owned. For providers other than
    // Qwen, the same model handles text and images. For Qwen, images
    // route to the user's detected vision-capable model instead — see
    // UserApiKeys.modelFor for why.
    final model = apiKeys.modelFor(provider, hasImages: attachments.isNotEmpty);

    await _conversationRepository.appendMessage(
      conversationId: conversationId,
      role: MessageRole.user,
      content: userMessage,
    );

    final historyMaps = history.map((m) => {'role': m.role.name, 'content': m.content}).toList();
    final contentBuffer = StringBuffer();

    await for (final event in _conversationRepository.streamAssistantReply(
      conversationId: conversationId,
      provider: provider,
      model: model,
      history: historyMaps,
      userMessage: userMessage,
      attachments: attachments,
      apiKey: apiKey,
      thinkingEnabled: thinkingEnabled,
      cancelToken: cancelToken,
    )) {
      if (event.type == AiStreamEventType.content) {
        contentBuffer.write(event.text);
      }
      yield event;
    }

    if (contentBuffer.isNotEmpty) {
      await _conversationRepository.appendMessage(
        conversationId: conversationId,
        role: MessageRole.assistant,
        content: contentBuffer.toString(),
      );
    }
  }
}
