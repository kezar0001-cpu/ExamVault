import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_progress.dart';
import '../../models/subject.dart';
import '../../models/topic.dart';
import '../../providers/progress_providers.dart';
import '../../providers/question_providers.dart';
import '../../theme/app_theme.dart';

/// Comprehensive statistics and progress tracking screen
class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  final Set<String> _expandedSubjects = {};

  @override
  Widget build(BuildContext context) {
    final progressAsync = ref.watch(userProgressProvider);
    final subjectsAsync = ref.watch(subjectsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress & Statistics'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(userProgressProvider);
          ref.invalidate(subjectsProvider);
        },
        child: progressAsync.when(
          data: (progress) => subjectsAsync.when(
            data: (subjects) => _buildProgressContent(context, progress, subjects),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => _buildErrorState(context, 'Error loading subjects'),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _buildErrorState(context, 'Error loading progress'),
        ),
      ),
    );
  }

  Widget _buildProgressContent(BuildContext context, UserProgress progress, List<Subject> subjects) {
    if (progress.totalQuestionsAttempted == 0) {
      return _buildEmptyState(context);
    }

    return CustomScrollView(
      slivers: [
        // Overall Statistics Card
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildOverallStatsCard(context, progress),
          ),
        ),

        // Subject Breakdown Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'Subject Breakdown',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        // Subject Cards
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final subjectId = progress.subjectProgress.keys.elementAt(index);
                final subjectProgress = progress.subjectProgress[subjectId]!;
                final subject = subjects.firstWhere(
                  (s) => s.id == subjectId,
                  orElse: () => Subject(id: subjectId, name: 'Unknown Subject'),
                );

                return _buildSubjectCard(
                  context,
                  subject,
                  subjectProgress,
                  subjects,
                );
              },
              childCount: progress.subjectProgress.length,
            ),
          ),
        ),

        // Bottom padding
        const SliverToBoxAdapter(
          child: SizedBox(height: 16),
        ),
      ],
    );
  }

  Widget _buildOverallStatsCard(BuildContext context, UserProgress progress) {
    final accuracy = progress.overallAccuracy;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryBlue, AppTheme.darkBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                color: AppTheme.surfaceWhite,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Overall Statistics',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.surfaceWhite,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Circular Progress Indicator with Accuracy
          Center(
            child: SizedBox(
              width: 140,
              height: 140,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: CircularProgressIndicator(
                      value: accuracy / 100,
                      strokeWidth: 12,
                      backgroundColor: AppTheme.surfaceWhite.withOpacity(0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.surfaceWhite),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${accuracy.toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: AppTheme.surfaceWhite,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Accuracy',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.surfaceWhite.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Stats Row
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  'Total Questions',
                  progress.totalQuestionsAttempted.toString(),
                  Icons.quiz_outlined,
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: AppTheme.surfaceWhite.withOpacity(0.3),
              ),
              Expanded(
                child: _buildStatItem(
                  context,
                  'Correct',
                  progress.totalQuestionsCorrect.toString(),
                  Icons.check_circle_outline,
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: AppTheme.surfaceWhite.withOpacity(0.3),
              ),
              Expanded(
                child: _buildStatItem(
                  context,
                  'Incorrect',
                  (progress.totalQuestionsAttempted - progress.totalQuestionsCorrect).toString(),
                  Icons.cancel_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppTheme.surfaceWhite.withOpacity(0.9),
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppTheme.surfaceWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.surfaceWhite.withOpacity(0.8),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectCard(
    BuildContext context,
    Subject subject,
    SubjectProgress subjectProgress,
    List<Subject> allSubjects,
  ) {
    final isExpanded = _expandedSubjects.contains(subject.id);
    final accuracy = subjectProgress.accuracy;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedSubjects.remove(subject.id);
                } else {
                  _expandedSubjects.add(subject.id);
                }
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.lightBlue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.book_outlined,
                          color: AppTheme.primaryBlue,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              subject.name,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${subjectProgress.questionsAttempted} questions • ${subjectProgress.questionsCorrect} correct',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textGray,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getAccuracyColor(accuracy).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${accuracy.toStringAsFixed(1)}%',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: _getAccuracyColor(accuracy),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: AppTheme.textGray,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: accuracy / 100,
                      minHeight: 8,
                      backgroundColor: AppTheme.backgroundColor,
                      valueColor: AlwaysStoppedAnimation<Color>(_getAccuracyColor(accuracy)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expandable Topic Section
          if (isExpanded && subjectProgress.topicProgress.isNotEmpty)
            _buildTopicSection(context, subjectProgress),
        ],
      ),
    );
  }

  Widget _buildTopicSection(BuildContext context, SubjectProgress subjectProgress) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor.withOpacity(0.5),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.topic_outlined,
                size: 18,
                color: AppTheme.textGray,
              ),
              const SizedBox(width: 8),
              Text(
                'Topic Breakdown',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.textGray,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Topics List
          ...subjectProgress.topicProgress.entries.map((entry) {
            final topicId = entry.key;
            final topicProgress = entry.value;
            return _buildTopicItem(context, topicId, topicProgress);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTopicItem(BuildContext context, String topicId, TopicProgress topicProgress) {
    final accuracy = topicProgress.accuracy;

    // Fetch topic details
    return ref.watch(topicsProvider(topicProgress.topicId.split('_').first)).when(
      data: (topics) {
        Topic? topic;
        try {
          topic = topics.firstWhere((t) => t.id == topicId);
        } catch (e) {
          topic = null;
        }
        final topicName = topic?.name ?? 'Topic $topicId';

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      topicName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    '${topicProgress.questionsCorrect}/${topicProgress.questionsAttempted}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textGray,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getAccuracyColor(accuracy).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${accuracy.toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _getAccuracyColor(accuracy),
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: accuracy / 100,
                  minHeight: 6,
                  backgroundColor: AppTheme.surfaceWhite,
                  valueColor: AlwaysStoppedAnimation<Color>(_getAccuracyColor(accuracy)),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _buildTopicItemSkeleton(context, topicId, topicProgress),
      ),
      error: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _buildTopicItemSkeleton(context, topicId, topicProgress),
      ),
    );
  }

  Widget _buildTopicItemSkeleton(BuildContext context, String topicId, TopicProgress topicProgress) {
    final accuracy = topicProgress.accuracy;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Topic',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              '${topicProgress.questionsCorrect}/${topicProgress.questionsAttempted}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textGray,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getAccuracyColor(accuracy).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${accuracy.toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _getAccuracyColor(accuracy),
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: accuracy / 100,
            minHeight: 6,
            backgroundColor: AppTheme.surfaceWhite,
            valueColor: AlwaysStoppedAnimation<Color>(_getAccuracyColor(accuracy)),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.lightBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.assessment_outlined,
                  size: 80,
                  color: AppTheme.primaryBlue.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No Progress Yet',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textBlack,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Start practicing to track your progress and see detailed statistics here.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textGray,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  // Navigate to practice screen
                  DefaultTabController.of(context).animateTo(0);
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Practicing'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: AppTheme.errorRed.withOpacity(0.5),
              ),
              const SizedBox(height: 24),
              Text(
                'Error',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textGray,
                ),
              ),
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: () {
                  ref.invalidate(userProgressProvider);
                  ref.invalidate(subjectsProvider);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getAccuracyColor(double accuracy) {
    if (accuracy >= 80) {
      return AppTheme.successGreen;
    } else if (accuracy >= 60) {
      return AppTheme.accentBlue;
    } else if (accuracy >= 40) {
      return Colors.orange;
    } else {
      return AppTheme.errorRed;
    }
  }
}
