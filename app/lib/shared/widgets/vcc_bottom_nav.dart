import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/routes.dart';
import '../../features/chat/providers/chat_provider.dart';

/// 底部导航栏 — Notion/Linear 黑白风格
class VccBottomNav extends ConsumerWidget {
  final Widget child;

  const VccBottomNav({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(RoutePaths.home)) return 0;
    if (location.startsWith(RoutePaths.square)) return 1;
    if (location.startsWith('/chat')) return 2;
    if (location.startsWith('/projects')) return 3;
    if (location.startsWith(RoutePaths.profile)) return 4;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(RoutePaths.home);
      case 1:
        context.go(RoutePaths.square);
      case 2:
        context.go(RoutePaths.chatList);
      case 3:
        context.go(RoutePaths.projectList);
      case 4:
        context.go(RoutePaths.profile);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chatState = ref.watch(conversationListProvider);
    final unreadCount = chatState.totalUnread;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkDivider : AppColors.gray200,
              width: 0.5,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex(context),
          onTap: (index) => _onTap(context, index),
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: '首页',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore),
              label: '广场',
            ),
            BottomNavigationBarItem(
              icon: _buildChatIcon(Icons.chat_bubble_outline, unreadCount),
              activeIcon: _buildChatIcon(Icons.chat_bubble, unreadCount),
              label: '消息',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: '项目',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: '我的',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatIcon(IconData icon, int unreadCount) {
    if (unreadCount <= 0) return Icon(icon);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        Positioned(
          right: -6,
          top: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            constraints: const BoxConstraints(minWidth: 16, minHeight: 14),
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.white, width: 1.5),
            ),
            child: Center(
              child: Text(
                unreadCount > 99 ? '99+' : '$unreadCount',
                style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
