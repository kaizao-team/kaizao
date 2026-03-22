import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/pages/splash_page.dart';
import '../features/auth/pages/onboarding_page.dart';
import '../features/auth/pages/login_page.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/home/pages/home_page.dart';
import '../features/project/pages/project_detail_page.dart';
import '../features/project/pages/publish_project_page.dart';
import '../features/profile/pages/profile_page.dart';
import '../features/chat/pages/conversation_list_page.dart';
import '../features/chat/pages/chat_detail_page.dart';
import '../features/match/pages/match_result_page.dart';
import '../features/match/pages/search_page.dart';
import '../features/settings/pages/settings_page.dart';
import '../shared/widgets/vcc_bottom_nav.dart';

// 路由路径常量
class RoutePaths {
  RoutePaths._();

  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String home = '/home';
  static const String square = '/square';
  static const String chatList = '/chat';
  static const String chatDetail = '/chat/:conversationId';
  static const String projectList = '/projects';
  static const String projectDetail = '/projects/:projectId';
  static const String publishProject = '/publish';
  static const String profile = '/profile';
  static const String profileView = '/profile/:userId';
  static const String matchResult = '/match/:projectId';
  static const String search = '/search';
  static const String settings = '/settings';
}

// 全局导航Key，用于底部导航栏
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RoutePaths.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoggedIn = authState.isLoggedIn;
      final isOnAuthPage = state.matchedLocation == RoutePaths.splash ||
          state.matchedLocation == RoutePaths.onboarding ||
          state.matchedLocation == RoutePaths.login;

      // 已登录但在登录相关页面 -> 跳转首页
      if (isLoggedIn && isOnAuthPage) {
        return RoutePaths.home;
      }

      // 未登录且不在认证相关页面 -> 跳转登录
      if (!isLoggedIn && !isOnAuthPage) {
        return RoutePaths.login;
      }

      return null;
    },
    routes: [
      // 启动页
      GoRoute(
        path: RoutePaths.splash,
        builder: (context, state) => const SplashPage(),
      ),
      // 引导页
      GoRoute(
        path: RoutePaths.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),
      // 登录页
      GoRoute(
        path: RoutePaths.login,
        builder: (context, state) => const LoginPage(),
      ),

      // 主Tab页面（使用ShellRoute包裹底部导航）
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => VccBottomNav(child: child),
        routes: [
          GoRoute(
            path: RoutePaths.home,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomePage(),
            ),
          ),
          GoRoute(
            path: RoutePaths.square,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SearchPage(),
            ),
          ),
          GoRoute(
            path: RoutePaths.chatList,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ConversationListPage(),
            ),
          ),
          GoRoute(
            path: RoutePaths.projectList,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProjectDetailPage(),
            ),
          ),
          GoRoute(
            path: RoutePaths.profile,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfilePage(),
            ),
          ),
        ],
      ),

      // 二级页面
      GoRoute(
        path: RoutePaths.projectDetail,
        builder: (context, state) => ProjectDetailPage(
          projectId: state.pathParameters['projectId'],
        ),
      ),
      GoRoute(
        path: RoutePaths.publishProject,
        builder: (context, state) => const PublishProjectPage(),
      ),
      GoRoute(
        path: RoutePaths.chatDetail,
        builder: (context, state) => ChatDetailPage(
          conversationId: state.pathParameters['conversationId'] ?? '',
        ),
      ),
      GoRoute(
        path: RoutePaths.profileView,
        builder: (context, state) => ProfilePage(
          userId: state.pathParameters['userId'],
        ),
      ),
      GoRoute(
        path: RoutePaths.matchResult,
        builder: (context, state) => MatchResultPage(
          projectId: state.pathParameters['projectId'] ?? '',
        ),
      ),
      GoRoute(
        path: RoutePaths.settings,
        builder: (context, state) => const SettingsPage(),
      ),
    ],
  );
});
