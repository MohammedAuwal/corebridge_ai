import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/providers.dart';
import '../screens/artifacts_screen.dart';
import '../screens/auth_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/files_screen.dart';
import '../screens/history_screen.dart';
import '../screens/home_screen.dart';
import '../screens/knowledge_base_screen.dart';
import '../screens/projects_screen.dart';
import '../screens/prompt_library_screen.dart';
import '../screens/settings_screen.dart';
import '../shell/app_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isAuthRoute = state.matchedLocation == '/auth';

      if (!isLoggedIn && !isAuthRoute) return '/auth';
      if (isLoggedIn && isAuthRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
          GoRoute(path: '/chat', builder: (context, state) => const ChatScreen()),
          GoRoute(path: '/projects', builder: (context, state) => const ProjectsScreen()),
          GoRoute(path: '/artifacts', builder: (context, state) => const ArtifactsScreen()),
          GoRoute(path: '/files', builder: (context, state) => const FilesScreen()),
          GoRoute(path: '/knowledge-base', builder: (context, state) => const KnowledgeBaseScreen()),
          GoRoute(path: '/prompt-library', builder: (context, state) => const PromptLibraryScreen()),
          GoRoute(path: '/history', builder: (context, state) => const HistoryScreen()),
          GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
        ],
      ),
    ],
  );
});
