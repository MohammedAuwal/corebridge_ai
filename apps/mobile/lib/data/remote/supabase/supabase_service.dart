import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient client;

  SupabaseService(this.client);

  static const String filesBucket = 'files';

  Future<String> uploadFile({
    required String path,
    required Uint8List bytes,
    String? contentType,
  }) async {
    await client.storage.from(filesBucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );
    return path;
  }

  Future<String> createSignedUrl(String path, {int expiresInSeconds = 3600}) {
    return client.storage.from(filesBucket).createSignedUrl(path, expiresInSeconds);
  }

  Future<void> deleteFile(String path) {
    return client.storage.from(filesBucket).remove([path]);
  }
}
