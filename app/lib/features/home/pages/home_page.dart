import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  static const List<_HomeCategoryData> _categories = [
    _HomeCategoryData(
      label: 'App',
      icon: Icons.smartphone_rounded,
      category: 'app',
    ),
    _HomeCategoryData(
      label: 'Website',
      icon: Icons.language_rounded,
      category: 'website',
    ),
    _HomeCategoryData(
      label: '小程序',
      icon: Icons.widgets_rounded,
      category: 'mini_program',
    ),
    _HomeCategoryData(
      label: '设计',
      icon: Icons.brush_rounded,
      category: 'design',
    ),
    _HomeCategoryData(
      label: '数据',
      icon: Icons.storage_rounded,
      category: 'data',
    ),
    _HomeCategoryData(
      label: '更多',
      icon: Icons.grid_view_rounded,
      category: 'more',
    ),
  ];

  static const List<_HomeProjectData> _projects = [
    _HomeProjectData(
      id: '1',
      title: '电商 App',
      status: '进行中',
      phase: 'Development',
      assignee: 'Liam K.',
      progress: 0.65,
      statusTextColor: AppColors.accent,
      statusBackground: Color(0xFFF1E9FF),
      avatarGradientStart: Color(0xFF8B5CF6),
      avatarGradientEnd: Color(0xFF6D28D9),
    ),
    _HomeProjectData(
      id: '2',
      title: '品牌升级',
      status: '评审中',
      phase: 'Design',
      assignee: 'Sarah M.',
      progress: 0.90,
      statusTextColor: AppColors.gray600,
      statusBackground: Color(0xFFF0F0F0),
      avatarGradientStart: Color(0xFFF59E0B),
      avatarGradientEnd: Color(0xFFD97706),
    ),
  ];

  static const List<_HomeCreatorData> _creators = [
    _HomeCreatorData(
      name: 'David Chen',
      rating: '4.9',
      fallbackText: 'D',
      tags: ['Python', 'AI'],
      gradientStart: Color(0xFF0F766E),
      gradientEnd: Color(0xFF115E59),
    ),
    _HomeCreatorData(
      name: 'Elena S.',
      rating: '5.0',
      fallbackText: 'E',
      tags: ['UI/UX', 'SaaS'],
      gradientStart: Color(0xFF0F172A),
      gradientEnd: Color(0xFF334155),
    ),
    _HomeCreatorData(
      name: 'Marcus T.',
      rating: '4.8',
      fallbackText: 'M',
      tags: ['React', 'Web'],
      gradientStart: Color(0xFF7C2D12),
      gradientEnd: Color(0xFFEA580C),
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(RoutePaths.publishProject),
        elevation: 3,
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.white,
        child: const Icon(Icons.add_rounded),
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.accent,
          onRefresh: () async {
            await Future.delayed(const Duration(milliseconds: 700));
          },
          child: ListView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.base,
              AppSpacing.md,
              AppSpacing.base,
              120,
            ),
            children: [
              const _HomeTopBar(),
              const SizedBox(height: AppSpacing.xl),
              const _GreetingSection(),
              const SizedBox(height: AppSpacing.base),
              _HomeHeroBanner(
                onPrimaryTap: () => context.push(RoutePaths.publishProject),
              ),
              const SizedBox(height: AppSpacing.base),
              _IdeaPromptBar(
                onTap: () => context.push(RoutePaths.publishProject),
              ),
              const SizedBox(height: 28),
              const _SectionHeader(title: 'Categories'),
              const SizedBox(height: AppSpacing.md),
              GridView.builder(
                itemCount: _categories.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                  childAspectRatio: 0.86,
                ),
                itemBuilder: (context, index) {
                  final item = _categories[index];
                  return _CategoryTile(
                    data: item,
                    onTap: () => context.push(
                      '${RoutePaths.publishProject}?category=${item.category}',
                    ),
                  );
                },
              ),
              const SizedBox(height: 28),
              _SectionHeader(
                title: 'My Projects',
                actionLabel: 'View All',
                onActionTap: () => context.go(RoutePaths.projectList),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 172,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _projects.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final project = _projects[index];
                    return _ProjectTile(
                      data: project,
                      onTap: () => context.push('/projects/${project.id}'),
                    );
                  },
                ),
              ),
              const SizedBox(height: 28),
              _SectionHeader(
                title: 'Recommended Creators',
                actionLabel: 'Explore',
                onActionTap: () => context.go(RoutePaths.square),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 184,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _creators.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final creator = _creators[index];
                    return _CreatorTile(data: creator);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeTopBar extends StatelessWidget {
  const _HomeTopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () {},
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 24, height: 24),
          icon: const Icon(
            Icons.search_rounded,
            color: AppColors.accent,
            size: 20,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          'Kaizao',
          style: AppTextStyles.h3.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        const Spacer(),
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF4D7BE), Color(0xFFE8C19E)],
            ),
          ),
          child: Center(
            child: Text(
              'D',
              style: AppTextStyles.body2.copyWith(
                color: AppColors.gray800,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GreetingSection extends StatelessWidget {
  const _GreetingSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hi, Dylan 👋',
          style: AppTextStyles.h2.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '今天准备开造什么？',
          style: AppTextStyles.body2.copyWith(
            color: AppColors.gray500,
          ),
        ),
      ],
    );
  }
}

class _HomeHeroBanner extends StatelessWidget {
  final VoidCallback onPrimaryTap;

  const _HomeHeroBanner({
    required this.onPrimaryTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPrimaryTap,
      child: Container(
        height: 162,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF7C3AED), Color(0xFF6D33E9)],
          ),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(124, 58, 237, 0.24),
              offset: Offset(0, 12),
              blurRadius: 28,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              const Positioned(
                top: 12,
                right: 8,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0x14FFFFFF),
                  ),
                  child: SizedBox(width: 40, height: 40),
                ),
              ),
              const Positioned(
                right: -42,
                bottom: -26,
                child: _HeroMotionVisual(size: 208),
              ),
              const Positioned(
                right: 44,
                bottom: -42,
                child: _HeroGlow(size: 126),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 205),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '把你的想法交给 AI，它会帮你落成产品。',
                        style: AppTextStyles.h2.copyWith(
                          color: AppColors.white,
                          height: 1.16,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        height: 34,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Get Started',
                          style: AppTextStyles.body2.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IdeaPromptBar extends StatelessWidget {
  final VoidCallback onTap;

  const _IdeaPromptBar({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F1F1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.auto_awesome_outlined,
              size: 18,
              color: AppColors.gray500,
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              'Describe your requirement...',
              style: AppTextStyles.body2.copyWith(
                color: AppColors.gray400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: AppTextStyles.body1.copyWith(
            color: AppColors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        if (actionLabel != null && onActionTap != null)
          GestureDetector(
            onTap: onActionTap,
            child: Text(
              actionLabel!,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final _HomeCategoryData data;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.data,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF3EEFF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                data.icon,
                size: 26,
                color: AppColors.accent,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            data.label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.gray500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectTile extends StatelessWidget {
  final _HomeProjectData data;
  final VoidCallback onTap;

  const _ProjectTile({
    required this.data,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 246,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(17, 24, 39, 0.05),
              offset: Offset(0, 6),
              blurRadius: 20,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    data.title,
                    style: AppTextStyles.body1.copyWith(
                      color: AppColors.black,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: data.statusBackground,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    data.status,
                    style: AppTextStyles.overline.copyWith(
                      color: data.statusTextColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Text(
                  data.phase,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.gray500,
                  ),
                ),
                const Spacer(),
                Text(
                  '${(data.progress * 100).round()}%',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.black,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: LinearProgressIndicator(
                value: data.progress,
                minHeight: 5,
                backgroundColor: const Color(0xFFEDEDED),
                color: const Color(0xFF8B5CF6),
              ),
            ),
            const SizedBox(height: AppSpacing.base),
            Row(
              children: [
                _GradientAvatar(
                  size: 24,
                  fallbackText: data.assignee.characters.first,
                  gradientStart: data.avatarGradientStart,
                  gradientEnd: data.avatarGradientEnd,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Assigned to ${data.assignee}',
                    style: AppTextStyles.overline.copyWith(
                      color: AppColors.gray500,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CreatorTile extends StatelessWidget {
  final _HomeCreatorData data;

  const _CreatorTile({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 144,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(17, 24, 39, 0.05),
            offset: Offset(0, 6),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        children: [
          _GradientAvatar(
            size: 64,
            fallbackText: data.fallbackText,
            gradientStart: data.gradientStart,
            gradientEnd: data.gradientEnd,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            data.name,
            style: AppTextStyles.body2.copyWith(
              color: AppColors.black,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.star_rounded,
                size: 14,
                color: Color(0xFFF59E0B),
              ),
              const SizedBox(width: 2),
              Text(
                data.rating,
                style: AppTextStyles.overline.copyWith(
                  color: AppColors.black,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            alignment: WrapAlignment.center,
            children: data.tags
                .map(
                  (tag) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F2),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      tag,
                      style: AppTextStyles.overline.copyWith(
                        color: AppColors.gray500,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _GradientAvatar extends StatelessWidget {
  final double size;
  final String fallbackText;
  final Color gradientStart;
  final Color gradientEnd;

  const _GradientAvatar({
    required this.size,
    required this.fallbackText,
    required this.gradientStart,
    required this.gradientEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [gradientStart, gradientEnd],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        fallbackText.toUpperCase(),
        style: AppTextStyles.body2.copyWith(
          color: AppColors.white,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.34,
        ),
      ),
    );
  }
}

class _HeroMotionVisual extends StatefulWidget {
  final double size;

  const _HeroMotionVisual({
    required this.size,
  });

  @override
  State<_HeroMotionVisual> createState() => _HeroMotionVisualState();
}

class _HeroMotionVisualState extends State<_HeroMotionVisual>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value * math.pi * 2;
        return Transform.translate(
          offset: Offset(
            math.cos(t * 0.9) * 8,
            math.sin(t) * 10,
          ),
          child: Transform.rotate(
            angle: math.sin(t * 0.8) * 0.05,
            child: child,
          ),
        );
      },
      child: IgnorePointer(
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: Image.asset(
            'assets/branding/app_launch_motion_flat.webp',
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
            alignment: Alignment.center,
          ),
        ),
      ),
    );
  }
}

class _HeroGlow extends StatelessWidget {
  final double size;

  const _HeroGlow({
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0x1FFFFFFF),
        ),
      ),
    );
  }
}

class _HomeCategoryData {
  final String label;
  final IconData icon;
  final String category;

  const _HomeCategoryData({
    required this.label,
    required this.icon,
    required this.category,
  });
}

class _HomeProjectData {
  final String id;
  final String title;
  final String status;
  final String phase;
  final String assignee;
  final double progress;
  final Color statusTextColor;
  final Color statusBackground;
  final Color avatarGradientStart;
  final Color avatarGradientEnd;

  const _HomeProjectData({
    required this.id,
    required this.title,
    required this.status,
    required this.phase,
    required this.assignee,
    required this.progress,
    required this.statusTextColor,
    required this.statusBackground,
    required this.avatarGradientStart,
    required this.avatarGradientEnd,
  });
}

class _HomeCreatorData {
  final String name;
  final String rating;
  final String fallbackText;
  final List<String> tags;
  final Color gradientStart;
  final Color gradientEnd;

  const _HomeCreatorData({
    required this.name,
    required this.rating,
    required this.fallbackText,
    required this.tags,
    required this.gradientStart,
    required this.gradientEnd,
  });
}
