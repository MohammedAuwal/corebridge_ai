import 'package:cloud_firestore/cloud_firestore.dart';

class UserApiKeys {
  final String? claude;
  final String? openai;
  final String? gemini;
  final String? qwen;

  const UserApiKeys({this.claude, this.openai, this.gemini, this.qwen});

  factory UserApiKeys.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const UserApiKeys();
    return UserApiKeys(
      claude: map['claude'] as String?,
      openai: map['openai'] as String?,
      gemini: map['gemini'] as String?,
      qwen: map['qwen'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (claude != null) 'claude': claude,
      if (openai != null) 'openai': openai,
      if (gemini != null) 'gemini': gemini,
      if (qwen != null) 'qwen': qwen,
    };
  }

  String? forProvider(String provider) {
    switch (provider) {
      case 'claude':
        return claude;
      case 'openai':
        return openai;
      case 'gemini':
        return gemini;
      case 'qwen':
        return qwen;
      default:
        return null;
    }
  }

  UserApiKeys copyWith({String? claude, String? openai, String? gemini, String? qwen}) {
    return UserApiKeys(
      claude: claude ?? this.claude,
      openai: openai ?? this.openai,
      gemini: gemini ?? this.gemini,
      qwen: qwen ?? this.qwen,
    );
  }
}

class UserSettingsRepository {
  final FirebaseFirestore _firestore;

  UserSettingsRepository(this._firestore);

  Future<UserApiKeys> getApiKeys(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return const UserApiKeys();
    return UserApiKeys.fromMap(doc.data()?['apiKeys'] as Map<String, dynamic>?);
  }

  Future<void> saveApiKeys(String uid, UserApiKeys apiKeys) async {
    await _firestore.collection('users').doc(uid).set({
      'apiKeys': apiKeys.toMap(),
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    }, SetOptions(merge: true));
  }
}
