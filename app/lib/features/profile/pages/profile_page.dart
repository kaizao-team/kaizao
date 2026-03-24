import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/routes.dart';
import '../../../shared/widgets/vcc_button.dart';
import '../../../shared/widgets/vcc_loading.dart';
import '../../../shared/widgets/vcc_empty_state.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_stats_row.dart';
import '../widgets/portfolio_grid.dart';
import '../widgets/role_switch_dialog.dart';

class ProfilePage extends ConsumerWidget {
  final String? userId;
  const ProfilePage({super.key, this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectiveId = userId ?? 'me';
    final isSelf = userId == null;
    final state = ref.watch(profileProvider(effectiveId));

    if (state.isLoading && state.profile == null) {
      return const Scaffold(body: VccLoading());
    }

    if (state.errorMessage != null && state.profile == null) {
      return Scaffold(
        appBar: isSelf ? null : AppBar(),
        body: VccEmptyState(
          icon: Icons.error_outline,
          title: '加载失败',
          subtitle: state.errorMessage ?? '',
          buttonText: '重试',
          onButtonPressed: () =>
              ref.read(profileProvider(effectiveId).notifier).loadProfile(),
        ),
      );
    }

    final profile = state.profile;
    if (profile == null) return const Scaffold(body: VccLoading());

    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.black,
        onRefresh: () =>
            ref.read(profileProvider(effectiveId).notifier).loadProfile(),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: ProfileHeader(profile: profile, isSelf: isSelf),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 52),
                    Text(
                      profile.nickname,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.tagline,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.gray500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star,
                            size: 14, color: AppColors.accentGold),
                        const SizedBox(width: 2),
                        Text(
                          profile.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.black,
                          ),
                        ),
                        Text(
                          ' · 信用分 ${profile.creditScore}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.gray400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ProfileStatsRow(stats: profile.stats),
                    const SizedBox(height: 20),
                    if (profile.bio.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Text(
                          profile.bio,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.gray600,
                            height: 1.6,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    if (state.skills.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: state.skills
                              .map((s) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.gray100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      s.name,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.gray600,
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    if (isSelf) ...[
                      VccButton(
                        text: '编辑主页',
                        type: VccButtonType.secondary,
                        onPressed: () => context.push(RoutePaths.editProfile),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _ActionTile(
                              icon: Icons.swap_horiz,
                              label: '切换角色',
                              onTap: () => _showRoleSwitch(
                                context,
                                ref,
                                profile.role,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ActionTile(
                              icon: Icons.account_balance_wallet_outlined,
                              label: '我的钱包',
                              onTap: () => context.push(RoutePaths.wallet),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ActionTile(
                              icon: Icons.settings_outlined,
                              label: '设置',
                              onTap: () => context.push(RoutePaths.settings),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: PortfolioGrid(items: state.portfolios),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  void _showRoleSwitch(BuildContext context, WidgetRef ref, int currentRole) {
    showDialog(
      context: context,
      builder: (_) => RoleSwitchDialog(
        currentRole: currentRole,
        onConfirm: () async {
          final newRole = currentRole == 1 ? 2 : 1;
          await ref.read(authStateProvider.notifier).selectRole(newRole);
        },
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.gray50,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: AppColors.black),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.gray600),
            ),
          ],
        ),
      ),
    );
  }
}
