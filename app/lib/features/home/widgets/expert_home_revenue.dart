import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../models/home_models.dart';

class ExpertHomeRevenue extends StatelessWidget {
  final RevenueData revenue;
  final VoidCallback? onViewDetail;

  const ExpertHomeRevenue({
    super.key,
    required this.revenue,
    this.onViewDetail,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.black,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '收入概览',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
                if (onViewDetail != null)
                  GestureDetector(
                    onTap: onViewDetail,
                    child: const Row(
                      children: [
                        Text(
                          '查看',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color.fromRGBO(255, 255, 255, 0.7),
                          ),
                        ),
                        Icon(Icons.chevron_right, size: 16,
                            color: Color.fromRGBO(255, 255, 255, 0.7)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _RevenueAmount(
              label: '累计收入',
              amount: revenue.totalIncome,
              large: true,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _RevenueAmount(
                    label: '本月收入',
                    amount: revenue.monthIncome,
                  ),
                ),
                Expanded(
                  child: _RevenueAmount(
                    label: '待结算',
                    amount: revenue.pendingIncome,
                  ),
                ),
              ],
            ),
            if (revenue.trend != 0) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    revenue.trend > 0
                        ? Icons.trending_up
                        : Icons.trending_down,
                    size: 16,
                    color: revenue.trend > 0
                        ? AppColors.success
                        : AppColors.error,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${revenue.trend > 0 ? '+' : ''}${revenue.trend.toStringAsFixed(1)}% 较上月',
                    style: TextStyle(
                      fontSize: 12,
                      color: revenue.trend > 0
                          ? AppColors.success
                          : AppColors.error,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RevenueAmount extends StatelessWidget {
  final String label;
  final double amount;
  final bool large;

  const _RevenueAmount({
    required this.label,
    required this.amount,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color.fromRGBO(255, 255, 255, 0.6),
          ),
        ),
        const SizedBox(height: 4),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: amount),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOut,
          builder: (context, value, _) => Text(
            '¥${value.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: large ? 28 : 20,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
        ),
      ],
    );
  }
}
