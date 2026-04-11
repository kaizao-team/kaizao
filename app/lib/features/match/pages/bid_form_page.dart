import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../shared/widgets/vcc_button.dart';
import '../../../shared/widgets/vcc_input.dart';
import '../../../shared/widgets/vcc_toast.dart';
import '../../notification/providers/notification_provider.dart';
import '../models/match_models.dart';
import '../providers/match_provider.dart';
import '../widgets/ai_suggestion_card.dart';

class BidFormPage extends ConsumerStatefulWidget {
  final String projectId;
  final double? budgetMin;

  const BidFormPage({
    super.key,
    required this.projectId,
    this.budgetMin,
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

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text('提交投标', style: AppTextStyles.h3),
      ),
      body: state.isLoading
          ? const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.black),
                ),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // AI 评估卡片
                        if (state.suggestion != null)
                          AiSuggestionCard(suggestion: state.suggestion!)
                        else
                          const AiSuggestionUnavailable(),
                        const SizedBox(height: AppSpacing.section),

                        // 报价金额
                        _FormField(
                          label: '报价金额',
                          child: VccInput(
                            controller: _amountController,
                            hint: '请输入报价（元）',
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9.]')),
                            ],
                            prefixIcon: Padding(
                              padding: const EdgeInsets.only(
                                  left: AppSpacing.base,
                                  right: AppSpacing.sm),
                              child: Center(
                                widthFactor: 1,
                                child: Text('¥',
                                    style: AppTextStyles.body1.copyWith(
                                        color: AppColors.gray500)),
                              ),
                            ),
                            onChanged: (val) {
                              final amount = double.tryParse(val);
                              if (amount != null) notifier.setAmount(amount);
                            },
                          ),
                        ),
                        if (state.isAmountZero)
                          _FieldHint(
                            text: '报价不能为 0',
                            color: AppColors.error,
                          ),
                        if (state.isAmountBelowBudget && !state.isAmountZero)
                          _FieldHint(
                            icon: Icons.warning_amber_rounded,
                            text:
                                '报价低于项目方预算下限 ¥${widget.budgetMin?.toStringAsFixed(0) ?? ''}',
                            color: AppColors.warning,
                          ),
                        const SizedBox(height: AppSpacing.xl),

                        // 预计工期
                        _FormField(
                          label: '预计工期',
                          child: VccInput(
                            controller: _durationController,
                            hint: '请输入天数',
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            suffixIcon: Padding(
                              padding: const EdgeInsets.only(
                                  right: AppSpacing.base,
                                  left: AppSpacing.sm),
                              child: Center(
                                widthFactor: 1,
                                child: Text('天',
                                    style: AppTextStyles.body2.copyWith(
                                        color: AppColors.gray500)),
                              ),
                            ),
                            onChanged: (val) {
                              final days = int.tryParse(val);
                              if (days != null) notifier.setDuration(days);
                            },
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // 方案描述
                        _FormField(
                          label: '方案描述',
                          child: Stack(
                            children: [
                              VccInput(
                                controller: _proposalController,
                                hint: '介绍你的开发方案、技术选型和项目经验',
                                maxLines: 5,
                                maxLength: 500,
                                onChanged: notifier.setProposal,
                              ),
                              Positioned(
                                right: 12,
                                bottom: 10,
                                child: Text(
                                  '$_proposalLength/500',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.gray400,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ),
                  ),
                ),

                // 固定底部按钮
                SafeArea(
                  top: false,
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: VccButton(
                      text: '提交投标',
                      isLoading: state.isSubmitting,
                      onPressed: state.canSubmit && !state.isAmountZero
                          ? () async {
                              final ok = await notifier.submit();
                              if (!context.mounted) return;
                              if (ok) {
                                ref
                                    .read(notificationProvider.notifier)
                                    .loadNotifications();
                                VccToast.show(context,
                                    message: '投标已提交',
                                    type: VccToastType.success);
                                context.pop();
                              } else if (state.errorMessage != null) {
                                VccToast.show(context,
                                    message: state.errorMessage!,
                                    type: VccToastType.error);
                              }
                            }
                          : null,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final Widget child;

  const _FormField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.inputLabel),
        const SizedBox(height: AppSpacing.sm),
        child,
      ],
    );
  }
}

class _FieldHint extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;

  const _FieldHint({
    required this.text,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.caption.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
