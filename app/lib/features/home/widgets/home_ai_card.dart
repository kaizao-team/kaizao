import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';

class HomeAiCard extends StatelessWidget {
  final String prompt;
  final VoidCallback onTap;

  const HomeAiCard({
    super.key,
    required this.prompt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = prompt.trim().isEmpty ? '一句话开始，AI 帮你整理结构。' : prompt.trim();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            color: AppColors.black,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(255, 255, 255, 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome_outlined,
                  size: 18,
                  color: Color.fromRGBO(255, 255, 255, 0.82),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '创建项目',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: Color.fromRGBO(255, 255, 255, 0.66),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(255, 255, 255, 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.arrow_outward_rounded,
                  size: 18,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
