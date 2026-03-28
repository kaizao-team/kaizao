import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/models/project_model.dart';
import '../../../shared/widgets/vcc_empty_state.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notification/providers/notification_provider.dart';
import '../../project/providers/project_list_provider.dart';
import '../providers/home_provider.dart';
import '../widgets/expert_home_demands.dart';
import '../widgets/expert_home_revenue.dart';
import '../widgets/expert_home_team_opportunities.dart';
import '../widgets/home_ai_card.dart';
import '../widgets/home_category_grid.dart';
import '../widgets/home_expert_section.dart';
import '../widgets/home_project_section.dart';
import '../widgets/home_skill_heat.dart';
import '../widgets/home_skeleton.dart';

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
    final projectListState = isDemander ? ref.watch(projectListProvider) : null;
    const homePhysics = AlwaysScrollableScrollPhysics(
      parent: BouncingScrollPhysics(),
    );

    return Scaffold(
      backgroundColor: AppColors.onboardingBackground,
      body: SafeArea(
        bottom: false,
        child: homeState.isLoading
            ? CustomScrollView(
                controller: _scrollController,
                physics: homePhysics,
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
                backgroundColor: AppColors.white,
                onRefresh: () => isDemander
                    ? _refreshDemanderHome(ref)
                    : ref.read(homeStateProvider.notifier).refresh(),
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: homePhysics,
                  slivers: [
                    SliverToBoxAdapter(
                      child: _HomeAppBar(onLogoTap: _scrollToTop),
                    ),
                    if (isDemander)
                      ..._buildDemanderSlices(
                        context,
                        ref,
                        homeState,
                        projectListState?.projects ?? const [],
                      )
                    else
                      ..._buildExpertSlices(context, ref, homeState),
                    const SliverToBoxAdapter(child: SizedBox(height: 108)),
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

  List<Widget> _buildDemanderSlices(
    BuildContext context,
    WidgetRef ref,
    HomeState state,
    List<ProjectModel> fallbackProjects,
  ) {
    final data = state.demanderData;
    final homeProjects = data?.myProjects ?? const <ProjectModel>[];
    final allProjects = homeProjects.isNotEmpty
        ? homeProjects
        : fallbackProjects;

    return [
      SliverToBoxAdapter(
        child: HomeAiCard(
          prompt: data?.aiPrompt ?? '一句话开始，AI 帮你整理结构。',
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
      SliverToBoxAdapter(child: HomeProjectSection(projects: allProjects)),
      if (data != null && data.recommendedExperts.isNotEmpty)
        SliverToBoxAdapter(
          child: HomeExpertSection(
            experts: data.recommendedExperts,
            onRefresh: () => ref.read(homeStateProvider.notifier).refresh(),
          ),
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
      if (data != null && data.teamOpportunities.isNotEmpty)
        SliverToBoxAdapter(
          child: ExpertHomeTeamOpportunities(
            opportunities: data.teamOpportunities,
            onOpenHall: () => context.push(RoutePaths.teamHall),
          ),
        ),
      if (data != null && data.skillHeat.isNotEmpty)
        SliverToBoxAdapter(child: HomeSkillHeat(skills: data.skillHeat)),
    ];
  }
}

Future<void> _refreshDemanderHome(WidgetRef ref) async {
  await Future.wait([
    ref.read(homeStateProvider.notifier).refresh(),
    ref.read(projectListProvider.notifier).refresh(),
  ]);
}

class _HomeAppBar extends ConsumerWidget {
  final VoidCallback? onLogoTap;

  const _HomeAppBar({this.onLogoTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(
      notificationProvider.select((s) => s.unreadCount),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: onLogoTap,
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/branding/app_launch_static_transparent_cropped.png',
                  width: 30,
                  height: 30,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 10),
                const Text(
                  '开造',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => context.push(RoutePaths.notifications),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.gray50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.gray200),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Center(
                    child: Icon(
                      Icons.notifications_none_rounded,
                      size: 18,
                      color: AppColors.gray700,
                    ),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF5A5F),
                          borderRadius: BorderRadius.all(Radius.circular(999)),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          unreadCount > 9 ? '9+' : '$unreadCount',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.1,
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
