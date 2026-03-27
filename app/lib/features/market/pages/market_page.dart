import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/vcc_loading.dart';
import '../../auth/providers/auth_provider.dart';
import '../../team/providers/team_provider.dart';
import '../../team/widgets/team_post_card.dart';
import '../providers/market_provider.dart';
import '../widgets/market_filter_bar.dart';
import '../widgets/market_filter_sheet.dart';
import '../widgets/market_project_card.dart';
import '../widgets/market_expert_card.dart';

class MarketPage extends ConsumerStatefulWidget {
  final String? initialCategory;

  const MarketPage({super.key, this.initialCategory});

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
    _tabController = TabController(length: 2, vsync: this);
    _scrollController.addListener(_onScroll);
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
                    '广场',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.black,
                      letterSpacing: 1,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.gray50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.search_rounded,
                      size: 20,
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
                    _buildTeamList(),
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
          Tab(text: '找团队', height: 36),
          Tab(text: '找专家', height: 36),
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
                  onRefresh: () => ref.read(_marketProvider.notifier).refresh(),
                  child: ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 4,
                    ),
                    itemCount:
                        state.projects.length +
                        (state.hasMore || state.isLoadingMore ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index == state.projects.length) {
                        return _buildFooter(state);
                      }
                      final project = state.projects[index];
                      return MarketProjectCard(
                        project: project,
                        isExpert: isExpert,
                        aiTip:
                            isExpert &&
                                project.matchScore != null &&
                                project.matchScore! >= 80
                            ? '技能高度匹配，推荐组队投标'
                            : null,
                        onTap: () => context.push('/projects/${project.id}'),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
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
            onTap: () => context.push('/profile/${expert.id}'),
          );
        },
      ),
    );
  }

  Widget _buildTeamList() {
    final teamState = ref.watch(teamHallProvider);

    if (teamState.isLoading) {
      return _buildSkeleton();
    }

    if (teamState.errorMessage != null && teamState.posts.isEmpty) {
      return _buildError(teamState.errorMessage!);
    }

    final allPosts = [
      ...teamState.aiRecommended,
      ...teamState.posts,
    ];

    if (allPosts.isEmpty) {
      return _buildEmpty();
    }

    return RefreshIndicator(
      color: AppColors.black,
      onRefresh: () => ref.read(teamHallProvider.notifier).loadPosts(),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: allPosts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 4),
        itemBuilder: (context, index) {
          final post = allPosts[index];
          return TeamPostCard(
            post: post,
            onTap: () => context.push('/projects/${post.projectId}'),
          );
        },
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => const VccCardSkeleton(),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.gray50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.explore_outlined,
                size: 36,
                color: AppColors.gray300,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '暂无内容',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.gray500,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '试试切换分类或调整筛选条件',
              style: TextStyle(fontSize: 13, color: AppColors.gray400),
            ),
          ],
        ),
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
            '已加载全部项目',
            style: TextStyle(fontSize: 13, color: AppColors.gray400),
          ),
        ),
      );
    }

    return const SizedBox(height: 20);
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
