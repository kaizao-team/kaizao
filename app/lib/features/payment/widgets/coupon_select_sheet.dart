import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../models/payment_models.dart';

class CouponSelectSheet extends StatelessWidget {
  final List<Coupon> coupons;
  final String? selectedId;
  final ValueChanged<String?> onSelect;

  const CouponSelectSheet({
    super.key,
    required this.coupons,
    this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final available = coupons.where((c) => c.isAvailable).toList();
    final unavailable = coupons.where((c) => !c.isAvailable).toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.gray300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('选择优惠券',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black)),
                if (selectedId != null)
                  TextButton(
                    onPressed: () {
                      onSelect(null);
                      Navigator.pop(context);
                    },
                    child: const Text('不使用优惠券',
                        style: TextStyle(fontSize: 13)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (available.isNotEmpty) ...[
              const Text('可用',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray500)),
              const SizedBox(height: 8),
              ...available.map((c) => _buildCoupon(context, c, true)),
            ],
            if (unavailable.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('不可用',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray400)),
              const SizedBox(height: 8),
              ...unavailable.map((c) => _buildCoupon(context, c, false)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCoupon(BuildContext context, Coupon coupon, bool isAvailable) {
    final isSelected = coupon.id == selectedId;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: isAvailable
            ? () {
                onSelect(coupon.id);
                Navigator.pop(context);
              }
            : null,
        borderRadius: BorderRadius.circular(10),
        child: Opacity(
          opacity: isAvailable ? 1.0 : 0.5,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.accentLight : AppColors.gray50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? AppColors.accent : AppColors.gray200,
                width: isSelected ? 1.5 : 0.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isAvailable
                        ? AppColors.accent.withValues(alpha: 0.1)
                        : AppColors.gray200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '¥${coupon.discountAmount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isAvailable
                            ? AppColors.accent
                            : AppColors.gray400,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(coupon.title,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.gray800)),
                      const SizedBox(height: 2),
                      Text(
                        coupon.reason ??
                            '满${coupon.minOrderAmount.toStringAsFixed(0)}可用 · ${coupon.expireDate}过期',
                        style: TextStyle(
                            fontSize: 11,
                            color: isAvailable
                                ? AppColors.gray500
                                : AppColors.error),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle,
                      size: 20, color: AppColors.accent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
