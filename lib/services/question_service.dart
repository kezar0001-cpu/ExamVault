import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subject.dart';
import '../models/topic.dart';
import '../models/question.dart';
import '../utils/list_utils.dart';
import '../utils/stream_utils.dart';

/// Service encapsulating Firestore queries for subjects, topics and questions.
class QuestionService {
  QuestionService({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

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

    final topicRefs = topicIds.map((id) => _db.collection('topics').doc(id)).toList();
    final chunks = chunkList<DocumentReference<Map<String, dynamic>>>(topicRefs, size: 10);

    Stream<List<Question>> queryChunk(List<DocumentReference<Map<String, dynamic>>> chunk) {
      Query<Object?> query = _db.collection('questions').where('topicId', whereIn: chunk);
      if (limit != null && chunks.length == 1) {
        query = query.limit(limit);
      }
      return query.snapshots().map((snapshot) => snapshot.docs
          .map((doc) => Question.fromMap(
                doc.id,
                doc.data()! as Map<String, dynamic>,
              ))
          .toList());
    }

    final chunkStreams = chunks.map(queryChunk).toList();
    return combineLatestListStreams(chunkStreams);
  }
}