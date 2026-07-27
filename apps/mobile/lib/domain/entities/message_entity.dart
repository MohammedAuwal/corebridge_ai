import 'package:equatable/equatable.dart';
import 'chat_attachment.dart';

enum MessageRole { user, assistant, system }

class MessageEntity extends Equatable {
  final String id;
  final String conversationId;
  final MessageRole role;
  final String content;
  final String thinking;
  final bool isStreaming;
  final bool isThinkingStreaming;
  final bool wasStopped;
  final List<ChatAttachment> attachments;
  final DateTime createdAt;

  const MessageEntity({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    this.thinking = '',
    this.isStreaming = false,
    this.isThinkingStreaming = false,
    this.wasStopped = false,
    this.attachments = const [],
    required this.createdAt,
  });

  factory MessageEntity.fromMap(String id, String conversationId, Map<String, dynamic> map) {
    return MessageEntity(
      id: id,
      conversationId: conversationId,
      role: MessageRole.values.firstWhere(
        (r) => r.name == map['role'],
        orElse: () => MessageRole.user,
      ),
      content: (map['content'] as String?) ?? '',
      thinking: (map['thinking'] as String?) ?? '',
      isStreaming: (map['isStreaming'] as bool?) ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'role': role.name,
      'content': content,
      'thinking': thinking,
      'isStreaming': isStreaming,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  MessageEntity copyWith({
    String? content,
    String? thinking,
    bool? isStreaming,
    bool? isThinkingStreaming,
    bool? wasStopped,
    List<ChatAttachment>? attachments,
  }) {
    return MessageEntity(
      id: id,
      conversationId: conversationId,
      role: role,
      content: content ?? this.content,
      thinking: thinking ?? this.thinking,
      isStreaming: isStreaming ?? this.isStreaming,
      isThinkingStreaming: isThinkingStreaming ?? this.isThinkingStreaming,
      wasStopped: wasStopped ?? this.wasStopped,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, conversationId, role, content, thinking, isStreaming, isThinkingStreaming, wasStopped, attachments, createdAt];
}
