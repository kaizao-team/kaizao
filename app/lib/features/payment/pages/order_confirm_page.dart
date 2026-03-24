import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/vcc_button.dart';
import '../../../shared/widgets/vcc_toast.dart';
import '../models/payment_models.dart';
import '../providers/payment_provider.dart';
import '../widgets/fee_breakdown.dart';
import '../widgets/payment_method_sheet.dart';
import '../widgets/coupon_select_sheet.dart';

class OrderConfirmPage extends ConsumerWidget {
  final String orderId;
  const OrderConfirmPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(paymentProvider(orderId));

    return Scaffold(
      appBar: AppBar(title: const Text('确认订单')),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : state.errorMessage != null
              ? _buildError(context, ref)
              : state.order == null
                  ? const Center(child: Text('订单不存在'))
                  : _buildBody(context, ref, state),
      bottomNavigationBar:
          state.order != null ? _buildBottom(context, ref, state) : null,
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.gray300),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => ref.invalidate(paymentProvider(orderId)),
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, WidgetRef ref, PaymentState state) {
    final order = state.order!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Project Info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.gray50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.projectTitle,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black)),
                const SizedBox(height: 6),
                Text('收款方: ${order.payeeName}',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.gray500)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Milestones
          const Text('里程碑分期',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black)),
          const SizedBox(height: 10),
          ...order.milestones.map((m) => _buildMilestone(m)),
          const SizedBox(height: 20),

          // Fee Breakdown
          FeeBreakdown(order: order, discount: state.discountAmount),
          const SizedBox(height: 16),

          // Guarantee
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.infoBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined,
                    size: 18, color: AppColors.info),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(order.guaranteeText,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.info)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Payment Method
          _buildPaymentMethodSelector(context, ref, state),
          const SizedBox(height: 12),

          // Coupon
          _buildCouponSelector(context, ref, state),
        ],
      ),
    );
  }

  Widget _buildMilestone(MilestonePayment m) {
    Color statusColor;
    String statusText;
    if (m.isPaid) {
      statusColor = AppColors.success;
      statusText = '已付';
    } else if (m.isCurrent) {
      statusColor = AppColors.accent;
      statusText = '当前';
    } else {
      statusColor = AppColors.gray400;
      statusText = '待付';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
                color: statusColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(m.title,
                style: const TextStyle(
                    fontSize: 14, color: AppColors.gray700)),
          ),
          Text(statusText,
              style: TextStyle(fontSize: 12, color: statusColor)),
          const SizedBox(width: 8),
          Text('¥${m.amount.toStringAsFixed(0)}',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray800)),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSelector(
      BuildContext context, WidgetRef ref, PaymentState state) {
    final method = state.selectedMethod;
    String label;
    IconData icon;
    Color iconColor;
    if (method == PaymentMethod.wechat) {
      label = '微信支付';
      icon = Icons.wechat;
      iconColor = const Color(0xFF07C160);
    } else if (method == PaymentMethod.alipay) {
      label = '支付宝';
      icon = Icons.account_balance_wallet;
      iconColor = const Color(0xFF1677FF);
    } else {
      label = '请选择支付方式';
      icon = Icons.payment;
      iconColor = AppColors.gray400;
    }

    return InkWell(
      onTap: () => _showMethodSheet(context, ref, state),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.gray200, width: 0.5),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: iconColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.gray800)),
            ),
            const Icon(Icons.chevron_right,
                size: 20, color: AppColors.gray400),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponSelector(
      BuildContext context, WidgetRef ref, PaymentState state) {
    final available = state.coupons.where((c) => c.isAvailable).length;
    final selectedCoupon = state.selectedCouponId != null
        ? state.coupons
            .where((c) => c.id == state.selectedCouponId)
            .firstOrNull
        : null;

    return InkWell(
      onTap: state.coupons.isEmpty
          ? null
          : () => _showCouponSheet(context, ref, state),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.gray200, width: 0.5),
        ),
        child: Row(
          children: [
            const Icon(Icons.confirmation_number_outlined,
                size: 22, color: AppColors.accent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                selectedCoupon != null
                    ? '${selectedCoupon.title} -¥${selectedCoupon.discountAmount.toStringAsFixed(0)}'
                    : available > 0
                        ? '$available张优惠券可用'
                        : '暂无可用优惠券',
                style: TextStyle(
                    fontSize: 14,
                    color: selectedCoupon != null
                        ? AppColors.accent
                        : AppColors.gray800),
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 20, color: AppColors.gray400),
          ],
        ),
      ),
    );
  }

  void _showMethodSheet(
      BuildContext context, WidgetRef ref, PaymentState state) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => PaymentMethodSheet(
        selected: state.selectedMethod,
        onSelect: (m) =>
            ref.read(paymentProvider(orderId).notifier).selectPaymentMethod(m),
      ),
    );
  }

  void _showCouponSheet(
      BuildContext context, WidgetRef ref, PaymentState state) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CouponSelectSheet(
        coupons: state.coupons,
        selectedId: state.selectedCouponId,
        onSelect: (id) =>
            ref.read(paymentProvider(orderId).notifier).selectCoupon(id),
      ),
    );
  }

  Widget _buildBottom(
      BuildContext context, WidgetRef ref, PaymentState state) {
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
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('实付金额',
                  style: TextStyle(fontSize: 12, color: AppColors.gray500)),
              Text(
                '¥${state.actualAmount.toStringAsFixed(0)}',
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.accent),
              ),
            ],
          ),
          const Spacer(),
            SizedBox(
            width: 140,
            child: VccButton(
              text: '立即支付',
              isLoading: state.isPaying,
              onPressed: state.selectedMethod == null
                  ? null
                  : () => _doPay(context, ref),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _doPay(BuildContext context, WidgetRef ref) async {
    final success =
        await ref.read(paymentProvider(orderId).notifier).pay();
    if (!context.mounted) return;
    if (success) {
      context.push('/orders/$orderId/result');
    } else {
      VccToast.show(context, message: '支付失败，请重试');
    }
  }
}
