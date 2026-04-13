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
    final isAsciiLabel = RegExp(r'^[\x00-\x7F]+$').hasMatch(label);
    return Text(
      label,
      textAlign: textAlign,
      style: AppTextStyles.overline.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: isAsciiLabel ? 2.4 : 0.8,
        color: AppColors.gray400,
      ),
    );
  }
}

class VccPageSection extends StatelessWidget {
  final String label;
  final Widget child;
  final Widget? trailing;
  final double spacing;

  const VccPageSection({
    super.key,
    required this.label,
    required this.child,
    this.trailing,
    this.spacing = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: VccSectionLabel(label)),
            if (trailing != null) trailing!,
          ],
        ),
        SizedBox(height: spacing),
        child,
      ],
    );
  }
}
