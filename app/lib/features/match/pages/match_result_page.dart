import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/vcc_avatar.dart';
import '../../../shared/widgets/vcc_button.dart';

class MatchResultPage extends StatelessWidget {
  final String projectId;
  const MatchResultPage({super.key, required this.projectId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('收到的投标 (5)')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final isAiRecommend = index == 0;
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: isAiRecommend
                  ? Border.all(color: AppColors.brandPurple, width: 2)
                  : Border.all(color: Colors.black.withOpacity(0.06), width: 0.5),
              boxShadow: AppShadows.shadow2,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isAiRecommend)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: AppGradients.primaryButton,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('AI推荐', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white)),
                  ),
                Row(
                  children: [
                    const VccAvatar(size: VccAvatarSize.medium, fallbackText: 'A'),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('阿杰', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.gray800)),
                          const Row(
                            children: [
                              Icon(Icons.star, size: 14, color: AppColors.accentGold),
                              SizedBox(width: 2),
                              Text('4.9 \u00b7 完成率98%', style: TextStyle(fontSize: 12, color: AppColors.gray500)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text('匹配 ${95 - index * 5}%', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.brandPurple)),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('报价：\u00a53,000  工期：8天', style: TextStyle(fontSize: 16, color: AppColors.gray800)),
                const SizedBox(height: 4),
                const Text('熟悉Flutter和Go开发，有类似项目经验...', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, color: AppColors.gray500)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    VccButton(text: '查看详情', type: VccButtonType.small, isFullWidth: false, onPressed: () {}),
                    const SizedBox(width: 8),
                    VccButton(text: '选 TA', type: VccButtonType.small, isFullWidth: false, onPressed: () {}),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
