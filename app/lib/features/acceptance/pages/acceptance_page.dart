import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/vcc_button.dart';
import '../../../shared/widgets/vcc_toast.dart';
import '../providers/acceptance_provider.dart';
import '../widgets/acceptance_checklist_widget.dart';
import '../widgets/revision_request_sheet.dart';
import '../widgets/payment_release_dialog.dart';

class AcceptancePage extends ConsumerWidget {
  final String milestoneId;
  const AcceptancePage({super.key, required this.milestoneId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(acceptanceProvider(milestoneId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('验收确认'),
        actions: [
          if (state.checklist?.previewUrl != null)
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('预览', style: TextStyle(fontSize: 13)),
            ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : state.errorMessage != null
              ? _buildError(context, ref)
              : state.checklist == null
                  ? const Center(child: Text('暂无验收数据'))
                  : _buildBody(context, ref, state),
      bottomNavigationBar:
          state.checklist != null ? _buildBottom(context, ref, state) : null,
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.gray300),
          const SizedBox(height: 12),
          const Text('加载失败',
              style: TextStyle(color: AppColors.gray500)),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () =>
                ref.read(acceptanceProvider(milestoneId).notifier).loadChecklist(),
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, WidgetRef ref, AcceptanceState state) {
    final cl = state.checklist!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Milestone Info Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accentLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cl.milestoneTitle,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _tag('¥${cl.amount.toStringAsFixed(0)}', AppColors.accent),
                    const SizedBox(width: 8),
                    _tag(cl.payeeName, AppColors.gray600),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('验收清单',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black)),
          const SizedBox(height: 12),
          AcceptanceChecklistWidget(
            items: cl.items,
            progress: cl.progress,
            onToggle: (id) => ref
                .read(acceptanceProvider(milestoneId).notifier)
                .toggleItem(id),
          ),
        ],
      ),
    );
  }

  Widget _tag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _buildBottom(
      BuildContext context, WidgetRef ref, AcceptanceState state) {
    final cl = state.checklist!;
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
            top: BorderSide(color: AppColors.gray200, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: VccButton(
              text: '修改请求',
              type: VccButtonType.secondary,
              onPressed: () => _showRevisionSheet(context, ref, cl),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: VccButton(
              text: '验收通过',
              onPressed: cl.allChecked
                  ? () => _showPaymentDialog(context, ref, cl)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  void _showRevisionSheet(
      BuildContext context, WidgetRef ref, checklist) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => RevisionRequestSheet(
        items: checklist.items,
        onSubmit: (desc, ids) async {
          final success = await ref
              .read(acceptanceProvider(milestoneId).notifier)
              .submitRevision(desc, ids);
          if (success && context.mounted) {
            VccToast.show(context, message: '修改请求已提交');
          }
          return success;
        },
      ),
    );
  }

  void _showPaymentDialog(
      BuildContext context, WidgetRef ref, checklist) {
    showDialog(
      context: context,
      builder: (_) => PaymentReleaseDialog(
        amount: checklist.amount,
        payeeName: checklist.payeeName,
        milestoneTitle: checklist.milestoneTitle,
        isSubmitting: ref.read(acceptanceProvider(milestoneId)).isSubmitting,
        onConfirm: () async {
          final success = await ref
              .read(acceptanceProvider(milestoneId).notifier)
              .confirmAcceptance();
          if (context.mounted) {
            Navigator.pop(context);
            if (success) {
              VccToast.show(context, message: '验收通过，款项已释放');
            }
          }
        },
      ),
    );
  }
}
