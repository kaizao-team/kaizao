import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../shared/widgets/vcc_button.dart';
import '../../../shared/widgets/vcc_input.dart';
import '../../../shared/widgets/vcc_loading.dart';
import '../../../shared/widgets/vcc_tag.dart';
import '../../../shared/widgets/vcc_toast.dart';
import '../../notification/providers/notification_provider.dart';
import '../../project/providers/project_detail_provider.dart';
import '../providers/match_provider.dart';

class BidFormPage extends ConsumerStatefulWidget {
  final String projectId;

  const BidFormPage({
    super.key,
    required this.projectId,
  });

  @override
  ConsumerState<BidFormPage> createState() => _BidFormPageState();
}

class _BidFormPageState extends ConsumerState<BidFormPage> {
  final _amountController = TextEditingController();
  final _durationController = TextEditingController();
  final _proposalController = TextEditingController();
  int _proposalLength = 0;

  @override
  void initState() {
    super.initState();
    _proposalController.addListener(() {
      final len = _proposalController.text.length;
      if (_proposalLength != len) setState(() => _proposalLength = len);
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _durationController.dispose();
    _proposalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bidFormProvider(widget.projectId));
    final notifier = ref.read(bidFormProvider(widget.projectId).notifier);
    final detailState = ref.watch(projectDetailProvider(widget.projectId));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        scrolledUnderElevation: 0,
        title: Text('投标', style: AppTextStyles.h3),
      ),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                // 项目摘要区
                SliverToBoxAdapter(
                  child: _ProjectContextSection(detailState: detailState),
                ),

                // AI 评估区
                SliverToBoxAdapter(
                  child: _AiEvaluationSection(
                    state: state,
                    onRetry: notifier.reloadSuggestion,
                  ),
                ),

                // 表单区
                SliverToBoxAdapter(
                  child: _BidFormSection(
                    amountController: _amountController,
                    durationController: _durationController,
                    proposalController: _proposalController,
                    proposalLength: _proposalLength,
                    state: state,
                    notifier: notifier,
                    budgetMin: detailState.budgetMin,
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          ),

          // 固定底部按钮
          _BottomSubmitBar(
            state: state,
            onSubmit: () async {
              final ok = await notifier.submit();
              if (!context.mounted) return;
              if (ok) {
                ref.read(notificationProvider.notifier).loadNotifications();
                VccToast.show(context,
                    message: '投标已提交', type: VccToastType.success);
                context.pop();
              } else if (state.errorMessage != null) {
                VccToast.show(context,
                    message: state.errorMessage!, type: VccToastType.error);
              }
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROJECT CONTEXT SECTION
// ─────────────────────────────────────────────────────────────────────────────

class _ProjectContextSection extends StatelessWidget {
  final ProjectDetailState detailState;

  const _ProjectContextSection({required this.detailState});

  @override
  Widget build(BuildContext context) {
    final techTags = detailState.techRequirements;
    final hasData = detailState.title.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PROJECT CONTEXT',
            style: AppTextStyles.overline.copyWith(
              letterSpacing: 1.5,
              color: AppColors.gray400,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          if (!hasData)
            const VccCardSkeleton()
          else
            Container(
              padding: const EdgeInsets.all(AppSpacing.base),
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.gray200, width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    detailState.title,
                    style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (techTags.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: techTags
                          .map((t) => VccTag(label: t))
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.base),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricColumn(
                          label: '预算',
                          value: detailState.budgetMin > 0
                              ? '¥${detailState.budgetMin.toInt()}-${detailState.budgetMax.toInt()}'
                              : '待定',
                        ),
                      ),
                      Expanded(
                        child: _MetricColumn(
                          label: '发布时间',
                          value: detailState.createdAt.isNotEmpty
                              ? detailState.createdAt.substring(0, 10)
                              : '—',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          const SizedBox(height: AppSpacing.section),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AI EVALUATION SECTION
// ─────────────────────────────────────────────────────────────────────────────

class _AiEvaluationSection extends StatelessWidget {
  final BidFormState state;
  final VoidCallback onRetry;

  const _AiEvaluationSection({
    required this.state,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI EVALUATION',
            style: AppTextStyles.overline.copyWith(
              letterSpacing: 1.5,
              color: AppColors.gray400,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          if (state.isLoading)
            const VccCardSkeleton()
          else if (state.suggestion != null)
            _AiCard(suggestion: state.suggestion!)
          else
            _AiUnavailableCard(onRetry: onRetry),

          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

class _AiCard extends StatelessWidget {
  final dynamic suggestion;

  const _AiCard({required this.suggestion});

  @override
  Widget build(BuildContext context) {
    final score = suggestion.skillMatchScore as int;
    final Color matchColor = score >= 80
        ? AppColors.success
        : score >= 60
            ? AppColors.warning
            : AppColors.error;
    final isLowMatch = score < 60;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.gray200, width: 0.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md - 0.5),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 2.5, color: AppColors.accent),
              Expanded(
                child: Container(
                  color: AppColors.surfaceRaised,
                  padding: const EdgeInsets.all(AppSpacing.base),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _MetricColumn(
                              label: '建议报价',
                              value:
                                  '¥${suggestion.suggestedPriceMin.toInt()}-${suggestion.suggestedPriceMax.toInt()}',
                            ),
                          ),
                          Expanded(
                            child: _MetricColumn(
                              label: '建议工期',
                              value:
                                  '${suggestion.suggestedDurationDays}天',
                            ),
                          ),
                          Expanded(
                            child: _MetricColumn(
                              label: '技能匹配',
                              value: '$score%',
                              valueColor: matchColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        suggestion.reason as String,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.gray500,
                          height: 1.5,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isLowMatch) ...[
                        const SizedBox(height: AppSpacing.md),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.warningBg,
                            borderRadius:
                                BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline,
                                  size: 14, color: AppColors.warning),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '技能匹配度较低，建议补充相关经验说明',
                                  style: AppTextStyles.caption
                                      .copyWith(color: AppColors.warning),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AiUnavailableCard extends StatelessWidget {
  final VoidCallback onRetry;

  const _AiUnavailableCard({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.gray200, width: 0.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, size: 16, color: AppColors.gray300),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'AI 评估暂时不可用',
              style: AppTextStyles.body2.copyWith(color: AppColors.gray400),
            ),
          ),
          GestureDetector(
            onTap: onRetry,
            child: Text(
              '重试',
              style: AppTextStyles.body2.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BID FORM SECTION
// ─────────────────────────────────────────────────────────────────────────────

class _BidFormSection extends StatelessWidget {
  final TextEditingController amountController;
  final TextEditingController durationController;
  final TextEditingController proposalController;
  final int proposalLength;
  final BidFormState state;
  final BidFormNotifier notifier;
  final double budgetMin;

  const _BidFormSection({
    required this.amountController,
    required this.durationController,
    required this.proposalController,
    required this.proposalLength,
    required this.state,
    required this.notifier,
    required this.budgetMin,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'YOUR BID',
            style: AppTextStyles.overline.copyWith(
              letterSpacing: 1.5,
              color: AppColors.gray400,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // 报价金额
          Text('报价金额', style: AppTextStyles.inputLabel),
          const SizedBox(height: AppSpacing.sm),
          VccInput(
            controller: amountController,
            hint: '请输入报价（元）',
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            prefixIcon: Padding(
              padding: const EdgeInsets.only(
                  left: AppSpacing.base, right: AppSpacing.sm),
              child: Center(
                widthFactor: 1,
                child: Text(
                  '¥',
                  style:
                      AppTextStyles.body1.copyWith(color: AppColors.gray500),
                ),
              ),
            ),
            onChanged: (val) {
              final amount = double.tryParse(val);
              if (amount != null) notifier.setAmount(amount);
            },
          ),
          if (state.isAmountZero)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '报价不能为 0',
                style:
                    AppTextStyles.caption.copyWith(color: AppColors.error),
              ),
            ),
          if (state.isAmountBelowBudget && !state.isAmountZero)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      size: 14, color: AppColors.warning),
                  const SizedBox(width: 4),
                  Text(
                    '低于 AI 建议报价区间',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.warning),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.xl),

          // 预计工期
          Text('预计工期', style: AppTextStyles.inputLabel),
          const SizedBox(height: AppSpacing.sm),
          VccInput(
            controller: durationController,
            hint: '预计完成天数',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            suffixIcon: Padding(
              padding: const EdgeInsets.only(
                  right: AppSpacing.base, left: AppSpacing.sm),
              child: Center(
                widthFactor: 1,
                child: Text(
                  '天',
                  style:
                      AppTextStyles.body2.copyWith(color: AppColors.gray500),
                ),
              ),
            ),
            onChanged: (val) {
              final days = int.tryParse(val);
              if (days != null) notifier.setDuration(days);
            },
          ),
          const SizedBox(height: AppSpacing.xl),

          // 方案描述
          Row(
            children: [
              Text('方案描述', style: AppTextStyles.inputLabel),
              const Spacer(),
              Text(
                '$proposalLength/500',
                style: AppTextStyles.caption,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          VccInput(
            controller: proposalController,
            hint: '介绍你的开发方案、技术选型和项目经验',
            maxLines: 5,
            maxLength: 500,
            onChanged: notifier.setProposal,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM SUBMIT BAR
// ─────────────────────────────────────────────────────────────────────────────

class _BottomSubmitBar extends StatelessWidget {
  final BidFormState state;
  final VoidCallback onSubmit;

  const _BottomSubmitBar({required this.state, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.gray200, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: VccButton(
            text: '提交投标',
            isLoading: state.isSubmitting,
            onPressed:
                state.canSubmit && !state.isAmountZero ? onSubmit : null,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED: METRIC COLUMN
// ─────────────────────────────────────────────────────────────────────────────

class _MetricColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _MetricColumn({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.overline.copyWith(
            color: AppColors.gray400,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: AppTextStyles.body1.copyWith(
            fontWeight: FontWeight.w700,
            color: valueColor ?? AppColors.onSurface,
          ),
        ),
      ],
    );
  }
}
