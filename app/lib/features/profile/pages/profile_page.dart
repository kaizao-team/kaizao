import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../shared/models/project_category.dart';
import '../../../shared/models/project_model.dart';
import '../../../shared/skills/skill_particle_field.dart';
import '../../../shared/widgets/vcc_card.dart';
import '../../../shared/widgets/vcc_empty_state.dart';
import '../../../shared/widgets/vcc_identity_hero.dart';
import '../../../shared/widgets/vcc_loading.dart';
import '../../../shared/widgets/vcc_section_label.dart';
import '../../project/providers/project_list_provider.dart';
import '../models/profile_models.dart';
import '../providers/profile_provider.dart';
import '../widgets/portfolio_grid.dart';

const double _kProfilePageHorizontalPadding = 20;
const double _kProfileSectionGap = 28;

class ProfilePage extends ConsumerStatefulWidget {
  final String? userId;

  const ProfilePage({super.key, this.userId});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  late final ScrollController _scrollController;
  final _heroKey = GlobalKey();
  double _scrollOffset = 0;
  double _heroHeight = 300;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final offset = _scrollController.offset.clamp(0.0, double.infinity).toDouble();
    if ((offset - _scrollOffset).abs() > 0.5) {
      setState(() => _scrollOffset = offset);
    }
  }

  void _measureHero() {
    final ctx = _heroKey.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box?.hasSize != true) return;
    final h = box!.size.height;
    if ((h - _heroHeight).abs() > 1) setState(() => _heroHeight = h);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveId = widget.userId ?? 'me';
    final isSelf = widget.userId == null;
    final state = ref.watch(profileProvider(effectiveId));

    if (state.isLoading && state.profile == null) {
      return const Scaffold(
        backgroundColor: AppColors.surface,
        body: VccLoading(),
      );
    }

    if (state.errorMessage != null && state.profile == null) {
      return Scaffold(
        backgroundColor: AppColors.surface,
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
    if (profile == null) {
      return const Scaffold(
        backgroundColor: AppColors.surface,
        body: VccLoading(),
      );
    }

    // Schedule hero measurement after build
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureHero());

    final headerProgress = (_scrollOffset / (_heroHeight + 70)).clamp(0.0, 1.0);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: headerProgress > 0.5
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: Stack(
          children: [
            RefreshIndicator(
              color: AppColors.black,
              onRefresh: () async {
                await ref
                    .read(profileProvider(effectiveId).notifier)
                    .loadProfile();
                if (isSelf && profile.isDemander) {
                  await ref.read(projectListProvider.notifier).refresh();
                }
              },
              child: CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: KeyedSubtree(
                      key: _heroKey,
                      child: _ProfileHero(
                        profile: profile,
                        isSelf: isSelf,
                        skills: state.skills,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      _kProfilePageHorizontalPadding,
                      18,
                      _kProfilePageHorizontalPadding,
                      40,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        VccPageSection(
                          label: 'OVERVIEW',
                          child: _ProfileMetricsCard(profile: profile),
                        ),
                        if (!profile.isDemander &&
                            state.portfolios.isNotEmpty) ...[
                          const SizedBox(height: _kProfileSectionGap),
                          PortfolioGrid(items: state.portfolios),
                        ],
                        const SizedBox(height: _kProfileSectionGap),
                        VccPageSection(
                          label: 'ACCOUNT',
                          child: _ProfileInfoCard(profile: profile),
                        ),
                        if (isSelf) ...[
                          const SizedBox(height: _kProfileSectionGap),
                          VccPageSection(
                            label: 'QUICK ACTIONS',
                            child: _ProfileMenuGroup(
                              items: [
                                _ProfileMenuItem(
                                  label: '编辑资料',
                                  trailingText: '完善资料',
                                  onTap: () =>
                                      context.push(RoutePaths.editProfile),
                                ),
                                _ProfileMenuItem(
                                  label: '我的钱包',
                                  trailingText: '余额与记录',
                                  onTap: () => context.push(RoutePaths.wallet),
                                ),
                                _ProfileMenuItem(
                                  label: '消息通知',
                                  onTap: () =>
                                      context.push(RoutePaths.notifications),
                                ),
                                _ProfileMenuItem(
                                  label: '我的收藏',
                                  onTap: () =>
                                      context.push(RoutePaths.favorites),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: _kProfileSectionGap),
                        VccPageSection(
                          label: 'SUPPORT',
                          child: _ProfileMenuGroup(
                            items: [
                              _ProfileMenuItem(
                                label: '帮助与反馈',
                                onTap: () =>
                                    context.push(RoutePaths.helpFeedback),
                              ),
                              _ProfileMenuItem(
                                label: '关于 KAIZO',
                                onTap: () => context.push(RoutePaths.about),
                              ),
                            ],
                          ),
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
            // Immersive header overlay — fades in as hero scrolls away
            if (isSelf)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _ImmersiveProfileHeader(
                  scrollOffset: _scrollOffset,
                  heroHeight: _heroHeight,
                  onSettingsTap: () => context.push(RoutePaths.settings),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHero extends ConsumerWidget {
  final UserProfile profile;
  final bool isSelf;
  final List<SkillTag> skills;

  const _ProfileHero({
    required this.profile,
    required this.isSelf,
    required this.skills,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = _profileSummary(profile);
    final skillParticles = skills
        .where((skill) => skill.name.trim().isNotEmpty)
        .map(
          (skill) => SkillParticleItem(
            id: skill.id,
            name: skill.name,
            category: skill.category,
            isPrimary: skill.isPrimary,
          ),
        )
        .toList(growable: false);
    final demandNotes = profile.isDemander && isSelf
        ? _buildDemandBoardNotes(ref.watch(projectListProvider).projects)
        : const <_DemandBoardNote>[];
    final hasSkillParticles = skillParticles.isNotEmpty;
    final hasDemandBoard = demandNotes.isNotEmpty;
    final heroLayers = <Widget>[
      const Positioned.fill(
        child: IgnorePointer(
          child: CustomPaint(
            painter: _DotGridPainter(),
          ),
        ),
      ),
    ];

    if (hasSkillParticles && !profile.isDemander) {
      heroLayers.add(
        Positioned(
          left: 0,
          right: 0,
          top: 64,
          bottom: 0,
          child: IgnorePointer(
            child: SkillParticleField(skills: skillParticles),
          ),
        ),
      );
    }

    if (hasDemandBoard) {
      heroLayers.add(
        Positioned(
          left: 18,
          right: 18,
          bottom: 18,
          child: IgnorePointer(
            child: _DemandKeywordBoard(notes: demandNotes),
          ),
        ),
      );
    }

    return VccIdentityHero(
      eyebrow: isSelf ? null : 'PROFILE',
      title: isSelf ? null : '我的',
      headline: profile.nickname,
      summary: summary,
      avatar: _HeroAvatarCard(profile: profile),
      badges: [
        VccHeroBadge(label: profile.roleName),
        if (profile.isVerified) const VccHeroBadge(label: '已认证'),
        if (profile.wechatBound) const VccHeroBadge(label: '微信已绑定'),
      ],
      actionLabel: isSelf ? null : '返回',
      actionIcon: isSelf ? null : Icons.arrow_back_ios_new_rounded,
      onActionTap: isSelf
          ? null
          : () {
              if (context.canPop()) {
                context.pop();
                return;
              }
              context.go(RoutePaths.home);
            },
      contentPadding: EdgeInsets.fromLTRB(20, isSelf ? 60 : 12, 20, 18),
      bottomSpacing: hasSkillParticles
          ? 110
          : hasDemandBoard
              ? 126
              : 28,
      layers: heroLayers,
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

class _DemandKeywordBoard extends StatelessWidget {
  final List<_DemandBoardNote> notes;

  const _DemandKeywordBoard({required this.notes});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final placements = _boardPlacementsFor(notes.length);
          return Stack(
            clipBehavior: Clip.none,
            children: List.generate(notes.length, (index) {
              final placement = placements[index];
              final note = notes[index];
              final width = constraints.maxWidth * placement.widthFactor;
              return Positioned(
                left: constraints.maxWidth * placement.leftFactor,
                top: placement.top,
                child: Transform.rotate(
                  angle: placement.angle,
                  child: _DemandPaperNote(
                    note: note,
                    width: width,
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

class _DemandPaperNote extends StatelessWidget {
  final _DemandBoardNote note;
  final double width;

  const _DemandPaperNote({
    required this.note,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.fromLTRB(14, 11, 12, 12),
      decoration: BoxDecoration(
        color: note.color,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.05),
        ),
        // Decorative paper-note shadow — intentional floating effect
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -3,
            left: 2,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.black.withValues(alpha: 0.68),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.22),
                    blurRadius: 1,
                    offset: const Offset(0, 0.5),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: -4,
            right: 10,
            child: Transform.rotate(
              angle: 0.2,
              child: Container(
                width: 16,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.32),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                note.caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.overline.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gray500,
                  letterSpacing: 0.9,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                note.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body1.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DemandBoardNote {
  final String caption;
  final String label;
  final Color color;

  const _DemandBoardNote({
    required this.caption,
    required this.label,
    required this.color,
  });
}

class _DemandBoardPlacement {
  final double leftFactor;
  final double top;
  final double widthFactor;
  final double angle;

  const _DemandBoardPlacement({
    required this.leftFactor,
    required this.top,
    required this.widthFactor,
    required this.angle,
  });
}

List<_DemandBoardPlacement> _boardPlacementsFor(int count) {
  switch (count) {
    case 1:
      return const [
        _DemandBoardPlacement(
          leftFactor: 0.24,
          top: 18,
          widthFactor: 0.52,
          angle: -0.05,
        ),
      ];
    case 2:
      return const [
        _DemandBoardPlacement(
          leftFactor: 0.08,
          top: 14,
          widthFactor: 0.42,
          angle: -0.06,
        ),
        _DemandBoardPlacement(
          leftFactor: 0.50,
          top: 30,
          widthFactor: 0.34,
          angle: 0.07,
        ),
      ];
    case 3:
      return const [
        _DemandBoardPlacement(
          leftFactor: 0.02,
          top: 12,
          widthFactor: 0.34,
          angle: -0.06,
        ),
        _DemandBoardPlacement(
          leftFactor: 0.34,
          top: 2,
          widthFactor: 0.30,
          angle: 0.04,
        ),
        _DemandBoardPlacement(
          leftFactor: 0.63,
          top: 20,
          widthFactor: 0.29,
          angle: -0.08,
        ),
      ];
    case 4:
      return const [
        _DemandBoardPlacement(
          leftFactor: 0.01,
          top: 10,
          widthFactor: 0.30,
          angle: -0.06,
        ),
        _DemandBoardPlacement(
          leftFactor: 0.28,
          top: 0,
          widthFactor: 0.28,
          angle: 0.05,
        ),
        _DemandBoardPlacement(
          leftFactor: 0.56,
          top: 12,
          widthFactor: 0.27,
          angle: -0.07,
        ),
        _DemandBoardPlacement(
          leftFactor: 0.22,
          top: 46,
          widthFactor: 0.38,
          angle: 0.09,
        ),
      ];
    default:
      return const [
        _DemandBoardPlacement(
          leftFactor: 0.01,
          top: 10,
          widthFactor: 0.27,
          angle: -0.05,
        ),
        _DemandBoardPlacement(
          leftFactor: 0.24,
          top: 0,
          widthFactor: 0.25,
          angle: 0.04,
        ),
        _DemandBoardPlacement(
          leftFactor: 0.50,
          top: 8,
          widthFactor: 0.25,
          angle: -0.08,
        ),
        _DemandBoardPlacement(
          leftFactor: 0.72,
          top: 18,
          widthFactor: 0.22,
          angle: 0.06,
        ),
        _DemandBoardPlacement(
          leftFactor: 0.14,
          top: 48,
          widthFactor: 0.31,
          angle: 0.08,
        ),
        _DemandBoardPlacement(
          leftFactor: 0.48,
          top: 48,
          widthFactor: 0.34,
          angle: -0.03,
        ),
      ];
  }
}

List<_DemandBoardNote> _buildDemandBoardNotes(List<ProjectModel> projects) {
  if (projects.isEmpty) return const [];

  final sorted = [...projects]..sort((a, b) {
      final aTime = a.publishedAt ?? a.createdAt;
      final bTime = b.publishedAt ?? b.createdAt;
      return bTime.compareTo(aTime);
    });

  final notes = <_DemandBoardNote>[];
  final usedLabels = <String>{};
  final palette = <Color>[
    const Color(0xFFF5EFE3),
    const Color(0xFFF2F1EC),
    const Color(0xFFEDE8F7),
    const Color(0xFFE9EEF7),
    const Color(0xFFF4E8E3),
    const Color(0xFFE8F1EB),
  ];

  for (final project in sorted.take(3)) {
    final categoryLabel = projectCategoryLabel(project.category);
    final fragments = _projectKeywordFragments(project);

    if (fragments.isNotEmpty) {
      final primary = fragments.first;
      if (usedLabels.add(primary)) {
        notes.add(
          _DemandBoardNote(
            caption: primary == categoryLabel ? '最近需求' : categoryLabel,
            label: primary,
            color: palette[notes.length % palette.length],
          ),
        );
      }
    } else if (usedLabels.add(categoryLabel)) {
      notes.add(
        _DemandBoardNote(
          caption: '最近需求',
          label: categoryLabel,
          color: palette[notes.length % palette.length],
        ),
      );
    }

    final budgetLabel = _compactBudgetLabel(project);
    if (budgetLabel != null &&
        notes.length < 6 &&
        usedLabels.add(budgetLabel)) {
      notes.add(
        _DemandBoardNote(
          caption: '预算区间',
          label: budgetLabel,
          color: palette[notes.length % palette.length],
        ),
      );
    }

    final statusLabel = project.homeStatusName;
    if (notes.length < 6 && usedLabels.add(statusLabel)) {
      notes.add(
        _DemandBoardNote(
          caption: '当前状态',
          label: statusLabel,
          color: palette[notes.length % palette.length],
        ),
      );
    }
  }

  return notes.take(6).toList(growable: false);
}

List<String> _projectKeywordFragments(ProjectModel project) {
  final fragments = <String>[];

  void collectTokens(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return;

    final compact = text.replaceAll(RegExp(r'\s+'), ' ');
    final pieces = compact
        .split(RegExp(r'[、,，;；/|·•\-_\n\r\t ]+'))
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty);

    for (final piece in pieces) {
      final normalized = _normalizeKeyword(piece);
      if (normalized == null || fragments.contains(normalized)) continue;
      fragments.add(normalized);
      if (fragments.length >= 2) return;
    }
  }

  collectTokens(project.title);
  if (fragments.length < 2) {
    collectTokens(project.description);
  }
  if (fragments.length < 2) {
    for (final tech in project.techRequirements) {
      final normalized = _normalizeKeyword(tech);
      if (normalized == null || fragments.contains(normalized)) continue;
      fragments.add(normalized);
      if (fragments.length >= 2) break;
    }
  }

  return fragments;
}

String? _normalizeKeyword(String input) {
  final text = input.trim();
  if (text.isEmpty || text.length > 16) return null;

  final condensed = text.replaceAll(RegExp(r'\s+'), ' ');
  final hasChinese = RegExp(r'[\u4e00-\u9fff]').hasMatch(condensed);
  final hasLetters = RegExp(r'[A-Za-z]').hasMatch(condensed);
  final hasDigits = RegExp(r'\d').hasMatch(condensed);

  if (hasChinese) {
    if (condensed.length < 2) return null;
    return condensed;
  }

  if (hasLetters) {
    final lower = condensed.toLowerCase();
    if (lower.length < 3) return null;
    final uniqueChars = lower.runes.toSet().length;
    final vowelCount = RegExp(r'[aeiou]').allMatches(lower).length;
    if (!hasDigits && uniqueChars <= 3) return null;
    if (!hasDigits && vowelCount == 0) return null;
    return condensed;
  }

  return null;
}

String? _compactBudgetLabel(ProjectModel project) {
  if (project.budgetMin == null && project.budgetMax == null) return null;

  String formatAmount(double value) {
    if (value >= 10000) {
      final w = value / 10000;
      final hasDecimal = (w * 10).round() % 10 != 0;
      return '${hasDecimal ? w.toStringAsFixed(1) : w.toStringAsFixed(0)}w';
    }
    if (value >= 1000) {
      final k = value / 1000;
      final hasDecimal = (k * 10).round() % 10 != 0;
      return '${hasDecimal ? k.toStringAsFixed(1) : k.toStringAsFixed(0)}k';
    }
    return value.toStringAsFixed(0);
  }

  final min = project.budgetMin;
  final max = project.budgetMax;
  if (min != null && max != null) {
    return '¥${formatAmount(min)}-${formatAmount(max)}';
  }
  if (min != null) {
    return '¥${formatAmount(min)}+';
  }
  if (max != null) {
    return '≤¥${formatAmount(max)}';
  }
  return null;
}

class _HeroAvatarCard extends StatelessWidget {
  final UserProfile profile;

  const _HeroAvatarCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return VccHeroAvatar(
      imageUrl: profile.avatar,
      fallbackText: profile.nickname.isNotEmpty ? profile.nickname : 'U',
    );
  }
}

class _ProfileMetricsCard extends StatelessWidget {
  final UserProfile profile;

  const _ProfileMetricsCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final items = profile.isDemander
        ? const [
            (label: '发布需求', icon: Icons.track_changes_outlined),
            (label: '综合评分', icon: Icons.star_outline_rounded),
            (label: '信用分', icon: Icons.verified_user_outlined),
          ]
        : const [
            (label: '完成项目', icon: Icons.task_alt_outlined),
            (label: '综合评分', icon: Icons.star_outline_rounded),
            (label: '信用分', icon: Icons.verified_user_outlined),
          ];

    final values = profile.isDemander
        ? [
            '${profile.stats.publishedProjects}',
            profile.rating.toStringAsFixed(1),
            '${profile.creditScore}',
          ]
        : [
            '${profile.stats.completedProjects}',
            profile.rating.toStringAsFixed(1),
            '${profile.creditScore}',
          ];

    return VccMetricsPanel(
      items: List.generate(
        items.length,
        (index) => VccMetricSpec(
          value: values[index],
          label: items[index].label,
          icon: items[index].icon,
        ),
      ),
    );
  }
}

class _ProfileInfoCard extends StatelessWidget {
  final UserProfile profile;

  const _ProfileInfoCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final summary = _profileMotto(profile);
    final isMotto = summary != null && _isMottoLike(summary);
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
    return VccSurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (summary != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              child: Text(
                summary,
                style: isMotto
                    ? AppTextStyles.h3.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.italic,
                        letterSpacing: -0.2,
                        color: AppColors.gray700,
                        height: 1.45,
                      )
                    : AppTextStyles.body2.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.7,
                      ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 18),
              height: 1,
              color: AppColors.outlineVariant,
            ),
          ],
          Padding(
            padding: EdgeInsets.fromLTRB(18, summary != null ? 4 : 8, 18, 6),
            child: Column(
              children: rows.asMap().entries.map((entry) {
                return _ProfileInfoRow(
                  item: entry.value,
                  isLast: entry.key == rows.length - 1,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  static String? _profileMotto(UserProfile profile) {
    final tagline = profile.tagline.trim();
    if (tagline.isNotEmpty) return tagline;

    final bio = profile.bio.trim();
    if (bio.isNotEmpty) return bio;

    return null;
  }

  static bool _isMottoLike(String text) {
    final compact = text.trim();
    return compact.isNotEmpty &&
        compact.length <= 48 &&
        !compact.contains('\n') &&
        !compact.contains('。') &&
        !compact.contains('，');
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
    return VccSurfaceCard(
      padding: EdgeInsets.zero,
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
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
                  bottom: BorderSide(color: AppColors.outlineVariant),
                ),
        ),
        child: Row(
          children: [
            Text(
              item.label,
              style: AppTextStyles.body1.copyWith(
                fontSize: 15,
                color: AppColors.onSurface,
              ),
            ),
            const Spacer(),
            if (item.trailingText != null) ...[
              Text(
                item.trailingText!,
                style: AppTextStyles.caption.copyWith(
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

class _ProfileInfoRow extends StatelessWidget {
  final _InfoItem item;
  final bool isLast;

  const _ProfileInfoRow({
    required this.item,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: AppColors.outlineVariant),
              ),
      ),
      child: Row(
        children: [
          Text(
            item.label,
            style: AppTextStyles.caption.copyWith(
              fontSize: 13,
              color: AppColors.gray400,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                item.value,
                textAlign: TextAlign.right,
                style: AppTextStyles.body2.copyWith(
                  fontSize: 14,
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
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

/// Immersive floating header for the self-profile page.
///
/// Always visible — starts with transparent background + white text on the
/// dark hero. As the user scrolls, background fades to AppColors.surface and
/// text transitions to black. Title physically shrinks 30→18px.
class _ImmersiveProfileHeader extends StatelessWidget {
  final double scrollOffset;
  final double heroHeight;
  final VoidCallback onSettingsTap;

  const _ImmersiveProfileHeader({
    required this.scrollOffset,
    required this.heroHeight,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    // Unified 0→1 progress over the full hero + shrink range
    final totalRange = heroHeight + 70;
    final progress =
        totalRange <= 0 ? 1.0 : (scrollOffset / totalRange).clamp(0.0, 1.0);

    // Title physically shrinks and moves up
    final titleSize = lerpDouble(30, 18, progress)!;
    final titleWeight =
        FontWeight.lerp(FontWeight.w700, FontWeight.w600, progress) ??
            FontWeight.w700;
    final titleTop =
        lerpDouble(topPadding + 12, topPadding + 14, progress)!;

    // Colors: white (on dark hero) → dark (on light header)
    final textColor = Color.lerp(Colors.white, AppColors.black, progress)!;
    final bgColor = AppColors.surface
        .withValues(alpha: Curves.easeIn.transform(progress));

    // Text portion collapses in the first half of scroll
    final textProgress = Curves.easeInOut
        .transform((progress * 2).clamp(0.0, 1.0));

    // Settings button: ghost white → invisible container (just icon)
    final settingsBg = Color.lerp(
      Colors.white.withValues(alpha: 0.12),
      Colors.transparent,
      textProgress,
    )!;
    final settingsBorder = Color.lerp(
      Colors.white.withValues(alpha: 0.18),
      Colors.transparent,
      textProgress,
    )!;
    // Align icon center with title center as both animate
    final titleCenterY = titleTop + titleSize / 2;
    const iconContainerHeight = 34.0; // padding(9) + icon(16) + padding(9)
    final settingsTop = titleCenterY - iconContainerHeight / 2;

    // Divider appears at full collapse
    final dividerOpacity = Curves.easeOut
        .transform(((progress - 0.9) / 0.1).clamp(0.0, 1.0));

    return SizedBox(
      height: topPadding + 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bgColor,
          border: dividerOpacity > 0
              ? Border(
                  bottom: BorderSide(
                    color: AppColors.gray200.withValues(alpha: dividerOpacity),
                    width: 0.5,
                  ),
                )
              : null,
        ),
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            // Settings button — collapses from (icon + 设置 text) to bare icon
            Positioned(
              top: settingsTop,
              right: 20,
              child: GestureDetector(
                onTap: onSettingsTap,
                child: Container(
                  padding: EdgeInsets.lerp(
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    const EdgeInsets.all(9),
                    textProgress,
                  ),
                  decoration: BoxDecoration(
                    color: settingsBg,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: settingsBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.settings_outlined,
                        size: 16,
                        color: textColor,
                      ),
                      // Text width collapses to zero
                      ClipRect(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          widthFactor: 1 - textProgress,
                          child: Opacity(
                            opacity: 1 - textProgress,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(width: 8),
                                Text(
                                  '设置',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Title "我的" — always visible, physically shrinks + color shifts
            Positioned(
              top: titleTop,
              left: 20,
              right: 132,
              child: IgnorePointer(
                child: Text(
                  '我的',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: titleWeight,
                    height: 1,
                    letterSpacing: -0.8,
                    color: textColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  const _DotGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x09FFFFFF)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const step = 20.0;
    for (double i = 0; i <= size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double j = 0; j <= size.height; j += step) {
      canvas.drawLine(Offset(0, j), Offset(size.width, j), paint);
    }

    final dotPaint = Paint()
      ..color = const Color(0x0EFFFFFF)
      ..style = PaintingStyle.fill;

    for (double i = 0; i <= size.width; i += step) {
      for (double j = 0; j <= size.height; j += step) {
        canvas.drawCircle(Offset(i, j), 1.0, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
