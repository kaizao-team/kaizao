import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/routes.dart';
import '../../../shared/widgets/vcc_avatar.dart';
import '../../../shared/widgets/vcc_loading.dart';
import '../../../shared/widgets/vcc_empty_state.dart';
import '../providers/profile_provider.dart';

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
      backgroundColor: AppColors.white,
      body: RefreshIndicator(
        color: AppColors.black,
        onRefresh: () =>
            ref.read(profileProvider(effectiveId).notifier).loadProfile(),
        child: ListView(
          children: [
            if (isSelf) _buildTopBar(context),

            if (!isSelf)
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),

            const SizedBox(height: 24),

            // Avatar
            Center(
              child: VccAvatar(
                size: VccAvatarSize.xlarge,
                imageUrl: profile.avatar,
                fallbackText: profile.nickname.isNotEmpty
                    ? profile.nickname[0]
                    : 'U',
              ),
            ),
            const SizedBox(height: 16),

            // Name
            Center(
              child: Text(
                profile.nickname,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Role badge
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  profile.isDemander ? '发起人' : '造物者',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.gray500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Tagline
            Center(
              child: Text(
                profile.tagline.isNotEmpty
                    ? profile.tagline
                    : '${profile.roleName} · 开造平台',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.gray400,
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Stats row
            _buildStatsRow(profile),

            // Separator
            _buildSeparator(),

            // Menu group 1
            _buildMenuItem('我的钱包', onTap: () {
              context.push(RoutePaths.wallet);
            }),
            _buildMenuItem('消息通知', onTap: () {
              // TODO: navigate to notifications
            }),

            _buildSeparator(),

            // Menu group 2
            _buildMenuItem('帮助与反馈', onTap: () {}),
            _buildMenuItem('关于开造', onTap: () {}),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            onPressed: () => context.push(RoutePaths.settings),
            icon: const Icon(
              Icons.settings_outlined,
              size: 22,
              color: AppColors.gray400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(profile) {
    final items = profile.isDemander
        ? [
            _StatData('${profile.stats.publishedProjects}', '发布需求'),
            _StatData(profile.rating.toStringAsFixed(1), '评分'),
            _StatData('${profile.creditScore}', '信用分'),
          ]
        : [
            _StatData('${profile.stats.completedProjects}', '完成项目'),
            _StatData(profile.rating.toStringAsFixed(1), '评分'),
            _StatData('${profile.creditScore}', '信用分'),
          ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: items
            .map((item) => Expanded(
                  child: Column(
                    children: [
                      Text(
                        item.value,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.gray400,
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildSeparator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      height: 1,
      color: const Color(0xFFF0F0F0),
    );
  }

  Widget _buildMenuItem(String title, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.gray700,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.chevron_right,
              size: 16,
              color: AppColors.gray300,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatData {
  final String value;
  final String label;
  const _StatData(this.value, this.label);
}
