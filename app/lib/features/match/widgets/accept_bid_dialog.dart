import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../models/match_models.dart';

class AcceptBidDialog extends StatefulWidget {
  final BidItem bid;
  final VoidCallback onConfirm;

  const AcceptBidDialog({
    super.key,
    required this.bid,
    required this.onConfirm,
  });

  @override
  State<AcceptBidDialog> createState() => _AcceptBidDialogState();

  static Future<bool?> show(
    BuildContext context, {
    required BidItem bid,
    required VoidCallback onConfirm,
  }) {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'AcceptBidDialog',
      barrierColor: const Color.fromRGBO(0, 0, 0, 0.5),
      transitionDuration: const Duration(milliseconds: 260),
      transitionBuilder: (context, anim, _, child) {
        return ScaleTransition(
          scale: Tween<double>(begin: 0.95, end: 1.0).animate(
            CurvedAnimation(parent: anim, curve: Curves.easeOut),
          ),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
      pageBuilder: (context, _, __) {
        return AcceptBidDialog(bid: bid, onConfirm: onConfirm);
      },
    );
  }
}

class _AcceptBidDialogState extends State<AcceptBidDialog> {
  @override
  Widget build(BuildContext context) {
    final bid = widget.bid;
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '确认选择',
                style: AppTextStyles.h3.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 20),
              _Row(label: '团队', value: bid.userName),
              const SizedBox(height: 10),
              _Row(label: '报价', value: '¥${bid.bidAmount.toStringAsFixed(0)}'),
              const SizedBox(height: 10),
              _Row(label: '工期', value: '${bid.durationDays}天'),
              const SizedBox(height: 10),
              Text('方案摘要',
                  style: AppTextStyles.caption.copyWith(
                      fontSize: 13, color: AppColors.gray500)),
              const SizedBox(height: 4),
              Text(
                bid.proposal,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body2.copyWith(
                  height: 1.5,
                  color: AppColors.gray700,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.gray300),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Center(
                          child: Text(
                            '再考虑',
                            style: AppTextStyles.body2.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: AppColors.gray600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        widget.onConfirm();
                        Navigator.of(context).pop(true);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.black,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Center(
                          child: Text(
                            '确认选择',
                            style: AppTextStyles.body2.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: AppTextStyles.caption.copyWith(
                fontSize: 13, color: AppColors.gray500)),
        Text(value,
            style: AppTextStyles.body2.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.black)),
      ],
    );
  }
}
