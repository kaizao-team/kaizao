import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/vcc_loading.dart';
import '../../auth/providers/auth_provider.dart';
import '../../project/providers/project_detail_provider.dart';
import '../models/market_filter.dart';
import '../providers/market_provider.dart';
import '../widgets/market_filter_bar.dart';
import '../widgets/market_filter_sheet.dart';
import '../widgets/market_project_card.dart';
import '../widgets/market_expert_card.dart';

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
  bool _isDemander = true;

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
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
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
    final isExpert = authState.userRole == 2;
    _isDemander = !isExpert;
    final hasActiveFilter = state.budgetMin != null || state.budgetMax != null;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  const Text(
                    '项目广场',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {},
                    child: const Icon(
                      Icons.search,
                      size: 24,
                      color: AppColors.gray500,
                    ),
                  ),
                ],
              ),
            ),
            if (_isDemander) _buildDemanderTabs(),
            if (_isDemander)
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildProjectList(
                      state: state,
                      isExpert: isExpert,
                      hasActiveFilter: hasActiveFilter,
                      userRole: authState.userRole,
                    ),
                    _buildExpertList(),
                  ],
                ),
              )
            else
              Expanded(
                child: _buildProjectList(
                  state: state,
                  isExpert: isExpert,
                  hasActiveFilter: hasActiveFilter,
                  userRole: authState.userRole,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDemanderTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.black,
          borderRadius: BorderRadius.circular(8),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: AppColors.white,
        unselectedLabelColor: AppColors.gray600,
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        dividerHeight: 0,
        padding: const EdgeInsets.all(3),
        tabs: const [
          Tab(text: '项目', height: 36),
          Tab(text: '找团队', height: 36),
        ],
      ),
    );
  }

  Widget _buildProjectList({
    required MarketState state,
    required bool isExpert,
    required bool hasActiveFilter,
    required int userRole,
  }) {
    return Column(
      children: [
        const SizedBox(height: 12),
        MarketFilterBar(
          selectedCategory: state.selectedCategory,
          sortBy: state.sortBy,
          hasActiveFilter: hasActiveFilter,
          userRole: userRole,
          onCategoryChanged: (cat) =>
              ref.read(_marketProvider.notifier).setCategory(cat),
          onSortChanged: (sort) =>
              ref.read(_marketProvider.notifier).setSort(sort),
          onFilterTap: () => _showFilterSheet(context, state),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: state.isLoading
              ? _buildSkeleton()
              : state.errorMessage != null && state.projects.isEmpty
                  ? _buildError(state.errorMessage!)
                  : state.projects.isEmpty
                      ? _buildEmpty()
                      : RefreshIndicator(
                          color: AppColors.black,
                          onRefresh: () =>
                              ref.read(_marketProvider.notifier).refresh(),
                          child: ListView(
                            controller: _scrollController,
                            padding: const EdgeInsets.only(top: 4, bottom: 20),
                            children: _buildProjectFeed(
                              context: context,
                              state: state,
                              isExpert: isExpert,
                            ),
                          ),
                        ),
        ),
      ],
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

  Widget _buildExpertList() {
    final expertState = ref.watch(expertListProvider);

    if (expertState.isLoading) {
      return _buildSkeleton();
    }

    if (expertState.errorMessage != null && expertState.experts.isEmpty) {
      return _buildError(expertState.errorMessage!);
    }

    if (expertState.experts.isEmpty) {
      return _buildEmpty();
    }

    return RefreshIndicator(
      color: AppColors.black,
      onRefresh: () => ref.read(expertListProvider.notifier).refresh(),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        itemCount: expertState.experts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final expert = expertState.experts[index];
          return MarketExpertCard(
            expert: expert,
            onTap: () => context.push('/team/${expert.id}/profile'),
          );
        },
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

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.gray100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.inbox_outlined,
              size: 32,
              color: AppColors.gray400,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '暂无内容',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.gray500,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '调整筛选条件试试',
            style: TextStyle(fontSize: 13, color: AppColors.gray400),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
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
          const Text(
            '加载失败',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.gray600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(fontSize: 13, color: AppColors.gray400),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => ref.read(_marketProvider.notifier).refresh(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '重试',
                style: TextStyle(fontSize: 14, color: AppColors.white),
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
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            '已加载全部需求',
            style: TextStyle(fontSize: 13, color: AppColors.gray400),
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
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: AppColors.gray400,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
            color: AppColors.black,
          ),
        ),
      ],
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
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.gray200),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              VccSkeleton(width: 88, height: 26, borderRadius: 999),
              Spacer(),
              VccSkeleton(width: 54, height: 14),
            ],
          ),
          SizedBox(height: 26),
          VccSkeleton(width: 220, height: 34, borderRadius: 10),
          SizedBox(height: 10),
          VccSkeleton(width: 176, height: 34, borderRadius: 10),
          SizedBox(height: 16),
          VccSkeleton(height: 16),
          SizedBox(height: 8),
          VccSkeleton(width: 240, height: 16),
          SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              VccSkeleton(width: 70, height: 28, borderRadius: 999),
              VccSkeleton(width: 84, height: 28, borderRadius: 999),
              VccSkeleton(width: 62, height: 28, borderRadius: 999),
            ],
          ),
          Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    VccSkeleton(width: 32, height: 12),
                    SizedBox(height: 8),
                    VccSkeleton(width: 120, height: 26),
                  ],
                ),
              ),
              SizedBox(width: 18),
              VccSkeleton(width: 34, height: 14),
              SizedBox(width: 12),
              VccSkeleton(width: 34, height: 14),
            ],
          ),
        ],
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
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.gray200),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 170;
          final titleWidth = compact ? 92.0 : 120.0;
          final titleWidth2 = compact ? 76.0 : 96.0;
          final descWidth = compact ? 110.0 : 140.0;
          final tagWidth = compact ? 48.0 : 64.0;

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
              const SizedBox(height: 18),
              VccSkeleton(width: titleWidth, height: 28, borderRadius: 10),
              const SizedBox(height: 8),
              VccSkeleton(width: titleWidth2, height: 28, borderRadius: 10),
              const SizedBox(height: 12),
              const VccSkeleton(height: 14),
              const SizedBox(height: 8),
              VccSkeleton(width: descWidth, height: 14),
              const Spacer(),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  VccSkeleton(width: tagWidth, height: 24, borderRadius: 999),
                  VccSkeleton(
                    width: tagWidth + (compact ? 6 : 10),
                    height: 24,
                    borderRadius: 999,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: VccSkeleton(
                      width: compact ? 76 : 96,
                      height: 18,
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
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.gray200),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 78,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VccSkeleton(width: 30, height: 12),
                SizedBox(height: 8),
                VccSkeleton(width: 64, height: 18),
                SizedBox(height: 18),
                VccSkeleton(width: 28, height: 12),
                SizedBox(height: 8),
                VccSkeleton(width: 24, height: 12),
              ],
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    VccSkeleton(width: 74, height: 24, borderRadius: 999),
                    Spacer(),
                    VccSkeleton(width: 44, height: 12),
                  ],
                ),
                SizedBox(height: 16),
                VccSkeleton(width: 164, height: 28, borderRadius: 10),
                SizedBox(height: 8),
                VccSkeleton(width: 132, height: 28, borderRadius: 10),
                SizedBox(height: 12),
                VccSkeleton(height: 14),
                SizedBox(height: 8),
                VccSkeleton(width: 180, height: 14),
                SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    VccSkeleton(width: 60, height: 24, borderRadius: 999),
                    VccSkeleton(width: 72, height: 24, borderRadius: 999),
                  ],
                ),
              ],
            ),
          ),
        ],
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
