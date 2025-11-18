import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/question.dart';
import '../../services/session_service.dart';
import '../../services/progress_service.dart';
import '../../providers/session_providers.dart';
import '../../providers/progress_providers.dart';
import '../../providers/auth_providers.dart';
import '../../utils/list_utils.dart';
import '../../theme/app_theme.dart';

/// Enhanced practice session screen with modern UI and comprehensive features
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

  // Track answers and state
  Map<int, int> _userAnswers = {}; // questionIndex -> selectedOptionIndex
  Map<int, bool> _answerResults = {}; // questionIndex -> isCorrect
  int? _selectedOption; // Currently selected option for current question
  bool _hasAnsweredCurrent = false; // Whether current question has been answered
  bool _showResults = false; // Whether to show final results screen
  bool _isReviewMode = false; // Whether in review mode

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final sessionDoc = await FirebaseFirestore.instance
          .collection('sessions')
          .doc(widget.sessionId)
          .get();

      final data = sessionDoc.data();
      if (data == null) {
        setState(() => _isLoading = false);
        return;
      }

      final List refs = data['questionIds'] as List? ?? [];
      final questionIds = refs.map((ref) => (ref as DocumentReference).id).toList();

      if (questionIds.isEmpty) {
        setState(() {
          _questions = const [];
          _isLoading = false;
        });
        return;
      }

      // Fetch questions in chunks
      final questionCollection = FirebaseFirestore.instance.collection('questions');
      final chunks = chunkList(questionIds, size: 10);
      final snapshots = await Future.wait(
        chunks.map((chunk) {
          return questionCollection
              .where(FieldPath.documentId, whereIn: chunk)
              .get();
        }),
      );

      final questionMap = <String, Question>{};
      for (final snapshot in snapshots) {
        for (final doc in snapshot.docs) {
          final data = doc.data();
          questionMap[doc.id] = Question.fromMap(doc.id, data);
        }
      }

      final questions = questionIds
          .map((id) => questionMap[id])
          .whereType<Question>()
          .toList();

      setState(() {
        _questions = questions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading questions: $e')),
        );
      }
    }
  }

  void _selectOption(int optionIndex) {
    if (_hasAnsweredCurrent) return; // Can't change answer after answering
    setState(() {
      _selectedOption = optionIndex;
    });
  }

  Future<void> _submitAnswer() async {
    if (_selectedOption == null || _hasAnsweredCurrent) return;

    final question = _questions![_currentIndex];
    final isCorrect = question.options[_selectedOption!].isCorrect;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Save answer to Firebase
      final sessionService = ref.read(sessionServiceProvider);
      await sessionService.saveAnswer(
        sessionId: widget.sessionId,
        questionId: question.id,
        selectedIndex: _selectedOption!,
        isCorrect: isCorrect,
      );

      setState(() {
        _userAnswers[_currentIndex] = _selectedOption!;
        _answerResults[_currentIndex] = isCorrect;
        _hasAnsweredCurrent = true;
        _isSubmitting = false;
      });
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting answer: $e')),
        );
      }
    }
  }

  void _nextQuestion() {
    if (_currentIndex < _questions!.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOption = _userAnswers[_currentIndex];
        _hasAnsweredCurrent = _userAnswers.containsKey(_currentIndex);
      });
    }
  }

  void _previousQuestion() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _selectedOption = _userAnswers[_currentIndex];
        _hasAnsweredCurrent = _userAnswers.containsKey(_currentIndex);
      });
    }
  }

  Future<void> _finishSession() async {
    setState(() => _isSubmitting = true);

    try {
      // Update progress using ProgressService
      final user = ref.read(authServiceProvider).currentUser;
      if (user != null) {
        final progressService = ref.read(progressServiceProvider);
        await progressService.updateProgressFromSession(
          userId: user.uid,
          sessionId: widget.sessionId,
        );
      }

      setState(() {
        _showResults = true;
        _isSubmitting = false;
      });
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error finishing session: $e')),
        );
      }
    }
  }

  void _startReview() {
    setState(() {
      _isReviewMode = true;
      _showResults = false;
      _currentIndex = 0;
      _selectedOption = _userAnswers[0];
      _hasAnsweredCurrent = true;
    });
  }

  void _goToHome() {
    Navigator.of(context).pop();
  }

  int get _correctCount {
    return _answerResults.values.where((isCorrect) => isCorrect).length;
  }

  int get _incorrectCount {
    return _answerResults.values.where((isCorrect) => !isCorrect).length;
  }

  double get _scorePercentage {
    if (_answerResults.isEmpty) return 0.0;
    return (_correctCount / _answerResults.length) * 100;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppTheme.primaryBlue),
              const SizedBox(height: 16),
              Text(
                'Loading questions...',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textGray,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_questions == null || _questions!.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppTheme.primaryBlue,
          foregroundColor: AppTheme.surfaceWhite,
          title: const Text('Practice Session'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning_amber_rounded,
                size: 64,
                color: AppTheme.errorRed,
              ),
              const SizedBox(height: 16),
              Text(
                'No questions available',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Please try creating a new session',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textGray,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _goToHome,
                icon: const Icon(Icons.home),
                label: const Text('Go Home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: AppTheme.surfaceWhite,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show results screen
    if (_showResults) {
      return _buildResultsScreen();
    }

    // Show question screen
    return _buildQuestionScreen();
  }

  Widget _buildQuestionScreen() {
    final question = _questions![_currentIndex];
    final totalQuestions = _questions!.length;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: AppTheme.surfaceWhite,
        title: Text(_isReviewMode ? 'Review Answers' : 'Practice Session'),
        elevation: 2,
        actions: [
          if (_isReviewMode)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _showResults = true;
                  _isReviewMode = false;
                });
              },
              tooltip: 'Exit Review',
            ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          _buildProgressIndicator(totalQuestions),

          // Question content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Question card
                  _buildQuestionCard(question),

                  const SizedBox(height: 24),

                  // Answer options
                  _buildAnswerOptions(question),

                  // Feedback and explanation (shown after answering)
                  if (_hasAnsweredCurrent) ...[
                    const SizedBox(height: 24),
                    _buildFeedbackCard(question),
                  ],
                ],
              ),
            ),
          ),

          // Action buttons
          _buildActionButtons(totalQuestions),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(int totalQuestions) {
    final progress = (_currentIndex + 1) / totalQuestions;

    return Container(
      color: AppTheme.surfaceWhite,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${_currentIndex + 1} of $totalQuestions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_hasAnsweredCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _answerResults[_currentIndex]!
                        ? AppTheme.successGreen.withOpacity(0.1)
                        : AppTheme.errorRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _answerResults[_currentIndex]!
                          ? AppTheme.successGreen
                          : AppTheme.errorRed,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    _answerResults[_currentIndex]! ? 'Correct' : 'Incorrect',
                    style: TextStyle(
                      color: _answerResults[_currentIndex]!
                          ? AppTheme.successGreen
                          : AppTheme.errorRed,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppTheme.lightBlue.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(Question question) {
    return Card(
      elevation: 2,
      color: AppTheme.surfaceWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question.text,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.textBlack,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
            if (question.imageUrls != null && question.imageUrls!.isNotEmpty) ...[
              const SizedBox(height: 16),
              ...question.imageUrls!.map((url) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: url,
                    placeholder: (context, url) => Container(
                      height: 200,
                      color: AppTheme.backgroundColor,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 200,
                      color: AppTheme.backgroundColor,
                      child: Center(
                        child: Icon(Icons.error, color: AppTheme.errorRed),
                      ),
                    ),
                  ),
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerOptions(Question question) {
    final optionLabels = ['A', 'B', 'C', 'D'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(
        question.options.length > 4 ? 4 : question.options.length,
        (index) {
          final option = question.options[index];
          final isSelected = _selectedOption == index;
          final isCorrect = option.isCorrect;
          final showCorrect = _hasAnsweredCurrent && isCorrect;
          final showIncorrect = _hasAnsweredCurrent && isSelected && !isCorrect;

          Color borderColor = AppTheme.textGray.withOpacity(0.3);
          Color backgroundColor = AppTheme.surfaceWhite;

          if (showCorrect) {
            borderColor = AppTheme.successGreen;
            backgroundColor = AppTheme.successGreen.withOpacity(0.1);
          } else if (showIncorrect) {
            borderColor = AppTheme.errorRed;
            backgroundColor = AppTheme.errorRed.withOpacity(0.1);
          } else if (isSelected && !_hasAnsweredCurrent) {
            borderColor = AppTheme.primaryBlue;
            backgroundColor = AppTheme.primaryBlue.withOpacity(0.05);
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: _hasAnsweredCurrent && !_isReviewMode
                    ? null
                    : () => _selectOption(index),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: borderColor,
                      width: isSelected || showCorrect || showIncorrect ? 2 : 1.5,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      // Option label (A, B, C, D)
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: showCorrect
                              ? AppTheme.successGreen
                              : showIncorrect
                                  ? AppTheme.errorRed
                                  : isSelected
                                      ? AppTheme.primaryBlue
                                      : AppTheme.backgroundColor,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            optionLabels[index],
                            style: TextStyle(
                              color: isSelected || showCorrect || showIncorrect
                                  ? AppTheme.surfaceWhite
                                  : AppTheme.textBlack,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Option text
                      Expanded(
                        child: Text(
                          option.text,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.textBlack,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                      // Checkmark or X icon
                      if (showCorrect)
                        Icon(
                          Icons.check_circle,
                          color: AppTheme.successGreen,
                          size: 28,
                        )
                      else if (showIncorrect)
                        Icon(
                          Icons.cancel,
                          color: AppTheme.errorRed,
                          size: 28,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeedbackCard(Question question) {
    final isCorrect = _answerResults[_currentIndex]!;

    return Card(
      elevation: 3,
      color: AppTheme.surfaceWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCorrect ? AppTheme.successGreen : AppTheme.errorRed,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isCorrect ? Icons.check_circle : Icons.cancel,
                  color: isCorrect ? AppTheme.successGreen : AppTheme.errorRed,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Text(
                  isCorrect ? 'Correct!' : 'Incorrect',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: isCorrect ? AppTheme.successGreen : AppTheme.errorRed,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Explanation',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    question.explanation ?? 'No explanation available.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textBlack,
                      height: 1.5,
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

  Widget _buildActionButtons(int totalQuestions) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        top: false,
        child: _hasAnsweredCurrent
            ? Row(
                children: [
                  if (_currentIndex > 0 && _isReviewMode)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _previousQuestion,
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Previous'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryBlue,
                          side: BorderSide(color: AppTheme.primaryBlue),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  if (_currentIndex > 0 && _isReviewMode)
                    const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting
                          ? null
                          : (_currentIndex < totalQuestions - 1
                              ? _nextQuestion
                              : (_isReviewMode
                                  ? () {
                                      setState(() {
                                        _showResults = true;
                                        _isReviewMode = false;
                                      });
                                    }
                                  : _finishSession)),
                      icon: Icon(
                        _currentIndex < totalQuestions - 1
                            ? Icons.arrow_forward
                            : (_isReviewMode ? Icons.close : Icons.check_circle),
                      ),
                      label: Text(
                        _isSubmitting
                            ? 'Please wait...'
                            : (_currentIndex < totalQuestions - 1
                                ? 'Next Question'
                                : (_isReviewMode ? 'Exit Review' : 'Finish Session')),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _currentIndex < totalQuestions - 1
                            ? AppTheme.primaryBlue
                            : AppTheme.successGreen,
                        foregroundColor: AppTheme.surfaceWhite,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        disabledBackgroundColor: AppTheme.textGray,
                      ),
                    ),
                  ),
                ],
              )
            : ElevatedButton(
                onPressed: _selectedOption == null || _isSubmitting
                    ? null
                    : _submitAnswer,
                child: Text(
                  _isSubmitting ? 'Submitting...' : 'Submit Answer',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: AppTheme.surfaceWhite,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  disabledBackgroundColor: AppTheme.textGray,
                ),
              ),
      ),
    );
  }

  Widget _buildResultsScreen() {
    final totalQuestions = _questions!.length;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: AppTheme.surfaceWhite,
        title: const Text('Session Complete'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Success icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.successGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.emoji_events,
                size: 60,
                color: AppTheme.successGreen,
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'Congratulations!',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: AppTheme.textBlack,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'You\'ve completed the practice session',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textGray,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Score card
            Card(
              elevation: 4,
              color: AppTheme.surfaceWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      'Your Score',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.textGray,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${_scorePercentage.toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Divider(color: AppTheme.textGray.withOpacity(0.2)),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _buildScoreStat(
                            'Correct',
                            _correctCount.toString(),
                            AppTheme.successGreen,
                            Icons.check_circle,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 60,
                          color: AppTheme.textGray.withOpacity(0.2),
                        ),
                        Expanded(
                          child: _buildScoreStat(
                            'Incorrect',
                            _incorrectCount.toString(),
                            AppTheme.errorRed,
                            Icons.cancel,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 60,
                          color: AppTheme.textGray.withOpacity(0.2),
                        ),
                        Expanded(
                          child: _buildScoreStat(
                            'Total',
                            totalQuestions.toString(),
                            AppTheme.primaryBlue,
                            Icons.quiz,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Action buttons
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: _startReview,
                  icon: const Icon(Icons.rate_review),
                  label: const Text('Review Answers'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: AppTheme.surfaceWhite,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _goToHome,
                  icon: const Icon(Icons.home),
                  label: const Text('Go Home'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryBlue,
                    side: BorderSide(color: AppTheme.primaryBlue, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreStat(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textGray,
          ),
        ),
      ],
    );
  }
}
