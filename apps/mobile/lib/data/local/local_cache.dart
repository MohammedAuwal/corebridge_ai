import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants/app_constants.dart';

/// Lightweight offline cache. Firestore already persists its own cache;
/// this box is specifically for queuing writes that depend on the
/// ai-router Edge Function, which Firestore's offline mode cannot cover.
class LocalCache {
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(AppConstants.pendingWritesBox);
    await Hive.openBox(AppConstants.cacheBoxConversations);
    await Hive.openBox(AppConstants.cacheBoxArtifacts);
  }

  static Box get pendingWrites => Hive.box(AppConstants.pendingWritesBox);
  static Box get conversationsCache => Hive.box(AppConstants.cacheBoxConversations);
  static Box get artifactsCache => Hive.box(AppConstants.cacheBoxArtifacts);

  static Future<void> queuePendingWrite(String key, Map<String, dynamic> payload) {
    return pendingWrites.put(key, payload);
  }

  static Future<void> clearPendingWrite(String key) {
    return pendingWrites.delete(key);
  }

  static Map<String, dynamic> allPendingWrites() {
    return Map<String, dynamic>.from(pendingWrites.toMap());
  }
}
