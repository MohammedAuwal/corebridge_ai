import 'package:equatable/equatable.dart';

enum ArtifactType { code, markdown, document, chart, diagram }

class ArtifactEntity extends Equatable {
  final String id;
  final String ownerId;
  final String conversationId;
  final String? projectId;
  final String title;
  final ArtifactType type;
  final String currentVersionId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ArtifactEntity({
    required this.id,
    required this.ownerId,
    required this.conversationId,
    this.projectId,
    required this.title,
    required this.type,
    required this.currentVersionId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ArtifactEntity.fromMap(String id, Map<String, dynamic> map) {
    return ArtifactEntity(
      id: id,
      ownerId: map['ownerId'] as String,
      conversationId: map['conversationId'] as String,
      projectId: map['projectId'] as String?,
      title: (map['title'] as String?) ?? 'Untitled artifact',
      type: ArtifactType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => ArtifactType.markdown,
      ),
      currentVersionId: map['currentVersionId'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'conversationId': conversationId,
      'projectId': projectId,
      'title': title,
      'type': type.name,
      'currentVersionId': currentVersionId,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  @override
  List<Object?> get props =>
      [id, ownerId, conversationId, projectId, title, type, currentVersionId, createdAt, updatedAt];
}
