import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/practice/practice_setup_screen.dart';
import '../screens/practice/practice_session_screen.dart';
import '../screens/progress/progress_screen.dart';
import '../screens/admin/admin_home_screen.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (context, state) => const SignUpScreen()),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
        routes: [
          GoRoute(
            path: 'practice',
            builder: (context, state) => const PracticeSetupScreen(),
            routes: [
              GoRoute(
                path: ':sessionId',
                builder: (context, state) => PracticeSessionScreen(
                  sessionId: state.pathParameters['sessionId']!,
                ),
              ),
            ],
          ),
          GoRoute(path: 'progress', builder: (context, state) => const ProgressScreen()),
          GoRoute(path: 'admin', builder: (context, state) => const AdminHomeScreen()),
        ],
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      final bool loggedIn = auth.value != null;
      final String path = state.matchedLocation;   // ← THIS IS THE CORRECT PROPERTY (works on all GoRouter versions)

      final bool isLoggingIn = path == '/login' || path == '/signup';

      if (!loggedIn && !isLoggingIn) return '/login';
      if (loggedIn && isLoggingIn) return '/';
      return null;
    },
  );
});