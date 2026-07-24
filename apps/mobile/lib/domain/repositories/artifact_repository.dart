import '../../core/error/failures.dart';
import '../entities/artifact_entity.dart';

abstract class ArtifactRepository {
  Stream<List<ArtifactEntity>> watchArtifacts(String ownerId, {String? projectId});
  Future<Result<ArtifactEntity>> createArtifact({
    required String ownerId,
    required String conversationId,
    String? projectId,
    required String title,
    required ArtifactType type,
    required String initialContent,
  });
  Future<Result<void>> saveVersion({
    required String artifactId,
    required String content,
  });
  Future<Result<String>> getVersionContent({
    required String artifactId,
    required String versionId,
  });
}
