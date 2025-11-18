import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a user within the application.  The document ID in Firestore
/// should match the Firebase Auth uid.
class AppUser {
  final String id;
  final String email;
  final String? name;
  final String role;
  final String? subscription;
  final String? country;
  final String? preferredSyllabus;

  const AppUser({
    required this.id,
    required this.email,
    this.name,
    this.role = 'student',
    this.subscription,
    this.country,
    this.preferredSyllabus,
  });

  factory AppUser.fromMap(String id, Map<String, dynamic> data) {
    return AppUser(
      id: id,
      email: data['email'] as String? ?? '',
      name: data['name'] as String?,
      role: data['role'] as String? ?? 'student',
      subscription: data['subscription'] as String?,
      country: data['country'] as String?,
      preferredSyllabus: data['preferredSyllabus'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': role,
      'subscription': subscription,
      'country': country,
      'preferredSyllabus': preferredSyllabus,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}