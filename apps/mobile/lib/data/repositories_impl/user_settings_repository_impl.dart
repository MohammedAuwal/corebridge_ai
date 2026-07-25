import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_api_keys.dart';
import '../../domain/repositories/user_settings_repository.dart';

class UserSettingsRepositoryImpl implements UserSettingsRepository {
  final FirebaseFirestore _firestore;

  UserSettingsRepositoryImpl(this._firestore);

  @override
  Future<UserApiKeys> getApiKeys(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists || doc.data() == null) return const UserApiKeys();

    final data = doc.data()!;
    if (!data.containsKey('apiKeys') || data['apiKeys'] == null) {
      return const UserApiKeys();
    }

    // Bulletproof cast: forces Firestore's internal map type into a standard Dart Map
    // so it never silently drops your keys during the read process.
    final apiKeysMap = Map<String, dynamic>.from(data['apiKeys'] as Map);
    return UserApiKeys.fromMap(apiKeysMap);
  }

  @override
  Future<void> saveApiKeys(String uid, UserApiKeys apiKeys) async {
    await _firestore.collection('users').doc(uid).set({
      'apiKeys': apiKeys.toMap(),
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    }, SetOptions(merge: true));
  }
}
