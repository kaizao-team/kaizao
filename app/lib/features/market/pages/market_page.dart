import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/vcc_loading.dart';
import '../providers/market_provider.dart';
import '../widgets/market_filter_bar.dart';
import '../widgets/market_filter_sheet.dart';
import '../widgets/market_project_card.dart';

class MarketPage extends ConsumerStatefulWidget {
  const MarketPage({super.key});

  @override
  ConsumerState<MarketPage> createState() => _MarketPageState();
}

class _MarketPageState extends ConsumerState<MarketPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      ref.read(marketStateProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(marketStateProvider);
    final hasActiveFilter =
        state.budgetMin != null || state.budgetMax != null;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  const Text(
                    '需求广场',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {},
                    child: const Icon(Icons.search,
                        size: 24, color: AppColors.gray500),
                  ),
                ],
              ),
            ),
            MarketFilterBar(
              selectedCategory: state.selectedCategory,
              sortBy: state.sortBy,
              hasActiveFilter: hasActiveFilter,
              onCategoryChanged: (cat) =>
                  ref.read(marketStateProvider.notifier).setCategory(cat),
              onSortChanged: (sort) =>
                  ref.read(marketStateProvider.notifier).setSort(sort),
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
                          onRefresh: () => ref
                              .read(marketStateProvider.notifier)
                              .refresh(),
                          child: ListView.separated(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 4),
                            itemCount: state.projects.length +
                                (state.hasMore || state.isLoadingMore
                                    ? 1
                                    : 0),
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              if (index == state.projects.length) {
                                return _buildFooter(state);
                              }
                              final project = state.projects[index];
                              return MarketProjectCard(
                                project: project,
                                onTap: () => context
                                    .push('/projects/${project.id}'),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
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
            child: const Icon(Icons.inbox_outlined, size: 32, color: AppColors.gray400),
          ),
          const SizedBox(height: 16),
          const Text('暂无需求', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.gray500)),
          const SizedBox(height: 4),
          const Text('调整筛选条件试试', style: TextStyle(fontSize: 13, color: AppColors.gray400)),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 48, color: AppColors.gray400),
          const SizedBox(height: 16),
          const Text('加载失败', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.gray600)),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(fontSize: 13, color: AppColors.gray400), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => ref.read(marketStateProvider.notifier).refresh(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(color: AppColors.black, borderRadius: BorderRadius.circular(8)),
              child: const Text('重试', style: TextStyle(fontSize: 14, color: AppColors.white)),
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

  void _showFilterSheet(BuildContext context, MarketState state) {
    MarketFilterSheet.show(
      context,
      selectedCategory: state.selectedCategory,
      budgetMin: state.budgetMin,
      budgetMax: state.budgetMax,
      onApply: (result) {
        final notifier = ref.read(marketStateProvider.notifier);
        notifier.setCategory(result.category);
        notifier.setBudgetRange(result.budgetMin, result.budgetMax);
      },
    );
  }
}
