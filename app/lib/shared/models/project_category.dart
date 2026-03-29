class ProjectCategorySpec {
  final String key;
  final String label;
  final String description;

  const ProjectCategorySpec({
    required this.key,
    required this.label,
    required this.description,
  });
}

const projectCategorySpecs = <ProjectCategorySpec>[
  ProjectCategorySpec(
    key: 'dev',
    label: '研发',
    description: '适合 App、网站、小程序与定制系统开发。',
  ),
  ProjectCategorySpec(
    key: 'visual',
    label: '视觉设计',
    description: '适合 UI、品牌与视觉体验设计。',
  ),
  ProjectCategorySpec(
    key: 'data',
    label: '数据',
    description: '适合数据分析、数据产品与 AI 数据应用。',
  ),
  ProjectCategorySpec(
    key: 'solution',
    label: '解决方案',
    description: '适合咨询、方案梳理、流程设计与技术路线规划。',
  ),
];

String normalizeProjectCategoryKey(String? value) {
  final normalized = value?.trim().toLowerCase() ?? '';
  if (normalized.isEmpty) return '';

  switch (normalized) {
    case 'data':
    case 'dev':
    case 'visual':
    case 'solution':
      return normalized;
    case 'app':
    case 'web':
    case 'miniprogram':
    case 'backend':
      return 'dev';
    case 'design':
      return 'visual';
    case 'consult':
    case 'other':
      return 'solution';
    case 'ai':
      return 'data';
    default:
      return normalized;
  }
}

ProjectCategorySpec? projectCategorySpecOf(String? value) {
  final normalized = normalizeProjectCategoryKey(value);
  if (normalized.isEmpty) return null;

  for (final spec in projectCategorySpecs) {
    if (spec.key == normalized) return spec;
  }
  return null;
}

bool supportsProjectCategory(String? value) {
  return projectCategorySpecOf(value) != null;
}

String projectCategoryLabel(String? value, {String fallback = '其他'}) {
  return projectCategorySpecOf(value)?.label ?? fallback;
}
