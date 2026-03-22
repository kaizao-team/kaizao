import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/routes.dart';
import '../../../shared/widgets/vcc_card.dart';
import '../../../shared/widgets/vcc_avatar.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.brandPurple,
          onRefresh: () async {
            await Future.delayed(const Duration(seconds: 1));
          },
          child: CustomScrollView(
            slivers: [
              // 顶部导航
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          gradient: AppGradients.primaryButton,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.rocket_launch, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '开造',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.gray800),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined, size: 24, color: AppColors.gray600),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ),

              // AI入口卡片
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: VccCard(
                    gradient: AppGradients.primary,
                    borderRadius: 16,
                    padding: const EdgeInsets.all(16),
                    onTap: () => context.push(RoutePaths.publishProject),
                    border: Border.all(color: Colors.transparent),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '你好，欢迎回来',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '把你的想法告诉我，AI帮你变成现实',
                          style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8)),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 16, color: Colors.white.withOpacity(0.6)),
                              const SizedBox(width: 8),
                              Text(
                                '描述你的需求...',
                                style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.6)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 热门分类
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('热门分类', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.gray800)),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 109 / 72,
                        children: [
                          _buildCategoryItem(Icons.phone_android, 'APP开发'),
                          _buildCategoryItem(Icons.language, '网站开发'),
                          _buildCategoryItem(Icons.widgets_outlined, '小程序'),
                          _buildCategoryItem(Icons.palette_outlined, 'UI设计'),
                          _buildCategoryItem(Icons.analytics_outlined, '数据分析'),
                          _buildCategoryItem(Icons.school_outlined, '技术指导'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // 我的项目
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('我的项目', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.gray800)),
                      GestureDetector(
                        onTap: () => context.go(RoutePaths.projectList),
                        child: const Text('查看全部 >', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.brandPurple)),
                      ),
                    ],
                  ),
                ),
              ),

              // 项目卡片列表
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: VccProjectCard(
                        title: '智能客服系统',
                        description: '开发一款基于AI的智能客服聊天机器人，支持多轮对话',
                        amount: '\u00a55,000',
                        tags: const ['Flutter', 'GPT-4', 'WebSocket'],
                        footerInfo: '供给方：阿杰 \u00b7 进度 68%',
                        onTap: () => context.push('/projects/1'),
                      ),
                    ),
                    childCount: 2,
                  ),
                ),
              ),

              // 推荐供给方
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                  child: const Text('推荐供给方', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.gray800)),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 180,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: 5,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) => _buildProviderCard(),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryItem(IconData icon, String label) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: AppColors.brandPurple),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.gray700)),
        ],
      ),
    );
  }

  Widget _buildProviderCard() {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.shadow2,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const VccAvatar(size: VccAvatarSize.medium, fallbackText: 'A'),
          const SizedBox(height: 8),
          const Text('阿杰', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.gray800)),
          const SizedBox(height: 4),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star, size: 14, color: AppColors.accentGold),
              SizedBox(width: 2),
              Text('4.9', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.gray800)),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Flutter', style: TextStyle(fontSize: 12, color: AppColors.gray500)),
        ],
      ),
    );
  }
}
