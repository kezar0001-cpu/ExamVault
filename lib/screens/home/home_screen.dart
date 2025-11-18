import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_providers.dart';
import '../../providers/question_providers.dart';
import '../../providers/progress_providers.dart';
import '../../theme/app_theme.dart';

/// Home screen displayed after login. Shows a welcome message, progress overview,
/// available subjects and navigation to practice, progress and admin sections.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appUserAsync = ref.watch(appUserProvider);
    final subjectsAsync = ref.watch(subjectsProvider);
    final progressAsync = ref.watch(userProgressProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ExamVault'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(subjectsProvider);
          ref.invalidate(userProgressProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Welcome card
                appUserAsync.when(
                  data: (user) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome${user?.name != null ? ', ${user!.name}' : ''}!',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ready to ace your ATPL exam?',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textGray,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  loading: () => const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Loading...'),
                    ),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 16),

                // Progress overview card
                progressAsync.when(
                  data: (progress) => Card(
                    color: AppTheme.primaryBlue,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Progress',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: AppTheme.surfaceWhite,
                                ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem(
                                context,
                                'Questions',
                                '${progress.totalQuestionsAttempted}',
                                Icons.quiz,
                              ),
                              _buildStatItem(
                                context,
                                'Correct',
                                '${progress.totalQuestionsCorrect}',
                                Icons.check_circle,
                              ),
                              _buildStatItem(
                                context,
                                'Accuracy',
                                '${progress.overallAccuracy.toStringAsFixed(1)}%',
                                Icons.trending_up,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 24),

                // Quick actions
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.play_arrow,
                        title: 'Start Practice',
                        color: AppTheme.primaryBlue,
                        onTap: () => context.push('/practice'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.analytics,
                        title: 'View Progress',
                        color: AppTheme.accentBlue,
                        onTap: () => context.push('/progress'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Subjects section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Available Subjects',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                subjectsAsync.when(
                  data: (subjects) {
                    if (subjects.isEmpty) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.folder_open,
                                size: 48,
                                color: AppTheme.textGray,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No subjects available yet',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: AppTheme.textGray,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Contact an administrator to add subjects',
                                style: Theme.of(context).textTheme.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: subjects.map((subject) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.lightBlue.withOpacity(0.2),
                              child: Icon(
                                Icons.menu_book,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                            title: Text(
                              subject.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            subtitle: subject.description != null
                                ? Text(subject.description!)
                                : null,
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              // Navigate to subject detail or practice
                              context.push('/practice');
                            },
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (_, __) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Failed to load subjects',
                        style: TextStyle(color: AppTheme.errorRed),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Admin button (only for admins)
                appUserAsync.maybeWhen(
                  data: (user) => user?.role == 'admin'
                      ? OutlinedButton.icon(
                          onPressed: () => context.push('/admin'),
                          icon: const Icon(Icons.admin_panel_settings),
                          label: const Text('Admin Dashboard'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                          ),
                        )
                      : const SizedBox.shrink(),
                  orElse: () => const SizedBox.shrink(),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppTheme.surfaceWhite,
          size: 32,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.surfaceWhite,
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.surfaceWhite.withOpacity(0.9),
              ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Icon(
                icon,
                color: AppTheme.surfaceWhite,
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.surfaceWhite,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}