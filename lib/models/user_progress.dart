import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents aggregated progress statistics for a user
class UserProgress {
  final String userId;
  final int totalQuestionsAttempted;
  final int totalQuestionsCorrect;
  final Map<String, SubjectProgress> subjectProgress;
  final DateTime? lastUpdated;

  const UserProgress({
    required this.userId,
    required this.totalQuestionsAttempted,
    required this.totalQuestionsCorrect,
    required this.subjectProgress,
    this.lastUpdated,
  });

  double get overallAccuracy {
    if (totalQuestionsAttempted == 0) return 0.0;
    return (totalQuestionsCorrect / totalQuestionsAttempted) * 100;
  }

  factory UserProgress.empty(String userId) {
    return UserProgress(
      userId: userId,
      totalQuestionsAttempted: 0,
      totalQuestionsCorrect: 0,
      subjectProgress: {},
    );
  }

  factory UserProgress.fromMap(String userId, Map<String, dynamic> data) {
    final subjectProgressData = data['subjectProgress'] as Map<String, dynamic>? ?? {};
    final subjectProgress = subjectProgressData.map(
      (key, value) => MapEntry(
        key,
        SubjectProgress.fromMap(value as Map<String, dynamic>),
      ),
    );

    return UserProgress(
      userId: userId,
      totalQuestionsAttempted: data['totalQuestionsAttempted'] as int? ?? 0,
      totalQuestionsCorrect: data['totalQuestionsCorrect'] as int? ?? 0,
      subjectProgress: subjectProgress,
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalQuestionsAttempted': totalQuestionsAttempted,
      'totalQuestionsCorrect': totalQuestionsCorrect,
      'subjectProgress': subjectProgress.map(
        (key, value) => MapEntry(key, value.toMap()),
      ),
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }

  UserProgress copyWith({
    int? totalQuestionsAttempted,
    int? totalQuestionsCorrect,
    Map<String, SubjectProgress>? subjectProgress,
  }) {
    return UserProgress(
      userId: userId,
      totalQuestionsAttempted: totalQuestionsAttempted ?? this.totalQuestionsAttempted,
      totalQuestionsCorrect: totalQuestionsCorrect ?? this.totalQuestionsCorrect,
      subjectProgress: subjectProgress ?? this.subjectProgress,
      lastUpdated: DateTime.now(),
    );
  }
}

/// Progress statistics for a specific subject
class SubjectProgress {
  final String subjectId;
  final int questionsAttempted;
  final int questionsCorrect;
  final Map<String, TopicProgress> topicProgress;

  const SubjectProgress({
    required this.subjectId,
    required this.questionsAttempted,
    required this.questionsCorrect,
    required this.topicProgress,
  });

  double get accuracy {
    if (questionsAttempted == 0) return 0.0;
    return (questionsCorrect / questionsAttempted) * 100;
  }

  factory SubjectProgress.empty(String subjectId) {
    return SubjectProgress(
      subjectId: subjectId,
      questionsAttempted: 0,
      questionsCorrect: 0,
      topicProgress: {},
    );
  }

  factory SubjectProgress.fromMap(Map<String, dynamic> data) {
    final topicProgressData = data['topicProgress'] as Map<String, dynamic>? ?? {};
    final topicProgress = topicProgressData.map(
      (key, value) => MapEntry(
        key,
        TopicProgress.fromMap(value as Map<String, dynamic>),
      ),
    );

    return SubjectProgress(
      subjectId: data['subjectId'] as String? ?? '',
      questionsAttempted: data['questionsAttempted'] as int? ?? 0,
      questionsCorrect: data['questionsCorrect'] as int? ?? 0,
      topicProgress: topicProgress,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subjectId': subjectId,
      'questionsAttempted': questionsAttempted,
      'questionsCorrect': questionsCorrect,
      'topicProgress': topicProgress.map(
        (key, value) => MapEntry(key, value.toMap()),
      ),
    };
  }
}

/// Progress statistics for a specific topic
class TopicProgress {
  final String topicId;
  final int questionsAttempted;
  final int questionsCorrect;

  const TopicProgress({
    required this.topicId,
    required this.questionsAttempted,
    required this.questionsCorrect,
  });

  double get accuracy {
    if (questionsAttempted == 0) return 0.0;
    return (questionsCorrect / questionsAttempted) * 100;
  }

  factory TopicProgress.fromMap(Map<String, dynamic> data) {
    return TopicProgress(
      topicId: data['topicId'] as String? ?? '',
      questionsAttempted: data['questionsAttempted'] as int? ?? 0,
      questionsCorrect: data['questionsCorrect'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'topicId': topicId,
      'questionsAttempted': questionsAttempted,
      'questionsCorrect': questionsCorrect,
    };
  }
}
