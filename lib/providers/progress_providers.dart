import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/progress_service.dart';
import '../models/user_progress.dart';
import 'auth_providers.dart';

/// Provider for the progress service
final progressServiceProvider = Provider<ProgressService>((ref) {
  return ProgressService();
});

/// Provider for user progress stream
final userProgressProvider = StreamProvider<UserProgress>((ref) {
  final user = ref.watch(authServiceProvider).currentUser;
  if (user == null) {
    return Stream.value(UserProgress.empty(''));
  }
  return ref.watch(progressServiceProvider).getUserProgress(user.uid);
});
