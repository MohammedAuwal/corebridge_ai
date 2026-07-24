import 'package:equatable/equatable.dart';

class ProjectEntity extends Equatable {
  final String id;
  final String ownerId;
  final String name;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProjectEntity({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProjectEntity.fromMap(String id, Map<String, dynamic> map) {
    return ProjectEntity(
      id: id,
      ownerId: map['ownerId'] as String,
      name: map['name'] as String,
      description: (map['description'] as String?) ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'name': name,
      'description': description,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  @override
  List<Object?> get props => [id, ownerId, name, description, createdAt, updatedAt];
}
