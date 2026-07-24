import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../core/error/failures.dart';
import '../../domain/entities/app_file_entity.dart';
import '../../domain/repositories/file_repository.dart';
import '../remote/supabase/supabase_service.dart';

class FileRepositoryImpl implements FileRepository {
  final FirebaseFirestore _firestore;
  final SupabaseService _supabaseService;
  final Uuid _uuid = const Uuid();

  FileRepositoryImpl(this._firestore, this._supabaseService);

  CollectionReference<Map<String, dynamic>> get _files =>
      _firestore.collection(AppConstants.filesCollection);

  @override
  Stream<List<AppFileEntity>> watchFiles(String ownerId, {String? projectId}) {
    Query<Map<String, dynamic>> query = _files.where('ownerId', isEqualTo: ownerId);
    if (projectId != null) {
      query = query.where('projectId', isEqualTo: projectId);
    }
    return query.orderBy('createdAt', descending: true).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => AppFileEntity.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  @override
  Future<Result<AppFileEntity>> uploadFile({
    required String ownerId,
    String? projectId,
    required String fileName,
    required Uint8List bytes,
    List<String> tags = const [],
  }) async {
    try {
      final storagePath = '$ownerId/${_uuid.v4()}-$fileName';
      await _supabaseService.uploadFile(path: storagePath, bytes: bytes);

      final now = DateTime.now();
      final entity = AppFileEntity(
        id: '',
        ownerId: ownerId,
        projectId: projectId,
        name: fileName,
        storagePath: storagePath,
        sizeBytes: bytes.length,
        tags: tags,
        createdAt: now,
      );

      final docRef = await _files.add(entity.toMap());
      return Result.success(AppFileEntity.fromMap(docRef.id, entity.toMap()));
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<String>> getSignedUrl(String storagePath) async {
    try {
      final url = await _supabaseService.createSignedUrl(storagePath);
      return Result.success(url);
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteFile(String fileId, String storagePath) async {
    try {
      await _supabaseService.deleteFile(storagePath);
      await _files.doc(fileId).delete();
      return Result.success(null);
    } catch (e) {
      return Result.failure(ServerFailure(e.toString()));
    }
  }
}
