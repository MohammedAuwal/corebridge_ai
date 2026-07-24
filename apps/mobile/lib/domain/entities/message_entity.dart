import 'package:equatable/equatable.dart';

enum MessageRole { user, assistant, system }

class MessageEntity extends Equatable {
  final String id;
  final String conversationId;
  final MessageRole role;
  final String content;
  final bool isStreaming;
  final DateTime createdAt;

  const MessageEntity({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    this.isStreaming = false,
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
      isStreaming: (map['isStreaming'] as bool?) ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'role': role.name,
      'content': content,
      'isStreaming': isStreaming,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  MessageEntity copyWith({String? content, bool? isStreaming}) {
    return MessageEntity(
      id: id,
      conversationId: conversationId,
      role: role,
      content: content ?? this.content,
      isStreaming: isStreaming ?? this.isStreaming,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [id, conversationId, role, content, isStreaming, createdAt];
}
