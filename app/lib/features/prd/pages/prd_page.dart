import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/prd_models.dart';
import '../providers/prd_provider.dart';
import '../widgets/prd_module_tree.dart';
import '../widgets/ears_card_widget.dart';
import '../widgets/prd_role_filter.dart';

class PrdPage extends ConsumerWidget {
  final String projectId;

  const PrdPage({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prdState = ref.watch(prdStateProvider(projectId));
    final authState = ref.watch(authStateProvider);
    final isDemander = authState.userRole != 2;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          prdState.data?.title ?? '项目文档',
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.black),
        ),
        centerTitle: true,
        actions: [
          if (prdState.data != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _ProgressBadge(progress: prdState.data!.progress),
            ),
        ],
      ),
      body: _buildBody(context, ref, prdState, isDemander),
    );
  }

  Widget _buildBody(
      BuildContext context, WidgetRef ref, PrdState prdState, bool isDemander) {
    if (prdState.isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.black));
    }

    if (prdState.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.gray400),
            const SizedBox(height: 16),
            Text(prdState.errorMessage!,
                style: const TextStyle(color: AppColors.gray500)),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () =>
                  ref.read(prdStateProvider(projectId).notifier).loadPrd(),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                    color: AppColors.black,
                    borderRadius: BorderRadius.circular(8)),
                child:
                    const Text('重试', style: TextStyle(color: AppColors.white)),
              ),
            ),
          ],
        ),
      );
    }

    final data = prdState.data;
    if (data == null) return const SizedBox();

    return Column(
      children: [
        _ViewModeToggle(
          viewMode: prdState.viewMode,
          onToggle: () =>
              ref.read(prdStateProvider(projectId).notifier).toggleViewMode(),
        ),
        if (prdState.viewMode == PrdViewMode.cards)
          PrdRoleFilter(
            selected: prdState.roleFilter,
            onChanged: (role) => ref
                .read(prdStateProvider(projectId).notifier)
                .setRoleFilter(role),
          ),
        const SizedBox(height: 8),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: prdState.viewMode == PrdViewMode.overview
                ? _OverviewTab(
                    key: const ValueKey('overview'),
                    data: data,
                    onCardTap: (cardId) {
                      ref
                          .read(prdStateProvider(projectId).notifier)
                          .toggleViewMode();
                      ref
                          .read(prdStateProvider(projectId).notifier)
                          .expandCard(cardId);
                    },
                  )
                : _CardsTab(
                    key: const ValueKey('cards'),
                    prdState: prdState,
                    projectId: projectId,
                    isDemander: isDemander,
                  ),
          ),
        ),
      ],
    );
  }
}

class _ProgressBadge extends StatelessWidget {
  final double progress;

  const _ProgressBadge({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: progress >= 1.0 ? AppColors.successBg : AppColors.gray100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${(progress * 100).toInt()}%',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: progress >= 1.0 ? AppColors.success : AppColors.gray600,
        ),
      ),
    );
  }
}

class _ViewModeToggle extends StatelessWidget {
  final PrdViewMode viewMode;
  final VoidCallback onToggle;

  const _ViewModeToggle({required this.viewMode, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppColors.gray100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: viewMode != PrdViewMode.overview ? onToggle : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: viewMode == PrdViewMode.overview
                        ? AppColors.white
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: viewMode == PrdViewMode.overview
                        ? const [
                            BoxShadow(
                                color: Color.fromRGBO(0, 0, 0, 0.05),
                                blurRadius: 4)
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.account_tree_outlined,
                          size: 16,
                          color: viewMode == PrdViewMode.overview
                              ? AppColors.black
                              : AppColors.gray400),
                      const SizedBox(width: 6),
                      Text(
                        '概览',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: viewMode == PrdViewMode.overview
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: viewMode == PrdViewMode.overview
                              ? AppColors.black
                              : AppColors.gray500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: viewMode != PrdViewMode.cards ? onToggle : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: viewMode == PrdViewMode.cards
                        ? AppColors.white
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: viewMode == PrdViewMode.cards
                        ? const [
                            BoxShadow(
                                color: Color.fromRGBO(0, 0, 0, 0.05),
                                blurRadius: 4)
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.view_agenda_outlined,
                          size: 16,
                          color: viewMode == PrdViewMode.cards
                              ? AppColors.black
                              : AppColors.gray400),
                      const SizedBox(width: 6),
                      Text(
                        '卡片',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: viewMode == PrdViewMode.cards
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: viewMode == PrdViewMode.cards
                              ? AppColors.black
                              : AppColors.gray500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final PrdData data;
  final ValueChanged<String> onCardTap;

  const _OverviewTab({super.key, required this.data, required this.onCardTap});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: PrdModuleTree(
        modules: data.modules,
        onCardTap: onCardTap,
      ),
    );
  }
}

class _CardsTab extends ConsumerWidget {
  final PrdState prdState;
  final String projectId;
  final bool isDemander;

  const _CardsTab({
    super.key,
    required this.prdState,
    required this.projectId,
    required this.isDemander,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = prdState.activeCards;
    final completed = prdState.completedCards;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        if (active.isNotEmpty) ...[
          _SectionHeader(label: '进行中', count: active.length),
          const SizedBox(height: 8),
          ...active.map((card) => EarsCardWidget(
                card: card,
                isExpanded: prdState.expandedCardId == card.id,
                isDemander: isDemander,
                onToggle: () => ref
                    .read(prdStateProvider(projectId).notifier)
                    .expandCard(card.id),
                onToggleCriteria: (criteriaId) => ref
                    .read(prdStateProvider(projectId).notifier)
                    .toggleCriteria(card.id, criteriaId),
                onDependencyTap: (depId) => ref
                    .read(prdStateProvider(projectId).notifier)
                    .expandCard(depId),
              )),
        ],
        if (completed.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SectionHeader(
              label: '已完成', count: completed.length, isCompleted: true),
          const SizedBox(height: 8),
          ...completed.map((card) => EarsCardWidget(
                card: card,
                isExpanded: prdState.expandedCardId == card.id,
                isDemander: isDemander,
                onToggle: () => ref
                    .read(prdStateProvider(projectId).notifier)
                    .expandCard(card.id),
                onToggleCriteria: (criteriaId) => ref
                    .read(prdStateProvider(projectId).notifier)
                    .toggleCriteria(card.id, criteriaId),
              )),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final int count;
  final bool isCompleted;

  const _SectionHeader({
    required this.label,
    required this.count,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: isCompleted ? AppColors.success : AppColors.accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.black),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: AppColors.gray100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('$count',
              style: const TextStyle(fontSize: 11, color: AppColors.gray500)),
        ),
      ],
    );
  }
}
