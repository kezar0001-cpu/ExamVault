import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/session.dart';

/// Service for managing practice/exam sessions and user answers.
class SessionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Creates a new session document and returns its ID.
  Future<String> createSession({
    required String userId,
    required String mode,
    required List<String> subjectIds,
    required List<String> topicIds,
    required List<String> questionIds,
  }) async {
    final docRef = await _db.collection('sessions').add({
      'userId': _db.collection('users').doc(userId),
      'mode': mode,
      'subjectIds': subjectIds
          .map((id) => _db.collection('subjects').doc(id))
          .toList(),
      'topicIds': topicIds
          .map((id) => _db.collection('topics').doc(id))
          .toList(),
      'questionIds': questionIds
          .map((id) => _db.collection('questions').doc(id))
          .toList(),
      'startTime': Timestamp.now(),
      'isCompleted': false,
    });
    return docRef.id;
  }

  /// Marks a session as completed and stores the score and end time.
  Future<void> completeSession({
    required String sessionId,
    required double score,
  }) async {
    await _db.collection('sessions').doc(sessionId).update({
      'isCompleted': true,
      'score': score,
      'endTime': Timestamp.now(),
    });
  }

  /// Adds or updates a user answer within the session's answers subcollection.
  Future<void> saveAnswer({
    required String sessionId,
    required String questionId,
    required int selectedIndex,
    required bool isCorrect,
    double? timeTaken,
  }) async {
    final answersRef = _db
        .collection('sessions')
        .doc(sessionId)
        .collection('answers');
    // Use questionId as the document ID to ensure idempotent writes
    await answersRef.doc(questionId).set({
      'questionId': _db.collection('questions').doc(questionId),
      'selectedIndex': selectedIndex,
      'isCorrect': isCorrect,
      'timeTaken': timeTaken,
    });
  }

  /// Streams all sessions for a given user ordered by start time descending.
  Stream<List<Session>> sessionsForUser(String userId) {
    final userRef = _db.collection('users').doc(userId);
    return _db
        .collection('sessions')
        .where('userId', isEqualTo: userRef)
        .orderBy('startTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Session.fromMap(doc.id, doc.data()))
            .toList());
  }
}