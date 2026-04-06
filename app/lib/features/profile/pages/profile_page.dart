import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forge2d/forge2d.dart' as f2d;
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_colors.dart';
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
              left: 18,
              right: 18,
              top: 64,
              bottom: 10,
              child: IgnorePointer(
                child: _HeroSkillBottleField(
                  skills: skills
                      .where((skill) => skill.name.trim().isNotEmpty)
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

class _HeroSkillBottleField extends StatefulWidget {
  final List<SkillTag> skills;

  const _HeroSkillBottleField({required this.skills});

  @override
  State<_HeroSkillBottleField> createState() => _HeroSkillBottleFieldState();
}

class _HeroSkillBottleFieldState extends State<_HeroSkillBottleField>
    with SingleTickerProviderStateMixin {
  static const double _worldScale = 30;
  static const double _settleTimeLimit = 5.2;

  late final Ticker _ticker;
  f2d.World? _world;
  Size _fieldSize = Size.zero;
  Duration? _lastElapsed;
  double _elapsedSeconds = 0;
  bool _reduceMotion = false;

  List<_SkillBottleParticle> _particles = const [];

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tickWorld);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextReduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (_reduceMotion != nextReduceMotion) {
      _reduceMotion = nextReduceMotion;
      _scheduleWorldReset();
    }
  }

  @override
  void didUpdateWidget(covariant _HeroSkillBottleField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_skillsSignature(oldWidget.skills) != _skillsSignature(widget.skills)) {
      _scheduleWorldReset();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _scheduleWorldReset() {
    if (!mounted || _fieldSize.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _configureWorld(_fieldSize);
    });
  }

  void _configureWorld(Size size) {
    if (size.isEmpty) return;

    _ticker.stop();
    _lastElapsed = null;
    _elapsedSeconds = 0;

    final world = f2d.World(f2d.Vector2(0, 24));
    world.setAllowSleep(true);
    final random = math.Random(_createLayoutSeed(size));

    final particles = _buildParticles(size, world, random);
    _buildBottleBounds(size, world, random);

    if (_reduceMotion) {
      for (final particle in particles) {
        _releaseParticle(particle, applyImpulse: false);
      }
      for (var i = 0; i < 210; i++) {
        world.stepDt(1 / 60);
      }
      for (final particle in particles) {
        particle.body.setAwake(false);
      }
    } else {
      _ticker.start();
    }

    setState(() {
      _world = world;
      _particles = particles;
    });
  }

  List<_SkillBottleParticle> _buildParticles(
    Size size,
    f2d.World world,
    math.Random random,
  ) {
    final widthInWorld = size.width / _worldScale;
    final heightInWorld = size.height / _worldScale;
    final particles = <_SkillBottleParticle>[];
    final primarySkillId = widget.skills
        .cast<SkillTag?>()
        .firstWhere(
          (skill) => skill?.isPrimary == true,
          orElse: () => widget.skills.isEmpty ? null : widget.skills.first,
        )
        ?.id;
    final shuffledSkills = [...widget.skills]..shuffle(random);
    final skillCount = math.max(1, shuffledSkills.length);
    final chipScale = (1 - (math.max(0, skillCount - 8) * 0.018)).clamp(
      0.78,
      1.0,
    );

    for (final entry in shuffledSkills.asMap().entries) {
      final skill = entry.value;
      final label = _BottleSkillChip.displayLabelOf(skill);
      final isHighlighted = skill.id == primarySkillId;
      final visual = _SkillBottleVisual.fromSkill(
        skill,
        highlighted: isHighlighted,
      );
      final chipWidth =
          (40 + (label.length * (5.5 * chipScale)) + (random.nextDouble() * 16))
              .clamp(44.0 * chipScale, 82.0 * chipScale);
      final chipHeight =
          (20.5 + (random.nextDouble() * 6.2)) * (0.9 + (chipScale * 0.1));
      final chipWidthWorld = chipWidth / _worldScale;
      final chipHeightWorld = chipHeight / _worldScale;
      final minCenterX = 0.34 + (chipWidthWorld / 2);
      final maxCenterX = widthInWorld - 0.34 - (chipWidthWorld / 2);
      final edgeBias = random.nextDouble();
      final spreadX = edgeBias < 0.2
          ? math.pow(random.nextDouble(), 0.72).toDouble()
          : edgeBias > 0.8
              ? 1 - math.pow(random.nextDouble(), 0.72).toDouble()
              : random.nextDouble();
      final startX = minCenterX + ((maxCenterX - minCenterX) * spreadX);
      final verticalRoll = random.nextDouble();
      final heightBand = switch (verticalRoll) {
        < 0.25 => 0.02 + (random.nextDouble() * 0.12),
        < 0.58 => 0.12 + (random.nextDouble() * 0.2),
        < 0.84 => 0.28 + (random.nextDouble() * 0.22),
        _ => 0.46 + (random.nextDouble() * 0.18),
      };
      final startY = (heightInWorld * heightBand).clamp(
        heightInWorld * 0.02,
        heightInWorld * 0.68,
      );
      final delayRoll = random.nextDouble();
      final launchDelay = switch (delayRoll) {
        < 0.18 => random.nextDouble() * 0.28,
        < 0.5 => 0.2 + (random.nextDouble() * 0.9),
        < 0.82 => 0.9 + (random.nextDouble() * 1.2),
        _ => 1.9 + (random.nextDouble() * 1.4),
      };
      final ballastDirection = random.nextBool() ? 1.0 : -1.0;
      final ballastOffsetX = ballastDirection *
          (chipWidthWorld * (0.1 + random.nextDouble() * 0.16));
      final ballastOffsetY =
          (chipHeightWorld * (0.06 + random.nextDouble() * 0.12));
      final launchPointLocal = f2d.Vector2(
        ballastDirection *
            (chipWidthWorld * (0.12 + random.nextDouble() * 0.16)),
        -(chipHeightWorld * (0.08 + random.nextDouble() * 0.12)),
      );
      final launchImpulse = f2d.Vector2(
        (random.nextDouble() - 0.5) * (0.8 + random.nextDouble() * 1.6),
        0.02 + (random.nextDouble() * 0.34),
      );
      final angularImpulse =
          (ballastDirection * (0.012 + random.nextDouble() * 0.05)) +
              ((random.nextDouble() - 0.5) * 0.026);
      final bodyDensity = 1.0 + (random.nextDouble() * 0.28);
      final bodyFriction = 0.62 + (random.nextDouble() * 0.18);
      final bodyRestitution = 0.03 + (random.nextDouble() * 0.05);
      final gravityScaleY = 0.84 + (random.nextDouble() * 0.92);
      final idleOpacity =
          0.04 + math.pow(random.nextDouble(), 1.35).toDouble() * 0.18;

      final body = world.createBody(
        f2d.BodyDef(
          type: f2d.BodyType.dynamic,
          active: true,
          isAwake: false,
          position: f2d.Vector2(
            startX.clamp(minCenterX, maxCenterX),
            startY,
          ),
          angle: (random.nextDouble() - 0.5) * 0.68,
          linearDamping: 1.9 + (random.nextDouble() * 1.5),
          angularDamping: 2.1 + (random.nextDouble() * 2.4),
          gravityScale: f2d.Vector2(1, gravityScaleY),
        ),
      );

      final cornerRadiusWorld = chipHeightWorld / 2;
      final centerHalfWidth = math.max(
        0.001,
        (chipWidthWorld / 2) - cornerRadiusWorld,
      );
      final centerBox = f2d.PolygonShape()
        ..setAsBoxXY(centerHalfWidth, chipHeightWorld / 2);
      final leftCap = f2d.CircleShape(
        radius: cornerRadiusWorld,
        position: f2d.Vector2(-centerHalfWidth, 0),
      );
      final rightCap = f2d.CircleShape(
        radius: cornerRadiusWorld,
        position: f2d.Vector2(centerHalfWidth, 0),
      );

      body.createFixtureFromShape(
        centerBox,
        density: bodyDensity,
        friction: bodyFriction,
        restitution: bodyRestitution,
      );
      body.createFixtureFromShape(
        leftCap,
        density: bodyDensity,
        friction: bodyFriction,
        restitution: bodyRestitution,
      );
      body.createFixtureFromShape(
        rightCap,
        density: bodyDensity,
        friction: bodyFriction,
        restitution: bodyRestitution,
      );
      body.createFixtureFromShape(
        f2d.CircleShape(
          radius: chipHeightWorld * 0.18,
          position: f2d.Vector2(ballastOffsetX, ballastOffsetY),
        ),
        density: bodyDensity * (0.9 + random.nextDouble() * 0.5),
        friction: bodyFriction,
        restitution: bodyRestitution * 0.6,
      );

      particles.add(
        _SkillBottleParticle(
          skill: skill,
          body: body,
          width: chipWidth,
          height: chipHeight,
          visual: visual,
          isHighlighted: isHighlighted,
          launchDelay: launchDelay,
          launchImpulse: launchImpulse,
          launchPointLocal: launchPointLocal,
          angularImpulse: angularImpulse,
          idleOpacity: idleOpacity,
          hasLaunched: _reduceMotion,
        ),
      );
    }

    return particles;
  }

  void _buildBottleBounds(Size size, f2d.World world, math.Random random) {
    final widthInWorld = size.width / _worldScale;
    final heightInWorld = size.height / _worldScale;
    final bounds = world.createBody(f2d.BodyDef());

    final floor = f2d.PolygonShape()
      ..setAsBox(
        widthInWorld * 0.44,
        0.11,
        f2d.Vector2(widthInWorld / 2, heightInWorld - 0.08),
        (random.nextDouble() - 0.5) * 0.05,
      );
    final leftWall = f2d.PolygonShape()
      ..setAsBox(
        0.12,
        heightInWorld * 0.46,
        f2d.Vector2(0.12, heightInWorld * 0.54),
        -(0.03 + random.nextDouble() * 0.03),
      );
    final rightWall = f2d.PolygonShape()
      ..setAsBox(
        0.12,
        heightInWorld * 0.46,
        f2d.Vector2(widthInWorld - 0.12, heightInWorld * 0.54),
        0.03 + (random.nextDouble() * 0.03),
      );

    bounds.createFixtureFromShape(floor, friction: 0.68);
    bounds.createFixtureFromShape(leftWall, friction: 0.14);
    bounds.createFixtureFromShape(rightWall, friction: 0.14);
  }

  void _tickWorld(Duration elapsed) {
    final world = _world;
    if (world == null) return;

    final dt = _lastElapsed == null
        ? 1 / 60
        : ((elapsed - _lastElapsed!).inMicroseconds /
                Duration.microsecondsPerSecond)
            .clamp(1 / 240, 1 / 24);
    _lastElapsed = elapsed;
    _elapsedSeconds += dt;

    for (final particle in _particles) {
      if (!particle.hasLaunched && _elapsedSeconds >= particle.launchDelay) {
        _releaseParticle(particle);
      }
    }

    world.stepDt(dt);

    final shouldStop = _elapsedSeconds > 1.1 &&
        (_particles.every(_isParticleSettled) ||
            _elapsedSeconds >= _settleTimeLimit);

    if (shouldStop) {
      for (final particle in _particles) {
        particle.body.setAwake(false);
      }
      _ticker.stop();
    }

    if (mounted) {
      setState(() {});
    }
  }

  bool _isParticleSettled(_SkillBottleParticle particle) {
    final body = particle.body;
    if (!particle.hasLaunched) return false;
    final minGroundZoneY = (_fieldSize.height / _worldScale) * 0.62;
    if (body.position.y < minGroundZoneY) return false;
    if (!body.isAwake) return true;
    return body.linearVelocity.length2 < 0.015 &&
        body.angularVelocity.abs() < 0.08;
  }

  void _releaseParticle(
    _SkillBottleParticle particle, {
    bool applyImpulse = true,
  }) {
    particle.hasLaunched = true;
    particle.body.setAwake(true);
    if (applyImpulse) {
      particle.body.applyLinearImpulse(
        particle.launchImpulse,
        point: particle.body.worldPoint(particle.launchPointLocal),
      );
      particle.body.applyAngularImpulse(particle.angularImpulse);
    }
  }

  int _skillsSignature(List<SkillTag> skills) {
    return Object.hashAll(
      skills.map((skill) => '${skill.id}|${skill.name}|${skill.category}'),
    );
  }

  int _createLayoutSeed(Size size) {
    final now = DateTime.now().microsecondsSinceEpoch;
    return Object.hash(
      now,
      _skillsSignature(widget.skills),
      size.width.round(),
      size.height.round(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final nextSize = Size(constraints.maxWidth, constraints.maxHeight);
        if (nextSize.width > 0 &&
            nextSize.height > 0 &&
            nextSize != _fieldSize) {
          _fieldSize = nextSize;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _configureWorld(nextSize);
          });
        }

        return RepaintBoundary(
          child: ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (rect) {
              return const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white,
                  Colors.white,
                  Colors.white,
                ],
                stops: [0, 0.04, 1],
              ).createShader(rect);
            },
            child: CustomPaint(
              painter: _SkillBottlePainter(
                particles: _particles,
                worldScale: _worldScale,
              ),
              size: Size.infinite,
            ),
          ),
        );
      },
    );
  }
}

class _SkillBottleParticle {
  final SkillTag skill;
  final f2d.Body body;
  final double width;
  final double height;
  final _SkillBottleVisual visual;
  final bool isHighlighted;
  final double launchDelay;
  final f2d.Vector2 launchImpulse;
  final f2d.Vector2 launchPointLocal;
  final double angularImpulse;
  final double idleOpacity;
  bool hasLaunched;

  _SkillBottleParticle({
    required this.skill,
    required this.body,
    required this.width,
    required this.height,
    required this.visual,
    required this.isHighlighted,
    required this.launchDelay,
    required this.launchImpulse,
    required this.launchPointLocal,
    required this.angularImpulse,
    required this.idleOpacity,
    this.hasLaunched = false,
  });
}

class _SkillBottleVisual {
  final String label;
  final IconData icon;
  final Color topColor;
  final Color bottomColor;
  final Color rimColor;
  final Color glowColor;
  final Color iconColor;
  final Color labelColor;
  final Color sparkColor;

  const _SkillBottleVisual({
    required this.label,
    required this.icon,
    required this.topColor,
    required this.bottomColor,
    required this.rimColor,
    required this.glowColor,
    required this.iconColor,
    required this.labelColor,
    required this.sparkColor,
  });

  factory _SkillBottleVisual.fromSkill(
    SkillTag skill, {
    required bool highlighted,
  }) {
    final icon = _BottleSkillChip.iconOf(skill);
    final label = _BottleSkillChip.displayLabelOf(skill);
    final name = skill.name.trim().toLowerCase();
    final category = skill.category.trim().toLowerCase();

    if (highlighted) {
      return _SkillBottleVisual(
        label: label,
        icon: icon,
        topColor: const Color(0xFF8B7CFF),
        bottomColor: const Color(0xFF5F4BD6),
        rimColor: Colors.white.withValues(alpha: 0.24),
        glowColor: AppColors.accent.withValues(alpha: 0.16),
        iconColor: Colors.white.withValues(alpha: 0.96),
        labelColor: Colors.white.withValues(alpha: 0.92),
        sparkColor: const Color(0xFFC7BCFF),
      );
    }

    if (name.contains('flutter') || category == 'mobile') {
      return _SkillBottleVisual(
        label: label,
        icon: icon,
        topColor: const Color(0xFF7FA2C6),
        bottomColor: const Color(0xFF556E8B),
        rimColor: Colors.white.withValues(alpha: 0.16),
        glowColor: const Color(0xFF84C3FF).withValues(alpha: 0.08),
        iconColor: Colors.white.withValues(alpha: 0.84),
        labelColor: Colors.white.withValues(alpha: 0.76),
        sparkColor: const Color(0xFFB9E3FF),
      );
    }

    if (name.contains('react') || category == 'framework') {
      return _SkillBottleVisual(
        label: label,
        icon: icon,
        topColor: const Color(0xFF6389BC),
        bottomColor: const Color(0xFF405F86),
        rimColor: Colors.white.withValues(alpha: 0.14),
        glowColor: AppColors.info.withValues(alpha: 0.08),
        iconColor: Colors.white.withValues(alpha: 0.82),
        labelColor: Colors.white.withValues(alpha: 0.74),
        sparkColor: const Color(0xFF95D6FF),
      );
    }

    if (name.contains('ui') || name.contains('设计') || category == 'design') {
      return _SkillBottleVisual(
        label: label,
        icon: icon,
        topColor: const Color(0xFFAD8A63),
        bottomColor: const Color(0xFF70583C),
        rimColor: Colors.white.withValues(alpha: 0.14),
        glowColor: AppColors.accentGold.withValues(alpha: 0.08),
        iconColor: Colors.white.withValues(alpha: 0.84),
        labelColor: Colors.white.withValues(alpha: 0.76),
        sparkColor: const Color(0xFFF4D6A0),
      );
    }

    return _SkillBottleVisual(
      label: label,
      icon: icon,
      topColor: const Color(0xFF6D6F78),
      bottomColor: const Color(0xFF44464E),
      rimColor: Colors.white.withValues(alpha: 0.12),
      glowColor: Colors.white.withValues(alpha: 0.05),
      iconColor: Colors.white.withValues(alpha: 0.8),
      labelColor: Colors.white.withValues(alpha: 0.72),
      sparkColor: Colors.white.withValues(alpha: 0.78),
    );
  }
}

class _SkillBottlePainter extends CustomPainter {
  final List<_SkillBottleParticle> particles;
  final double worldScale;

  const _SkillBottlePainter({
    required this.particles,
    required this.worldScale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final floorGlowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, 1.15),
        radius: 0.9,
        colors: [
          Colors.white.withValues(alpha: 0.08),
          Colors.white.withValues(alpha: 0.03),
          Colors.white.withValues(alpha: 0),
        ],
        stops: const [0, 0.34, 1],
      ).createShader(
        Rect.fromLTWH(0, size.height * 0.16, size.width, size.height * 0.92),
      );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      floorGlowPaint,
    );

    final floorPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.28, size.height - 2.5),
      Offset(size.width * 0.72, size.height - 2.5),
      floorPaint,
    );

    final regularParticles = particles
        .where((particle) => !particle.isHighlighted)
        .toList(growable: false)
      ..sort((a, b) => a.body.position.y.compareTo(b.body.position.y));
    final highlightedParticles = particles
        .where((particle) => particle.isHighlighted)
        .toList(growable: false)
      ..sort((a, b) => a.body.position.y.compareTo(b.body.position.y));

    for (final particle in regularParticles) {
      _paintParticle(canvas, size, particle);
    }
    for (final particle in highlightedParticles) {
      _paintParticle(canvas, size, particle);
    }
  }

  void _paintParticle(Canvas canvas, Size size, _SkillBottleParticle particle) {
    final center = Offset(
      particle.body.position.x * worldScale,
      particle.body.position.y * worldScale,
    );
    final isPinnedHighlight = particle.isHighlighted;
    final opacity = isPinnedHighlight ? 0.96 : 0.68;
    final fillTopColor = particle.visual.topColor;
    final fillBottomColor = particle.visual.bottomColor;
    final rimColor = particle.visual.rimColor;
    final iconColor = particle.visual.iconColor;
    final labelColor = particle.visual.labelColor;
    final sparkColor = particle.visual.sparkColor;
    final shadowShift = isPinnedHighlight ? 3.2 : 2.4;
    final angle = particle.body.angle;
    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: particle.width,
      height: particle.height,
    );
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(particle.height / 2),
    );

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    final auraPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
      ..color = (isPinnedHighlight
              ? particle.visual.glowColor.withValues(alpha: 0.24)
              : particle.visual.glowColor.withValues(alpha: 0.08))
          .withValues(alpha: isPinnedHighlight ? 0.22 : 0.08);
    canvas.drawRRect(rrect.inflate(3.2), auraPaint);

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(
        alpha: (isPinnedHighlight ? 0.1 : 0.08) * opacity,
      );
    canvas.drawRRect(rrect.shift(Offset(0, shadowShift)), shadowPaint);

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          fillTopColor.withValues(alpha: opacity * 0.96),
          fillBottomColor.withValues(alpha: opacity * 0.9),
        ],
      ).createShader(rect);
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..color = rimColor.withValues(
        alpha: isPinnedHighlight ? 0.94 : opacity + 0.04,
      );

    canvas.drawRRect(rrect, fillPaint);
    canvas.drawRRect(rrect, strokePaint);

    final topHighlightPaint = Paint()
      ..color = Colors.white.withValues(
        alpha: isPinnedHighlight ? 0.22 : 0.14,
      )
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(-(particle.width / 2) + 8, -(particle.height * 0.18)),
      Offset((particle.width / 2) - 12, -(particle.height * 0.18)),
      topHighlightPaint,
    );

    final iconBubbleCenter = Offset(
      -(particle.width / 2) + (particle.height * 0.56),
      0,
    );
    final iconBubblePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(
            alpha: isPinnedHighlight ? 0.36 : 0.18,
          ),
          Colors.white.withValues(alpha: isPinnedHighlight ? 0.08 : 0.04),
        ],
      ).createShader(
        Rect.fromCircle(
          center: iconBubbleCenter,
          radius: particle.height * 0.34,
        ),
      );
    canvas.drawCircle(
      iconBubbleCenter,
      particle.height * 0.3,
      iconBubblePaint,
    );

    _paintIcon(
      canvas,
      particle.visual.icon,
      iconBubbleCenter,
      color: iconColor.withValues(
        alpha: isPinnedHighlight ? 0.98 : 0.86,
      ),
      size: (particle.height * 0.46).clamp(9.6, 12.8),
    );

    _paintLabel(
      canvas,
      particle.visual.label,
      Offset(iconBubbleCenter.dx + (particle.height * 0.46), 0),
      color: labelColor.withValues(alpha: isPinnedHighlight ? 0.96 : 0.84),
      fontSize: (particle.height * 0.4).clamp(8.6, 10.6),
    );

    final sparkPaint = Paint()
      ..color = sparkColor.withValues(
        alpha: isPinnedHighlight ? 0.48 : 0.22,
      );
    canvas.drawCircle(
      Offset((particle.width / 2) - 8, -(particle.height * 0.12)),
      1.8,
      sparkPaint,
    );

    canvas.restore();
  }

  void _paintIcon(
    Canvas canvas,
    IconData icon,
    Offset center, {
    required Color color,
    required double size,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          inherit: false,
          fontSize: size,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    painter.paint(
      canvas,
      Offset(center.dx - (painter.width / 2), center.dy - (painter.height / 2)),
    );
  }

  void _paintLabel(
    Canvas canvas,
    String label,
    Offset anchor, {
    required Color color,
    required double fontSize,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          inherit: false,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.24,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    painter.paint(
      canvas,
      Offset(anchor.dx, -painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _SkillBottlePainter oldDelegate) {
    return true;
  }
}

class _BottleSkillChip extends StatelessWidget {
  final SkillTag skill;
  final bool highlighted;

  const _BottleSkillChip({
    required this.skill,
    required this.highlighted,
  });

  static String displayLabelOf(SkillTag skill) {
    final name = skill.name.trim();
    const aliases = {
      'Flutter': 'FL',
      'React': 'RE',
      'Python': 'PY',
      'Docker': 'DK',
      'VS Code': 'VS',
      'Cursor': 'CS',
      'Jira': 'JR',
      'Notion': 'NT',
      'Git': 'Git',
      'UI设计': 'UI',
      '后端': 'API',
      'Rust': 'RS',
    };
    return aliases[name] ?? (name.length <= 4 ? name : name.substring(0, 4));
  }

  static IconData iconOf(SkillTag skill) {
    final name = skill.name.trim().toLowerCase();
    final category = skill.category.trim().toLowerCase();

    if (name.contains('flutter')) return Icons.flutter_dash_rounded;
    if (name.contains('react')) return Icons.blur_circular_rounded;
    if (name.contains('python')) return Icons.code_rounded;
    if (name.contains('docker')) return Icons.inventory_2_outlined;
    if (name.contains('jira')) return Icons.view_kanban_outlined;
    if (name.contains('notion')) return Icons.notes_rounded;
    if (name.contains('git')) return Icons.source_rounded;
    if (name.contains('cursor')) return Icons.ads_click_rounded;
    if (name.contains('rust')) return Icons.settings_suggest_rounded;
    if (name.contains('ui') || name.contains('设计')) {
      return Icons.palette_outlined;
    }
    if (name.contains('后端')) return Icons.dns_outlined;

    switch (category) {
      case 'mobile':
        return Icons.phone_iphone_rounded;
      case 'framework':
        return Icons.layers_outlined;
      case 'language':
        return Icons.code_rounded;
      case 'design':
        return Icons.palette_outlined;
      case 'tool':
        return Icons.build_outlined;
      default:
        return Icons.auto_awesome_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = displayLabelOf(skill);
    final icon = iconOf(skill);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: highlighted
            ? AppColors.accent.withValues(alpha: 0.16)
            : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: highlighted
              ? AppColors.accent.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(
                  alpha: highlighted ? 0.18 : 0.1,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 10,
                color: highlighted
                    ? Colors.white.withValues(alpha: 0.96)
                    : Colors.white.withValues(alpha: 0.76),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: highlighted
                    ? Colors.white.withValues(alpha: 0.95)
                    : Colors.white.withValues(alpha: 0.72),
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
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
