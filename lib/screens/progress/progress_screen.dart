import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_providers.dart';
import '../../providers/session_providers.dart';
import '../../models/session.dart';

/// Screen showing a list of completed sessions and their scores.
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authServiceProvider).currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to view progress')), 
      );
    }
    final sessionsAsync = ref.watch(sessionsForUserProvider(user.uid));
    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: sessionsAsync.when(
        data: (sessions) {
          if (sessions.isEmpty) {
            return const Center(child: Text('No sessions yet. Start practicing!'));
          }
          return ListView.builder(
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final Session session = sessions[index];
              final date = session.startTime;
              final score = session.score;
              final mode = session.mode;
              return ListTile(
                title: Text('${mode[0].toUpperCase()}${mode.substring(1)} session'),
                subtitle: Text(
                    '${date.toLocal().toString().split('.').first} • Score: ${score != null ? '${(score * 100).toStringAsFixed(1)}%' : 'n/a'}'),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Error loading progress')),
      ),
    );
  }
}