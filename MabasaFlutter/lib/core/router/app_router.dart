import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/jobs/presentation/screens/job_swipe_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/employer/dashboard/employer_dashboard_screen.dart';
import '../../features/employee/dashboard/employee_dashboard_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/jobs',
        builder: (context, state) => const JobSwipeScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/dashboard/employer',
        builder: (context, state) => const EmployerDashboardScreen(),
      ),
      GoRoute(
        path: '/dashboard/employee',
        builder: (context, state) => const EmployeeDashboardScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
    ],
  );
});
