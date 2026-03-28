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
    final heroAmount =
        revenue.monthIncome > 0 ? revenue.monthIncome : revenue.totalIncome;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F0F10), Color(0xFF303032)],
          ),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    '工作台',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                ),
                const Spacer(),
                if (onViewDetail != null)
                  InkWell(
                    onTap: onViewDetail,
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '钱包',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.white,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: AppColors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 22),
            const Text(
              '本月收入',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color.fromRGBO(255, 255, 255, 0.68),
              ),
            ),
            const SizedBox(height: 8),
            _RevenueAmount(
              label: '',
              amount: heroAmount,
              large: true,
            ),
            const SizedBox(height: 10),
            Text(
              _summaryText(revenue),
              style: const TextStyle(
                fontSize: 13,
                height: 1.45,
                color: Color.fromRGBO(255, 255, 255, 0.72),
              ),
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final tileWidth = (constraints.maxWidth - 16) / 3;

                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    SizedBox(
                      width: tileWidth,
                      child: _RevenueSnapshot(
                        label: '累计收入',
                        value: _formatCurrency(revenue.totalIncome),
                      ),
                    ),
                    SizedBox(
                      width: tileWidth,
                      child: _RevenueSnapshot(
                        label: '待结算',
                        value: _formatCurrency(revenue.pendingIncome),
                      ),
                    ),
                    SizedBox(
                      width: tileWidth,
                      child: _RevenueSnapshot(
                        label: '较上月',
                        value:
                            '${revenue.trend > 0 ? '+' : ''}${revenue.trend.toStringAsFixed(1)}%',
                        valueColor: _trendColor(revenue.trend),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RevenueSnapshot extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _RevenueSnapshot({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color.fromRGBO(255, 255, 255, 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppColors.white,
            ),
          ),
        ],
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
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color.fromRGBO(255, 255, 255, 0.6),
            ),
          ),
          const SizedBox(height: 4),
        ],
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: amount),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOut,
          builder: (context, value, _) => Text(
            _formatCurrency(value),
            style: TextStyle(
              fontSize: large ? 34 : 20,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
              height: 1.05,
            ),
          ),
        ),
      ],
    );
  }
}

String _formatCurrency(num value) {
  final normalized = value.toStringAsFixed(0);
  final grouped = normalized.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return '¥$grouped';
}

String _summaryText(RevenueData revenue) {
  if (revenue.trend > 0) {
    return '回款节奏比上月更稳，继续优先响应高匹配项目。';
  }
  if (revenue.trend < 0) {
    return '本月回款稍慢，先把待结算项目往前推进。';
  }
  return '本月节奏稳定，适合继续补充高质量项目储备。';
}

Color _trendColor(double trend) {
  if (trend > 0) return AppColors.successDark;
  if (trend < 0) return AppColors.errorDark;
  return AppColors.white;
}
