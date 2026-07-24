import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/project_entity.dart';
import '../../domain/repositories/project_repository.dart';

class ProjectRepositoryImpl implements ProjectRepository {
  final FirebaseFirestore _firestore;

  ProjectRepositoryImpl(this._firestore);

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(AppConstants.projectsCollection);

  @override
  Stream<List<ProjectEntity>> watchProjects(String ownerId) {
    return _collection
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProjectEntity.fromMap(doc.id, doc.data()))
            .toList());
  }

  @override
  Future<Result<ProjectEntity>> createProject({
    required String ownerId,
    required String name,
    required String description,
  }) async {
    try {
      final now = DateTime.now();
      final entity = ProjectEntity(
        id: '',
        ownerId: ownerId,
        name: name,
        description: description,
        createdAt: now,
        updatedAt: now,
      );
      final docRef = await _collection.add(entity.toMap());
      return Result.success(ProjectEntity.fromMap(docRef.id, entity.toMap()));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteProject(String projectId) async {
    try {
      await _collection.doc(projectId).delete();
      return Result.success(null);
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }
}
