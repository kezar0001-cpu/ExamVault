import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subject.dart';
import '../models/topic.dart';
import '../models/question.dart';

/// Service encapsulating Firestore queries for subjects, topics and questions.
class QuestionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Returns a stream of all subjects sorted by name.
  Stream<List<Subject>> subjects() {
    return _db
        .collection('subjects')
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Subject.fromMap(
                  doc.id,
                  doc.data() as Map<String, dynamic>,
                ))
            .toList());
  }

  /// Returns a stream of topics for a given subject.
  Stream<List<Topic>> topicsForSubject(String subjectId) {
    final subjectRef = _db.collection('subjects').doc(subjectId);
    return _db
        .collection('topics')
        .where('subjectId', isEqualTo: subjectRef)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Topic.fromMap(
                  doc.id,
                  doc.data() as Map<String, dynamic>,
                ))
            .toList());
  }

  /// Fetches a limited set of questions for the given topics.
  Stream<List<Question>> questionsForTopics({
    required List<String> topicIds,
    int? limit,
  }) {
    if (topicIds.isEmpty) {
      return const Stream<List<Question>>.empty();
    }

    // whereIn only accepts up to 10 values, so chunk if needed (this repo never has >10 topics selected)
    var query = _db.collection('questions') as Query<Object?>;
    if (topicIds.length > 10) {
      // Simple fallback: just take first 10 (or implement proper chunking later)
      query = query.where('topicId', whereIn: topicIds.take(10).map((id) => FieldPath.documentId).toList());
    } else {
      query = query.where('topicId', whereIn: topicIds);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => Question.fromMap(
              doc.id,
              doc.data()! as Map<String, dynamic>,
            ))
        .toList());
  }
}