import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/vcc_avatar.dart';
import '../../../shared/widgets/vcc_button.dart';
import '../../../shared/widgets/vcc_tag.dart';
import '../../../shared/widgets/vcc_toast.dart';
import '../../auth/providers/auth_provider.dart';
import '../../favorite/providers/favorite_provider.dart';
import '../providers/project_detail_provider.dart';

class ProjectDetailPage extends ConsumerWidget {
  final String? projectId;

  const ProjectDetailPage({super.key, this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = projectId ?? '';
    if (id.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('项目详情')),
        body: const Center(child: Text('无效的项目ID')),
      );
    }

    final state = ref.watch(projectDetailProvider(id));

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: state.isLoading
          ? const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.black),
                ),
              ),
            )
          : state.data == null
              ? const Center(
                  child: Text(
                    '加载失败',
                    style: TextStyle(color: AppColors.gray500),
                  ),
                )
              : _DetailContent(state: state, projectId: id),
      bottomNavigationBar: state.data != null
          ? _BottomActions(projectId: id, state: state)
          : null,
    );
  }
}

class _BottomActions extends ConsumerWidget {
  final String projectId;
  final ProjectDetailState state;

  const _BottomActions({required this.projectId, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final isDemander = authState.userRole != 2;

    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: Row(
            children: [
              Expanded(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    VccButton(
                      text: '沟通',
                      type: VccButtonType.secondary,
                      onPressed: null,
                    ),
                    Positioned(
                      right: -4,
                      top: -8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gray500,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '即将开放',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: VccButton(
                  text: _rightButtonText(isDemander),
                  onPressed: _rightButtonEnabled(isDemander)
                      ? () => _rightButtonAction(context, ref, isDemander)
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _rightButtonText(bool isDemander) {
    if (isDemander) {
      if (state.status <= 2) return '查看投标';
      return '查看进度';
    } else {
      if (state.status >= 5) return '进入看板';
      if (state.hasBid) return '已投标';
      return '投标';
    }
  }

  bool _rightButtonEnabled(bool isDemander) {
    if (!isDemander && state.status < 5 && state.hasBid) return false;
    return true;
  }

  Future<void> _rightButtonAction(
      BuildContext context, WidgetRef ref, bool isDemander) async {
    if (isDemander) {
      if (state.status <= 2) {
        context.push('/projects/$projectId/bids');
      } else {
        context.push('/projects/$projectId/manage');
      }
    } else {
      if (state.status >= 5) {
        context.push('/projects/$projectId/manage');
      } else {
        await context.push('/projects/$projectId/bid');
        if (context.mounted) {
          ref.invalidate(projectDetailProvider(projectId));
        }
      }
    }
  }
}

class _DetailContent extends StatelessWidget {
  final ProjectDetailState state;
  final String projectId;

  const _DetailContent({required this.state, required this.projectId});

  @override
  Widget build(BuildContext context) {
    final s = state;

    return CustomScrollView(
      slivers: [
        _ParticleHeroSliver(state: s, projectId: projectId),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (s.ownerName.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildOwnerCard(s),
              ],
              const SizedBox(height: 12),
              _buildDescriptionSection(s),
              if (s.prdSummary.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildPrdSection(s),
              ],
              if (s.milestones.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildMilestoneSection(s),
              ],
              const SizedBox(height: 48),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOwnerCard(ProjectDetailState s) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          VccAvatar(
            size: VccAvatarSize.medium,
            fallbackText:
                s.ownerName.isNotEmpty ? s.ownerName.substring(0, 1) : '?',
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.ownerName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1C1C),
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  '项目方',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.gray400,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F3F3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '查看主页',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF666666),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection(ProjectDetailState s) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('项目概要'),
          const SizedBox(height: 14),
          Text(
            s.description,
            style: const TextStyle(
              fontSize: 15,
              height: 1.7,
              color: Color(0xFF444444),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F9F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _buildSummaryRow('预算范围', s.budgetDisplay),
                const SizedBox(height: 12),
                _buildSummaryRow('项目分类', s.categoryName),
                if (s.timeAgo.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildSummaryRow('发布时间', s.timeAgo),
                ],
                const SizedBox(height: 12),
                _buildSummaryRow('浏览/投标',
                    '${s.viewCount} 次浏览 · ${s.bidCount} 个投标'),
              ],
            ),
          ),
          if (s.techRequirements.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              '技术要求',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.gray400,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  s.techRequirements.map((t) => VccTag(label: t)).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF999999),
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF444444),
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPrdSection(ProjectDetailState s) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('PRD 摘要'),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F3F3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              s.prdSummary,
              style: const TextStyle(
                fontSize: 14,
                height: 1.7,
                color: Color(0xFF555555),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneSection(ProjectDetailState s) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _SectionLabel('里程碑'),
              if (s.progress > 0) ...[
                const SizedBox(width: 8),
                Text(
                  '${s.progress}%',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray500,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          ...s.milestones.asMap().entries.map(
                (entry) => _buildMilestone(
                  entry.value,
                  isLast: entry.key == s.milestones.length - 1,
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildMilestone(Map<String, dynamic> milestone,
      {bool isLast = false}) {
    final title = milestone['title']?.toString() ?? '';
    final status = milestone['status']?.toString() ?? 'pending';
    final progress = milestone['progress'] as int? ?? 0;

    final isCompleted = status == 'completed';
    final isActive = status == 'in_progress';

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppColors.success
                  : isActive
                      ? AppColors.black
                      : const Color(0xFFE8E8E8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isCompleted ? Icons.check : Icons.circle,
              size: isCompleted ? 16 : 8,
              color: isCompleted || isActive
                  ? AppColors.white
                  : AppColors.gray400,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isCompleted
                    ? AppColors.gray400
                    : const Color(0xFF1A1C1C),
                decoration: isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          if (isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F3F3),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$progress%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1C1C),
                ),
              ),
            ),
        ],
      ),
    );
  }

}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1A1C1C),
        letterSpacing: -0.2,
      ),
    );
  }
}

class _ParticleHeroSliver extends StatefulWidget {
  final ProjectDetailState state;
  final String projectId;

  const _ParticleHeroSliver({required this.state, required this.projectId});

  @override
  State<_ParticleHeroSliver> createState() => _ParticleHeroSliverState();
}

class _ParticleHeroSliverState extends State<_ParticleHeroSliver>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _particles = List.generate(
      40,
      (_) => _Particle.random(_random),
    );
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    return SliverToBoxAdapter(
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F0F0F), Color(0xFF1E1E1E)],
              ),
            ),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                _updateParticles();
                return CustomPaint(
                  painter: _ParticlePainter(_particles),
                  child: child,
                );
              },
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
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
                          const Spacer(),
                          _FavoriteButton(projectId: widget.projectId),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          VccStatusTag(
                            label: s.statusName,
                            type: VccTagType.status,
                            status: _statusTagType(s.status),
                          ),
                          if (s.matchScore > 0) ...[
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '匹配 ${s.matchScore}%',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white70,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        s.title,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.2,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              s.categoryName,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white60,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          if (s.timeAgo.isNotEmpty) ...[
                            const SizedBox(width: 10),
                            Text(
                              s.timeAgo,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white38,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          _HeroStat(
                            value: s.budgetDisplay,
                            label: '预算',
                            large: true,
                          ),
                          const SizedBox(width: 32),
                          _HeroStat(
                            value: '${s.viewCount}',
                            label: '浏览',
                          ),
                          const SizedBox(width: 32),
                          _HeroStat(
                            value: '${s.bidCount}',
                            label: '投标',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _updateParticles() {
    for (final p in _particles) {
      p.vy += p.gravity;
      p.x += p.vx;
      p.y += p.vy;

      if (p.y > 1.0) {
        p.y = -0.05;
        p.vy = _random.nextDouble() * 0.002;
        p.x = _random.nextDouble();
      }
      if (p.x > 1.0) p.x = 0.0;
      if (p.x < 0.0) p.x = 1.0;

      p.opacity = (p.baseOpacity * (1.0 - p.y * 0.6)).clamp(0.0, 1.0);
    }
  }

  String _statusTagType(int status) {
    switch (status) {
      case 5:
        return 'in_progress';
      case 6:
        return 'pending';
      case 7:
        return 'completed';
      case 9:
        return 'at_risk';
      default:
        return 'not_started';
    }
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
    final baseOp = 0.1 + rng.nextDouble() * 0.35;
    return _Particle(
      x: rng.nextDouble(),
      y: rng.nextDouble(),
      vx: (rng.nextDouble() - 0.5) * 0.001,
      vy: rng.nextDouble() * 0.003,
      radius: 1.0 + rng.nextDouble() * 2.5,
      opacity: baseOp,
      baseOpacity: baseOp,
      gravity: 0.00002 + rng.nextDouble() * 0.00005,
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

class _HeroStat extends StatelessWidget {
  final String value;
  final String label;
  final bool large;

  const _HeroStat({
    required this.value,
    required this.label,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: large ? 22 : 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: large ? -0.3 : 0,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.white38,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

class _FavoriteButton extends ConsumerStatefulWidget {
  final String projectId;
  const _FavoriteButton({required this.projectId});

  @override
  ConsumerState<_FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends ConsumerState<_FavoriteButton> {
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    final projectId = widget.projectId;
    final detailState = ref.watch(projectDetailProvider(projectId));
    final toggleState = ref.watch(favoriteToggleProvider);

    if (!_initialized && detailState.data != null) {
      _initialized = true;
      if (detailState.isFavorited) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(favoriteToggleProvider.notifier).markFavorited(projectId);
        });
      }
    }

    final isFav = toggleState.isFavorited(projectId);
    final isLoading = toggleState.isLoading(projectId);

    return GestureDetector(
      onTap: isLoading
          ? null
          : () async {
              final ok = await ref
                  .read(favoriteToggleProvider.notifier)
                  .toggle(targetType: 'project', targetId: projectId);
              if (!context.mounted) return;
              if (ok) {
                final newFav =
                    ref.read(favoriteToggleProvider).isFavorited(projectId);
                VccToast.show(context, message: newFav ? '已收藏' : '已取消收藏');
              }
            },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.white38),
                ),
              )
            : Icon(
                isFav ? Icons.bookmark : Icons.bookmark_border,
                size: 22,
                color: isFav ? Colors.white : Colors.white54,
              ),
      ),
    );
  }
}
