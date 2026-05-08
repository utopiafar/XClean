import 'package:go_router/go_router.dart';
import '../presentation/screens/dashboard/dashboard_screen.dart';
import '../presentation/screens/clean/preview_screen.dart';
import '../presentation/screens/rules/rule_editor_screen.dart';
import '../presentation/screens/rules/rule_list_screen.dart';
import '../presentation/screens/analyze/large_file_screen.dart';
import '../presentation/screens/settings/settings_screen.dart';
import '../presentation/screens/tasks/auto_task_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/preview',
      builder: (context, state) => const PreviewScreen(),
    ),
    GoRoute(
      path: '/rules',
      builder: (context, state) => const RuleListScreen(),
    ),
    GoRoute(
      path: '/rule_editor',
      builder: (context, state) {
        final extra = state.extra;
        return RuleEditorScreen(ruleId: extra is int ? extra : null);
      },
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/auto_tasks',
      builder: (context, state) => const AutoTaskScreen(),
    ),
    GoRoute(
      path: '/large_files',
      builder: (context, state) => const LargeFileScreen(),
    ),
  ],
);
