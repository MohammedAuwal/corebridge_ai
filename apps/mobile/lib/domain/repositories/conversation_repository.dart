import '../../core/error/failures.dart';
import '../entities/conversation_entity.dart';
import '../entities/message_entity.dart';

abstract class ConversationRepository {
  Stream<List<ConversationEntity>> watchConversations(String ownerId, {String? projectId});
  Stream<List<MessageEntity>> watchMessages(String conversationId, {int limit});
  Future<Result<ConversationEntity>> createConversation({
    required String ownerId,
    String? projectId,
    required String title,
  });
  Future<Result<MessageEntity>> appendMessage({
    required String conversationId,
    required MessageRole role,
    required String content,
  });
  Stream<String> streamAssistantReply({
    required String conversationId,
    required String provider,
    required String model,
    required List<Map<String, String>> messages,
    required String apiKey,
  });
}
