import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  FirebaseService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : auth = auth ?? FirebaseAuth.instance,
        firestore = firestore ?? FirebaseFirestore.instance;

  String? get currentUserId => auth.currentUser?.uid;

  Stream<User?> get authStateChanges => auth.authStateChanges();

  Future<UserCredential> signInWithEmail(String email, String password) {
    return auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> registerWithEmail(String email, String password) {
    return auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() => auth.signOut();
}
