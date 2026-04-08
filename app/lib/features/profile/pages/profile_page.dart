import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/skills/skill_particle_field.dart';
import '../../../shared/widgets/vcc_empty_state.dart';
import '../../../shared/widgets/vcc_loading.dart';
import '../models/profile_models.dart';
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
        backgroundColor: const Color(0xFFF9F9F9),
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
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: _ProfileHero(
                profile: profile,
                isSelf: isSelf,
                skills: state.skills,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildSectionLabel('OVERVIEW'),
                  const SizedBox(height: 10),
                  _ProfileMetricsCard(profile: profile),
                  const SizedBox(height: 28),
                  _buildSectionLabel('ACCOUNT'),
                  const SizedBox(height: 10),
                  _ProfileInfoCard(profile: profile),
                  if (isSelf) ...[
                    const SizedBox(height: 28),
                    _buildSectionLabel('QUICK ACTIONS'),
                    const SizedBox(height: 10),
                    _ProfileMenuGroup(
                      items: [
                        _ProfileMenuItem(
                          label: '编辑资料',
                          trailingText: '完善资料',
                          onTap: () => context.push(RoutePaths.editProfile),
                        ),
                        _ProfileMenuItem(
                          label: '我的钱包',
                          trailingText: '余额与记录',
                          onTap: () => context.push(RoutePaths.wallet),
                        ),
                        _ProfileMenuItem(
                          label: '消息通知',
                          onTap: () => context.push(RoutePaths.notifications),
                        ),
                        _ProfileMenuItem(
                          label: '我的收藏',
                          onTap: () => context.push(RoutePaths.favorites),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 28),
                  _buildSectionLabel('SUPPORT'),
                  const SizedBox(height: 10),
                  _ProfileMenuGroup(
                    items: [
                      _ProfileMenuItem(
                        label: '帮助与反馈',
                        onTap: () => context.push(RoutePaths.helpFeedback),
                      ),
                      _ProfileMenuItem(
                        label: '关于 KAIZO',
                        onTap: () => context.push(RoutePaths.about),
                      ),
                    ],
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.gray400,
        letterSpacing: 2.5,
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  final UserProfile profile;
  final bool isSelf;
  final List<SkillTag> skills;

  const _ProfileHero({
    required this.profile,
    required this.isSelf,
    required this.skills,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final summary = _profileSummary(profile);

    return Container(
      padding: EdgeInsets.only(top: topPadding),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF111111), Color(0xFF3C3B3B)],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            right: -30,
            top: -10,
            child: CustomPaint(
              size: const Size(180, 180),
              painter: _DotGridPainter(),
            ),
          ),
          if (skills.any((skill) => skill.name.trim().isNotEmpty))
            Positioned(
              left: 0,
              right: 0,
              top: 64,
              bottom: 0,
              child: IgnorePointer(
                child: SkillParticleField(
                  skills: skills
                      .where((skill) => skill.name.trim().isNotEmpty)
                      .map(
                        (skill) => SkillParticleItem(
                          id: skill.id,
                          name: skill.name,
                          category: skill.category,
                          isPrimary: skill.isPrimary,
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'PROFILE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.4),
                        letterSpacing: 3,
                      ),
                    ),
                    const Spacer(),
                    _TopActionButton(
                      label: isSelf ? '设置' : '返回',
                      icon: isSelf
                          ? Icons.settings_outlined
                          : Icons.arrow_back_ios_new_rounded,
                      onTap: () {
                        if (isSelf) {
                          context.push(RoutePaths.settings);
                          return;
                        }
                        if (context.canPop()) {
                          context.pop();
                          return;
                        }
                        context.go(RoutePaths.home);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  '我的',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.5,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _HeroAvatarCard(profile: profile),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.nickname,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _HeroBadge(label: profile.roleName),
                              if (profile.isVerified)
                                const _HeroBadge(label: '已认证'),
                              if (profile.wechatBound)
                                const _HeroBadge(label: '微信已绑定'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (summary != null)
                            Text(
                              summary,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.55,
                                color: Colors.white.withValues(alpha: 0.72),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 110),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String? _profileSummary(UserProfile profile) {
    final bio = profile.bio.trim();
    if (bio.isNotEmpty) return bio;

    final tagline = profile.tagline.trim();
    if (tagline.isNotEmpty) return tagline;

    return null;
  }
}

class _HeroAvatarCard extends StatelessWidget {
  final UserProfile profile;

  const _HeroAvatarCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final initial =
        profile.nickname.isNotEmpty ? profile.nickname[0].toUpperCase() : 'U';
    final avatarUrl = profile.avatar?.trim() ?? '';

    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: avatarUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: avatarUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    _HeroAvatarPlaceholder(initial: initial),
                errorWidget: (_, __, ___) =>
                    _HeroAvatarPlaceholder(initial: initial),
              )
            : _HeroAvatarPlaceholder(initial: initial),
      ),
    );
  }
}

class _HeroAvatarPlaceholder extends StatelessWidget {
  final String initial;

  const _HeroAvatarPlaceholder({required this.initial});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white.withValues(alpha: 0.12),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: 38,
          fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: 0.82),
        ),
      ),
    );
  }
}

class _ProfileMetricsCard extends StatelessWidget {
  final UserProfile profile;

  const _ProfileMetricsCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final items = profile.isDemander
        ? [
            _MetricItem(
              '${profile.stats.publishedProjects}',
              '发布需求',
              Icons.track_changes_outlined,
            ),
            _MetricItem(
              profile.rating.toStringAsFixed(1),
              '综合评分',
              Icons.star_outline_rounded,
            ),
            _MetricItem(
              '${profile.creditScore}',
              '信用分',
              Icons.verified_user_outlined,
            ),
          ]
        : [
            _MetricItem(
              '${profile.stats.completedProjects}',
              '完成项目',
              Icons.task_alt_outlined,
            ),
            _MetricItem(
              profile.rating.toStringAsFixed(1),
              '综合评分',
              Icons.star_outline_rounded,
            ),
            _MetricItem(
              '${profile.creditScore}',
              '信用分',
              Icons.verified_user_outlined,
            ),
          ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Expanded(
            child: Row(
              children: [
                if (index != 0)
                  Container(
                    width: 1,
                    height: 34,
                    color: AppColors.gray100,
                  ),
                if (index != 0) const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.value,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1C1C),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            item.icon,
                            size: 13,
                            color: AppColors.gray400,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.label,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.gray400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ProfileInfoCard extends StatelessWidget {
  final UserProfile profile;

  const _ProfileInfoCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final summary = _profileSummary(profile);
    final rows = <_InfoItem>[
      _InfoItem('身份', profile.roleName),
      _InfoItem('认证状态', profile.isVerified ? '已认证' : '未认证'),
      _InfoItem('微信绑定', profile.wechatBound ? '已绑定' : '未绑定'),
      _InfoItem('信用分', '${profile.creditScore}'),
      if (_formatMaskedPhone(profile.phone) != null)
        _InfoItem('联系手机', _formatMaskedPhone(profile.phone)!),
      if (_formatJoinLabel(profile.createdAt) != null)
        _InfoItem('加入时间', _formatJoinLabel(profile.createdAt)!),
    ];
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (summary != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
              child: Text(
                summary,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.7,
                  color: Color(0xFF555555),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 18),
              height: 1,
              color: AppColors.gray100,
            ),
          ],
          Padding(
            padding: EdgeInsets.fromLTRB(18, summary != null ? 14 : 18, 18, 16),
            child: Column(
              children: rows.asMap().entries.map((entry) {
                final isLast = entry.key == rows.length - 1;
                final row = entry.value;
                return Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 72,
                        child: Text(
                          row.label,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.gray400,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          row.value,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF1A1C1C),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  static String? _profileSummary(UserProfile profile) {
    final bio = profile.bio.trim();
    if (bio.isNotEmpty) return bio;

    final tagline = profile.tagline.trim();
    if (tagline.isNotEmpty) return tagline;

    return null;
  }

  static String? _formatMaskedPhone(String? phone) {
    if (phone == null || phone.trim().isEmpty) return null;
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 7) {
      return '${digits.substring(0, 3)}****${digits.substring(digits.length - 4)}';
    }
    return phone;
  }

  static String? _formatJoinLabel(String raw) {
    if (raw.trim().isEmpty) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      return raw.length >= 10 ? raw.substring(0, 10) : raw;
    }
    return '${parsed.year}.${parsed.month.toString().padLeft(2, '0')}';
  }
}

class _ProfileMenuGroup extends StatelessWidget {
  final List<_ProfileMenuItem> items;

  const _ProfileMenuGroup({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final isLast = entry.key == items.length - 1;
          final item = entry.value;
          return _ProfileMenuRow(
            item: item,
            isLast: isLast,
          );
        }).toList(),
      ),
    );
  }
}

class _ProfileMenuRow extends StatelessWidget {
  final _ProfileMenuItem item;
  final bool isLast;

  const _ProfileMenuRow({
    required this.item,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: item.onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
                  bottom: BorderSide(color: AppColors.gray100),
                ),
        ),
        child: Row(
          children: [
            Text(
              item.label,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF1A1C1C),
              ),
            ),
            const Spacer(),
            if (item.trailingText != null) ...[
              Text(
                item.trailingText!,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.gray400,
                ),
              ),
              const SizedBox(width: 8),
            ],
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

class _TopActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _TopActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  final String label;

  const _HeroBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.white.withValues(alpha: 0.86),
        ),
      ),
    );
  }
}

class _MetricItem {
  final String value;
  final String label;
  final IconData icon;

  const _MetricItem(this.value, this.label, this.icon);
}

class _InfoItem {
  final String label;
  final String value;

  const _InfoItem(this.label, this.value);
}

class _ProfileMenuItem {
  final String label;
  final String? trailingText;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.label,
    this.trailingText,
    required this.onTap,
  });
}

class _DotGridPainter extends CustomPainter {
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
