import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subject.dart';
import '../models/topic.dart';
import '../models/question.dart';
import '../services/question_service.dart';

/// Provider for [QuestionService].
final questionServiceProvider = Provider<QuestionService>((ref) => QuestionService());

/// Stream provider returning all subjects.
final subjectsProvider = StreamProvider<List<Subject>>((ref) {
  final service = ref.watch(questionServiceProvider);
  return service.subjects();
});

/// Stream provider returning topics for a given subject ID.
final topicsProvider = StreamProvider.family<List<Topic>, String>((ref, subjectId) {
  final service = ref.watch(questionServiceProvider);
  return service.topicsForSubject(subjectId);
});

/// Stream provider returning questions for a list of topic IDs.  You can pass
/// an empty list to receive an empty list.
final questionsProvider = StreamProvider.family<List<Question>, List<String>>((ref, topicIds) {
  final service = ref.watch(questionServiceProvider);
  return service.questionsForTopics(topicIds: topicIds);
});