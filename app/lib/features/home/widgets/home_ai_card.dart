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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.black,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '你好，欢迎回来',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                prompt,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color.fromRGBO(255, 255, 255, 0.7),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(255, 255, 255, 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: const Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 16,
                        color: Color.fromRGBO(255, 255, 255, 0.5)),
                    SizedBox(width: 8),
                    Text(
                      '描述你的需求...',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color.fromRGBO(255, 255, 255, 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
