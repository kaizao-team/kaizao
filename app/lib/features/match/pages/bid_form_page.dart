import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/vcc_button.dart';
import '../../../shared/widgets/vcc_input.dart';
import '../../../shared/widgets/vcc_toast.dart';
import '../models/match_models.dart';
import '../providers/match_provider.dart';
import '../widgets/ai_suggestion_card.dart';
import '../widgets/bid_type_toggle.dart';

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
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('提交投标',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
      ),
      body: state.isLoading
          ? const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.black),
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (state.suggestion != null)
                    AiSuggestionCard(suggestion: state.suggestion!),
                  const SizedBox(height: 24),
                  BidTypeToggle(
                    selected: state.bidType,
                    onChanged: notifier.setBidType,
                  ),
                  if (state.bidType == BidFormType.team) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.gray50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.gray200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.group_outlined,
                              size: 20, color: AppColors.gray500),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text('选择团队',
                                style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.gray500)),
                          ),
                          GestureDetector(
                            onTap: () {},
                            child: const Text('去组队 →',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.accent)),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const Text('报价金额',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black)),
                  const SizedBox(height: 8),
                  VccInput(
                    controller: _amountController,
                    hint: '请输入报价（元）',
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      final amount = double.tryParse(val);
                      if (amount != null) notifier.setAmount(amount);
                    },
                  ),
                  if (state.isAmountZero)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text('报价不能为 0',
                          style:
                              TextStyle(fontSize: 12, color: AppColors.error)),
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
                            '报价低于需求方预算下限 ¥${widget.budgetMin?.toStringAsFixed(0) ?? ''}',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.warning),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                  const Text('预计工期',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black)),
                  const SizedBox(height: 8),
                  VccInput(
                    controller: _durationController,
                    hint: '预计完成天数',
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      final days = int.tryParse(val);
                      if (days != null) notifier.setDuration(days);
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text('方案描述',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black)),
                  const SizedBox(height: 8),
                  VccInput(
                    controller: _proposalController,
                    hint: '介绍你的开发方案、技术选型和项目经验',
                    maxLines: 5,
                    onChanged: notifier.setProposal,
                  ),
                  const SizedBox(height: 32),
                  VccButton(
                    text: state.isSubmitting ? '提交中...' : '提交投标',
                    isLoading: state.isSubmitting,
                    onPressed: state.canSubmit && !state.isAmountZero
                        ? () async {
                            final ok = await notifier.submit();
                            if (!context.mounted) return;
                            if (ok) {
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
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
