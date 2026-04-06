import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/vcc_avatar.dart';
import '../../../shared/widgets/vcc_button.dart';
import '../../../shared/widgets/vcc_loading.dart';
import '../../../shared/widgets/vcc_tag.dart';
import '../../team/models/team_profile.dart';
import '../../team/providers/team_provider.dart';

class TeamProfilePage extends ConsumerStatefulWidget {
  final String teamId;

  const TeamProfilePage({super.key, required this.teamId});

  @override
  ConsumerState<TeamProfilePage> createState() => _TeamProfilePageState();
}

class _TeamProfilePageState extends ConsumerState<TeamProfilePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _particleController;
  late final List<_Particle> _particles;
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _particles = List.generate(35, (_) => _Particle.random(_rng));
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(teamProfileProvider(widget.teamId));

    if (state.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF9F9F9),
        body: VccLoading(),
      );
    }

    final profile = state.profile;
    if (profile == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9F9F9),
        appBar: AppBar(
          title: const Text(
            '团队资料',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
        ),
        body: const Center(
          child: Text('未找到团队信息', style: TextStyle(color: AppColors.gray400)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: CustomScrollView(
        slivers: [
          _buildHeroSliver(context, profile),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 28),
                  _buildStatsRow(profile),
                  if (profile.description != null &&
                      profile.description!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildDescBlock(profile),
                  ],
                  if (profile.skills.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildSkillsBlock(profile),
                  ],
                  if (profile.members.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildMembersBlock(profile),
                  ],
                  const SizedBox(height: 20),
                  _buildInfoBlock(profile),
                  const SizedBox(height: 32),
                  VccButton(text: '发起沟通', onPressed: null),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSliver(BuildContext context, TeamProfile profile) {
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _particleController,
        builder: (context, child) {
          _tickParticles();
          return CustomPaint(
            painter: _ParticlePainter(_particles),
            child: child,
          );
        },
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0A0A0A), Color(0xFF1A1A1A)],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    behavior: HitTestBehavior.opaque,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.06),
                              blurRadius: 24,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: VccAvatar(
                          imageUrl: profile.avatarUrl,
                          size: VccAvatarSize.xlarge,
                          fallbackText: profile.teamName.isNotEmpty
                              ? profile.teamName[0]
                              : 'T',
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              profile.teamName,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                height: 1.2,
                                letterSpacing: -0.5,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                if (profile.vibeLevel != null &&
                                    profile.vibeLevel!.isNotEmpty)
                                  _HeroBadge(
                                    text: profile.vibeLevel!,
                                    bright: true,
                                  ),
                                _HeroBadge(
                                  text: profile.memberCount > 1
                                      ? '${profile.memberCount}人团队'
                                      : '个人',
                                ),
                                if (profile.isAvailable)
                                  const _HeroBadge(text: '接单中'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (profile.tagline != null &&
                      profile.tagline!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      profile.tagline!,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: Colors.white54,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 20),
                  Text(
                    profile.rateDisplay,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(TeamProfile profile) {
    final hasVibeLevel =
        profile.vibeLevel != null && profile.vibeLevel!.isNotEmpty;

    return Row(
      children: [
        _StatCard(
          value: hasVibeLevel
              ? profile.vibeLevel!
              : (profile.avgRating > 0
                  ? profile.avgRating.toStringAsFixed(1)
                  : '-'),
          label: hasVibeLevel ? '等级' : '评分',
          icon: hasVibeLevel ? Icons.shield_rounded : Icons.star_rounded,
          iconColor:
              hasVibeLevel ? const Color(0xFF1A1C1C) : AppColors.accentGold,
        ),
        const SizedBox(width: 10),
        _StatCard(
          value: '${profile.totalProjects}',
          label: '历史项目',
          icon: Icons.folder_outlined,
          iconColor: const Color(0xFF1A1C1C),
        ),
        const SizedBox(width: 10),
        _StatCard(
          value: profile.experienceYears > 0
              ? '${profile.experienceYears}年'
              : '-',
          label: '经验',
          icon: Icons.timeline_rounded,
          iconColor: AppColors.gray500,
        ),
      ],
    );
  }

  Widget _buildDescBlock(TeamProfile profile) {
    return _CardBlock(
      label: '团队介绍',
      child: Text(
        profile.description!,
        style: const TextStyle(
          fontSize: 14,
          height: 1.7,
          color: Color(0xFF555555),
        ),
      ),
    );
  }

  Widget _buildSkillsBlock(TeamProfile profile) {
    return _CardBlock(
      label: '技术栈',
      child: Wrap(
        spacing: 8,
        runSpacing: 10,
        children: profile.skills.map((s) => VccTag(label: s)).toList(),
      ),
    );
  }

  Widget _buildMembersBlock(TeamProfile profile) {
    return _CardBlock(
      label: '团队成员',
      child: Column(
        children: profile.members.asMap().entries.map((entry) {
          final m = entry.value;
          return Padding(
            padding: EdgeInsets.only(
              bottom: entry.key < profile.members.length - 1 ? 14 : 0,
            ),
            child: Row(
              children: [
                VccAvatar(
                  imageUrl: m.avatarUrl,
                  size: VccAvatarSize.small,
                  fallbackText: m.nickname.isNotEmpty ? m.nickname[0] : '?',
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              m.nickname,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1C1C),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (m.isLeader) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1C1C),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                '队长',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (m.role.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          m.role,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.gray400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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

  Widget _buildInfoBlock(TeamProfile profile) {
    return _CardBlock(
      label: '详细信息',
      child: Column(
        children: [
          _InfoRow(label: '团队规模', value: '${profile.memberCount} 人'),
          if (profile.vibePower > 0) ...[
            const SizedBox(height: 14),
            _InfoRow(label: 'Vibe Power', value: '${profile.vibePower}'),
          ],
          const SizedBox(height: 14),
          _InfoRow(
            label: '完成项目',
            value: '${profile.completedProjects} 个',
          ),
          if (profile.hourlyRate != null && profile.hourlyRate! > 0) ...[
            const SizedBox(height: 14),
            _InfoRow(
              label: '报价范围',
              value: '¥${profile.hourlyRate!.toInt()}/h',
            ),
          ],
          if (profile.experienceYears > 0) ...[
            const SizedBox(height: 14),
            _InfoRow(
              label: '经验年限',
              value: '${profile.experienceYears} 年',
            ),
          ],
        ],
      ),
    );
  }

  void _tickParticles() {
    for (final p in _particles) {
      p.vy += p.gravity;
      p.x += p.vx;
      p.y += p.vy;

      if (p.y > 1.0) {
        p.y = -0.02;
        p.vy = _rng.nextDouble() * 0.002;
        p.x = _rng.nextDouble();
      }
      if (p.x > 1.0) p.x = 0.0;
      if (p.x < 0.0) p.x = 1.0;

      p.opacity = (p.baseOpacity * (1.0 - p.y * 0.5)).clamp(0.0, 1.0);
    }
  }
}

class _HeroBadge extends StatelessWidget {
  final String text;
  final bool bright;

  const _HeroBadge({required this.text, this.bright = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: bright ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: bright ? FontWeight.w600 : FontWeight.w500,
          color: bright ? Colors.white : Colors.white60,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color iconColor;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1C1C),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.gray400,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardBlock extends StatelessWidget {
  final String label;
  final Widget child;

  const _CardBlock({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.gray400,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: AppColors.gray500),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1A1C1C),
          ),
        ),
      ],
    );
  }
}

class _Particle {
  double x;
  double y;
  double vx;
  double vy;
  double radius;
  double opacity;
  double baseOpacity;
  double gravity;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.radius,
    required this.opacity,
    required this.baseOpacity,
    required this.gravity,
  });

  factory _Particle.random(Random rng) {
    final baseOp = 0.08 + rng.nextDouble() * 0.25;
    return _Particle(
      x: rng.nextDouble(),
      y: rng.nextDouble(),
      vx: (rng.nextDouble() - 0.5) * 0.0008,
      vy: rng.nextDouble() * 0.002,
      radius: 0.8 + rng.nextDouble() * 2.0,
      opacity: baseOp,
      baseOpacity: baseOp,
      gravity: 0.00001 + rng.nextDouble() * 0.00004,
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;

  _ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: p.opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}
