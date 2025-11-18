import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_providers.dart';

/// Admin dashboard placeholder.  Here admins can manage questions and subjects.
class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appUserAsync = ref.watch(appUserProvider);
    return appUserAsync.when(
      data: (user) {
        if (user == null || user.role != 'admin') {
          return const Scaffold(
            body: Center(child: Text('Access denied')), 
          );
        }
        return Scaffold(
          appBar: AppBar(title: const Text('Admin Dashboard')),
          body: const Center(
            child: Text(
              'Admin features are under construction. Here you will be able to add, edit and retire questions, upload images and manage subjects/topics.',
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => const Scaffold(body: Center(child: Text('Error loading user'))),
    );
  }
}