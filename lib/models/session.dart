import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a study or exam session.
class Session {
  final String id;
  final String userId;
  final String mode; // 'practice' or 'exam'
  final List<String> subjectIds;
  final List<String> topicIds;
  final List<String> questionIds;
  final DateTime startTime;
  final DateTime? endTime;
  final bool isCompleted;
  final double? score;

  const Session({
    required this.id,
    required this.userId,
    required this.mode,
    required this.subjectIds,
    required this.topicIds,
    required this.questionIds,
    required this.startTime,
    this.endTime,
    this.isCompleted = false,
    this.score,
  });

  factory Session.fromMap(String id, Map<String, dynamic> data) {
    return Session(
      id: id,
      userId: (data['userId'] as DocumentReference).id,
      mode: data['mode'] as String? ?? 'practice',
      subjectIds: (data['subjectIds'] as List?)?.map((e) => (e as DocumentReference).id).toList() ?? [],
      topicIds: (data['topicIds'] as List?)?.map((e) => (e as DocumentReference).id).toList() ?? [],
      questionIds: (data['questionIds'] as List?)?.map((e) => (e as DocumentReference).id).toList() ?? [],
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp?)?.toDate(),
      isCompleted: data['isCompleted'] as bool? ?? false,
      score: (data['score'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': FirebaseFirestore.instance.collection('users').doc(userId),
      'mode': mode,
      'subjectIds': subjectIds
          .map((id) => FirebaseFirestore.instance.collection('subjects').doc(id))
          .toList(),
      'topicIds': topicIds
          .map((id) => FirebaseFirestore.instance.collection('topics').doc(id))
          .toList(),
      'questionIds': questionIds
          .map((id) => FirebaseFirestore.instance.collection('questions').doc(id))
          .toList(),
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'isCompleted': isCompleted,
      'score': score,
    };
  }
}

/// Represents a single answer to a question within a session.
class UserAnswer {
  final String id;
  final String questionId;
  final int selectedIndex;
  final bool isCorrect;
  final double? timeTaken;

  const UserAnswer({
    required this.id,
    required this.questionId,
    required this.selectedIndex,
    required this.isCorrect,
    this.timeTaken,
  });

  factory UserAnswer.fromMap(String id, Map<String, dynamic> data) {
    return UserAnswer(
      id: id,
      questionId: (data['questionId'] as DocumentReference).id,
      selectedIndex: (data['selectedIndex'] as num).toInt(),
      isCorrect: data['isCorrect'] as bool? ?? false,
      timeTaken: (data['timeTaken'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'questionId': FirebaseFirestore.instance
          .collection('questions')
          .doc(questionId),
      'selectedIndex': selectedIndex,
      'isCorrect': isCorrect,
      'timeTaken': timeTaken,
    };
  }
}