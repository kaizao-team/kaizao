import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/routes.dart';
import '../../../shared/widgets/vcc_empty_state.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/home_provider.dart';
import '../widgets/home_ai_card.dart';
import '../widgets/home_category_grid.dart';
import '../widgets/home_project_section.dart';
import '../widgets/home_expert_section.dart';
import '../widgets/expert_home_revenue.dart';
import '../widgets/expert_home_demands.dart';
import '../widgets/home_skill_heat.dart';
import '../widgets/home_skeleton.dart';
import '../../notification/providers/notification_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final homeState = ref.watch(homeStateProvider);
    final isDemander = authState.userRole != 2;

    return Scaffold(
      body: SafeArea(
        child: homeState.isLoading
            ? CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _HomeAppBar(onLogoTap: _scrollToTop),
                  ),
                  const SliverToBoxAdapter(child: HomeSkeleton()),
                ],
              )
            : homeState.errorMessage != null
            ? _buildError(homeState.errorMessage!)
            : RefreshIndicator(
                color: AppColors.black,
                onRefresh: () => ref.read(homeStateProvider.notifier).refresh(),
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: _HomeAppBar(onLogoTap: _scrollToTop),
                    ),
                    if (isDemander)
                      ..._buildDemanderSlices(context, homeState)
                    else
                      ..._buildExpertSlices(context, ref, homeState),
                    const SliverToBoxAdapter(child: SizedBox(height: 32)),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: VccEmptyState(
        icon: Icons.cloud_off_outlined,
        title: '加载失败',
        subtitle: message,
        buttonText: '重试',
        onButtonPressed: () => ref.read(homeStateProvider.notifier).refresh(),
      ),
    );
  }

  List<Widget> _buildDemanderSlices(BuildContext context, HomeState state) {
    final data = state.demanderData;
    return [
      SliverToBoxAdapter(
        child: HomeAiCard(
          prompt: data?.aiPrompt ?? '把你的想法告诉我，AI 帮你变成现实',
          onTap: () => context.push(RoutePaths.publishProject),
        ),
      ),
      if (data != null && data.categories.isNotEmpty)
        SliverToBoxAdapter(
          child: HomeCategoryGrid(
            categories: data.categories,
            onCategoryTap: (key) => context.go(
              Uri(
                path: RoutePaths.square,
                queryParameters: {'category': key},
              ).toString(),
            ),
          ),
        ),
      if (data != null && data.myProjects.isNotEmpty)
        SliverToBoxAdapter(
          child: HomeProjectSection(projects: data.myProjects),
        ),
      if (data != null && data.recommendedExperts.isNotEmpty)
        SliverToBoxAdapter(
          child: HomeExpertSection(experts: data.recommendedExperts),
        ),
    ];
  }

  List<Widget> _buildExpertSlices(
    BuildContext context,
    WidgetRef ref,
    HomeState state,
  ) {
    final data = state.expertData;
    return [
      if (data != null)
        SliverToBoxAdapter(
          child: ExpertHomeRevenue(
            revenue: data.revenue,
            onViewDetail: () => context.push(RoutePaths.wallet),
          ),
        ),
      if (data != null && data.recommendedDemands.isNotEmpty)
        SliverToBoxAdapter(
          child: ExpertHomeDemands(demands: data.recommendedDemands),
        ),
      if (data != null && data.skillHeat.isNotEmpty)
        SliverToBoxAdapter(child: HomeSkillHeat(skills: data.skillHeat)),
    ];
  }
}

class _HomeAppBar extends ConsumerWidget {
  final VoidCallback? onLogoTap;

  const _HomeAppBar({this.onLogoTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final _unreadCount = ref.watch(
      notificationProvider.select((s) => s.unreadCount),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: onLogoTap,
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.black,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.rocket_launch,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  '开造',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => context.push(RoutePaths.notifications),
            child: SizedBox(
              width: 40,
              height: 40,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Center(
                    child: Icon(
                      Icons.notifications_outlined,
                      size: 24,
                      color: AppColors.gray500,
                    ),
                  ),
                  if (_unreadCount > 0)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            _unreadCount > 9 ? '9+' : '$_unreadCount',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
