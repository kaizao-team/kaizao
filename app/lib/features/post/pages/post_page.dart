import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/vcc_step_indicator.dart';
import '../../../shared/widgets/vcc_toast.dart';
import '../../market/widgets/market_budget_slider.dart';
import '../models/post_models.dart';
import '../providers/post_provider.dart';
import '../widgets/post_category_step.dart';
import '../widgets/post_ai_chat.dart';
import '../widgets/post_prd_loading.dart';
import '../widgets/post_match_mode.dart';

class PostPage extends ConsumerStatefulWidget {
  final String? initialCategory;

  const PostPage({super.key, this.initialCategory});

  @override
  ConsumerState<PostPage> createState() => _PostPageState();
}

class _PostPageState extends ConsumerState<PostPage> {
  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(postStateProvider.notifier)
            .selectCategory(widget.initialCategory!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final postState = ref.watch(postStateProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.black),
          onPressed: () => _handleBack(postState),
        ),
        title: const Text('创建项目',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.black)),
        centerTitle: true,
        actions: [
          if (postState.currentStep > 0 && postState.currentStep < 4)
            TextButton(
              onPressed: () => ref.read(postStateProvider.notifier).saveDraft(),
              child: const Text('保存草稿',
                  style: TextStyle(fontSize: 13, color: AppColors.gray500)),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: VccStepIndicator(
              totalSteps: 5,
              currentStep: postState.currentStep,
              labels: const ['分类', 'AI对话', 'PRD', '预算', '撮合'],
            ),
          ),
          const Divider(height: 1, color: AppColors.gray200),
          Expanded(child: _buildStepContent(postState)),
        ],
      ),
      bottomNavigationBar: _buildBottomAction(postState),
    );
  }

  Widget _buildStepContent(PostState postState) {
    if (postState.isGeneratingPrd) {
      return PostPrdLoading(progress: postState.prdProgress);
    }

    switch (postState.currentStep) {
      case 0:
        return PostCategoryStep(
          selected: postState.category,
          onSelect: (cat) =>
              ref.read(postStateProvider.notifier).selectCategory(cat),
        );
      case 1:
        return const PostAiChat();
      case 2:
        return _PrdPreviewStep(prdData: postState.prdData);
      case 3:
        return _BudgetStep(
          budgetMin: postState.budgetMin,
          budgetMax: postState.budgetMax,
          suggestion: postState.budgetSuggestion,
          onChanged: (range) => ref
              .read(postStateProvider.notifier)
              .setBudget(range.start, range.end),
        );
      case 4:
        return PostMatchMode(
          selected: postState.matchMode,
          onSelect: (mode) =>
              ref.read(postStateProvider.notifier).setMatchMode(mode),
        );
      default:
        return const SizedBox();
    }
  }

  Widget? _buildBottomAction(PostState postState) {
    if (postState.isGeneratingPrd) return null;

    switch (postState.currentStep) {
      case 2:
        return _BottomBar(
          label: '确认 PRD，设置预算',
          enabled: postState.prdData != null,
          onTap: () => ref.read(postStateProvider.notifier).goToStep(3),
        );
      case 3:
        return _BottomBar(
          label: '下一步',
          enabled: postState.budgetMin != null && postState.budgetMax != null,
          onTap: () => ref.read(postStateProvider.notifier).goToStep(4),
        );
      case 4:
        return _BottomBar(
          label: '创建项目',
          enabled: postState.canPublish,
          isLoading: postState.isPublishing,
          onTap: _handlePublish,
          hasValidationError: postState.validationErrors.isNotEmpty,
        );
      default:
        return null;
    }
  }

  Future<void> _handlePublish() async {
    final notifier = ref.read(postStateProvider.notifier);
    final errors = notifier.validate();
    if (errors.isNotEmpty) {
      final firstError = errors.keys.first;
      final Map<String, String> errorMessages = {
        'category': '请选择分类',
        'prd': '请先生成PRD',
        'budget': '请设置预算范围',
        'matchMode': '请选择撮合模式',
      };
      if (mounted) {
        VccToast.show(context,
            message: errorMessages[firstError] ?? '请完善信息',
            type: VccToastType.warning);
      }
      return;
    }

    final projectId = await notifier.publish();
    if (projectId != null && mounted) {
      VccToast.show(context, message: '项目创建成功', type: VccToastType.success);
      context.go('/projects/$projectId');
    }
  }

  void _handleBack(PostState postState) {
    if (postState.currentStep > 0 && postState.messages.isNotEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('确认离开？',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          content: const Text('当前编辑内容将丢失，确定要离开吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  const Text('取消', style: TextStyle(color: AppColors.gray500)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.pop();
              },
              child:
                  const Text('确定离开', style: TextStyle(color: AppColors.error)),
            ),
          ],
        ),
      );
    } else {
      context.pop();
    }
  }
}

class _PrdPreviewStep extends StatelessWidget {
  final PrdGeneratedData? prdData;

  const _PrdPreviewStep({this.prdData});

  @override
  Widget build(BuildContext context) {
    if (prdData == null) {
      return const Center(
          child: Text('暂无PRD数据', style: TextStyle(color: AppColors.gray400)));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description_outlined,
                  size: 20, color: AppColors.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  prdData!.title,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('模块概览',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray600)),
          const SizedBox(height: 12),
          ...prdData!.modules.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.gray50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.gray200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.accentLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.widgets_outlined,
                            size: 18, color: AppColors.accent),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.name,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.black)),
                            const SizedBox(height: 2),
                            Text('${m.cardCount} 张需求卡片',
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.gray500)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          size: 18, color: AppColors.gray400),
                    ],
                  ),
                ),
              )),
          if (prdData!.budgetSuggestion != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.accentLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline,
                      size: 18, color: AppColors.accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      prdData!.budgetSuggestion!.reason,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.accent),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BudgetStep extends StatelessWidget {
  final double? budgetMin;
  final double? budgetMax;
  final BudgetSuggestion? suggestion;
  final ValueChanged<RangeValues> onChanged;

  const _BudgetStep({
    this.budgetMin,
    this.budgetMax,
    this.suggestion,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Text(
            '设置预算范围',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.black),
          ),
          const SizedBox(height: 8),
          const Text(
            '设置合理的预算有助于吸引优质团队',
            style: TextStyle(fontSize: 14, color: AppColors.gray500),
          ),
          const SizedBox(height: 32),
          MarketBudgetSlider(
            min: 0,
            max: 50000,
            currentMin: budgetMin,
            currentMax: budgetMax,
            onChanged: onChanged,
          ),
          if (suggestion != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.accentLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.accentMuted),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome,
                      size: 18, color: AppColors.accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('AI 推荐预算',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.accent)),
                        const SizedBox(height: 2),
                        Text(
                          '¥${suggestion!.min.toStringAsFixed(0)} - ¥${suggestion!.max.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final String label;
  final bool enabled;
  final bool isLoading;
  final VoidCallback onTap;
  final bool hasValidationError;

  const _BottomBar({
    required this.label,
    required this.enabled,
    this.isLoading = false,
    required this.onTap,
    this.hasValidationError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.gray200, width: 0.5)),
      ),
      child: GestureDetector(
        onTap: enabled && !isLoading ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: enabled ? AppColors.black : AppColors.gray300,
            borderRadius: BorderRadius.circular(12),
            border: hasValidationError
                ? Border.all(color: AppColors.error, width: 2)
                : null,
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.white),
                  )
                : Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
