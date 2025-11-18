import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/question.dart';
import '../../providers/question_providers.dart';
import '../../providers/session_providers.dart';
import '../../providers/auth_providers.dart';
import '../../services/session_service.dart';
import '../../services/question_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Screen displaying a practice session question by question.
class PracticeSessionScreen extends ConsumerStatefulWidget {
  final String sessionId;
  const PracticeSessionScreen({Key? key, required this.sessionId}) : super(key: key);

  @override
  ConsumerState<PracticeSessionScreen> createState() => _PracticeSessionScreenState();
}

class _PracticeSessionScreenState extends ConsumerState<PracticeSessionScreen> {
  List<Question>? _questions;
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    // Fetch the session document to get question IDs
    final sessionDoc = await FirebaseFirestore.instance
        .collection('sessions')
        .doc(widget.sessionId)
        .get();
    final data = sessionDoc.data();
    if (data == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    final List refs = data['questionIds'] as List;
    final questionIds = refs.map((ref) => (ref as DocumentReference).id).toList();
    // Query questions
    final questionsQuery = FirebaseFirestore.instance
        .collection('questions')
        .where(FieldPath.documentId, whereIn: questionIds)
        .get();
    final snapshot = await questionsQuery;
    final questions = snapshot.docs
        .map((doc) => Question.fromMap(doc.id, doc.data()))
        .toList();
    setState(() {
      _questions = questions;
      _isLoading = false;
    });
  }

  void _answerQuestion(int selectedIndex) async {
    if (_questions == null) return;
    final question = _questions![_currentIndex];
    final isCorrect = question.options[selectedIndex].isCorrect;
    final sessionService = ref.read(sessionServiceProvider);
    setState(() {
      _isSubmitting = true;
    });
    await sessionService.saveAnswer(
      sessionId: widget.sessionId,
      questionId: question.id,
      selectedIndex: selectedIndex,
      isCorrect: isCorrect,
    );
    setState(() {
      _isSubmitting = false;
      // Move to next question or finish
      if (_currentIndex < _questions!.length - 1) {
        _currentIndex++;
      } else {
        // Completed session
        _showCompletionDialog();
      }
    });
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Session Complete'),
        content: const Text('You have completed the practice session.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_questions == null || _questions!.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('No questions available.')),
      );
    }
    final question = _questions![_currentIndex];
    return Scaffold(
      appBar: AppBar(
        title: Text('Question ${_currentIndex + 1} of ${_questions!.length}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(question.text, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (question.imageUrls != null)
              ...question.imageUrls!.map((url) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: CachedNetworkImage(
                      imageUrl: url,
                      placeholder: (context, url) => const CircularProgressIndicator(),
                      errorWidget: (context, url, error) => const Icon(Icons.error),
                    ),
                  )),
            const SizedBox(height: 16),
            ...List.generate(question.options.length, (index) {
              final option = question.options[index];
              return Card(
                child: ListTile(
                  title: Text(option.text),
                  onTap: _isSubmitting ? null : () => _answerQuestion(index),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}