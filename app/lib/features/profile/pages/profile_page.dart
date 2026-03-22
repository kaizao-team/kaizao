import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/vcc_avatar.dart';
import '../../../shared/widgets/vcc_button.dart';

class ProfilePage extends StatelessWidget {
  final String? userId;
  const ProfilePage({super.key, this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 头部渐变区域
          SliverToBoxAdapter(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 180,
                  decoration: const BoxDecoration(gradient: AppGradients.primary),
                ),
                Positioned(
                  bottom: -40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const VccAvatar(size: VccAvatarSize.xlarge, fallbackText: 'V'),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 52),
                const Text('Vibe Coder', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.gray800)),
                const SizedBox(height: 4),
                const Text('全栈 Vibe Coder', style: TextStyle(fontSize: 14, color: AppColors.gray500)),
                const SizedBox(height: 4),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star, size: 14, color: AppColors.accentGold),
                    SizedBox(width: 2),
                    Text('4.9', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.gray800)),
                    Text(' \u00b7 信用分 920', style: TextStyle(fontSize: 12, color: AppColors.gray400)),
                  ],
                ),
                const SizedBox(height: 24),
                // 数据三格
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem('12', '完成项目'),
                    _buildStatItem('98%', '好评率'),
                    _buildStatItem('3.2天', '平均交付'),
                  ],
                ),
                const SizedBox(height: 24),
                // 技能标签
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['Flutter', 'Go', 'React', 'Node.js', 'PostgreSQL', 'AI']
                        .map((s) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.gray100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(s, style: const TextStyle(fontSize: 12, color: AppColors.gray600)),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: VccButton(text: '编辑主页', type: VccButtonType.secondary, onPressed: () {}),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.gray800)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.gray400)),
      ],
    );
  }
}
