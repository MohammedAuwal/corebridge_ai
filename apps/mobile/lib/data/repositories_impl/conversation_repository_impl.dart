import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../core/error/failures.dart';
import '../../core/network/api_client.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/conversation_repository.dart';

class ConversationRepositoryImpl implements ConversationRepository {
  final FirebaseFirestore _firestore;
  final AiRouterClient _aiRouter;

  ConversationRepositoryImpl(this._firestore, String supabaseFunctionsBaseUrl)
      : _aiRouter = AiRouterClient(supabaseFunctionsBaseUrl);

  CollectionReference<Map<String, dynamic>> get _conversations =>
      _firestore.collection(AppConstants.conversationsCollection);

  @override
  Stream<List<ConversationEntity>> watchConversations(String ownerId, {String? projectId}) {
    Query<Map<String, dynamic>> query =
        _conversations.where('ownerId', isEqualTo: ownerId);
    if (projectId != null) {
      query = query.where('projectId', isEqualTo: projectId);
    }
    return query.orderBy('updatedAt', descending: true).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => ConversationEntity.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  @override
  Stream<List<MessageEntity>> watchMessages(String conversationId, {int limit = AppConstants.messagePageSize}) {
    return _conversations
        .doc(conversationId)
        .collection(AppConstants.messagesSubcollection)
        .orderBy('createdAt', descending: false)
        .limitToLast(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageEntity.fromMap(doc.id, conversationId, doc.data()))
            .toList());
  }

  @override
  Future<Result<ConversationEntity>> createConversation({
    required String ownerId,
    String? projectId,
    required String title,
  }) async {
    try {
      final now = DateTime.now();
      final data = ConversationEntity(
        id: '',
        ownerId: ownerId,
        projectId: projectId,
        title: title,
        createdAt: now,
        updatedAt: now,
      ).toMap();
      final docRef = await _conversations.add(data);
      return Result.success(ConversationEntity.fromMap(docRef.id, data));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<MessageEntity>> appendMessage({
    required String conversationId,
    required MessageRole role,
    required String content,
  }) async {
    try {
      final now = DateTime.now();
      final entity = MessageEntity(
        id: '',
        conversationId: conversationId,
        role: role,
        content: content,
        createdAt: now,
      );
      final docRef = await _conversations
          .doc(conversationId)
          .collection(AppConstants.messagesSubcollection)
          .add(entity.toMap());

      await _conversations.doc(conversationId).update({
        'updatedAt': now.millisecondsSinceEpoch,
      });

      return Result.success(MessageEntity.fromMap(docRef.id, conversationId, entity.toMap()));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<String> streamAssistantReply({
    required String conversationId,
    required String provider,
    required String model,
    required List<Map<String, String>> messages,
    required String apiKey,
  }) {
    return _aiRouter.streamCompletion(
      provider: provider,
      model: model,
      messages: messages,
      apiKey: apiKey,
    );
  }
}
