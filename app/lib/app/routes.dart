import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/pages/splash_page.dart';
import '../features/auth/pages/onboarding_page.dart';
import '../features/auth/pages/login_page.dart';
import '../features/auth/pages/role_select_page.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/onboarding/pages/demander_profile_page.dart';
import '../features/onboarding/pages/demander_guide_create_page.dart';
import '../features/onboarding/pages/demander_guide_fill_page.dart';
import '../features/onboarding/pages/demander_complete_page.dart';
import '../features/onboarding/pages/expert_profile_page.dart';
import '../features/onboarding/pages/expert_supplement_page.dart';
import '../features/onboarding/pages/expert_level_page.dart';
import '../features/home/pages/home_page.dart';
import '../features/project/pages/project_detail_page.dart';
import '../features/post/pages/post_page.dart';
import '../features/prd/pages/prd_page.dart';
import '../features/profile/pages/profile_page.dart';
import '../features/chat/pages/conversation_list_page.dart';
import '../features/chat/pages/chat_detail_page.dart';
import '../features/match/pages/bid_list_page.dart';
import '../features/match/pages/bid_form_page.dart';
import '../features/market/pages/market_page.dart';
import '../features/project/pages/project_list_page.dart';
import '../features/project/pages/project_manage_page.dart';
import '../features/acceptance/pages/acceptance_page.dart';
import '../features/payment/pages/order_confirm_page.dart';
import '../features/payment/pages/payment_result_page.dart';
import '../features/settings/pages/settings_page.dart';
import '../features/profile/pages/edit_profile_page.dart';
import '../features/wallet/pages/wallet_page.dart';
import '../features/team/pages/team_hall_page.dart';
import '../features/team/pages/create_team_post_page.dart';
import '../features/team/pages/team_confirm_page.dart';
import '../features/rate/pages/rate_page.dart';
import '../shared/widgets/vcc_bottom_nav.dart';

class RoutePaths {
  RoutePaths._();

  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String roleSelect = '/role-select';

  static const String demanderOnboarding1 = '/onboard/demander/1';
  static const String demanderOnboarding2 = '/onboard/demander/2';
  static const String demanderOnboarding3 = '/onboard/demander/3';
  static const String demanderOnboarding4 = '/onboard/demander/4';

  static const String expertOnboarding1 = '/onboard/expert/1';
  static const String expertOnboarding2 = '/onboard/expert/2';
  static const String expertOnboarding3 = '/onboard/expert/3';

  static const String home = '/home';
  static const String square = '/square';
  static const String chatList = '/chat';
  static const String chatDetail = '/chat/:conversationId';
  static const String projectList = '/projects';
  static const String projectDetail = '/projects/:projectId';
  static const String publishProject = '/publish';
  static const String prd = '/projects/:projectId/prd';
  static const String profile = '/profile';
  static const String profileView = '/profile/:userId';
  static const String bidList = '/projects/:projectId/bids';
  static const String bidForm = '/projects/:projectId/bid';
  static const String projectManage = '/projects/:projectId/manage';
  static const String acceptance =
      '/projects/:projectId/milestones/:milestoneId/acceptance';
  static const String orderConfirm = '/orders/:orderId/confirm';
  static const String paymentResult = '/orders/:orderId/result';
  static const String settings = '/settings';
  static const String income = '/income';
  static const String editProfile = '/profile/edit';
  static const String wallet = '/wallet';
  static const String teamHall = '/team';
  static const String createTeamPost = '/team/create';
  static const String teamConfirm = '/team/:teamId/confirm';
  static const String rate = '/rate';
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

const _authExemptPaths = {
  RoutePaths.splash,
  RoutePaths.onboarding,
  RoutePaths.login,
  RoutePaths.roleSelect,
  RoutePaths.demanderOnboarding1,
  RoutePaths.demanderOnboarding2,
  RoutePaths.demanderOnboarding3,
  RoutePaths.demanderOnboarding4,
  RoutePaths.expertOnboarding1,
  RoutePaths.expertOnboarding2,
  RoutePaths.expertOnboarding3,
};

Page<void> _cupertinoPage(Widget child) {
  return CupertinoPage(child: child);
}

final routerProvider = Provider<GoRouter>((ref) {
  final changeNotifier = ref.watch(authChangeNotifierProvider);

  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RoutePaths.splash,
    debugLogDiagnostics: false,
    refreshListenable: changeNotifier,
    redirect: (context, state) {
      final container = ProviderScope.containerOf(context);
      final authState = container.read(authStateProvider);
      final location = state.matchedLocation;

      if (!authState.isInitialized) {
        return location == RoutePaths.splash ? null : RoutePaths.splash;
      }

      if (location == RoutePaths.splash) {
        if (authState.isFirstLaunch) return RoutePaths.onboarding;
        return authState.isLoggedIn ? RoutePaths.home : RoutePaths.login;
      }

      final isLoggedIn = authState.isLoggedIn;
      final isOnAuthPage = _authExemptPaths.contains(location);

      if (isLoggedIn && location == RoutePaths.login) {
        return RoutePaths.home;
      }

      if (!isLoggedIn && !isOnAuthPage) {
        return RoutePaths.login;
      }

      return null;
    },
    routes: [
      GoRoute(path: RoutePaths.splash, builder: (_, __) => const SplashPage()),
      GoRoute(path: RoutePaths.onboarding, builder: (_, __) => const OnboardingPage()),
      GoRoute(path: RoutePaths.login, builder: (_, __) => const LoginPage()),
      GoRoute(path: RoutePaths.roleSelect, builder: (_, __) => const RoleSelectPage()),

      GoRoute(path: RoutePaths.demanderOnboarding1, pageBuilder: (_, __) => _cupertinoPage(const DemanderProfilePage())),
      GoRoute(path: RoutePaths.demanderOnboarding2, pageBuilder: (_, __) => _cupertinoPage(const DemanderGuideCreatePage())),
      GoRoute(path: RoutePaths.demanderOnboarding3, pageBuilder: (_, __) => _cupertinoPage(const DemanderGuideFillPage())),
      GoRoute(path: RoutePaths.demanderOnboarding4, pageBuilder: (_, __) => _cupertinoPage(const DemanderCompletePage())),

      GoRoute(path: RoutePaths.expertOnboarding1, pageBuilder: (_, __) => _cupertinoPage(const ExpertProfilePage())),
      GoRoute(path: RoutePaths.expertOnboarding2, pageBuilder: (_, __) => _cupertinoPage(const ExpertSupplementPage())),
      GoRoute(path: RoutePaths.expertOnboarding3, pageBuilder: (_, __) => _cupertinoPage(const ExpertLevelPage())),

      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => VccBottomNav(child: child),
        routes: [
          GoRoute(
            path: RoutePaths.home,
            pageBuilder: (_, __) => const NoTransitionPage(child: HomePage()),
          ),
          GoRoute(
            path: RoutePaths.square,
            pageBuilder: (_, __) => const NoTransitionPage(child: MarketPage()),
          ),
          GoRoute(
            path: RoutePaths.chatList,
            pageBuilder: (_, __) => const NoTransitionPage(child: ConversationListPage()),
          ),
          GoRoute(
            path: RoutePaths.projectList,
            pageBuilder: (_, __) => const NoTransitionPage(child: ProjectListPage()),
          ),
          GoRoute(
            path: RoutePaths.profile,
            pageBuilder: (_, __) => const NoTransitionPage(child: ProfilePage()),
          ),
        ],
      ),

      GoRoute(
        path: RoutePaths.projectDetail,
        pageBuilder: (_, state) => _cupertinoPage(
          ProjectDetailPage(projectId: state.pathParameters['projectId']),
        ),
      ),
      GoRoute(
        path: RoutePaths.publishProject,
        pageBuilder: (_, state) {
          final category = state.uri.queryParameters['category'];
          return _cupertinoPage(PostPage(initialCategory: category));
        },
      ),
      GoRoute(
        path: RoutePaths.prd,
        pageBuilder: (_, state) => _cupertinoPage(
          PrdPage(projectId: state.pathParameters['projectId'] ?? ''),
        ),
      ),
      GoRoute(
        path: RoutePaths.chatDetail,
        pageBuilder: (_, state) => _cupertinoPage(
          ChatDetailPage(conversationId: state.pathParameters['conversationId'] ?? ''),
        ),
      ),
      GoRoute(
        path: RoutePaths.profileView,
        pageBuilder: (_, state) => _cupertinoPage(
          ProfilePage(userId: state.pathParameters['userId']),
        ),
      ),
      GoRoute(
        path: RoutePaths.bidList,
        pageBuilder: (_, state) => _cupertinoPage(
          BidListPage(projectId: state.pathParameters['projectId'] ?? ''),
        ),
      ),
      GoRoute(
        path: RoutePaths.bidForm,
        pageBuilder: (_, state) => _cupertinoPage(
          BidFormPage(projectId: state.pathParameters['projectId'] ?? ''),
        ),
      ),
      GoRoute(
        path: RoutePaths.projectManage,
        pageBuilder: (_, state) => _cupertinoPage(
          ProjectManagePage(projectId: state.pathParameters['projectId'] ?? ''),
        ),
      ),
      GoRoute(
        path: RoutePaths.acceptance,
        pageBuilder: (_, state) => _cupertinoPage(
          AcceptancePage(milestoneId: state.pathParameters['milestoneId'] ?? ''),
        ),
      ),
      GoRoute(
        path: RoutePaths.orderConfirm,
        pageBuilder: (_, state) => _cupertinoPage(
          OrderConfirmPage(orderId: state.pathParameters['orderId'] ?? ''),
        ),
      ),
      GoRoute(
        path: RoutePaths.paymentResult,
        pageBuilder: (_, state) => _cupertinoPage(
          PaymentResultPage(orderId: state.pathParameters['orderId'] ?? ''),
        ),
      ),
      GoRoute(path: RoutePaths.settings, pageBuilder: (_, __) => _cupertinoPage(const SettingsPage())),
      GoRoute(path: RoutePaths.editProfile, pageBuilder: (_, __) => _cupertinoPage(const EditProfilePage())),
      GoRoute(path: RoutePaths.wallet, pageBuilder: (_, __) => _cupertinoPage(const WalletPage())),
      GoRoute(path: RoutePaths.income, pageBuilder: (_, __) => _cupertinoPage(const WalletPage())),
      GoRoute(path: RoutePaths.teamHall, pageBuilder: (_, __) => _cupertinoPage(const TeamHallPage())),
      GoRoute(path: RoutePaths.createTeamPost, pageBuilder: (_, __) => _cupertinoPage(const CreateTeamPostPage())),
      GoRoute(
        path: RoutePaths.teamConfirm,
        pageBuilder: (_, state) => _cupertinoPage(
          TeamConfirmPage(teamId: state.pathParameters['teamId'] ?? ''),
        ),
      ),
      GoRoute(
        path: RoutePaths.rate,
        pageBuilder: (_, state) {
          final projectId = state.uri.queryParameters['projectId'] ?? '';
          final revieweeId = state.uri.queryParameters['revieweeId'] ?? '';
          final revieweeName = state.uri.queryParameters['revieweeName'] ?? '';
          final isDemander = state.uri.queryParameters['isDemander'] != 'false';
          return _cupertinoPage(RatePage(
            projectId: projectId,
            revieweeId: revieweeId,
            revieweeName: revieweeName,
            isDemander: isDemander,
          ));
        },
      ),
    ],
  );

  ref.onDispose(() => router.dispose());
  return router;
});
