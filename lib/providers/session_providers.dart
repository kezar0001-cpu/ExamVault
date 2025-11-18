import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/session_service.dart';
import '../models/session.dart';

/// Provider for [SessionService].
final sessionServiceProvider = Provider<SessionService>((ref) => SessionService());

/// Stream provider returning all sessions for a given user ID.
final sessionsForUserProvider =
    StreamProvider.family<List<Session>, String>((ref, userId) {
  final service = ref.watch(sessionServiceProvider);
  return service.sessionsForUser(userId);
});