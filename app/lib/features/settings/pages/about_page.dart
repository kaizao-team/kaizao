import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_colors.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text(
          '关于 KAIZO',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          const SizedBox(height: 48),
          Center(
            child: Image.asset(
              'assets/branding/app_launch_static_transparent_cropped.png',
              width: 72,
              height: 72,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              isAntiAlias: true,
            ),
          ),
          const SizedBox(height: 14),
          const Center(
            child: Text(
              'KAIZO',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1C1C),
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Center(
            child: Text(
              'AI 驱动的软件项目撮合平台',
              style: TextStyle(fontSize: 14, color: AppColors.gray500),
            ),
          ),
          const SizedBox(height: 6),
          const Center(
            child: Text(
              'v1.0.0',
              style: TextStyle(fontSize: 12, color: AppColors.gray400),
            ),
          ),
          const SizedBox(height: 40),
          _buildSection(
            children: const [
              Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Text(
                  '让每一个好想法，都能找到对的团队来实现。',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1C1C),
                    height: 1.5,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Text(
                  'KAIZO 通过人工智能技术，帮助项目方快速梳理软件需求，并智能匹配最合适的开发团队。无论你是有创意想要落地的创业者，还是寻找优质项目的技术团队，KAIZO 都能让对接更高效、协作更透明。',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF555555),
                    height: 1.7,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildSection(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 14),
                child: Text(
                  '核心能力',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray400,
                    letterSpacing: 2,
                  ),
                ),
              ),
              _buildFeatureItem(
                'AI 需求梳理',
                '通过智能对话，帮你把模糊的想法变成清晰的项目需求',
              ),
              _buildFeatureItem(
                '智能团队匹配',
                '基于技能、经验、评价等多维度，精准推荐最适合的团队',
              ),
              _buildFeatureItem(
                '高效撮合流程',
                '从需求发布到团队确认，全流程线上化，减少沟通成本',
              ),
              _buildFeatureItem(
                '透明项目管理',
                '项目进展实时可见，双方协作有据可查',
              ),
              const SizedBox(height: 8),
            ],
          ),
          const SizedBox(height: 8),
          _buildSection(
            children: const [
              Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 14),
                child: Text(
                  '联系方式',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray400,
                    letterSpacing: 2,
                  ),
                ),
              ),
              _InfoRow(label: '官方网站', value: '敬请期待'),
              _InfoRow(label: '客服邮箱', value: 'liangyutao.good@163.com'),
              SizedBox(height: 6),
            ],
          ),
          const SizedBox(height: 8),
          _buildSection(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 14),
                child: Text(
                  '法律信息',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray400,
                    letterSpacing: 2,
                  ),
                ),
              ),
              _LinkRow(
                label: '用户协议',
                onTap: () => context.push(RoutePaths.userAgreement),
              ),
              _LinkRow(
                label: '隐私政策',
                onTap: () => context.push(RoutePaths.privacyPolicy),
              ),
              const SizedBox(height: 6),
            ],
          ),
          const SizedBox(height: 40),
          Center(
            child: Text(
              '© 2026 KAIZO. All rights reserved.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.gray400.withValues(alpha: 0.6),
              ),
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  static Widget _buildSection({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  static Widget _buildFeatureItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 7),
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: Color(0xFF1A1C1C),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1C1C),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.gray500,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: AppColors.gray600),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 13, color: AppColors.gray400),
          ),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _LinkRow({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 14, color: AppColors.gray600),
            ),
            const Spacer(),
            const Icon(
              Icons.chevron_right,
              size: 16,
              color: AppColors.gray300,
            ),
          ],
        ),
      ),
    );
  }
}
