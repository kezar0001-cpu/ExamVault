import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_progress.dart';
import '../models/session.dart';

/// Service for tracking and updating user progress statistics
class ProgressService {
  ProgressService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// Get user progress stream
  Stream<UserProgress> getUserProgress(String userId) {
    return _db
        .collection('userProgress')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return UserProgress.empty(userId);
      }
      return UserProgress.fromMap(userId, snapshot.data()!);
    });
  }

  /// Update progress after completing a session
  Future<void> updateProgressFromSession({
    required String userId,
    required String sessionId,
  }) async {
    // Get session data
    final sessionDoc = await _db.collection('sessions').doc(sessionId).get();
    if (!sessionDoc.exists) return;

    final sessionData = sessionDoc.data();
    if (sessionData == null) return;

    // Get all answers for this session
    final answersSnapshot = await _db
        .collection('sessions')
        .doc(sessionId)
        .collection('answers')
        .get();

    if (answersSnapshot.docs.isEmpty) return;

    // Calculate statistics
    final totalAnswers = answersSnapshot.docs.length;
    final correctAnswers = answersSnapshot.docs
        .where((doc) => doc.data()['isCorrect'] == true)
        .length;

    // Get subject and topic IDs from questions
    final Map<String, int> subjectAttempts = {};
    final Map<String, int> subjectCorrect = {};
    final Map<String, Map<String, int>> topicAttempts = {};
    final Map<String, Map<String, int>> topicCorrect = {};

    for (final answerDoc in answersSnapshot.docs) {
      final answerData = answerDoc.data();
      final questionRef = answerData['questionId'] as DocumentReference;
      final questionDoc = await questionRef.get();

      if (!questionDoc.exists) continue;

      final questionData = questionDoc.data() as Map<String, dynamic>;
      final subjectId = (questionData['subjectId'] as DocumentReference).id;
      final topicId = (questionData['topicId'] as DocumentReference).id;
      final isCorrect = answerData['isCorrect'] as bool;

      // Update subject stats
      subjectAttempts[subjectId] = (subjectAttempts[subjectId] ?? 0) + 1;
      if (isCorrect) {
        subjectCorrect[subjectId] = (subjectCorrect[subjectId] ?? 0) + 1;
      }

      // Update topic stats
      topicAttempts.putIfAbsent(subjectId, () => {});
      topicCorrect.putIfAbsent(subjectId, () => {});
      topicAttempts[subjectId]![topicId] =
          (topicAttempts[subjectId]![topicId] ?? 0) + 1;
      if (isCorrect) {
        topicCorrect[subjectId]![topicId] =
            (topicCorrect[subjectId]![topicId] ?? 0) + 1;
      }
    }

    // Update user progress document
    await _updateUserProgress(
      userId: userId,
      totalAttempts: totalAnswers,
      totalCorrect: correctAnswers,
      subjectAttempts: subjectAttempts,
      subjectCorrect: subjectCorrect,
      topicAttempts: topicAttempts,
      topicCorrect: topicCorrect,
    );

    // Mark session as completed and update score
    final score = totalAnswers > 0 ? (correctAnswers / totalAnswers) * 100 : 0.0;
    await _db.collection('sessions').doc(sessionId).update({
      'isCompleted': true,
      'endTime': FieldValue.serverTimestamp(),
      'score': score,
    });
  }

  Future<void> _updateUserProgress({
    required String userId,
    required int totalAttempts,
    required int totalCorrect,
    required Map<String, int> subjectAttempts,
    required Map<String, int> subjectCorrect,
    required Map<String, Map<String, int>> topicAttempts,
    required Map<String, Map<String, int>> topicCorrect,
  }) async {
    final progressRef = _db.collection('userProgress').doc(userId);

    await _db.runTransaction((transaction) async {
      final progressDoc = await transaction.get(progressRef);

      UserProgress currentProgress;
      if (progressDoc.exists && progressDoc.data() != null) {
        currentProgress = UserProgress.fromMap(userId, progressDoc.data()!);
      } else {
        currentProgress = UserProgress.empty(userId);
      }

      // Update overall stats
      final newTotalAttempts = currentProgress.totalQuestionsAttempted + totalAttempts;
      final newTotalCorrect = currentProgress.totalQuestionsCorrect + totalCorrect;

      // Update subject and topic stats
      final Map<String, SubjectProgress> newSubjectProgress = Map.from(currentProgress.subjectProgress);

      for (final subjectId in subjectAttempts.keys) {
        final currentSubjectProgress = newSubjectProgress[subjectId] ?? SubjectProgress.empty(subjectId);

        final newSubjectAttempts = currentSubjectProgress.questionsAttempted + (subjectAttempts[subjectId] ?? 0);
        final newSubjectCorrect = currentSubjectProgress.questionsCorrect + (subjectCorrect[subjectId] ?? 0);

        // Update topic stats for this subject
        final Map<String, TopicProgress> newTopicProgress = Map.from(currentSubjectProgress.topicProgress);

        final subjectTopicAttempts = topicAttempts[subjectId] ?? {};
        final subjectTopicCorrect = topicCorrect[subjectId] ?? {};

        for (final topicId in subjectTopicAttempts.keys) {
          final currentTopicProgress = newTopicProgress[topicId] ?? TopicProgress(topicId: topicId, questionsAttempted: 0, questionsCorrect: 0);

          newTopicProgress[topicId] = TopicProgress(
            topicId: topicId,
            questionsAttempted: currentTopicProgress.questionsAttempted + (subjectTopicAttempts[topicId] ?? 0),
            questionsCorrect: currentTopicProgress.questionsCorrect + (subjectTopicCorrect[topicId] ?? 0),
          );
        }

        newSubjectProgress[subjectId] = SubjectProgress(
          subjectId: subjectId,
          questionsAttempted: newSubjectAttempts,
          questionsCorrect: newSubjectCorrect,
          topicProgress: newTopicProgress,
        );
      }

      final updatedProgress = UserProgress(
        userId: userId,
        totalQuestionsAttempted: newTotalAttempts,
        totalQuestionsCorrect: newTotalCorrect,
        subjectProgress: newSubjectProgress,
        lastUpdated: DateTime.now(),
      );

      transaction.set(progressRef, updatedProgress.toMap());
    });
  }
}
