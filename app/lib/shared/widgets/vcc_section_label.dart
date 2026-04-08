import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';

class VccSectionLabel extends StatelessWidget {
  final String text;
  final bool uppercase;
  final TextAlign textAlign;

  const VccSectionLabel(
    this.text, {
    super.key,
    this.uppercase = true,
    this.textAlign = TextAlign.left,
  });

  @override
  Widget build(BuildContext context) {
    final label = uppercase ? text.toUpperCase() : text;
    return Text(
      label,
      textAlign: textAlign,
      style: AppTextStyles.overline.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 2.4,
        color: AppColors.gray400,
      ),
    );
  }
}
