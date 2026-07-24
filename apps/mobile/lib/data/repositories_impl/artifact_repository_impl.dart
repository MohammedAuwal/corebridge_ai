import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/artifact_entity.dart';
import '../../domain/repositories/artifact_repository.dart';

class ArtifactRepositoryImpl implements ArtifactRepository {
  final FirebaseFirestore _firestore;
  final Uuid _uuid = const Uuid();

  ArtifactRepositoryImpl(this._firestore);

  CollectionReference<Map<String, dynamic>> get _artifacts =>
      _firestore.collection(AppConstants.artifactsCollection);

  @override
  Stream<List<ArtifactEntity>> watchArtifacts(String ownerId, {String? projectId}) {
    Query<Map<String, dynamic>> query = _artifacts.where('ownerId', isEqualTo: ownerId);
    if (projectId != null) {
      query = query.where('projectId', isEqualTo: projectId);
    }
    return query.orderBy('updatedAt', descending: true).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => ArtifactEntity.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  @override
  Future<Result<ArtifactEntity>> createArtifact({
    required String ownerId,
    required String conversationId,
    String? projectId,
    required String title,
    required ArtifactType type,
    required String initialContent,
  }) async {
    try {
      final now = DateTime.now();
      final versionId = _uuid.v4();

      final artifactData = ArtifactEntity(
        id: '',
        ownerId: ownerId,
        conversationId: conversationId,
        projectId: projectId,
        title: title,
        type: type,
        currentVersionId: versionId,
        createdAt: now,
        updatedAt: now,
      ).toMap();

      final docRef = await _artifacts.add(artifactData);

      await _artifacts
          .doc(docRef.id)
          .collection(AppConstants.artifactVersionsSubcollection)
          .doc(versionId)
          .set({
        'content': initialContent,
        'createdAt': now.millisecondsSinceEpoch,
      });

      return Result.success(ArtifactEntity.fromMap(docRef.id, artifactData));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> saveVersion({
    required String artifactId,
    required String content,
  }) async {
    try {
      final versionId = _uuid.v4();
      final now = DateTime.now();

      await _artifacts
          .doc(artifactId)
          .collection(AppConstants.artifactVersionsSubcollection)
          .doc(versionId)
          .set({
        'content': content,
        'createdAt': now.millisecondsSinceEpoch,
      });

      await _artifacts.doc(artifactId).update({
        'currentVersionId': versionId,
        'updatedAt': now.millisecondsSinceEpoch,
      });

      return Result.success(null);
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<String>> getVersionContent({
    required String artifactId,
    required String versionId,
  }) async {
    try {
      final doc = await _artifacts
          .doc(artifactId)
          .collection(AppConstants.artifactVersionsSubcollection)
          .doc(versionId)
          .get();

      if (!doc.exists) {
        return Result.failure(const NotFoundFailure('Artifact version not found.'));
      }

      return Result.success(doc.data()!['content'] as String);
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }
}
