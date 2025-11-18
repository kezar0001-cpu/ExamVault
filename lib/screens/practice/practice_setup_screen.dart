import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_providers.dart';
import '../../providers/question_providers.dart';
import '../../providers/session_providers.dart';

/// Screen allowing the user to configure a practice session.
class PracticeSetupScreen extends ConsumerStatefulWidget {
  const PracticeSetupScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PracticeSetupScreen> createState() => _PracticeSetupScreenState();
}

class _PracticeSetupScreenState extends ConsumerState<PracticeSetupScreen> {
  final Set<String> _selectedSubjectIds = {};
  final Set<String> _selectedTopicIds = {};
  int _questionCount = 20;
  @override
  Widget build(BuildContext context) {
    final subjectsAsync = ref.watch(subjectsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Practice Setup')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select subjects:'),
            subjectsAsync.when(
              data: (subjects) {
                return Expanded(
                  child: ListView(
                    children: subjects.map((subject) {
                      final isSelected = _selectedSubjectIds.contains(subject.id);
                      return CheckboxListTile(
                        title: Text(subject.name),
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _selectedSubjectIds.add(subject.id);
                            } else {
                              _selectedSubjectIds.remove(subject.id);
                            }
                            // Clear topics if subject deselected
                            _selectedTopicIds.removeWhere((topicId) => true);
                          });
                        },
                      );
                    }).toList(),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('Failed to load subjects'),
            ),
            const SizedBox(height: 8),
            if (_selectedSubjectIds.isNotEmpty) ...[
              const Text('Topic selection is not yet implemented.'),
              const SizedBox(height: 16),
            ],
            // Number of questions input
            Row(
              children: [
                const Text('Number of questions:'),
                const SizedBox(width: 12),
                DropdownButton<int>(
                  value: _questionCount,
                  items: [10, 20, 30, 50, 100]
                      .map((n) => DropdownMenuItem<int>(value: n, child: Text('$n')))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _questionCount = value;
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                // Must select at least one topic
                if (_selectedTopicIds.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select at least one topic')),
                  );
                  return;
                }
                final user = ref.read(authServiceProvider).currentUser;
                if (user == null) return;
                final questionIds = <String>[]; // We'll query Firestore for questions but simplified later
                // Query questions for selected topics and limit to _questionCount
                final questionsStream = ref
                    .read(questionServiceProvider)
                    .questionsForTopics(topicIds: _selectedTopicIds.toList(), limit: _questionCount)
                    .first;
                final questions = await questionsStream;
                questionIds.addAll(questions.map((q) => q.id));
                // Create session
                final sessionId = await ref.read(sessionServiceProvider).createSession(
                  userId: user.uid,
                  mode: 'practice',
                  subjectIds: _selectedSubjectIds.toList(),
                  topicIds: _selectedTopicIds.toList(),
                  questionIds: questionIds,
                );
                // Navigate to practice session
                context.push('/practice/$sessionId');
              },
              child: const Text('Start Practice'),
            ),
          ],
        ),
      ),
    );
  }
}