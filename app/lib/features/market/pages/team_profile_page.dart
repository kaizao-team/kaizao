import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../shared/skills/skill_particle_field.dart';
import '../../../shared/widgets/vcc_avatar.dart';
import '../../../shared/widgets/vcc_button.dart';
import '../../../shared/widgets/vcc_card.dart';
import '../../../shared/widgets/vcc_identity_hero.dart';
import '../../../shared/widgets/vcc_loading.dart';
import '../../../shared/widgets/vcc_section_label.dart';
import '../../team/models/team_profile.dart';
import '../../team/providers/team_provider.dart';

const double _kTeamPageHorizontalPadding = 20;
const double _kTeamSectionGap = 28;

class TeamProfilePage extends ConsumerWidget {
  final String teamId;

  const TeamProfilePage({super.key, required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(teamProfileProvider(teamId));

    if (state.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.surface,
        body: VccLoading(),
      );
    }

    final profile = state.profile;
    if (profile == null) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          title: Text(
            '团队档案',
            style: AppTextStyles.h3.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
        ),
        body: Center(
          child: Text(
            state.errorMessage?.isNotEmpty == true
                ? state.errorMessage!
                : '未找到团队信息',
            style: AppTextStyles.body2.copyWith(
              fontSize: 14,
              color: AppColors.gray500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final hasStorySection = _TeamStoryCard.hasVisibleContent(profile);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _TeamHero(profile: profile)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              _kTeamPageHorizontalPadding,
              18,
              _kTeamPageHorizontalPadding,
              40,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                VccPageSection(
                  label: '概览',
                  child: _TeamMetricsCard(profile: profile),
                ),
                if (hasStorySection) ...[
                  const SizedBox(height: _kTeamSectionGap),
                  VccPageSection(
                    label: '团队介绍',
                    child: _TeamStoryCard(profile: profile),
                  ),
                ],
                const SizedBox(height: _kTeamSectionGap),
                VccPageSection(
                  label: '成员',
                  child: _TeamMembersCard(profile: profile),
                ),
                const SizedBox(height: _kTeamSectionGap),
                const VccButton(
                  text: '发起沟通',
                  onPressed: null,
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamHero extends StatelessWidget {
  final TeamProfile profile;

  const _TeamHero({required this.profile});

  @override
  Widget build(BuildContext context) {
    final heroSkills = _teamHeroSkills(profile);
    final heroSummary = _teamHeroSummary(profile);
    final layers = <Widget>[
      const Positioned.fill(
        child: IgnorePointer(
          child: CustomPaint(
            painter: _TeamHeroGridPainter(),
          ),
        ),
      ),
      Positioned(
        top: 18,
        right: -20,
        child: Transform.rotate(
          angle: -0.14,
          child: Container(
            width: 136,
            height: 104,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.xxl),
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
        ),
      ),
      Positioned(
        right: 20,
        top: 88,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
        ),
      ),
    ];

    if (heroSkills.isNotEmpty) {
      layers.add(
        Positioned(
          left: 0,
          right: 0,
          top: 64,
          bottom: 0,
          child: IgnorePointer(
            child: SkillParticleField(skills: heroSkills),
          ),
        ),
      );
    }

    return VccIdentityHero(
      eyebrow: '团队资料',
      title: '团队',
      headline: profile.teamName,
      summary: heroSummary,
      avatar: _HeroAvatarCard(profile: profile),
      badges: [
        const VccHeroBadge(label: '团队方'),
        if (profile.vibeLevel != null && profile.vibeLevel!.isNotEmpty)
          VccHeroBadge(label: profile.vibeLevel!),
        VccHeroBadge(label: profile.isAvailable ? '接单中' : '档期待确认'),
      ],
      actionLabel: '返回',
      actionIcon: Icons.arrow_back_ios_new_rounded,
      onActionTap: () {
        if (context.canPop()) {
          context.pop();
          return;
        }
        context.go(RoutePaths.square);
      },
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
      bottomSpacing: _teamHeroBottomSpacing(
        skillCount: heroSkills.length,
        hasSummary: heroSummary != null,
      ),
      layers: layers,
    );
  }
}

String? _teamHeroSummary(TeamProfile profile) {
  final candidates = [
    profile.tagline,
    profile.description,
    profile.resumeSummary,
  ];
  for (final item in candidates) {
    final normalized = item?.replaceAll(RegExp(r'\s+'), ' ').trim() ?? '';
    if (normalized.isNotEmpty && !_isRepeatedHeroSummary(normalized, profile)) {
      return _truncateHeroSummary(normalized);
    }
  }
  return null;
}

String _truncateHeroSummary(String text) {
  const maxLength = 34;
  if (text.length <= maxLength) return text;
  return '${text.substring(0, maxLength).trimRight()}…';
}

bool _isRepeatedHeroSummary(String text, TeamProfile profile) {
  final normalizedText = _normalizeHeroText(text);
  final normalizedName = _normalizeHeroText(profile.teamName);
  final normalizedNickname = _normalizeHeroText(profile.nickname);

  if (normalizedText.isEmpty) return true;
  if (normalizedName.isNotEmpty &&
      (normalizedText == normalizedName ||
          normalizedText.contains(normalizedName))) {
    return true;
  }
  if (normalizedNickname.isNotEmpty &&
      (normalizedText == normalizedNickname ||
          normalizedText.contains(normalizedNickname))) {
    return true;
  }

  return false;
}

String _normalizeHeroText(String value) {
  return value.replaceAll(RegExp(r'\s+'), '').trim().toLowerCase();
}

double _teamHeroBottomSpacing({
  required int skillCount,
  required bool hasSummary,
}) {
  if (skillCount <= 0) {
    return hasSummary ? 28 : 18;
  }
  if (skillCount <= 4) {
    return hasSummary ? 72 : 82;
  }
  if (skillCount <= 8) {
    return hasSummary ? 80 : 92;
  }
  return hasSummary ? 88 : 100;
}

List<SkillParticleItem> _teamHeroSkills(TeamProfile profile) {
  final officialSkills = profile.skills
      .map((skill) => skill.trim())
      .where((skill) => skill.isNotEmpty)
      .toList(growable: false);
  final displaySkills = officialSkills;

  return displaySkills
      .asMap()
      .entries
      .map(
        (entry) => SkillParticleItem.resolve(
          entry.value,
          isPrimary: entry.key == 0,
        ),
      )
      .toList(growable: false);
}

class _HeroAvatarCard extends StatelessWidget {
  final TeamProfile profile;

  const _HeroAvatarCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return VccHeroAvatar(
      imageUrl: profile.avatarUrl,
      fallbackText: profile.teamName.isNotEmpty ? profile.teamName : 'T',
    );
  }
}

class _TeamMetricsCard extends StatelessWidget {
  final TeamProfile profile;

  const _TeamMetricsCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return VccMetricsPanel(
      items: [
        VccMetricSpec(
          value: '${profile.totalProjects}',
          label: '累计项目',
          icon: Icons.folder_outlined,
        ),
        VccMetricSpec(
          value: '${profile.memberCount}',
          label: '团队成员',
          icon: Icons.people_outline_rounded,
        ),
        VccMetricSpec(
          value:
              profile.experienceYears > 0 ? '${profile.experienceYears}' : '-',
          label: '经验年限',
          icon: Icons.timeline_rounded,
        ),
      ],
    );
  }
}

class _TeamStoryCard extends StatelessWidget {
  final TeamProfile profile;

  const _TeamStoryCard({required this.profile});

  static bool hasVisibleContent(TeamProfile profile) =>
      _storySummary(profile) != null || _storyDetails(profile).isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final summary = _storySummary(profile);
    final details = _storyDetails(profile);

    return VccSurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (summary != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
              child: Text(
                summary,
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.7,
                ),
              ),
            ),
          ],
          if (details.isNotEmpty) ...[
            if (summary != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 18),
                height: 1,
                color: AppColors.outlineVariant,
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(18, summary != null ? 4 : 8, 18, 6),
              child: Column(
                children: details.asMap().entries.map((entry) {
                  return _TeamStoryRow(
                    item: entry.value,
                    isLast: entry.key == details.length - 1,
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String? _storySummary(TeamProfile profile) {
    final candidates = [
      profile.resumeSummary,
      profile.description,
      profile.tagline,
    ];
    for (final item in candidates) {
      final text = item?.trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return null;
  }

  static List<String> _storyDetails(TeamProfile profile) {
    final items = <String>[];
    if (profile.avgRating > 0) {
      items.add('综合评分 ${profile.avgRating.toStringAsFixed(1)}');
    }
    if (profile.completedProjects > 0) {
      items.add('已完成 ${profile.completedProjects} 个项目');
    }
    if (profile.vibePower > 0) {
      items.add('团队氛围 ${profile.vibePower}');
    }
    return items;
  }
}

class _TeamStoryRow extends StatelessWidget {
  final String item;
  final bool isLast;

  const _TeamStoryRow({
    required this.item,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: AppColors.outlineVariant),
              ),
      ),
      child: Text(
        item,
        style: AppTextStyles.body2.copyWith(
          fontSize: 13,
          color: AppColors.gray500,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _TeamMembersCard extends StatefulWidget {
  final TeamProfile profile;

  const _TeamMembersCard({required this.profile});

  @override
  State<_TeamMembersCard> createState() => _TeamMembersCardState();
}

class _TeamMembersCardState extends State<_TeamMembersCard> {
  static const double _leaderSize = 56;
  static const double _memberSize = 42;
  static const double _overlap = 10;

  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final members = _displayMembers(widget.profile);
    final selected = _selectedIndex != null && _selectedIndex! < members.length
        ? members[_selectedIndex!]
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '核心成员',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: AppColors.gray400,
              ),
            ),
            const Spacer(),
            Text(
              _summaryText(widget.profile, members),
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.gray500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: SizedBox(
            height: _leaderSize,
            child: _buildAvatarStrip(members),
          ),
        ),
        _TeamMemberStatusLine(
          member: selected,
          onTap: selected?.canOpenProfile == true
              ? () => _openProfile(selected!)
              : null,
        ),
      ],
    );
  }

  Widget _buildAvatarStrip(List<_TeamDisplayMember> members) {
    if (members.isEmpty) return const SizedBox.shrink();

    const step = _memberSize - _overlap;
    final totalWidth = _leaderSize + ((members.length - 1) * step) + 20;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(right: 20),
      child: SizedBox(
        width: totalWidth,
        height: _leaderSize,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (var i = 0; i < members.length; i++)
              _buildPositionedAvatar(i, members[i], step),
          ],
        ),
      ),
    );
  }

  Widget _buildPositionedAvatar(
    int index,
    _TeamDisplayMember member,
    double step,
  ) {
    final isLeader = index == 0;
    final isSelected = _selectedIndex == index;
    final hasSelection = _selectedIndex != null;
    final size = isLeader ? _leaderSize : _memberSize;
    final left = isLeader ? 0.0 : _leaderSize + ((index - 1) * step) - _overlap;
    final top = isLeader ? 0.0 : (_leaderSize - _memberSize) / 2;

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: () => _handleTap(member, index),
        child: AnimatedScale(
          scale: isSelected ? 1.15 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          child: AnimatedOpacity(
            opacity: hasSelection && !isSelected ? 0.45 : 1.0,
            duration: const Duration(milliseconds: 180),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.white,
                border: Border.all(
                  color: isSelected ? AppColors.accent : AppColors.white,
                  width: isLeader ? 3 : 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? AppColors.accent.withValues(alpha: 0.18)
                        : const Color(0x0C000000),
                    blurRadius: isSelected ? 12 : 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: VccAvatar(
                  imageUrl: member.avatarUrl,
                  size: size > 50 ? VccAvatarSize.large : VccAvatarSize.medium,
                  fallbackText: member.displayName,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleTap(_TeamDisplayMember member, int index) {
    if (_selectedIndex == index && member.canOpenProfile) {
      _openProfile(member);
      return;
    }

    setState(() {
      _selectedIndex = _selectedIndex == index ? null : index;
    });
  }

  void _openProfile(_TeamDisplayMember member) {
    if (!member.canOpenProfile) return;
    context.push(
      RoutePaths.expertProfileView.replaceFirst(':userId', member.userId),
    );
  }

  static List<_TeamDisplayMember> _displayMembers(TeamProfile profile) {
    final leader = _findLeader(profile);
    final leaderName = leader?.nickname.isNotEmpty == true
        ? leader!.nickname
        : (profile.nickname.isNotEmpty ? profile.nickname : '负责人');
    final members = <_TeamDisplayMember>[
      _TeamDisplayMember(
        id: leader?.id.toString() ?? 'leader:${profile.id}',
        userId: leader?.userId ?? profile.leaderUuid,
        displayName: leaderName,
        avatarUrl:
            leader?.avatarUrl ?? profile.leaderAvatarUrl ?? profile.avatarUrl,
        roleLabel: leader?.role.isNotEmpty == true ? leader!.role : '团队负责人',
        isLeader: true,
      ),
      ...profile.members.where((member) => !member.isLeader).map(
            (member) => _TeamDisplayMember(
              id: member.id.toString(),
              userId: member.userId,
              displayName:
                  member.nickname.isNotEmpty ? member.nickname : '团队成员',
              avatarUrl: member.avatarUrl,
              roleLabel: member.role.isNotEmpty ? member.role : '团队成员',
            ),
          ),
    ];

    return members;
  }

  static TeamProfileMember? _findLeader(TeamProfile profile) {
    for (final member in profile.members) {
      if (member.isLeader) return member;
    }
    return null;
  }

  static String _summaryText(
    TeamProfile profile,
    List<_TeamDisplayMember> members,
  ) {
    final count =
        profile.memberCount > 0 ? profile.memberCount : members.length;
    return count <= 1 ? '当前公开负责人' : '$count 位成员';
  }
}

class _TeamMemberStatusLine extends StatelessWidget {
  final _TeamDisplayMember? member;
  final VoidCallback? onTap;

  const _TeamMemberStatusLine({
    required this.member,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.3),
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: member == null
          ? const SizedBox(key: ValueKey('empty'), height: 8)
          : GestureDetector(
              key: ValueKey(member!.id),
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    Text(
                      member!.displayName,
                      style: AppTextStyles.body2.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      ' · ',
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 13,
                        color: AppColors.gray300,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        member!.roleLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.gray500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (member!.canOpenProfile) ...[
                      const SizedBox(width: 10),
                      Text(
                        '主页',
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.gray400,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.arrow_outward_rounded,
                        size: 13,
                        color: AppColors.gray400,
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}

class _TeamDisplayMember {
  final String id;
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final String roleLabel;
  final bool isLeader;

  const _TeamDisplayMember({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.avatarUrl,
    required this.roleLabel,
    this.isLeader = false,
  });

  bool get canOpenProfile => userId.isNotEmpty;
}

class _TeamHeroGridPainter extends CustomPainter {
  const _TeamHeroGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x09FFFFFF)
      ..strokeWidth = 0.5;

    const spacing = 18.0;
    for (double x = 0; x <= size.width; x += spacing) {
      for (double y = 0; y <= size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 0.85, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
