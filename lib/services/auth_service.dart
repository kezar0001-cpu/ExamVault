import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service encapsulating authentication logic and user profile creation.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Stream of authentication state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Returns the current [User] or null if not signed in.
  User? get currentUser => _auth.currentUser;

  /// Creates a new user account with email and password.
  /// Also creates a corresponding document in the `users` collection.
  Future<UserCredential> signUp({
    required String email,
    required String password,
    String? name,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user!.uid;
    await _db.collection('users').doc(uid).set({
      'email': email,
      'name': name,
      'role': 'student',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return cred;
  }

  /// Signs in an existing user.
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// Signs out the current user.
  Future<void> signOut() => _auth.signOut();
}