import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../shared/widgets/vcc_card.dart';
import '../models/post_models.dart';

class PostMatchMode extends StatelessWidget {
  final MatchMode? selected;
  final ValueChanged<MatchMode> onSelect;

  const PostMatchMode({
    super.key,
    this.selected,
    required this.onSelect,
  });

  static const _modeDetails = {
    MatchMode.ai: _MatchModeDetail(
      eyebrow: '平台先筛',
      description: '系统先根据分类、预算和交付节奏筛出更匹配的团队，适合还没锁定合作对象的需求方。',
      note: '更省时间，适合第一次发项目',
      icon: Icons.auto_awesome_rounded,
    ),
    MatchMode.manual: _MatchModeDetail(
      eyebrow: '公开发布',
      description: '项目进入广场，由团队主动投标。适合你想多看几种报价和方案，再自己判断。',
      note: '选择面更广，但需要自己花时间筛选',
      icon: Icons.travel_explore_rounded,
    ),
    MatchMode.invite: _MatchModeDetail(
      eyebrow: '定向邀请',
      description: '你已经有明确团队或候选人，平台只负责把流程组织起来，减少来回沟通成本。',
      note: '适合已有合作对象或明确名单',
      icon: Icons.person_add_alt_1_rounded,
    ),
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: MatchMode.values.map((mode) {
        final detail = _modeDetails[mode]!;
        final isSelected = selected == mode;

        return Padding(
          padding: EdgeInsets.only(
            bottom: mode == MatchMode.values.last ? 0 : 12,
          ),
          child: VccCard(
            onTap: () => onSelect(mode),
            padding: const EdgeInsets.all(18),
            backgroundColor:
                isSelected ? AppColors.black : AppColors.onboardingSurface,
            border: Border.all(
              color: isSelected ? AppColors.black : AppColors.gray200,
            ),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color.fromRGBO(17, 17, 17, 0.08),
                      blurRadius: 24,
                      offset: Offset(0, 12),
                    ),
                  ]
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color.fromRGBO(255, 255, 255, 0.12)
                            : AppColors.gray100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        detail.icon,
                        size: 20,
                        color: isSelected ? AppColors.white : AppColors.gray700,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            detail.eyebrow,
                            style: AppTextStyles.onboardingMeta.copyWith(
                              color: isSelected
                                  ? const Color.fromRGBO(255, 255, 255, 0.64)
                                  : AppColors.gray500,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            mode.label,
                            style: AppTextStyles.h3.copyWith(
                              color: isSelected
                                  ? AppColors.white
                                  : AppColors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isSelected
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      size: 20,
                      color: isSelected ? AppColors.white : AppColors.gray300,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  detail.description,
                  style: AppTextStyles.body2.copyWith(
                    height: 1.6,
                    color: isSelected
                        ? const Color.fromRGBO(255, 255, 255, 0.78)
                        : AppColors.gray600,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color.fromRGBO(255, 255, 255, 0.08)
                        : AppColors.gray100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    detail.note,
                    style: AppTextStyles.caption.copyWith(
                      height: 1.45,
                      color: isSelected
                          ? const Color.fromRGBO(255, 255, 255, 0.72)
                          : AppColors.gray600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _MatchModeDetail {
  final String eyebrow;
  final String description;
  final String note;
  final IconData icon;

  const _MatchModeDetail({
    required this.eyebrow,
    required this.description,
    required this.note,
    required this.icon,
  });
}
