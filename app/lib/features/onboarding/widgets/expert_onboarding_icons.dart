import 'package:flutter/material.dart';

IconData onboardingExpertSkillIcon(String skill) {
  switch (skill) {
    case 'Flutter':
      return Icons.phone_iphone_rounded;
    case 'React':
      return Icons.web_rounded;
    case 'Vue.js':
      return Icons.dashboard_customize_rounded;
    case 'Python':
      return Icons.smart_toy_rounded;
    case 'Go':
      return Icons.hub_rounded;
    case 'Rust':
      return Icons.precision_manufacturing_rounded;
    case 'UI设计':
      return Icons.palette_outlined;
    case 'AI/ML':
      return Icons.auto_awesome_rounded;
    case '后端':
      return Icons.storage_rounded;
    case '全栈':
      return Icons.layers_rounded;
    default:
      return Icons.bolt_rounded;
  }
}

IconData onboardingExpertToolIcon(String tool) {
  switch (tool) {
    case 'Git':
      return Icons.account_tree_rounded;
    case 'Figma':
      return Icons.draw_rounded;
    case 'Notion':
      return Icons.notes_rounded;
    case 'Cursor':
      return Icons.ads_click_rounded;
    case 'VS Code':
      return Icons.code_rounded;
    case 'Docker':
      return Icons.inventory_2_rounded;
    case 'Jira':
      return Icons.rule_rounded;
    default:
      return Icons.build_rounded;
  }
}
