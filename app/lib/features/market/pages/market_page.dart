import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../shared/widgets/vcc_loading.dart';
import '../../../shared/widgets/vcc_top_switch.dart';
import '../../auth/providers/auth_provider.dart';
import '../../project/providers/project_detail_provider.dart';
import '../models/market_expert.dart';
import '../models/market_filter.dart';
import '../providers/market_provider.dart';
import '../widgets/market_filter_bar.dart';
import '../widgets/market_filter_sheet.dart';
import '../widgets/market_project_card.dart';
import '../widgets/team_featured_card.dart';
import '../widgets/team_presence_hero.dart';
import '../widgets/team_waterfall_tile.dart';

class MarketPage extends ConsumerStatefulWidget {
  final String? initialCategory;
  final String? initialTab;

  const MarketPage({super.key, this.initialCategory, this.initialTab});

  @override
  ConsumerState<MarketPage> createState() => _MarketPageState();
}

class _MarketPageState extends ConsumerState<MarketPage>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late TabController _tabController;

  StateNotifierProvider<MarketNotifier, MarketState> get _marketProvider =>
      marketStateProvider(widget.initialCategory);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: _tabIndexFor(widget.initialTab),
    );
    _tabController.addListener(_handleTabChange);
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant MarketPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      final targetIndex = _tabIndexFor(widget.initialTab);
      if (_tabController.index != targetIndex) {
        _tabController.index = targetIndex;
      }
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      ref.read(_marketProvider.notifier).loadMore();
    }
  }

  int _tabIndexFor(String? value) {
    return value == 'experts' ? 1 : 0;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_marketProvider);
    final authState = ref.watch(authStateProvider);
    final expertState = ref.watch(expertListProvider);
    final isExpert = authState.userRole == 2;
    final hasActiveFilter = state.budgetMin != null || state.budgetMax != null;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
              child: _buildHeader(
                state: state,
                expertState: expertState,
                hasActiveFilter: hasActiveFilter,
                userRole: authState.userRole,
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildProjectList(
                    state: state,
                    isExpert: isExpert,
                  ),
                  _buildExpertList(expertState),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader({
    required MarketState state,
    required ExpertListState expertState,
    required bool hasActiveFilter,
    required int userRole,
  }) {
    final isProjectTab = _tabController.index == 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '广场',
              style: AppTextStyles.h2.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: VccTopSwitch(
                labels: const ['项目', '团队'],
                selectedIndex: _tabController.index,
                onChanged: (index) => _tabController.animateTo(index),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: AppDurations.normal,
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeOutCubic,
          child: isProjectTab
              ? MarketFilterBar(
                  selectedCategory: state.selectedCategory,
                  sortBy: state.sortBy,
                  hasActiveFilter: hasActiveFilter,
                  userRole: userRole,
                  onCategoryChanged: (cat) =>
                      ref.read(_marketProvider.notifier).setCategory(cat),
                  onSortChanged: (sort) =>
                      ref.read(_marketProvider.notifier).setSort(sort),
                  onFilterTap: () => _showFilterSheet(context, state),
                )
              : const SizedBox.shrink(
                  key: ValueKey('team-header-empty'),
                ),
        ),
      ],
    );
  }

  Widget _buildProjectList({
    required MarketState state,
    required bool isExpert,
  }) {
    if (state.isLoading) {
      return _buildSkeleton();
    }

    if (state.errorMessage != null && state.projects.isEmpty) {
      return _buildError(
        state.errorMessage!,
        onRetry: () => ref.read(_marketProvider.notifier).refresh(),
      );
    }

    if (state.projects.isEmpty) {
      return _buildEmpty();
    }

    return RefreshIndicator(
      color: AppColors.black,
      onRefresh: () => ref.read(_marketProvider.notifier).refresh(),
      child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.only(top: 4, bottom: 20),
        children: _buildProjectFeed(
          context: context,
          state: state,
          isExpert: isExpert,
        ),
      ),
    );
  }

  List<Widget> _buildProjectFeed({
    required BuildContext context,
    required MarketState state,
    required bool isExpert,
  }) {
    final projects = state.projects;
    final feature = projects.first;
    final shelf = projects.skip(1).take(4).toList(growable: false);
    final editorial = projects.skip(1 + shelf.length).toList(growable: false);

    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: MarketProjectCard(
          project: feature,
          isExpert: isExpert,
          variant: MarketProjectCardVariant.feature,
          aiTip: _projectAiTip(feature, isExpert),
          onTap: () => _openProject(context, feature),
        ),
      ),
      if (shelf.isNotEmpty) ...[
        const SizedBox(height: 24),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: _MarketSectionHeader(
            eyebrow: '广场正在流动',
            title: '继续逛逛',
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 286,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: shelf.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final project = shelf[index];
              return SizedBox(
                width: 282,
                child: MarketProjectCard(
                  project: project,
                  isExpert: isExpert,
                  variant: MarketProjectCardVariant.shelf,
                  aiTip: _projectAiTip(project, isExpert),
                  onTap: () => _openProject(context, project),
                ),
              );
            },
          ),
        ),
      ],
      if (editorial.isNotEmpty) ...[
        const SizedBox(height: 24),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: _MarketSectionHeader(
            eyebrow: '更多需求',
            title: '继续浏览',
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(editorial.length, (index) {
          final project = editorial[index];
          return Padding(
            padding: EdgeInsets.fromLTRB(20, index == 0 ? 0 : 12, 20, 0),
            child: MarketProjectCard(
              project: project,
              isExpert: isExpert,
              variant: MarketProjectCardVariant.editorial,
              metaLeading: index.isEven,
              aiTip: _projectAiTip(project, isExpert),
              onTap: () => _openProject(context, project),
            ),
          );
        }),
      ],
      _buildFooter(state),
    ];
  }

  Widget _buildExpertList(ExpertListState expertState) {
    if (expertState.isLoading) {
      return _buildSkeleton();
    }

    if (expertState.errorMessage != null && expertState.experts.isEmpty) {
      return _buildError(
        expertState.errorMessage!,
        onRetry: () => ref.read(expertListProvider.notifier).refresh(),
      );
    }

    if (expertState.experts.isEmpty) {
      return _buildEmpty(
        title: '还没有公开展示的团队',
        subtitle: '稍后再来看看新的协作团队',
      );
    }

    final rankedExperts = [...expertState.experts]..sort(
        (left, right) =>
            _teamHighlightScore(right).compareTo(_teamHighlightScore(left)),
      );

    // Zone 2: top 4 as featured cards
    final featured = rankedExperts.take(4).toList(growable: false);
    // Zone 3: the rest as waterfall tiles
    final waterfall =
        rankedExperts.skip(featured.length).toList(growable: false);

    return RefreshIndicator(
      color: AppColors.black,
      onRefresh: () => ref.read(expertListProvider.notifier).refresh(),
      child: ListView(
        padding: const EdgeInsets.only(top: 4, bottom: 20),
        children: [
          // ── Zone 1: Presence Hero ──
          TeamPresenceHero(experts: rankedExperts),

          // ── Zone 2: Featured Cards (horizontal scroll) ──
          if (featured.isNotEmpty) ...[
            const SizedBox(height: 4),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: _MarketSectionHeader(
                eyebrow: '社区精选',
                title: '值得认识的团队',
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: featured.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final expert = featured[index];
                  return SizedBox(
                    width: 220,
                    child: TeamFeaturedCard(
                      expert: expert,
                      highlight: index == 0,
                      onTap: () => context.push('/team/${expert.id}/profile'),
                    ),
                  );
                },
              ),
            ),
          ],

          // ── Zone 3: Waterfall Feed ──
          if (waterfall.isNotEmpty) ...[
            const SizedBox(height: 28),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: _MarketSectionHeader(
                eyebrow: '团队名录',
                title: '看看大家都在做什么',
              ),
            ),
            const SizedBox(height: 12),
            _TeamWaterfall(
              experts: waterfall,
              onTapExpert: (expert) =>
                  context.push('/team/${expert.id}/profile'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 4),
      children: const [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: SizedBox(
            height: 280,
            child: _MarketFeatureSkeletonCard(),
          ),
        ),
        SizedBox(height: 24),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: _MarketSectionHeaderSkeleton(),
        ),
        SizedBox(height: 12),
        SizedBox(
          height: 232,
          child: Row(
            children: [
              SizedBox(width: 20),
              Expanded(child: _MarketShelfSkeletonCard()),
              SizedBox(width: 12),
              Expanded(child: _MarketShelfSkeletonCard()),
              SizedBox(width: 20),
            ],
          ),
        ),
        SizedBox(height: 24),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: SizedBox(
            height: 200,
            child: _MarketEditorialSkeletonCard(),
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty({
    String title = '暂无内容',
    String subtitle = '调整筛选条件试试',
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.gray100,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: const Icon(
              Icons.inbox_outlined,
              size: 32,
              color: AppColors.gray400,
            ),
          ),
          const SizedBox(height: AppSpacing.base),
          Text(
            title,
            style: AppTextStyles.body1.copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.gray500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTextStyles.body2.copyWith(color: AppColors.gray400),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message, {VoidCallback? onRetry}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 48,
            color: AppColors.gray400,
          ),
          const SizedBox(height: 16),
          Text(
            '加载失败',
            style: AppTextStyles.body1.copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.gray600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            style: AppTextStyles.body2.copyWith(color: AppColors.gray400),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.black,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                '重试',
                style: AppTextStyles.body2.copyWith(color: AppColors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(MarketState state) {
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.gray400),
            ),
          ),
        ),
      );
    }

    if (!state.hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            '已加载全部需求',
            style: AppTextStyles.body2.copyWith(color: AppColors.gray400),
          ),
        ),
      );
    }

    return const SizedBox(height: 20);
  }

  Future<void> _openProject(
    BuildContext context,
    MarketProjectItem project,
  ) async {
    await context.push('/projects/${project.routingId}');
    if (!mounted) return;
    final detail = ref.read(
      projectDetailProvider(project.routingId),
    );
    if (detail.data != null) {
      ref.read(_marketProvider.notifier).updateProjectViewCount(
            project.routingId,
            detail.viewCount,
          );
    }
  }

  String? _projectAiTip(MarketProjectItem project, bool isExpert) {
    if (!isExpert || project.matchScore == null || project.matchScore! < 80) {
      return null;
    }
    return '技能高度匹配，推荐优先沟通';
  }

  double _teamHighlightScore(MarketExpertItem expert) {
    return (expert.rating * 24) +
        (expert.completedProjects * 3.5) +
        (expert.memberCount * 4) +
        (expert.vibePower * 0.6);
  }

  void _showFilterSheet(BuildContext context, MarketState state) {
    MarketFilterSheet.show(
      context,
      selectedCategory: state.selectedCategory,
      budgetMin: state.budgetMin,
      budgetMax: state.budgetMax,
      onApply: (result) {
        final notifier = ref.read(_marketProvider.notifier);
        notifier.setCategory(result.category);
        notifier.setBudgetRange(result.budgetMin, result.budgetMax);
      },
    );
  }
}

class _MarketSectionHeader extends StatelessWidget {
  final String eyebrow;
  final String title;

  const _MarketSectionHeader({
    required this.eyebrow,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: AppTextStyles.overline.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: AppColors.gray400,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: AppTextStyles.h2.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
          ),
        ),
      ],
    );
  }
}

class _TeamWaterfall extends StatelessWidget {
  final List<MarketExpertItem> experts;
  final ValueChanged<MarketExpertItem> onTapExpert;

  const _TeamWaterfall({
    required this.experts,
    required this.onTapExpert,
  });

  @override
  Widget build(BuildContext context) {
    // Split into two columns for masonry effect
    final leftItems = <MarketExpertItem>[];
    final rightItems = <MarketExpertItem>[];
    for (var i = 0; i < experts.length; i++) {
      if (i.isEven) {
        leftItems.add(experts[i]);
      } else {
        rightItems.add(experts[i]);
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              children: [
                for (var i = 0; i < leftItems.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  TeamWaterfallTile(
                    expert: leftItems[i],
                    tinted: i.isOdd,
                    onTap: () => onTapExpert(leftItems[i]),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              children: [
                for (var i = 0; i < rightItems.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  TeamWaterfallTile(
                    expert: rightItems[i],
                    tinted: i.isEven,
                    onTap: () => onTapExpert(rightItems[i]),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MarketFeatureSkeletonCard extends StatelessWidget {
  const _MarketFeatureSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(AppRadius.xxxl),
        border: Border.all(color: AppColors.gray200),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 248;
          final titleHeight = compact ? 28.0 : 34.0;
          final lineHeight = compact ? 14.0 : 16.0;
          final tagHeight = compact ? 24.0 : 28.0;
          final verticalGapLg = compact ? 16.0 : 26.0;
          final verticalGapMd = compact ? 12.0 : 18.0;
          final bottomMetricHeight = compact ? 22.0 : 26.0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  VccSkeleton(
                    width: compact ? 76 : 88,
                    height: compact ? 24 : 26,
                    borderRadius: 999,
                  ),
                  const Spacer(),
                  VccSkeleton(
                    width: compact ? 44 : 54,
                    height: 14,
                  ),
                ],
              ),
              SizedBox(height: verticalGapLg),
              VccSkeleton(
                width: compact ? 196 : 220,
                height: titleHeight,
                borderRadius: 10,
              ),
              const SizedBox(height: 8),
              VccSkeleton(
                width: compact ? 148 : 176,
                height: titleHeight,
                borderRadius: 10,
              ),
              SizedBox(height: compact ? 12 : 16),
              VccSkeleton(height: lineHeight),
              const SizedBox(height: 8),
              if (!compact) ...[
                const VccSkeleton(width: 240, height: 16),
                SizedBox(height: verticalGapMd),
              ] else ...[
                const VccSkeleton(width: 196, height: 14),
                const SizedBox(height: 12),
              ],
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  VccSkeleton(
                    width: compact ? 58 : 70,
                    height: tagHeight,
                    borderRadius: 999,
                  ),
                  VccSkeleton(
                    width: compact ? 72 : 84,
                    height: tagHeight,
                    borderRadius: 999,
                  ),
                  if (!compact)
                    const VccSkeleton(
                      width: 62,
                      height: 28,
                      borderRadius: 999,
                    ),
                ],
              ),
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const VccSkeleton(width: 32, height: 12),
                        const SizedBox(height: 8),
                        VccSkeleton(
                          width: compact ? 96 : 120,
                          height: bottomMetricHeight,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: compact ? 12 : 18),
                  const VccSkeleton(width: 34, height: 14),
                  const SizedBox(width: 12),
                  const VccSkeleton(width: 34, height: 14),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MarketShelfSkeletonCard extends StatelessWidget {
  const _MarketShelfSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: AppColors.gray200),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact =
              constraints.maxWidth < 170 || constraints.maxHeight < 178;
          final titleWidth = compact ? 92.0 : 120.0;
          final titleWidth2 = compact ? 76.0 : 96.0;
          final descWidth = compact ? 110.0 : 140.0;
          final tagWidth = compact ? 48.0 : 64.0;
          final titleHeight = compact ? 22.0 : 28.0;
          final topGap = compact ? 12.0 : 18.0;
          final bottomGap = compact ? 10.0 : 16.0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  VccSkeleton(
                    width: compact ? 58 : 72,
                    height: 24,
                    borderRadius: 999,
                  ),
                  const Spacer(),
                  VccSkeleton(
                    width: compact ? 40 : 52,
                    height: 12,
                  ),
                ],
              ),
              SizedBox(height: topGap),
              VccSkeleton(
                width: titleWidth,
                height: titleHeight,
                borderRadius: 10,
              ),
              const SizedBox(height: 8),
              VccSkeleton(
                width: titleWidth2,
                height: titleHeight,
                borderRadius: 10,
              ),
              SizedBox(height: compact ? 8 : 12),
              VccSkeleton(height: compact ? 12 : 14),
              const SizedBox(height: 8),
              VccSkeleton(
                width: descWidth,
                height: compact ? 12 : 14,
              ),
              const Spacer(),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  VccSkeleton(
                    width: tagWidth,
                    height: compact ? 22 : 24,
                    borderRadius: 999,
                  ),
                  VccSkeleton(
                    width: tagWidth + (compact ? 6 : 10),
                    height: compact ? 22 : 24,
                    borderRadius: 999,
                  ),
                ],
              ),
              SizedBox(height: bottomGap),
              Row(
                children: [
                  Expanded(
                    child: VccSkeleton(
                      width: compact ? 76 : 96,
                      height: compact ? 16 : 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  VccSkeleton(
                    width: compact ? 44 : 58,
                    height: 12,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MarketEditorialSkeletonCard extends StatelessWidget {
  const _MarketEditorialSkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: AppColors.gray200),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 170;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: compact ? 68 : 78,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const VccSkeleton(width: 30, height: 12),
                    const SizedBox(height: 8),
                    VccSkeleton(
                      width: compact ? 52 : 64,
                      height: compact ? 16 : 18,
                    ),
                    SizedBox(height: compact ? 12 : 18),
                    const VccSkeleton(width: 28, height: 12),
                    const SizedBox(height: 8),
                    const VccSkeleton(width: 24, height: 12),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        VccSkeleton(
                          width: compact ? 66 : 74,
                          height: 24,
                          borderRadius: 999,
                        ),
                        const Spacer(),
                        const VccSkeleton(width: 44, height: 12),
                      ],
                    ),
                    SizedBox(height: compact ? 12 : 16),
                    VccSkeleton(
                      width: compact ? 146 : 164,
                      height: compact ? 24 : 28,
                      borderRadius: 10,
                    ),
                    const SizedBox(height: 8),
                    VccSkeleton(
                      width: compact ? 116 : 132,
                      height: compact ? 24 : 28,
                      borderRadius: 10,
                    ),
                    SizedBox(height: compact ? 8 : 12),
                    VccSkeleton(height: compact ? 12 : 14),
                    const SizedBox(height: 8),
                    VccSkeleton(
                      width: compact ? 150 : 180,
                      height: compact ? 12 : 14,
                    ),
                    SizedBox(height: compact ? 10 : 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        VccSkeleton(
                          width: compact ? 52 : 60,
                          height: compact ? 22 : 24,
                          borderRadius: 999,
                        ),
                        VccSkeleton(
                          width: compact ? 62 : 72,
                          height: compact ? 22 : 24,
                          borderRadius: 999,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MarketSectionHeaderSkeleton extends StatelessWidget {
  const _MarketSectionHeaderSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VccSkeleton(width: 72, height: 11),
        SizedBox(height: 6),
        VccSkeleton(width: 118, height: 24, borderRadius: 8),
      ],
    );
  }
}
