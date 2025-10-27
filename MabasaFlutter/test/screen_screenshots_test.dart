import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:dio/dio.dart';
import 'package:mabasa_flutter/main.dart';
import 'package:mabasa_flutter/core/router/app_router.dart';
import 'package:mabasa_flutter/core/services/api_client.dart';
import 'package:mabasa_flutter/core/services/auth_service.dart';
import 'package:mabasa_flutter/features/auth/presentation/screens/login_screen.dart';
import 'package:mabasa_flutter/features/auth/presentation/screens/register_screen.dart';
import 'package:mabasa_flutter/features/employee/dashboard/employee_dashboard_screen.dart';
import 'package:mabasa_flutter/features/employee/dashboard/profile_setup_screen.dart';
import 'package:mabasa_flutter/features/jobs/presentation/screens/job_swipe_screen.dart';
import 'package:mabasa_flutter/features/jobs/presentation/screens/applications_screen.dart';
import 'package:mabasa_flutter/features/jobs/presentation/screens/notifications_screen.dart';
import 'package:mabasa_flutter/features/employer/dashboard/employer_dashboard_screen.dart';
import 'package:mabasa_flutter/features/employer/candidates/candidate_swipe_screen.dart';
import 'package:mabasa_flutter/features/employer/jobs/manage_jobs_screen.dart';
import 'package:mabasa_flutter/features/employer/jobs/job_applicants_swipe_screen.dart';
import 'package:mabasa_flutter/features/employer/interviews/interviews_screen.dart';
import 'package:mabasa_flutter/features/employer/shortlist/shortlist_screen.dart';
import 'package:mabasa_flutter/features/profile/presentation/screens/profile_screen.dart';
import 'package:mabasa_flutter/features/settings/settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock API client to prevent real network calls
  final mockApiClient = MockApiClient();

  // Mock auth service
  final mockAuthService = MockAuthService();

  setUpAll(() async {
    await loadAppFonts();
  });

  group('Screen Screenshots', () {
    testGoldens('Login Screen', (tester) async {
      await tester.pumpWidgetBuilder(
        const MaterialApp(
          home: LoginScreen(),
        ),
        wrapper: materialAppWrapper(),
      );

      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'login_screen');
    });

    testGoldens('Register Screen - Role Selection', (tester) async {
      await tester.pumpWidgetBuilder(
        const MaterialApp(
          home: RegisterScreen(),
        ),
        wrapper: materialAppWrapper(),
      );

      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'register_screen_role_selection');
    });

    testGoldens('Employee Dashboard', (tester) async {
      await tester.pumpWidgetBuilder(
        const MaterialApp(
          home: EmployeeDashboardScreen(),
        ),
        wrapper: materialAppWrapper(),
      );

      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'employee_dashboard');
    });

    testGoldens('Job Swipe Screen', (tester) async {
      await tester.pumpWidgetBuilder(
        const MaterialApp(
          home: JobSwipeScreen(),
        ),
        wrapper: materialAppWrapper(),
      );

      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'job_swipe_screen');
    });

    testGoldens('Applications Screen', (tester) async {
      await tester.pumpWidgetBuilder(
        const MaterialApp(
          home: ApplicationsScreen(),
        ),
        wrapper: materialAppWrapper(),
      );

      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'applications_screen');
    });

    testGoldens('Notifications Screen', (tester) async {
      await tester.pumpWidgetBuilder(
        const MaterialApp(
          home: NotificationsScreen(),
        ),
        wrapper: materialAppWrapper(),
      );

      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'notifications_screen');
    });

    testGoldens('Employer Dashboard', (tester) async {
      await tester.pumpWidgetBuilder(
        const MaterialApp(
          home: EmployerDashboardScreen(),
        ),
        wrapper: materialAppWrapper(),
      );

      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'employer_dashboard');
    });

    testGoldens('Candidate Swipe Screen', (tester) async {
      await tester.pumpWidgetBuilder(
        const MaterialApp(
          home: CandidateSwipeScreen(),
        ),
        wrapper: materialAppWrapper(),
      );

      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'candidate_swipe_screen');
    });

    testGoldens('Manage Jobs Screen', (tester) async {
      await tester.pumpWidgetBuilder(
        const MaterialApp(
          home: ManageJobsScreen(),
        ),
        wrapper: materialAppWrapper(),
      );

      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'manage_jobs_screen');
    });

    testGoldens('Interviews Screen', (tester) async {
      await tester.pumpWidgetBuilder(
        const MaterialApp(
          home: InterviewsScreen(),
        ),
        wrapper: materialAppWrapper(),
      );

      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'interviews_screen');
    });

    testGoldens('Shortlist Screen', (tester) async {
      await tester.pumpWidgetBuilder(
        const MaterialApp(
          home: ShortlistScreen(),
        ),
        wrapper: materialAppWrapper(),
      );

      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'shortlist_screen');
    });

    testGoldens('Profile Screen', (tester) async {
      await tester.pumpWidgetBuilder(
        const MaterialApp(
          home: ProfileScreen(),
        ),
        wrapper: materialAppWrapper(),
      );

      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'profile_screen');
    });

    testGoldens('Settings Screen', (tester) async {
      await tester.pumpWidgetBuilder(
        const MaterialApp(
          home: SettingsScreen(),
        ),
        wrapper: materialAppWrapper(),
      );

      await tester.pumpAndSettle();

      await screenMatchesGolden(tester, 'settings_screen');
    });
  });
}

// Mock implementations
class MockApiClient {
  Future<Dio> authed() async {
    return Dio(BaseOptions(baseUrl: 'http://mock-api.com'));
  }
}

class MockAuthService {
  Future<Map<String, dynamic>> login({
    required String usernameOrEmail,
    required String password,
  }) async {
    return {'role': 'employee', 'id': 1};
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String role,
    String? firstName,
    String? lastName,
  }) async {
    return {'role': role, 'id': 1};
  }
}
