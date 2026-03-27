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
      backgroundColor: const Color(0xFFF9F9F9),
      body: RefreshIndicator(
        color: AppColors.black,
        onRefresh: () =>
            ref.read(profileProvider(effectiveId).notifier).loadProfile(),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildBannerSection(context, isSelf),
            Transform.translate(
              offset: const Offset(0, -36),
              child: Column(
                children: [
                  _buildAvatarAndInfo(profile),
                  const SizedBox(height: 20),
                  _buildStatsRow(profile),
                  const SizedBox(height: 24),
                  _buildMenuSection(context),
                ],
              ),
            ),
            const SizedBox(height: 44),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerSection(BuildContext context, bool isSelf) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: topPadding),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1C1C), Color(0xFF2D2F2F)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            top: -20,
            child: CustomPaint(
              size: const Size(200, 200),
              painter: _GridPatternPainter(),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -10,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.04),
                  width: 1,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 12, 56),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'VCC',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.8),
                    letterSpacing: 1.5,
                  ),
                ),
                if (isSelf)
                  IconButton(
                    onPressed: () => context.push(RoutePaths.settings),
                    icon: Icon(
                      Icons.settings_outlined,
                      size: 22,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarAndInfo(dynamic profile) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: VccAvatar(
            size: VccAvatarSize.xlarge,
            imageUrl: profile.avatar,
            fallbackText:
                profile.nickname.isNotEmpty ? profile.nickname[0] : 'U',
          ),
        ),
        const SizedBox(height: 14),
        Text(
          profile.nickname,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1C1C),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F3F3),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            profile.isDemander ? '项目方' : '团队方',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.gray500,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          profile.tagline.isNotEmpty
              ? profile.tagline
              : '${profile.roleName} · 开造平台',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.gray400,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(dynamic profile) {
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
                          color: Color(0xFF1A1C1C),
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

  Widget _buildMenuSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildMenuItem('我的钱包', onTap: () {
            context.push(RoutePaths.wallet);
          }),
          _buildMenuItem('消息通知', onTap: () {}),
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            height: 1,
            color: const Color(0xFFF3F3F3),
          ),
          const SizedBox(height: 8),
          _buildMenuItem('帮助与反馈', onTap: () {}),
          _buildMenuItem('关于开造', onTap: () {}),
        ],
      ),
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

class _GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const step = 20.0;
    for (double i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double j = 0; j < size.height; j += step) {
      canvas.drawLine(Offset(0, j), Offset(size.width, j), paint);
    }

    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    for (double i = 0; i < size.width; i += step) {
      for (double j = 0; j < size.height; j += step) {
        canvas.drawCircle(Offset(i, j), 1.2, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
