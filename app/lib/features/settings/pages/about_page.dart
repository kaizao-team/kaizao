import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '关于开造',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 40),
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.black,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Text(
                  '开',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              '开造',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.black,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Center(
            child: Text(
              'VibeBuild · v1.0.0',
              style: TextStyle(fontSize: 13, color: AppColors.gray400),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'AI 驱动的软件外包协作平台',
              style: TextStyle(fontSize: 14, color: AppColors.gray500),
            ),
          ),
          const SizedBox(height: 40),
          const Divider(height: 1, color: AppColors.gray200),
          _buildInfoRow('官网', 'vibebuild.com'),
          _buildInfoRow('客服邮箱', 'support@vibebuild.com'),
          _buildInfoRow('备案号', '京ICP备 20260001号'),
          const Divider(height: 1, color: AppColors.gray200),
          const SizedBox(height: 40),
          Center(
            child: Text(
              '© 2026 VibeBuild. All rights reserved.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.gray400.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.gray200, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 15, color: AppColors.gray600),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 14, color: AppColors.gray400),
          ),
        ],
      ),
    );
  }
}
