import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/remote/cloudinary/cloudinary_service.dart';
import '../../data/remote/firebase/firebase_service.dart';
import '../../data/remote/supabase/supabase_service.dart';
import '../../data/repositories_impl/artifact_repository_impl.dart';
import '../../data/repositories_impl/conversation_repository_impl.dart';
import '../../data/repositories_impl/file_repository_impl.dart';
import '../../data/repositories_impl/project_repository_impl.dart';
import '../../domain/repositories/artifact_repository.dart';
import '../../domain/repositories/conversation_repository.dart';
import '../../domain/repositories/file_repository.dart';
import '../../domain/repositories/project_repository.dart';
import '../../domain/usecases/create_artifact_usecase.dart';
import '../../domain/usecases/send_message_usecase.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);
final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);
final supabaseClientProvider = Provider<SupabaseClient>((ref) => Supabase.instance.client);

final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService(
    auth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
  );
});

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService(ref.watch(supabaseClientProvider));
});

final cloudinaryServiceProvider = Provider<CloudinaryService>((ref) {
  // Replace with your Cloudinary cloud name at build time (--dart-define).
  const cloudName = String.fromEnvironment('CLOUDINARY_CLOUD_NAME', defaultValue: '');
  return const CloudinaryService(cloudName);
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseServiceProvider).authStateChanges;
});

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return ProjectRepositoryImpl(ref.watch(firestoreProvider));
});

final conversationRepositoryProvider = Provider<ConversationRepository>((ref) {
  return ConversationRepositoryImpl(
    ref.watch(firestoreProvider),
    ref.watch(supabaseClientProvider),
  );
});

final artifactRepositoryProvider = Provider<ArtifactRepository>((ref) {
  return ArtifactRepositoryImpl(ref.watch(firestoreProvider));
});

final fileRepositoryProvider = Provider<FileRepository>((ref) {
  return FileRepositoryImpl(
    ref.watch(firestoreProvider),
    ref.watch(supabaseServiceProvider),
  );
});

final sendMessageUseCaseProvider = Provider<SendMessageUseCase>((ref) {
  return SendMessageUseCase(ref.watch(conversationRepositoryProvider));
});

final createArtifactUseCaseProvider = Provider<CreateArtifactUseCase>((ref) {
  return CreateArtifactUseCase(ref.watch(artifactRepositoryProvider));
});
