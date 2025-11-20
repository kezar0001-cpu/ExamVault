import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../models/app_user.dart';

/// Single instance of AuthService
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Firebase authentication state: Stream<User?>
final firebaseAuthStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// Maps Firebase Auth user → AppUser from Firestore
/// This is the correct and final version.
final appUserProvider = StreamProvider<AppUser?>((ref) {
  final authState = ref.watch(firebaseAuthStateProvider);

  return authState.when(
    data: (firebaseUser) {
      if (firebaseUser == null) {
        return Stream.value(null);
      }

      // Return the Firestore user document stream
      return FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .snapshots()
          .map((doc) {
        final data = doc.data();
        if (data == null) return null;
        return AppUser.fromMap(doc.id, data);
      });
    },
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
  );
});
