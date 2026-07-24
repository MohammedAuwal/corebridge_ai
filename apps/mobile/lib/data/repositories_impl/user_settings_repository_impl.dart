import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_api_keys.dart';
import '../../domain/repositories/user_settings_repository.dart';

class UserSettingsRepositoryImpl implements UserSettingsRepository {
  final FirebaseFirestore _firestore;

  UserSettingsRepositoryImpl(this._firestore);

  @override
  Future<UserApiKeys> getApiKeys(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return const UserApiKeys();
    return UserApiKeys.fromMap(doc.data()?['apiKeys'] as Map<String, dynamic>?);
  }

  @override
  Future<void> saveApiKeys(String uid, UserApiKeys apiKeys) async {
    await _firestore.collection('users').doc(uid).set({
      'apiKeys': apiKeys.toMap(),
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    }, SetOptions(merge: true));
  }
}
