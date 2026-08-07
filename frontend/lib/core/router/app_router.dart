import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/providers/session_providers.dart';
import '../../presentation/screens/activities/activity_detail_screen.dart';
import '../../presentation/screens/activities/grade_composition_screen.dart';
import '../../presentation/screens/agenda/agenda_screen.dart';
import '../../presentation/screens/attendance/attendance_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/classes/class_detail_screen.dart';
import '../../presentation/screens/classes/classes_screen.dart';
import '../../presentation/screens/dashboard/dashboard_screen.dart';
import '../../presentation/screens/reports/reports_screen.dart';
import '../../presentation/screens/settings/settings_screen.dart';
import '../../presentation/screens/splash_screen.dart';
import '../../presentation/screens/students/students_screen.dart';
import '../widgets/app_scaffold.dart';

/// Rotas nomeadas (paths) centralizadas para navegação tipada e legível.
abstract class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const dashboard = '/dashboard';
  static const classes = '/classes';
  static const students = '/students';
  static const agenda = '/agenda';
  static const reports = '/reports';
  static const settings = '/settings';

  static String classDetail(String classId) => '/classes/$classId';
  static String attendance(String classId, String lessonId) => '/classes/$classId/lessons/$lessonId/attendance';
  static String activityDetail(String classId, String activityId) => '/classes/$classId/activities/$activityId';
  static String gradeComposition(String classId, String disciplineId) =>
      '/classes/$classId/grade-composition/$disciplineId';
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = ref.watch(routerRefreshProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      final atSplash = state.matchedLocation == AppRoutes.splash;
      final atLogin = state.matchedLocation == AppRoutes.login;

      if (authState.status == AuthStatus.checking) {
        return atSplash ? null : AppRoutes.splash;
      }
      if (authState.status == AuthStatus.unauthenticated) {
        return atLogin ? null : AppRoutes.login;
      }
      if (atSplash || atLogin) return AppRoutes.dashboard;
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (context, state) => const SplashScreen()),
      GoRoute(path: AppRoutes.login, builder: (context, state) => const LoginScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppScaffold(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.dashboard, builder: (context, state) => const DashboardScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.classes,
              builder: (context, state) => const ClassesScreen(),
              routes: [
                GoRoute(
                  path: ':classId',
                  builder: (context, state) => ClassDetailScreen(
                    classId: state.pathParameters['classId']!,
                    initialTabIndex: state.extra as int?,
                  ),
                  routes: [
                    GoRoute(
                      path: 'lessons/:lessonId/attendance',
                      builder: (context, state) => AttendanceScreen(
                        classId: state.pathParameters['classId']!,
                        lessonId: state.pathParameters['lessonId']!,
                      ),
                    ),
                    GoRoute(
                      path: 'activities/:activityId',
                      builder: (context, state) => ActivityDetailScreen(
                        classId: state.pathParameters['classId']!,
                        activityId: state.pathParameters['activityId']!,
                      ),
                    ),
                    GoRoute(
                      path: 'grade-composition/:disciplineId',
                      builder: (context, state) => GradeCompositionScreen(
                        classId: state.pathParameters['classId']!,
                        disciplineId: state.pathParameters['disciplineId']!,
                        disciplineName: state.uri.queryParameters['name'] ?? 'Disciplina',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.students, builder: (context, state) => const StudentsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.agenda, builder: (context, state) => const AgendaScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.reports, builder: (context, state) => const ReportsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.settings, builder: (context, state) => const SettingsScreen()),
          ]),
        ],
      ),
    ],
  );
});
