import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/vcc_button.dart';

class PaymentReleaseDialog extends StatelessWidget {
  final double amount;
  final String payeeName;
  final String milestoneTitle;
  final bool isSubmitting;
  final VoidCallback onConfirm;

  const PaymentReleaseDialog({
    super.key,
    required this.amount,
    required this.payeeName,
    required this.milestoneTitle,
    required this.isSubmitting,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.successBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.check_circle_outline,
                  size: 32, color: AppColors.success),
            ),
            const SizedBox(height: 16),
            const Text(
              '确认验收通过',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black),
            ),
            const SizedBox(height: 8),
            const Text(
              '验收通过后，托管资金将释放给团队',
              style: TextStyle(fontSize: 13, color: AppColors.gray500),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.gray50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _infoRow('里程碑', milestoneTitle),
                  const SizedBox(height: 8),
                  _infoRow('收款方', payeeName),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('释放金额',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.gray700)),
                      Text(
                        '¥${amount.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: VccButton(
                    text: '取消',
                    type: VccButtonType.secondary,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: VccButton(
                    text: '确认通过',
                    isLoading: isSubmitting,
                    onPressed: onConfirm,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 13, color: AppColors.gray500)),
        Text(value,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.gray800)),
      ],
    );
  }
}
