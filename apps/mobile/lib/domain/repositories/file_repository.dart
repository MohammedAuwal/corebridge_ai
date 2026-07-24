import 'dart:typed_data';
import '../../core/error/failures.dart';
import '../entities/app_file_entity.dart';

abstract class FileRepository {
  Stream<List<AppFileEntity>> watchFiles(String ownerId, {String? projectId});
  Future<Result<AppFileEntity>> uploadFile({
    required String ownerId,
    String? projectId,
    required String fileName,
    required Uint8List bytes,
    List<String> tags,
  });
  Future<Result<String>> getSignedUrl(String storagePath);
  Future<Result<void>> deleteFile(String fileId, String storagePath);
}
