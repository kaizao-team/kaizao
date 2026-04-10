import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 340) {
            return _CompactRevenueBoard(
              revenue: revenue,
              heroAmount: heroAmount,
              onViewDetail: onViewDetail,
            );
          }

          return _SplitRevenueBoard(
            revenue: revenue,
            heroAmount: heroAmount,
            onViewDetail: onViewDetail,
          );
        },
      ),
    );
  }
}

class _SplitRevenueBoard extends StatelessWidget {
  final RevenueData revenue;
  final double heroAmount;
  final VoidCallback? onViewDetail;

  const _SplitRevenueBoard({
    required this.revenue,
    required this.heroAmount,
    this.onViewDetail,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(0),
      child: SizedBox(
        height: 164,
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: _RevenueHeroPanel(
                revenue: revenue,
                heroAmount: heroAmount,
                onViewDetail: onViewDetail,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  Expanded(
                    child: _RevenueSnapshot(
                      label: '累计收入',
                      value: _formatCurrency(revenue.totalIncome),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: _RevenueSnapshot(
                      label: '待结算',
                      value: _formatCurrency(revenue.pendingIncome),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactRevenueBoard extends StatelessWidget {
  final RevenueData revenue;
  final double heroAmount;
  final VoidCallback? onViewDetail;

  const _CompactRevenueBoard({
    required this.revenue,
    required this.heroAmount,
    this.onViewDetail,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(0),
      child: Column(
        children: [
          SizedBox(
            height: 148,
            child: _RevenueHeroPanel(
              revenue: revenue,
              heroAmount: heroAmount,
              onViewDetail: onViewDetail,
              compact: true,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final tileWidth = (constraints.maxWidth - 8) / 2;
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
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RevenueHeroPanel extends StatelessWidget {
  final RevenueData revenue;
  final double heroAmount;
  final VoidCallback? onViewDetail;
  final bool compact;

  const _RevenueHeroPanel({
    required this.revenue,
    required this.heroAmount,
    this.onViewDetail,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F0F10), Color(0xFF303032)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _HeroPill(label: '工作台'),
              const Spacer(),
              if (onViewDetail != null)
                _HeroAction(
                  label: '钱包',
                  onTap: onViewDetail!,
                ),
            ],
          ),
          const Spacer(),
          Text(
            '本月收入',
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color.fromRGBO(255, 255, 255, 0.68),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: _RevenueAmount(
                  amount: heroAmount,
                  large: !compact,
                ),
              ),
              if (revenue.trend != 0) ...[
                const SizedBox(width: 10),
                _TrendBadge(trend: revenue.trend),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _summaryText(revenue),
            maxLines: compact ? 2 : 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              height: 1.45,
              color: const Color.fromRGBO(255, 255, 255, 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  final String label;

  const _HeroPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: AppTextStyles.overline.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
          color: AppColors.white,
        ),
      ),
    );
  }
}

class _HeroAction extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _HeroAction({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: AppColors.white,
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendBadge extends StatelessWidget {
  final double trend;

  const _TrendBadge({required this.trend});

  @override
  Widget build(BuildContext context) {
    final isPositive = trend >= 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.north_east_rounded : Icons.south_east_rounded,
            size: 14,
            color: isPositive ? AppColors.successDark : AppColors.errorDark,
          ),
          const SizedBox(width: 4),
          Text(
            _trendText(trend),
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: isPositive ? AppColors.successDark : AppColors.errorDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _RevenueSnapshot extends StatelessWidget {
  final String label;
  final String value;

  const _RevenueSnapshot({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.overline.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.gray500,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppTextStyles.body1.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RevenueAmount extends StatelessWidget {
  final double amount;
  final bool large;

  const _RevenueAmount({
    required this.amount,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: amount),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOut,
      builder: (context, value, _) => FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          _formatCurrency(value),
          maxLines: 1,
          style: AppTextStyles.h1.copyWith(
            fontSize: large ? 31 : 28,
            color: AppColors.white,
            height: 1.02,
          ),
        ),
      ),
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

String _trendText(double trend) {
  return '${trend > 0 ? '+' : ''}${trend.toStringAsFixed(1)}%';
}

String _summaryText(RevenueData revenue) {
  if (revenue.trend > 0) {
    return '回款在提速，优先继续响应高匹配项目。';
  }
  if (revenue.trend < 0) {
    return '回款偏慢，先把待结算项目往前推。';
  }
  return '节奏稳定，适合补充下一批高质量项目。';
}
