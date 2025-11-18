import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_providers.dart';
import '../../providers/question_providers.dart';
import '../../providers/session_providers.dart';
import '../../models/subject.dart';
import '../../models/topic.dart';
import '../../theme/app_theme.dart';

/// Screen allowing the user to configure a practice session.
class PracticeSetupScreen extends ConsumerStatefulWidget {
  const PracticeSetupScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PracticeSetupScreen> createState() => _PracticeSetupScreenState();
}

class _PracticeSetupScreenState extends ConsumerState<PracticeSetupScreen> {
  final Set<String> _selectedSubjectIds = {};
  final Set<String> _selectedTopicIds = {};
  final Map<String, bool> _expandedSubjects = {};
  int _questionCount = 20;
  bool _isCreatingSession = false;

  @override
  Widget build(BuildContext context) {
    final subjectsAsync = ref.watch(subjectsProvider);
    final canStartPractice = _selectedTopicIds.isNotEmpty && !_isCreatingSession;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Practice Setup'),
        elevation: 0,
      ),
      body: subjectsAsync.when(
        data: (subjects) => _buildContent(context, subjects, canStartPractice),
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppTheme.errorRed,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load subjects',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<Subject> subjects, bool canStartPractice) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header section
                Text(
                  'Select Your Topics',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: AppTheme.textBlack,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose subjects and topics to practice',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textGray,
                      ),
                ),
                const SizedBox(height: 24),

                // Subjects and topics
                if (subjects.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: AppTheme.textGray,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No subjects available',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppTheme.textGray,
                                ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...subjects.map((subject) => _buildSubjectCard(subject)).toList(),

                const SizedBox(height: 24),

                // Question count selector
                _buildQuestionCountCard(),

                const SizedBox(height: 16),

                // Selection summary
                if (_selectedTopicIds.isNotEmpty) _buildSelectionSummary(),
              ],
            ),
          ),
        ),

        // Bottom button
        _buildBottomButton(canStartPractice),
      ],
    );
  }

  Widget _buildSubjectCard(Subject subject) {
    final isSelected = _selectedSubjectIds.contains(subject.id);
    final isExpanded = _expandedSubjects[subject.id] ?? false;
    final topicsAsync = ref.watch(topicsProvider(subject.id));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedSubjectIds.remove(subject.id);
                  _expandedSubjects[subject.id] = false;
                  // Remove all topics from this subject
                  topicsAsync.whenData((topics) {
                    for (var topic in topics) {
                      _selectedTopicIds.remove(topic.id);
                    }
                  });
                } else {
                  _selectedSubjectIds.add(subject.id);
                  _expandedSubjects[subject.id] = true;
                }
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Checkbox
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryBlue : AppTheme.textGray,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            size: 16,
                            color: AppTheme.surfaceWhite,
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),

                  // Subject name and description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subject.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: AppTheme.textBlack,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        if (subject.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            subject.description!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textGray,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Expand icon
                  if (isSelected)
                    IconButton(
                      icon: Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: AppTheme.primaryBlue,
                      ),
                      onPressed: () {
                        setState(() {
                          _expandedSubjects[subject.id] = !isExpanded;
                        });
                      },
                    ),
                ],
              ),
            ),
          ),

          // Topics section
          if (isSelected && isExpanded)
            Container(
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: topicsAsync.when(
                data: (topics) {
                  if (topics.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: Text(
                          'No topics available for this subject',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textGray,
                              ),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                              child: Row(
                                children: [
                                  Text(
                                    'Topics',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: AppTheme.textGray,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  const Spacer(),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        final allSelected = topics.every(
                                          (topic) => _selectedTopicIds.contains(topic.id),
                                        );
                                        if (allSelected) {
                                          // Deselect all
                                          for (var topic in topics) {
                                            _selectedTopicIds.remove(topic.id);
                                          }
                                        } else {
                                          // Select all
                                          for (var topic in topics) {
                                            _selectedTopicIds.add(topic.id);
                                          }
                                        }
                                      });
                                    },
                                    child: Text(
                                      topics.every((topic) => _selectedTopicIds.contains(topic.id))
                                          ? 'Deselect All'
                                          : 'Select All',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ...topics.map((topic) => _buildTopicItem(topic)).toList(),
                          ],
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                error: (error, stackTrace) => Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Failed to load topics: $error',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.errorRed,
                        ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopicItem(Topic topic) {
    final isSelected = _selectedTopicIds.contains(topic.id);

    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedTopicIds.remove(topic.id);
          } else {
            _selectedTopicIds.add(topic.id);
          }
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
        child: Row(
          children: [
            // Checkbox
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.accentBlue : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppTheme.accentBlue : AppTheme.textGray,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 14,
                      color: AppTheme.surfaceWhite,
                    )
                  : null,
            ),
            const SizedBox(width: 12),

            // Topic name and description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    topic.name,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textBlack,
                        ),
                  ),
                  if (topic.description != null && topic.description!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      topic.description!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textGray,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCountCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              Icons.quiz_outlined,
              color: AppTheme.primaryBlue,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Number of Questions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.textBlack,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.lightBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
              ),
              child: DropdownButton<int>(
                value: _questionCount,
                underline: const SizedBox(),
                icon: Icon(Icons.arrow_drop_down, color: AppTheme.primaryBlue),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                items: [10, 20, 30, 50]
                    .map((n) => DropdownMenuItem<int>(
                          value: n,
                          child: Text('$n'),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _questionCount = value;
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionSummary() {
    return Card(
      elevation: 2,
      color: AppTheme.lightBlue.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.primaryBlue.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: AppTheme.successGreen,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selection Summary',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.textBlack,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_selectedSubjectIds.length} subject${_selectedSubjectIds.length != 1 ? 's' : ''} • '
                    '${_selectedTopicIds.length} topic${_selectedTopicIds.length != 1 ? 's' : ''}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textGray,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton(bool canStartPractice) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: canStartPractice ? _startPractice : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: canStartPractice ? AppTheme.primaryBlue : AppTheme.textGray,
              foregroundColor: AppTheme.surfaceWhite,
              disabledBackgroundColor: AppTheme.textGray.withOpacity(0.3),
              disabledForegroundColor: AppTheme.textGray,
              elevation: canStartPractice ? 4 : 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isCreatingSession
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.surfaceWhite),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.play_arrow, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        'Start Practice',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppTheme.surfaceWhite,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _startPractice() async {
    if (_selectedTopicIds.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select at least one topic'),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      return;
    }

    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please log in to start practice'),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isCreatingSession = true;
    });

    try {
      // Query questions for selected topics and limit to _questionCount
      final questionsStream = ref
          .read(questionServiceProvider)
          .questionsForTopics(topicIds: _selectedTopicIds.toList(), limit: _questionCount)
          .first;

      final questions = await questionsStream;

      if (questions.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No questions found for the selected topics'),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        setState(() {
          _isCreatingSession = false;
        });
        return;
      }

      final questionIds = questions.map((q) => q.id).toList();

      // Create session
      final sessionId = await ref.read(sessionServiceProvider).createSession(
            userId: user.uid,
            mode: 'practice',
            subjectIds: _selectedSubjectIds.toList(),
            topicIds: _selectedTopicIds.toList(),
            questionIds: questionIds,
          );

      if (!mounted) return;

      // Navigate to practice session
      context.push('/practice/$sessionId');
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create practice session: $error'),
          backgroundColor: AppTheme.errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingSession = false;
        });
      }
    }
  }
}
