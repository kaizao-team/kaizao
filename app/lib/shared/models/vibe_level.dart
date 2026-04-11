/// VibePower 等级映射
class VibeLevelSpec {
  final String code;
  final String label;
  final int minPower;
  final int maxPower;

  const VibeLevelSpec({
    required this.code,
    required this.label,
    required this.minPower,
    required this.maxPower,
  });
}

const vibeLevelSpecs = <VibeLevelSpec>[
  VibeLevelSpec(code: 'vc-T1', label: '初启', minPower: 0, maxPower: 99),
  VibeLevelSpec(code: 'vc-T2', label: '胜任', minPower: 100, maxPower: 199),
  VibeLevelSpec(code: 'vc-T3', label: '熟练', minPower: 200, maxPower: 349),
  VibeLevelSpec(code: 'vc-T4', label: '出众', minPower: 350, maxPower: 549),
  VibeLevelSpec(code: 'vc-T5', label: '资深', minPower: 550, maxPower: 749),
  VibeLevelSpec(code: 'vc-T6', label: '卓越', minPower: 750, maxPower: 949),
  VibeLevelSpec(code: 'vc-T7', label: '杰出', minPower: 950, maxPower: 1199),
  VibeLevelSpec(code: 'vc-T8', label: '非凡', minPower: 1200, maxPower: 1499),
  VibeLevelSpec(code: 'vc-T9', label: '登峰', minPower: 1500, maxPower: 1899),
  VibeLevelSpec(code: 'vc-T10', label: '传奇', minPower: 1900, maxPower: 99999),
];

/// 根据 vibe_level code 获取中文段位名
String vibeLevelLabel(String? code, {String fallback = '初启'}) {
  if (code == null || code.isEmpty) return fallback;
  for (final spec in vibeLevelSpecs) {
    if (spec.code == code) return spec.label;
  }
  return fallback;
}

/// 根据 VibePower 分数获取等级 code
String vibeLevelFromPower(int power) {
  for (final spec in vibeLevelSpecs) {
    if (power >= spec.minPower && power <= spec.maxPower) {
      return spec.code;
    }
  }
  return 'vc-T1';
}

/// 根据 VibePower 分数直接获取中文段位名
String vibeLevelLabelFromPower(int power) {
  return vibeLevelLabel(vibeLevelFromPower(power));
}
