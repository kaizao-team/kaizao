import 'package:flutter/material.dart';

enum AppSkillKind { skill, tool }

class AppSkillDefinition {
  final String id;
  final String label;
  final String category;
  final AppSkillKind kind;
  final List<String> aliases;
  final String shortLabel;
  final IconData fallbackIcon;
  final String? assetPath;
  final String? onboardingDescription;

  const AppSkillDefinition({
    required this.id,
    required this.label,
    required this.category,
    required this.kind,
    required this.aliases,
    required this.shortLabel,
    required this.fallbackIcon,
    this.assetPath,
    this.onboardingDescription,
  });

  bool get hasAssetIcon => assetPath != null;
}

class AppSkillRegistry {
  static const List<AppSkillDefinition> _definitions = [
    AppSkillDefinition(
      id: 'flutter',
      label: 'Flutter',
      category: 'framework',
      kind: AppSkillKind.skill,
      aliases: ['flutter开发'],
      shortLabel: 'FL',
      fallbackIcon: Icons.flutter_dash_rounded,
      assetPath: 'assets/skills/icons/flutter.svg',
      onboardingDescription: '适合移动端产品、跨端应用与交互型工具。',
    ),
    AppSkillDefinition(
      id: 'react',
      label: 'React',
      category: 'framework',
      kind: AppSkillKind.skill,
      aliases: [],
      shortLabel: 'RE',
      fallbackIcon: Icons.blur_circular_rounded,
      assetPath: 'assets/skills/icons/react.svg',
      onboardingDescription: '适合 Web 应用、后台系统与复杂前端交互。',
    ),
    AppSkillDefinition(
      id: 'vuejs',
      label: 'Vue.js',
      category: 'framework',
      kind: AppSkillKind.skill,
      aliases: ['vue', 'vuejs'],
      shortLabel: 'VUE',
      fallbackIcon: Icons.dashboard_customize_rounded,
      assetPath: 'assets/skills/icons/vuejs.svg',
      onboardingDescription: '适合官网、中后台和快速交付型项目。',
    ),
    AppSkillDefinition(
      id: 'angular',
      label: 'Angular',
      category: 'framework',
      kind: AppSkillKind.skill,
      aliases: [],
      shortLabel: 'NG',
      fallbackIcon: Icons.change_history_rounded,
      assetPath: 'assets/skills/icons/angular.svg',
    ),
    AppSkillDefinition(
      id: 'nextjs',
      label: 'Next.js',
      category: 'framework',
      kind: AppSkillKind.skill,
      aliases: ['next', 'nextjs'],
      shortLabel: 'NX',
      fallbackIcon: Icons.language_rounded,
    ),
    AppSkillDefinition(
      id: 'nuxt',
      label: 'Nuxt',
      category: 'framework',
      kind: AppSkillKind.skill,
      aliases: ['nuxtjs'],
      shortLabel: 'NXT',
      fallbackIcon: Icons.language_rounded,
    ),
    AppSkillDefinition(
      id: 'python',
      label: 'Python',
      category: 'language',
      kind: AppSkillKind.skill,
      aliases: [],
      shortLabel: 'PY',
      fallbackIcon: Icons.code_rounded,
      assetPath: 'assets/skills/icons/python.svg',
      onboardingDescription: '适合数据处理、自动化、AI 服务与后端逻辑。',
    ),
    AppSkillDefinition(
      id: 'go',
      label: 'Go',
      category: 'language',
      kind: AppSkillKind.skill,
      aliases: ['golang'],
      shortLabel: 'GO',
      fallbackIcon: Icons.hub_rounded,
      assetPath: 'assets/skills/icons/go.svg',
      onboardingDescription: '适合高并发 API、服务架构与工程稳定性建设。',
    ),
    AppSkillDefinition(
      id: 'rust',
      label: 'Rust',
      category: 'language',
      kind: AppSkillKind.skill,
      aliases: [],
      shortLabel: 'RS',
      fallbackIcon: Icons.precision_manufacturing_rounded,
      assetPath: 'assets/skills/icons/rust.svg',
      onboardingDescription: '适合高性能模块、底层工具与安全要求较高的项目。',
    ),
    AppSkillDefinition(
      id: 'swift',
      label: 'Swift',
      category: 'language',
      kind: AppSkillKind.skill,
      aliases: [],
      shortLabel: 'SW',
      fallbackIcon: Icons.rocket_launch_rounded,
      assetPath: 'assets/skills/icons/swift.svg',
    ),
    AppSkillDefinition(
      id: 'kotlin',
      label: 'Kotlin',
      category: 'language',
      kind: AppSkillKind.skill,
      aliases: [],
      shortLabel: 'KT',
      fallbackIcon: Icons.android_rounded,
      assetPath: 'assets/skills/icons/kotlin.svg',
    ),
    AppSkillDefinition(
      id: 'java',
      label: 'Java',
      category: 'language',
      kind: AppSkillKind.skill,
      aliases: ['openjdk'],
      shortLabel: 'JV',
      fallbackIcon: Icons.coffee_rounded,
      assetPath: 'assets/skills/icons/java.svg',
    ),
    AppSkillDefinition(
      id: 'dart',
      label: 'Dart',
      category: 'language',
      kind: AppSkillKind.skill,
      aliases: [],
      shortLabel: 'DT',
      fallbackIcon: Icons.code_rounded,
      assetPath: 'assets/skills/icons/dart.svg',
    ),
    AppSkillDefinition(
      id: 'typescript',
      label: 'TypeScript',
      category: 'language',
      kind: AppSkillKind.skill,
      aliases: ['ts'],
      shortLabel: 'TS',
      fallbackIcon: Icons.data_object_rounded,
      assetPath: 'assets/skills/icons/typescript.svg',
    ),
    AppSkillDefinition(
      id: 'nodejs',
      label: 'Node.js',
      category: 'backend',
      kind: AppSkillKind.skill,
      aliases: ['node', 'nodejs', 'node js'],
      shortLabel: 'NODE',
      fallbackIcon: Icons.route_rounded,
      assetPath: 'assets/skills/icons/nodejs.svg',
    ),
    AppSkillDefinition(
      id: 'postgresql',
      label: 'PostgreSQL',
      category: 'database',
      kind: AppSkillKind.skill,
      aliases: ['postgres', 'psql'],
      shortLabel: 'PG',
      fallbackIcon: Icons.storage_rounded,
      assetPath: 'assets/skills/icons/postgresql.svg',
    ),
    AppSkillDefinition(
      id: 'mongodb',
      label: 'MongoDB',
      category: 'database',
      kind: AppSkillKind.skill,
      aliases: ['mongo'],
      shortLabel: 'MG',
      fallbackIcon: Icons.dataset_rounded,
      assetPath: 'assets/skills/icons/mongodb.svg',
    ),
    AppSkillDefinition(
      id: 'redis',
      label: 'Redis',
      category: 'database',
      kind: AppSkillKind.skill,
      aliases: [],
      shortLabel: 'RD',
      fallbackIcon: Icons.memory_rounded,
      assetPath: 'assets/skills/icons/redis.svg',
    ),
    AppSkillDefinition(
      id: 'docker',
      label: 'Docker',
      category: 'devops',
      kind: AppSkillKind.tool,
      aliases: [],
      shortLabel: 'DK',
      fallbackIcon: Icons.inventory_2_rounded,
      assetPath: 'assets/skills/icons/docker.svg',
    ),
    AppSkillDefinition(
      id: 'k8s',
      label: 'K8s',
      category: 'devops',
      kind: AppSkillKind.skill,
      aliases: ['kubernetes', 'k8s'],
      shortLabel: 'K8S',
      fallbackIcon: Icons.cloud_circle_rounded,
      assetPath: 'assets/skills/icons/kubernetes.svg',
    ),
    AppSkillDefinition(
      id: 'firebase',
      label: 'Firebase',
      category: 'backend',
      kind: AppSkillKind.skill,
      aliases: [],
      shortLabel: 'FB',
      fallbackIcon: Icons.local_fire_department_rounded,
      assetPath: 'assets/skills/icons/firebase.svg',
    ),
    AppSkillDefinition(
      id: 'supabase',
      label: 'Supabase',
      category: 'backend',
      kind: AppSkillKind.skill,
      aliases: [],
      shortLabel: 'SB',
      fallbackIcon: Icons.cloud_done_rounded,
    ),
    AppSkillDefinition(
      id: 'figma',
      label: 'Figma',
      category: 'design',
      kind: AppSkillKind.tool,
      aliases: [],
      shortLabel: 'FG',
      fallbackIcon: Icons.draw_rounded,
      assetPath: 'assets/skills/icons/figma.svg',
    ),
    AppSkillDefinition(
      id: 'ui-design',
      label: 'UI设计',
      category: 'design',
      kind: AppSkillKind.skill,
      aliases: ['ui设计', '视觉设计', 'ui design'],
      shortLabel: 'UI',
      fallbackIcon: Icons.palette_outlined,
      onboardingDescription: '适合界面方案、交互细化与视觉统一。',
    ),
    AppSkillDefinition(
      id: 'ui-ux',
      label: 'UI/UX',
      category: 'design',
      kind: AppSkillKind.skill,
      aliases: ['uiux', 'ui ux', 'ui/ux设计', 'uiux设计'],
      shortLabel: 'UX',
      fallbackIcon: Icons.design_services_rounded,
    ),
    AppSkillDefinition(
      id: 'ai-ml',
      label: 'AI/ML',
      category: 'ai',
      kind: AppSkillKind.skill,
      aliases: ['ai', 'ml', 'machine learning', 'artificial intelligence'],
      shortLabel: 'AI',
      fallbackIcon: Icons.auto_awesome_rounded,
      onboardingDescription: '适合 AI 功能接入、模型应用与智能流程。',
    ),
    AppSkillDefinition(
      id: 'backend',
      label: '后端',
      category: 'backend',
      kind: AppSkillKind.skill,
      aliases: ['backend', '后端开发'],
      shortLabel: 'API',
      fallbackIcon: Icons.storage_rounded,
      onboardingDescription: '适合业务接口、数据库设计与服务端治理。',
    ),
    AppSkillDefinition(
      id: 'fullstack',
      label: '全栈',
      category: 'fullstack',
      kind: AppSkillKind.skill,
      aliases: ['full stack', 'fullstack', '全栈开发'],
      shortLabel: 'FS',
      fallbackIcon: Icons.layers_rounded,
      onboardingDescription: '适合从产品原型到完整上线的整体推进。',
    ),
    AppSkillDefinition(
      id: 'git',
      label: 'Git',
      category: 'tool',
      kind: AppSkillKind.tool,
      aliases: [],
      shortLabel: 'Git',
      fallbackIcon: Icons.account_tree_rounded,
      assetPath: 'assets/skills/icons/git.svg',
    ),
    AppSkillDefinition(
      id: 'notion',
      label: 'Notion',
      category: 'tool',
      kind: AppSkillKind.tool,
      aliases: [],
      shortLabel: 'NT',
      fallbackIcon: Icons.notes_rounded,
      assetPath: 'assets/skills/icons/notion.svg',
    ),
    AppSkillDefinition(
      id: 'cursor',
      label: 'Cursor',
      category: 'tool',
      kind: AppSkillKind.tool,
      aliases: [],
      shortLabel: 'CS',
      fallbackIcon: Icons.ads_click_rounded,
      assetPath: 'assets/skills/icons/cursor.svg',
    ),
    AppSkillDefinition(
      id: 'vscode',
      label: 'VS Code',
      category: 'tool',
      kind: AppSkillKind.tool,
      aliases: ['visual studio code', 'vscode', 'vs code'],
      shortLabel: 'VS',
      fallbackIcon: Icons.code_rounded,
      assetPath: 'assets/skills/icons/vscode.svg',
    ),
    AppSkillDefinition(
      id: 'jira',
      label: 'Jira',
      category: 'tool',
      kind: AppSkillKind.tool,
      aliases: [],
      shortLabel: 'JR',
      fallbackIcon: Icons.view_kanban_outlined,
      assetPath: 'assets/skills/icons/jira.svg',
    ),
  ];

  static final Map<String, AppSkillDefinition> _byId = {
    for (final definition in _definitions) definition.id: definition,
  };

  static final Map<String, AppSkillDefinition> _byAlias = _buildAliasIndex();

  static final List<String> _expertOnboardingSkillIds = [
    'flutter',
    'react',
    'vuejs',
    'python',
    'go',
    'rust',
    'ui-design',
    'ai-ml',
    'backend',
    'fullstack',
  ];

  static final List<String> _expertOnboardingToolIds = [
    'git',
    'figma',
    'notion',
    'cursor',
    'vscode',
    'docker',
    'jira',
  ];

  static final List<String> _profilePresetIds = [
    'flutter',
    'react',
    'vuejs',
    'angular',
    'swift',
    'kotlin',
    'go',
    'rust',
    'python',
    'java',
    'nodejs',
    'typescript',
    'postgresql',
    'mongodb',
    'redis',
    'docker',
    'k8s',
    'ai-ml',
    'figma',
    'ui-ux',
  ];

  static List<AppSkillDefinition> get expertOnboardingSkills =>
      _expertOnboardingSkillIds.map(definitionById).toList(growable: false);

  static List<AppSkillDefinition> get expertOnboardingTools =>
      _expertOnboardingToolIds.map(definitionById).toList(growable: false);

  static List<AppSkillDefinition> get profilePresetSkills =>
      _profilePresetIds.map(definitionById).toList(growable: false);

  static AppSkillDefinition definitionById(String id) =>
      _byId[id] ?? resolve(id);

  static AppSkillDefinition resolve(String raw, {String? category}) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return _fallbackDefinition('技能', category: category);
    }
    final normalized = _normalize(trimmed);
    return _byAlias[normalized] ??
        _fallbackDefinition(trimmed, category: category);
  }

  static String canonicalLabelOf(String raw, {String? category}) =>
      resolve(raw, category: category).label;

  static String categoryOf(String raw, {String? fallbackCategory}) =>
      resolve(raw, category: fallbackCategory).category;

  static String shortLabelOf(String raw, {String? category}) =>
      resolve(raw, category: category).shortLabel;

  static Map<String, AppSkillDefinition> _buildAliasIndex() {
    final map = <String, AppSkillDefinition>{};
    for (final definition in _definitions) {
      final values = [definition.id, definition.label, ...definition.aliases];
      for (final value in values) {
        map[_normalize(value)] = definition;
      }
    }
    return map;
  }

  static AppSkillDefinition _fallbackDefinition(
    String raw, {
    String? category,
  }) {
    final label = raw.trim().isEmpty ? '技能' : raw.trim();
    final resolvedCategory = _normalizeCategory(category);
    return AppSkillDefinition(
      id: _normalize(label),
      label: label,
      category: resolvedCategory,
      kind: AppSkillKind.skill,
      aliases: const [],
      shortLabel: _fallbackShortLabel(label),
      fallbackIcon: _fallbackIconFor(category: resolvedCategory, raw: label),
    );
  }

  static String _normalize(String value) {
    final trimmed = value.trim().toLowerCase();
    return trimmed.replaceAll(RegExp(r'[\s\.\-_/+]+'), '');
  }

  static String _normalizeCategory(String? value) {
    final normalized = value?.trim().toLowerCase() ?? '';
    if (normalized.isEmpty) return 'other';
    return normalized;
  }

  static String _fallbackShortLabel(String value) {
    if (value.length <= 4) return value;
    return value.substring(0, 4).toUpperCase();
  }

  static IconData _fallbackIconFor({
    required String category,
    required String raw,
  }) {
    final normalizedRaw = raw.toLowerCase();
    if (normalizedRaw.contains('设计')) return Icons.palette_outlined;
    if (normalizedRaw.contains('后端')) return Icons.storage_rounded;
    if (normalizedRaw.contains('全栈')) return Icons.layers_rounded;
    if (normalizedRaw.contains('ai')) return Icons.auto_awesome_rounded;
    if (normalizedRaw.contains('数据')) return Icons.dataset_rounded;
    switch (category) {
      case 'framework':
      case 'frontend':
        return Icons.web_rounded;
      case 'mobile':
        return Icons.phone_iphone_rounded;
      case 'language':
        return Icons.code_rounded;
      case 'design':
        return Icons.palette_outlined;
      case 'database':
        return Icons.storage_rounded;
      case 'devops':
        return Icons.settings_suggest_rounded;
      case 'backend':
        return Icons.dns_rounded;
      case 'fullstack':
        return Icons.layers_rounded;
      case 'ai':
        return Icons.auto_awesome_rounded;
      case 'tool':
        return Icons.build_rounded;
      default:
        return Icons.bolt_rounded;
    }
  }
}
