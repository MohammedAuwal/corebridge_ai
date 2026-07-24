import '../../core/error/failures.dart';
import '../entities/project_entity.dart';

abstract class ProjectRepository {
  Stream<List<ProjectEntity>> watchProjects(String ownerId);
  Future<Result<ProjectEntity>> createProject({
    required String ownerId,
    required String name,
    required String description,
  });
  Future<Result<void>> deleteProject(String projectId);
}
