import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_providers.dart';
import '../../providers/question_providers.dart';

/// Home screen displayed after login.  Shows a welcome message, available
/// subjects and navigation to practice, progress and admin sections.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appUserAsync = ref.watch(appUserProvider);
    final subjectsAsync = ref.watch(subjectsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('ATPL Prep'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            appUserAsync.when(
              data: (user) => Text(
                'Welcome${user?.name != null ? ', ${user!.name}' : ''}!',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              loading: () => const Text('Loading user...'),
              error: (_, __) => const Text('Error loading user'),
            ),
            const SizedBox(height: 16),
            subjectsAsync.when(
              data: (subjects) {
                return Expanded(
                  child: ListView.builder(
                    itemCount: subjects.length,
                    itemBuilder: (context, index) {
                      final subject = subjects[index];
                      return ListTile(
                        title: Text(subject.name),
                        subtitle: subject.description != null
                            ? Text(subject.description!)
                            : null,
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('Failed to load subjects'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.push('/practice');
              },
              child: const Text('Start Practice'),
            ),
            ElevatedButton(
              onPressed: () {
                context.push('/progress');
              },
              child: const Text('View Progress'),
            ),
            appUserAsync.maybeWhen(
              data: (user) => user?.role == 'admin'
                  ? ElevatedButton(
                      onPressed: () {
                        context.push('/admin');
                      },
                      child: const Text('Admin Dashboard'),
                    )
                  : const SizedBox.shrink(),
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}