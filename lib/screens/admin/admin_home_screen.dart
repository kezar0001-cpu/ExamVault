import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_providers.dart';
import '../../theme/app_theme.dart';

/// Admin dashboard for managing questions, subjects, and topics.
/// Provides functionality to seed sample data from JSON into Firestore.
class AdminHomeScreen extends ConsumerStatefulWidget {
  const AdminHomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Statistics
  int _subjectsCount = 0;
  int _topicsCount = 0;
  int _questionsCount = 0;
  bool _loadingStats = true;

  // Loading states for operations
  bool _seedingSubjects = false;
  bool _seedingTopics = false;
  bool _seedingQuestions = false;
  bool _seedingAll = false;
  bool _clearing = false;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  /// Load current statistics from Firestore
  Future<void> _loadStatistics() async {
    setState(() => _loadingStats = true);
    try {
      final subjectsSnapshot = await _db.collection('subjects').count().get();
      final topicsSnapshot = await _db.collection('topics').count().get();
      final questionsSnapshot = await _db.collection('questions').count().get();

      setState(() {
        _subjectsCount = subjectsSnapshot.count ?? 0;
        _topicsCount = topicsSnapshot.count ?? 0;
        _questionsCount = questionsSnapshot.count ?? 0;
        _loadingStats = false;
      });
    } catch (e) {
      setState(() => _loadingStats = false);
      _showError('Failed to load statistics: $e');
    }
  }

  /// Load and parse the sample questions JSON file
  Future<Map<String, dynamic>> _loadJsonData() async {
    try {
      final jsonString = await rootBundle.loadString('assets/sample_questions.json');
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to load JSON file: $e');
    }
  }

  /// Seed subjects to Firestore
  Future<void> _seedSubjects() async {
    setState(() => _seedingSubjects = true);
    try {
      final data = await _loadJsonData();
      final subjects = data['subjects'] as List<dynamic>;

      final batch = _db.batch();
      for (final subject in subjects) {
        final subjectData = subject as Map<String, dynamic>;
        final docRef = _db.collection('subjects').doc(subjectData['id'] as String);
        batch.set(docRef, {
          'name': subjectData['name'],
          'description': subjectData['description'],
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      await _loadStatistics();
      _showSuccess('Successfully seeded ${subjects.length} subjects');
    } catch (e) {
      _showError('Failed to seed subjects: $e');
    } finally {
      setState(() => _seedingSubjects = false);
    }
  }

  /// Seed topics to Firestore
  Future<void> _seedTopics() async {
    setState(() => _seedingTopics = true);
    try {
      final data = await _loadJsonData();
      final topics = data['topics'] as List<dynamic>;

      final batch = _db.batch();
      for (final topic in topics) {
        final topicData = topic as Map<String, dynamic>;
        final docRef = _db.collection('topics').doc(topicData['id'] as String);
        batch.set(docRef, {
          'name': topicData['name'],
          'description': topicData['description'],
          'subjectId': _db.collection('subjects').doc(topicData['subjectId'] as String),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      await _loadStatistics();
      _showSuccess('Successfully seeded ${topics.length} topics');
    } catch (e) {
      _showError('Failed to seed topics: $e');
    } finally {
      setState(() => _seedingTopics = false);
    }
  }

  /// Seed questions to Firestore
  Future<void> _seedQuestions() async {
    setState(() => _seedingQuestions = true);
    try {
      final appUserAsync = ref.read(appUserProvider);
      final appUser = appUserAsync.value;

      if (appUser == null) {
        throw Exception('No authenticated user found');
      }

      final data = await _loadJsonData();
      final questions = data['questions'] as List<dynamic>;
      final topics = data['topics'] as List<dynamic>;

      // Create a map of topicId -> subjectId for easy lookup
      final Map<String, String> topicToSubject = {};
      for (final topic in topics) {
        final topicData = topic as Map<String, dynamic>;
        topicToSubject[topicData['id'] as String] = topicData['subjectId'] as String;
      }

      // Process questions in batches (Firestore batch limit is 500)
      const batchSize = 500;
      for (int i = 0; i < questions.length; i += batchSize) {
        final batch = _db.batch();
        final end = (i + batchSize < questions.length) ? i + batchSize : questions.length;

        for (int j = i; j < end; j++) {
          final question = questions[j] as Map<String, dynamic>;
          final topicId = question['topicId'] as String;
          final subjectId = topicToSubject[topicId];

          if (subjectId == null) {
            throw Exception('Subject not found for topic: $topicId');
          }

          final docRef = _db.collection('questions').doc();
          batch.set(docRef, {
            'text': question['text'],
            'topicId': _db.collection('topics').doc(topicId),
            'subjectId': _db.collection('subjects').doc(subjectId),
            'options': question['options'],
            'explanation': question['explanation'],
            'difficulty': question['difficulty'],
            'createdBy': _db.collection('users').doc(appUser.id),
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        await batch.commit();
      }

      await _loadStatistics();
      _showSuccess('Successfully seeded ${questions.length} questions');
    } catch (e) {
      _showError('Failed to seed questions: $e');
    } finally {
      setState(() => _seedingQuestions = false);
    }
  }

  /// Seed all data at once
  Future<void> _seedAllData() async {
    setState(() => _seedingAll = true);
    try {
      await _seedSubjects();
      await _seedTopics();
      await _seedQuestions();
      _showSuccess('Successfully seeded all data');
    } catch (e) {
      _showError('Failed to seed all data: $e');
    } finally {
      setState(() => _seedingAll = false);
    }
  }

  /// Clear all data from Firestore
  Future<void> _clearAllData() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'Are you sure you want to delete all subjects, topics, and questions? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _clearing = true);
    try {
      // Delete all questions
      final questionsSnapshot = await _db.collection('questions').get();
      for (final doc in questionsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete all topics
      final topicsSnapshot = await _db.collection('topics').get();
      for (final doc in topicsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete all subjects
      final subjectsSnapshot = await _db.collection('subjects').get();
      for (final doc in subjectsSnapshot.docs) {
        await doc.reference.delete();
      }

      await _loadStatistics();
      _showSuccess('Successfully cleared all data');
    } catch (e) {
      _showError('Failed to clear data: $e');
    } finally {
      setState(() => _clearing = false);
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorRed,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appUserAsync = ref.watch(appUserProvider);

    return appUserAsync.when(
      data: (user) {
        if (user == null || user.role != 'admin') {
          return const Scaffold(
            body: Center(child: Text('Access denied')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Admin Dashboard'),
            backgroundColor: AppTheme.primaryBlue,
          ),
          body: RefreshIndicator(
            onRefresh: _loadStatistics,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Statistics Card
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.analytics_outlined,
                                color: AppTheme.primaryBlue,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Database Statistics',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: AppTheme.primaryBlue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          if (_loadingStats)
                            const Center(child: CircularProgressIndicator())
                          else
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatItem('Subjects', _subjectsCount, Icons.subject),
                                _buildStatItem('Topics', _topicsCount, Icons.topic),
                                _buildStatItem('Questions', _questionsCount, Icons.quiz),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Seed Data Card
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.cloud_upload_outlined,
                                color: AppTheme.primaryBlue,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Seed Sample Data',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: AppTheme.primaryBlue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Load sample data from assets/sample_questions.json',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textGray,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Individual seed buttons
                          _buildActionButton(
                            label: 'Seed Subjects',
                            icon: Icons.subject,
                            onPressed: _seedSubjects,
                            loading: _seedingSubjects,
                            color: AppTheme.primaryBlue,
                          ),
                          const SizedBox(height: 12),
                          _buildActionButton(
                            label: 'Seed Topics',
                            icon: Icons.topic,
                            onPressed: _seedTopics,
                            loading: _seedingTopics,
                            color: AppTheme.primaryBlue,
                          ),
                          const SizedBox(height: 12),
                          _buildActionButton(
                            label: 'Seed Questions',
                            icon: Icons.quiz,
                            onPressed: _seedQuestions,
                            loading: _seedingQuestions,
                            color: AppTheme.primaryBlue,
                          ),
                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 20),

                          // Seed all button
                          _buildActionButton(
                            label: 'Seed All Data',
                            icon: Icons.cloud_done,
                            onPressed: _seedAllData,
                            loading: _seedingAll,
                            color: AppTheme.accentBlue,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Danger Zone Card
                  Card(
                    elevation: 4,
                    color: AppTheme.errorRed.withOpacity(0.05),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: AppTheme.errorRed,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Danger Zone',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: AppTheme.errorRed,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Destructive actions that cannot be undone',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textGray,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildActionButton(
                            label: 'Clear All Data',
                            icon: Icons.delete_forever,
                            onPressed: _clearAllData,
                            loading: _clearing,
                            color: AppTheme.errorRed,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const Scaffold(
        body: Center(child: Text('Error loading user')),
      ),
    );
  }

  Widget _buildStatItem(String label, int count, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryBlue, size: 32),
        const SizedBox(height: 8),
        Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppTheme.textBlack,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textGray,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required bool loading,
    required Color color,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: color.withOpacity(0.5),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(icon, size: 24),
        label: Text(
          loading ? 'Processing...' : label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}