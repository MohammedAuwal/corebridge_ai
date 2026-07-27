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
    required String model,
    List<ChatAttachment> attachments = const [],
    bool thinkingEnabled = false,
    CancelToken? cancelToken,
  }) async* {
    final apiKeys = await _userSettingsRepository.getApiKeys(uid);
    final apiKey = apiKeys.forProvider(provider);

    if (apiKey == null || apiKey.trim().isEmpty) {
      throw StateError('No API key set for $provider. Add one in Settings → AI Providers.');
    }

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

    // Whatever was received — full or partial (if the user hit stop) —
    // gets saved. A cancelled stream returns cleanly rather than
    // throwing, so this line always runs.
    if (contentBuffer.isNotEmpty) {
      await _conversationRepository.appendMessage(
        conversationId: conversationId,
        role: MessageRole.assistant,
        content: contentBuffer.toString(),
      );
    }
  }
}
