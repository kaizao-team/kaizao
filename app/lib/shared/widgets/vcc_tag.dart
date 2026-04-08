import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';

/// 简单技能标签（用于卡片内）
class VccTag extends StatelessWidget {
  final String label;

  const VccTag({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.gray600,
        ),
      ),
    );
  }
}

enum VccTagType { skill, status, ears, deletable }

/// 开造 VCC 标签组件
/// 支持技能标签、状态标签、EARS类型标签、可删除标签
class VccStatusTag extends StatelessWidget {
  final String label;
  final VccTagType type;
  final String? status;
  final String? earsType;
  final VoidCallback? onDelete;

  const VccStatusTag({
    super.key,
    required this.label,
    this.type = VccTagType.skill,
    this.status,
    this.earsType,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case VccTagType.skill:
        return _buildSkillTag();
      case VccTagType.status:
        return _buildStatusTag();
      case VccTagType.ears:
        return _buildEarsTag();
      case VccTagType.deletable:
        return _buildDeletableTag();
    }
  }

  Widget _buildSkillTag() {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.gray600,
        ),
      ),
    );
  }

  Widget _buildStatusTag() {
    Color bgColor;
    Color textColor;

    switch (status) {
      case 'in_progress':
        bgColor = AppColors.infoBg;
        textColor = AppColors.info;
        break;
      case 'pending':
        bgColor = AppColors.warningBg;
        textColor = AppColors.warning;
        break;
      case 'completed':
        bgColor = AppColors.successBg;
        textColor = AppColors.success;
        break;
      case 'at_risk':
        bgColor = AppColors.errorBg;
        textColor = AppColors.error;
        break;
      case 'not_started':
        bgColor = AppColors.gray100;
        textColor = AppColors.gray500;
        break;
      default:
        bgColor = AppColors.gray100;
        textColor = AppColors.gray500;
    }

    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: AppTextStyles.statusTag.copyWith(
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildEarsTag() {
    Gradient gradient;
    switch (earsType) {
      case 'ubiquitous':
        gradient = AppGradients.earsUbiquitous;
        break;
      case 'event':
        gradient = AppGradients.earsEvent;
        break;
      case 'state':
        gradient = AppGradients.earsState;
        break;
      case 'optional':
        gradient = AppGradients.earsOptional;
        break;
      case 'unwanted':
        gradient = AppGradients.earsUnwanted;
        break;
      default:
        gradient = AppGradients.earsUbiquitous;
    }

    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: AppTextStyles.statusTag.copyWith(
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildDeletableTag() {
    return Container(
      height: 32,
      padding: const EdgeInsets.only(left: 12, right: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTextStyles.body2.copyWith(
              color: AppColors.gray700,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onDelete,
            child: const Icon(
              Icons.close,
              size: 16,
              color: AppColors.gray400,
            ),
          ),
        ],
      ),
    );
  }
}
