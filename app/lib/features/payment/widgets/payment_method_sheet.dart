import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../models/payment_models.dart';

class PaymentMethodSheet extends StatelessWidget {
  final PaymentMethod? selected;
  final ValueChanged<PaymentMethod> onSelect;

  const PaymentMethodSheet({
    super.key,
    this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.gray300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text('选择支付方式',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black)),
            const SizedBox(height: 20),
            _buildOption(
              context,
              icon: Icons.wechat,
              iconColor: const Color(0xFF07C160),
              label: '微信支付',
              method: PaymentMethod.wechat,
            ),
            const SizedBox(height: 10),
            _buildOption(
              context,
              icon: Icons.account_balance_wallet,
              iconColor: const Color(0xFF1677FF),
              label: '支付宝',
              method: PaymentMethod.alipay,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required PaymentMethod method,
  }) {
    final isSelected = selected == method;
    return InkWell(
      onTap: () {
        onSelect(method);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentLight : AppColors.gray50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.gray200,
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 28, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.gray800)),
            ),
            if (isSelected)
              const Icon(Icons.check_circle,
                  size: 22, color: AppColors.accent),
          ],
        ),
      ),
    );
  }
}
