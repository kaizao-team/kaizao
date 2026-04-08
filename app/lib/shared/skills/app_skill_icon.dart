import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'app_skill_registry.dart';

class AppSkillIcon extends StatelessWidget {
  final String skill;
  final String? category;
  final double size;
  final Color? color;
  final BoxFit fit;

  const AppSkillIcon({
    super.key,
    required this.skill,
    this.category,
    this.size = 18,
    this.color,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    final definition = AppSkillRegistry.resolve(skill, category: category);
    if (definition.assetPath != null) {
      return SvgPicture.asset(
        definition.assetPath!,
        width: size,
        height: size,
        fit: fit,
        colorFilter:
            color == null ? null : ColorFilter.mode(color!, BlendMode.srcIn),
      );
    }
    return Icon(definition.fallbackIcon, size: size, color: color);
  }
}
