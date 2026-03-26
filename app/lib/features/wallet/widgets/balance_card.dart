import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../models/wallet_models.dart';

class BalanceCard extends StatelessWidget {
  final WalletBalance balance;
  final VoidCallback onWithdraw;

  const BalanceCard({
    super.key,
    required this.balance,
    required this.onWithdraw,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '可提现余额 (¥)',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.gray400,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                balance.available.toStringAsFixed(2),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                  height: 1,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onWithdraw,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '提现',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _MiniStat(label: '冻结中', value: '¥${balance.frozen.toStringAsFixed(0)}'),
              const SizedBox(width: 32),
              _MiniStat(label: '累计收入', value: '¥${balance.totalEarned.toStringAsFixed(0)}'),
              const SizedBox(width: 32),
              _MiniStat(label: '已提现', value: '¥${balance.totalWithdrawn.toStringAsFixed(0)}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.white.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }
}
