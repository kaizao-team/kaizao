import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../models/payment_models.dart';

class FeeBreakdown extends StatelessWidget {
  final OrderDetail order;
  final double discount;

  const FeeBreakdown({
    super.key,
    required this.order,
    required this.discount,
  });

  double get _actualAmount => order.totalAmount - discount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('费用明细',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black)),
          const SizedBox(height: 12),
          _row('项目金额', '¥${order.projectAmount.toStringAsFixed(0)}'),
          const SizedBox(height: 8),
          _row('平台服务费', '¥${order.platformFee.toStringAsFixed(0)}'),
          if (discount > 0) ...[
            const SizedBox(height: 8),
            _row('优惠抵扣', '-¥${discount.toStringAsFixed(0)}',
                valueColor: AppColors.error),
          ],
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('实付金额',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black)),
              Text(
                '¥${_actualAmount.toStringAsFixed(0)}',
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.accent),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                const TextStyle(fontSize: 13, color: AppColors.gray500)),
        Text(value,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: valueColor ?? AppColors.gray800)),
      ],
    );
  }
}
