import '../../core/error/failures.dart';
import '../entities/artifact_entity.dart';
import '../repositories/artifact_repository.dart';

class CreateArtifactUseCase {
  final ArtifactRepository _repository;

  CreateArtifactUseCase(this._repository);

  Future<Result<ArtifactEntity>> call({
    required String ownerId,
    required String conversationId,
    String? projectId,
    required String title,
    required ArtifactType type,
    required String initialContent,
  }) {
    return _repository.createArtifact(
      ownerId: ownerId,
      conversationId: conversationId,
      projectId: projectId,
      title: title,
      type: type,
      initialContent: initialContent,
    );
  }
}
