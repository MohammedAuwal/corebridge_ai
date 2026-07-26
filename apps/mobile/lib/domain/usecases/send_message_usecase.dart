import '../entities/ai_stream_event.dart';
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
    bool thinkingEnabled = false,
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

    final contextMessages = [
      ...history.map((m) => {'role': m.role.name, 'content': m.content}),
      {'role': 'user', 'content': userMessage},
    ];

    final contentBuffer = StringBuffer();

    await for (final event in _conversationRepository.streamAssistantReply(
      conversationId: conversationId,
      provider: provider,
      model: model,
      messages: contextMessages,
      apiKey: apiKey,
      thinkingEnabled: thinkingEnabled,
    )) {
      if (event.type == AiStreamEventType.content) {
        contentBuffer.write(event.text);
      }
      yield event;
    }

    await _conversationRepository.appendMessage(
      conversationId: conversationId,
      role: MessageRole.assistant,
      content: contentBuffer.toString(),
    );
  }
}
