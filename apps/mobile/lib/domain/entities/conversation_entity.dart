import 'package:equatable/equatable.dart';

class ConversationEntity extends Equatable {
  final String id;
  final String ownerId;
  final String? projectId;
  final String title;
  final List<String> pinnedMessageIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ConversationEntity({
    required this.id,
    required this.ownerId,
    this.projectId,
    required this.title,
    this.pinnedMessageIds = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory ConversationEntity.fromMap(String id, Map<String, dynamic> map) {
    return ConversationEntity(
      id: id,
      ownerId: map['ownerId'] as String,
      projectId: map['projectId'] as String?,
      title: (map['title'] as String?) ?? 'Untitled conversation',
      pinnedMessageIds: List<String>.from(map['pinnedMessageIds'] as List? ?? []),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'projectId': projectId,
      'title': title,
      'pinnedMessageIds': pinnedMessageIds,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  @override
  List<Object?> get props =>
      [id, ownerId, projectId, title, pinnedMessageIds, createdAt, updatedAt];
}
