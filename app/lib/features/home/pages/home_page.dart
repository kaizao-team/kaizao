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

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final homeState = ref.watch(homeStateProvider);
    final isDemander = authState.userRole != 2;

    return Scaffold(
      body: SafeArea(
        child: homeState.isLoading
            ? const CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _HomeAppBar()),
                  SliverToBoxAdapter(child: HomeSkeleton()),
                ],
              )
            : homeState.errorMessage != null
            ? _buildError(ref, homeState.errorMessage!)
            : RefreshIndicator(
                color: AppColors.black,
                onRefresh: () => ref.read(homeStateProvider.notifier).refresh(),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    const SliverToBoxAdapter(child: _HomeAppBar()),
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

  Widget _buildError(WidgetRef ref, String message) {
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

class _HomeAppBar extends StatelessWidget {
  const _HomeAppBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
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
          const Spacer(),
          IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              size: 24,
              color: AppColors.gray500,
            ),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
