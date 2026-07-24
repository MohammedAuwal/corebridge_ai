class AppConstants {
  AppConstants._();

  static const String appName = 'CoreBridge AI';

  // Firestore collection names — keep in sync with docs/ARCHITECTURE.md
  static const String usersCollection = 'users';
  static const String projectsCollection = 'projects';
  static const String conversationsCollection = 'conversations';
  static const String messagesSubcollection = 'items';
  static const String artifactsCollection = 'artifacts';
  static const String artifactVersionsSubcollection = 'versions';
  static const String filesCollection = 'files';
  static const String promptLibraryCollection = 'promptLibrary';

  // Debounce/throttle
  static const Duration autosaveDebounce = Duration(milliseconds: 800);

  // Pagination
  static const int messagePageSize = 50;

  // Hive box names
  static const String cacheBoxConversations = 'cache_conversations';
  static const String cacheBoxArtifacts = 'cache_artifacts';
  static const String pendingWritesBox = 'pending_writes';
}
