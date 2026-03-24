import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/routes.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/home_provider.dart';
import '../widgets/home_ai_card.dart';
import '../widgets/home_category_grid.dart';
import '../widgets/home_project_section.dart';
import '../widgets/home_expert_section.dart';
import '../widgets/home_skeleton.dart';
import '../widgets/expert_home_revenue.dart';
import '../widgets/expert_home_demands.dart';
import '../models/home_models.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final homeState = ref.watch(homeStateProvider);
    final isDemander = authState.userRole != 2;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.black,
          onRefresh: () async {
            await ref.read(homeStateProvider.notifier).refresh();
          },
          child: homeState.isLoading && homeState.demanderData == null && homeState.expertData == null
              ? const CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _HomeTopBar()),
                    SliverToBoxAdapter(child: HomeSkeleton()),
                  ],
                )
              : homeState.errorMessage != null && homeState.demanderData == null && homeState.expertData == null
                  ? _ErrorView(
                      message: homeState.errorMessage!,
                      onRetry: () => ref.read(homeStateProvider.notifier).refresh(),
                    )
                  : isDemander
                      ? _DemanderHome(homeState: homeState)
                      : _ExpertHome(homeState: homeState),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: _HomeTopBar()),
        SliverFillRemaining(
          child: Center(
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
                  onTap: onRetry,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    decoration: BoxDecoration(color: AppColors.black, borderRadius: BorderRadius.circular(8)),
                    child: const Text('重试', style: TextStyle(fontSize: 14, color: AppColors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeTopBar extends StatelessWidget {
  const _HomeTopBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.black,
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Center(
              child: Text(
                'V',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.white,
                  height: 1,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            '开造',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.notifications_outlined,
                size: 24, color: AppColors.gray500),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _DemanderHome extends StatelessWidget {
  final HomeState homeState;

  const _DemanderHome({required this.homeState});

  @override
  Widget build(BuildContext context) {
    final data = homeState.demanderData;

    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: _HomeTopBar()),
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
              onCategoryTap: (key) {
                context.push('${RoutePaths.publishProject}?category=$key');
              },
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
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

class _ExpertHome extends StatelessWidget {
  final HomeState homeState;

  const _ExpertHome({required this.homeState});

  @override
  Widget build(BuildContext context) {
    final data = homeState.expertData;

    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: _HomeTopBar()),
        if (data != null)
          SliverToBoxAdapter(
            child: ExpertHomeRevenue(
              revenue: data.revenue,
              onViewDetail: () {
                context.push('/income');
              },
            ),
          ),
        if (data != null && data.recommendedDemands.isNotEmpty)
          SliverToBoxAdapter(
            child: ExpertHomeDemands(demands: data.recommendedDemands),
          ),
        if (data != null && data.skillHeat.isNotEmpty)
          SliverToBoxAdapter(
            child: _SkillHeatSection(skills: data.skillHeat),
          ),
        if (data != null && data.teamOpportunities.isNotEmpty)
          SliverToBoxAdapter(
            child: _TeamOpportunitiesSection(
              opportunities: data.teamOpportunities,
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

class _SkillHeatSection extends StatelessWidget {
  final List<SkillHeatItem> skills;

  const _SkillHeatSection({required this.skills});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '技能热力',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: skills.map((s) {
              final isHot = s.heat >= 85;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isHot ? AppColors.black : AppColors.gray100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      s.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isHot ? AppColors.white : AppColors.gray700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${s.heat}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isHot ? AppColors.accent : AppColors.gray400,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _TeamOpportunitiesSection extends StatelessWidget {
  final List<TeamOpportunity> opportunities;

  const _TeamOpportunitiesSection({required this.opportunities});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '团队机会',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 12),
          ...opportunities.map(
            (opp) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.gray200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.accentLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.groups_outlined, size: 22, color: AppColors.accent),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              opp.projectTitle,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.black),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '需要 ${opp.neededRole} · ${opp.teamSize}人团队',
                              style: const TextStyle(fontSize: 12, color: AppColors.gray500),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '¥${opp.budget}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.black),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
