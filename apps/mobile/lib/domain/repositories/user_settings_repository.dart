import '../entities/user_api_keys.dart';

abstract class UserSettingsRepository {
  Future<UserApiKeys> getApiKeys(String uid);
  Future<void> saveApiKeys(String uid, UserApiKeys apiKeys);
}
