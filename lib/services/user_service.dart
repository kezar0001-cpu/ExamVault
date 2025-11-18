import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

/// Service responsible for retrieving user profiles from Firestore.
class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Fetches the [AppUser] document for the given uid.
  Future<AppUser?> fetchUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromMap(doc.id, doc.data()!);
  }
}