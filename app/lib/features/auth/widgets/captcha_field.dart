import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../shared/widgets/vcc_input.dart';
import '../repositories/auth_repository.dart';

/// 图形验证码输入区域：标签 + 输入框 + 验证码图片（可点击刷新）
class CaptchaField extends StatelessWidget {
  final CaptchaResult? captcha;
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onRefresh;
  final bool isLoading;
  final bool compact;

  const CaptchaField({
    super.key,
    required this.captcha,
    required this.controller,
    required this.focusNode,
    required this.onRefresh,
    this.isLoading = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: AppSpacing.xs),
          child: Text(
            '验证码',
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.gray500,
            ),
          ),
        ),
        Theme(
          data: theme.copyWith(
            inputDecorationTheme: theme.inputDecorationTheme.copyWith(
              fillColor: AppColors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base,
                vertical: AppSpacing.base,
              ),
              hintStyle: AppTextStyles.inputHint.copyWith(
                color: AppColors.gray300,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(
                  color: AppColors.gray200,
                  width: 1.2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(
                  color: AppColors.black,
                  width: 1.4,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(
                  color: AppColors.gray200,
                  width: 1.2,
                ),
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: VccInput(
                  hint: '请输入图形验证码',
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: TextInputType.visiblePassword,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(8),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              GestureDetector(
                onTap: isLoading ? null : onRefresh,
                child: Container(
                  width: 120,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.gray100,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: AppColors.gray200,
                      width: 1.2,
                    ),
                  ),
                  child: _buildCaptchaContent(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCaptchaContent() {
    if (isLoading) {
      return const Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.gray400,
          ),
        ),
      );
    }

    if (captcha == null || captcha!.imageBase64.isEmpty) {
      return Center(
        child: Text(
          '点击获取',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.gray400,
          ),
        ),
      );
    }

    try {
      final bytes = base64Decode(captcha!.imageBase64);
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md - 1),
        child: Image.memory(
          bytes,
          fit: BoxFit.contain,
          width: 120,
          height: 48,
        ),
      );
    } catch (_) {
      return Center(
        child: Text(
          '加载失败，点击重试',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.gray400,
            fontSize: 11,
          ),
        ),
      );
    }
  }
}
