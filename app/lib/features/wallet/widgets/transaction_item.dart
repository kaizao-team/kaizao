import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../models/wallet_models.dart';

class TransactionItem extends StatelessWidget {
  final Transaction transaction;

  const TransactionItem({super.key, required this.transaction});

  IconData get _icon {
    return switch (transaction.type) {
      TransactionType.income => Icons.arrow_downward,
      TransactionType.withdraw => Icons.arrow_upward,
      TransactionType.fee => Icons.receipt_long,
    };
  }

  Color get _iconBg {
    return switch (transaction.type) {
      TransactionType.income => AppColors.success.withValues(alpha: 0.1),
      TransactionType.withdraw => AppColors.accent.withValues(alpha: 0.1),
      TransactionType.fee => AppColors.gray200,
    };
  }

  Color get _iconColor {
    return switch (transaction.type) {
      TransactionType.income => AppColors.success,
      TransactionType.withdraw => AppColors.accent,
      TransactionType.fee => AppColors.gray500,
    };
  }

  @override
  Widget build(BuildContext context) {
    final amountStr = transaction.isPositive
        ? '+${transaction.amount.toStringAsFixed(2)}'
        : transaction.amount.toStringAsFixed(2);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_icon, size: 20, color: _iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _formatDate(transaction.createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.gray400,
                      ),
                    ),
                    if (transaction.status == 'processing') ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentGold.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '处理中',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.accentGold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Text(
            amountStr,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: transaction.isPositive ? AppColors.success : AppColors.black,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String isoDate) {
    if (isoDate.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoDate);
      return '${dt.month}月${dt.day}日 ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoDate;
    }
  }
}
