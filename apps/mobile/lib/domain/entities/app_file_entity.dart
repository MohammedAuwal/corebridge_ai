import 'package:equatable/equatable.dart';

class AppFileEntity extends Equatable {
  final String id;
  final String ownerId;
  final String? projectId;
  final String name;
  final String storagePath;
  final String? cloudinaryId;
  final int sizeBytes;
  final List<String> tags;
  final DateTime createdAt;

  const AppFileEntity({
    required this.id,
    required this.ownerId,
    this.projectId,
    required this.name,
    required this.storagePath,
    this.cloudinaryId,
    required this.sizeBytes,
    this.tags = const [],
    required this.createdAt,
  });

  factory AppFileEntity.fromMap(String id, Map<String, dynamic> map) {
    return AppFileEntity(
      id: id,
      ownerId: map['ownerId'] as String,
      projectId: map['projectId'] as String?,
      name: map['name'] as String,
      storagePath: map['storagePath'] as String,
      cloudinaryId: map['cloudinaryId'] as String?,
      sizeBytes: (map['sizeBytes'] as num?)?.toInt() ?? 0,
      tags: List<String>.from(map['tags'] as List? ?? []),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'projectId': projectId,
      'name': name,
      'storagePath': storagePath,
      'cloudinaryId': cloudinaryId,
      'sizeBytes': sizeBytes,
      'tags': tags,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  @override
  List<Object?> get props =>
      [id, ownerId, projectId, name, storagePath, cloudinaryId, sizeBytes, tags, createdAt];
}
