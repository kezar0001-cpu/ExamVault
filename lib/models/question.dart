import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single multiple‑choice question.
class QuestionOption {
  final String text;
  final bool isCorrect;

  const QuestionOption({required this.text, required this.isCorrect});

  factory QuestionOption.fromMap(Map<String, dynamic> data) {
    return QuestionOption(
      text: data['text'] as String? ?? '',
      isCorrect: data['isCorrect'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'isCorrect': isCorrect,
    };
  }
}

class Question {
  final String id;
  final String subjectId;
  final String topicId;
  final String text;
  final List<String>? imageUrls;
  final List<QuestionOption> options;
  final String explanation;
  final int? difficulty;
  final String? reference;
  final Map<String, bool>? flags;
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Question({
    required this.id,
    required this.subjectId,
    required this.topicId,
    required this.text,
    this.imageUrls,
    required this.options,
    required this.explanation,
    this.difficulty,
    this.reference,
    this.flags,
    required this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory Question.fromMap(String id, Map<String, dynamic> data) {
    final List optionsData = data['options'] as List? ?? [];
    return Question(
      id: id,
      subjectId: (data['subjectId'] as DocumentReference).id,
      topicId: (data['topicId'] as DocumentReference).id,
      text: data['text'] as String? ?? '',
      imageUrls: (data['imageUrls'] as List?)?.map((e) => e as String).toList(),
      options:
          optionsData.map((e) => QuestionOption.fromMap(e as Map<String, dynamic>)).toList(),
      explanation: data['explanation'] as String? ?? '',
      difficulty: (data['difficulty'] as num?)?.toInt(),
      reference: data['reference'] as String?,
      flags: (data['flags'] as Map?)?.cast<String, bool>(),
      createdBy: (data['createdBy'] as DocumentReference).id,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subjectId': FirebaseFirestore.instance.collection('subjects').doc(subjectId),
      'topicId': FirebaseFirestore.instance.collection('topics').doc(topicId),
      'text': text,
      'imageUrls': imageUrls,
      'options': options.map((e) => e.toMap()).toList(),
      'explanation': explanation,
      'difficulty': difficulty,
      'reference': reference,
      'flags': flags,
      'createdBy': FirebaseFirestore.instance.collection('users').doc(createdBy),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}