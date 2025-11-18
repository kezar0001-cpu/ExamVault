import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../models/app_user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Provider for [AuthService].  This ensures a single instance across the app.
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Provider exposing the raw Firebase auth state as a [Stream<User?>].
final firebaseAuthStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// Provider that maps the Firebase user into an [AppUser] by loading the
/// corresponding document from Firestore.  When the user signs out, it
/// automatically emits `null`.
final appUserProvider = StreamProvider<AppUser?>((ref) {
  final authState = ref.watch(firebaseAuthStateProvider);
  final userService = UserService();
  return authState.when(
    data: (user) {
      if (user == null) {
        return Stream.value(null);
      }
      return ref.watch(userDocumentProvider(user.uid).stream);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

/// Internal provider that watches a single user document by uid.  This is
/// separate so that multiple parts of the app can watch the same user
/// document without reloading it.
/// Stream provider watching a user document in Firestore.
/// It emits `AppUser?` so it can return null if the document is missing.
final userDocumentProvider = StreamProvider.family<AppUser?, String>((ref, uid) {
  final docStream = FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .snapshots();
  return docStream.map((doc) {
    final data = doc.data();
    if (data == null) return null;
    return AppUser.fromMap(doc.id, data);
  });
});