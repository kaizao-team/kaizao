import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../shared/widgets/vcc_toast.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_chrome.dart';
import '../widgets/expert_onboarding_icons.dart';

const _expertStepLabels = ['资料', '补充', '等级'];

/// ONBOARD-005: 专家资料编辑引导
class ExpertProfilePage extends ConsumerStatefulWidget {
  const ExpertProfilePage({super.key});

  @override
  ConsumerState<ExpertProfilePage> createState() => _ExpertProfilePageState();
}

class _ExpertProfilePageState extends ConsumerState<ExpertProfilePage> {
  final _nicknameController = TextEditingController();
  final Set<String> _selectedSkills = {};
  final Set<String> _selectedTools = {};

  int _selfRating = 3;
  String _availability = '';
  double _rateMin = 200;
  double _rateMax = 800;

  final _skillOptions = const [
    'Flutter',
    'React',
    'Vue.js',
    'Python',
    'Go',
    'Rust',
    'UI设计',
    'AI/ML',
    '后端',
    '全栈',
  ];

  final _toolOptions = const [
    'Git',
    'Figma',
    'Notion',
    'Cursor',
    'VS Code',
    'Docker',
    'Jira',
  ];

  final _availabilityOptions = const ['1周内', '1-2周', '1个月内', '随时'];
  final _skillDescriptions = const {
    'Flutter': '适合移动端产品、跨端应用与交互型工具。',
    'React': '适合 Web 应用、后台系统与复杂前端交互。',
    'Vue.js': '适合官网、中后台和快速交付型项目。',
    'Python': '适合数据处理、自动化、AI 服务与后端逻辑。',
    'Go': '适合高并发 API、服务架构与工程稳定性建设。',
    'Rust': '适合高性能模块、底层工具与安全要求较高的项目。',
    'UI设计': '适合界面方案、交互细化与视觉统一。',
    'AI/ML': '适合 AI 功能接入、模型应用与智能流程。',
    '后端': '适合业务接口、数据库设计与服务端治理。',
    '全栈': '适合从产品原型到完整上线的整体推进。',
  };
  final _ratingTitles = const ['入门执行', '稳定交付', '独立推进', '资深协作', '专家主导'];
  final _ratingDescriptions = const [
    '适合明确需求与标准流程任务，能在协作中快速进入状态。',
    '可以稳定完成常规模块，对节奏和质量有基本把控。',
    '能够独立拆解问题，推进中等复杂度项目并主动沟通风险。',
    '有跨角色协作经验，能处理复杂交付并提供专业建议。',
    '适合承担关键路径设计与主导决策，是项目中的核心推进者。',
  ];

  @override
  void initState() {
    super.initState();
    final draft = ref.read(onboardingProvider).draft;
    _nicknameController.text = draft['nickname'] as String? ?? '';
    if (draft['skills'] is List) {
      _selectedSkills.addAll((draft['skills'] as List).cast<String>());
    }
    if (draft['tools'] is List) {
      _selectedTools.addAll((draft['tools'] as List).cast<String>());
    }
    _selfRating = (draft['self_rating'] as int?) ?? 3;
    _availability = draft['availability'] as String? ?? '';
    _rateMin = (draft['rate_min'] as num?)?.toDouble() ?? 200;
    _rateMax = (draft['rate_max'] as num?)?.toDouble() ?? 800;
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  bool get _isValid {
    final nickname = _nicknameController.text.trim();
    return nickname.length >= 2 &&
        nickname.length <= 16 &&
        _selectedSkills.isNotEmpty &&
        _selectedTools.isNotEmpty;
  }

  Future<void> _next() async {
    FocusScope.of(context).unfocus();
    if (!_isValid) return;

    final notifier = ref.read(onboardingProvider.notifier);
    final success = await notifier.submitExpertProfile(
      nickname: _nicknameController.text.trim(),
      skills: _selectedSkills.toList(),
      tools: _selectedTools.toList(),
      selfRating: _selfRating,
      availability: _availability,
      rateMin: _rateMin,
      rateMax: _rateMax,
    );
    if (!mounted) return;

    if (success) {
      await notifier.nextStep();
      if (mounted) context.go(RoutePaths.expertOnboarding2);
      return;
    }

    final message = ref.read(onboardingProvider).errorMessage;
    if (message != null) {
      VccToast.show(context, message: message, type: VccToastType.error);
    }
  }

  InputDecoration _nicknameDecoration() {
    return InputDecoration(
      hintText: '2-16个字符',
      hintStyle: AppTextStyles.inputHint.copyWith(color: AppColors.gray300),
      counterText: '${_nicknameController.text.length}/16',
      counterStyle: AppTextStyles.caption.copyWith(
        color: AppColors.onboardingMutedText,
      ),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(
          color: AppColors.onboardingHairline,
          width: 1,
        ),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(
          color: AppColors.onboardingPrimary,
          width: 1.5,
        ),
      ),
      border: const UnderlineInputBorder(
        borderSide: BorderSide(
          color: AppColors.onboardingHairline,
          width: 1,
        ),
      ),
    );
  }

  String _formatRate(double value) {
    final amount = value.toInt().toString();
    final chars = amount.split('').reversed.toList();
    final buffer = StringBuffer();
    for (var i = 0; i < chars.length; i++) {
      if (i > 0 && i % 3 == 0) buffer.write(',');
      buffer.write(chars[i]);
    }
    return buffer.toString().split('').reversed.join();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    final nickname = _nicknameController.text.trim().isEmpty
        ? '你的专家称呼'
        : _nicknameController.text.trim();

    return OnboardingScaffold(
      currentStep: 0,
      stepLabels: _expertStepLabels,
      onBack: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(RoutePaths.roleSelect);
        }
      },
      primaryActionText: '继续完善',
      onPrimaryAction: _isValid ? _next : null,
      isPrimaryLoading: state.isLoading,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 36),
          const Text('建立你的专家档案', style: AppTextStyles.onboardingTitle),
          const SizedBox(height: 12),
          const Text(
            '告诉平台你擅长什么、习惯怎样合作。需求方会更快判断你是否适合这个项目。',
            style: AppTextStyles.onboardingBody,
          ),
          const SizedBox(height: 28),
          _ExpertProfilePreviewCard(
            nickname: nickname,
            skills: _selectedSkills.toList(),
            tools: _selectedTools.toList(),
            availability: _availability,
            rateText:
                '¥${_formatRate(_rateMin)} - ¥${_formatRate(_rateMax)} / 天',
          ),
          const SizedBox(height: 18),
          const OnboardingSectionHeader(
            title: '这是一份动态专家档案',
            description: '你每选择一项能力，平台就会更准确地理解你适合解决什么问题。',
            accessory: OnboardingHelperTag(text: '平台会据此生成初始专家画像'),
          ),
          const SizedBox(height: 32),
          const OnboardingSectionHeader(
            title: '你的称呼',
            description: '需求方会在推荐卡片和对话页里先看到这个名字。',
          ),
          const SizedBox(height: 8),
          OnboardingDeckCard(
            child: TextField(
              controller: _nicknameController,
              maxLength: 16,
              onChanged: (_) => setState(() {}),
              style: AppTextStyles.h2.copyWith(fontSize: 26),
              decoration: _nicknameDecoration(),
            ),
          ),
          const SizedBox(height: 28),
          const OnboardingSectionHeader(
            title: '选择你的主力方向',
            description: '别全选。先选最能代表你的 2-4 项，档案会更可信。',
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 12.0;
              final itemWidth = (constraints.maxWidth - spacing) / 2;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: _skillOptions.map((skill) {
                  return SizedBox(
                    width: itemWidth,
                    child: OnboardingChoiceCard(
                      title: skill,
                      description: _skillDescriptions[skill]!,
                      selected: _selectedSkills.contains(skill),
                      badge: '能力',
                      icon: onboardingExpertSkillIcon(skill),
                      onTap: () {
                        setState(() {
                          if (_selectedSkills.contains(skill)) {
                            _selectedSkills.remove(skill);
                          } else {
                            _selectedSkills.add(skill);
                          }
                        });
                      },
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 28),
          const OnboardingSectionHeader(
            title: '你常用哪些工具',
            description: '工具偏好会暗示你的工作流和协作方式。',
          ),
          const SizedBox(height: 12),
          OnboardingDeckCard(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _toolOptions.map((tool) {
                return OnboardingChip(
                  label: tool,
                  icon: onboardingExpertToolIcon(tool),
                  selected: _selectedTools.contains(tool),
                  onTap: () {
                    setState(() {
                      if (_selectedTools.contains(tool)) {
                        _selectedTools.remove(tool);
                      } else {
                        _selectedTools.add(tool);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 30),
          const OnboardingSectionHeader(
            title: '经验密度',
            description: '这里不是考试分数，而是平台理解你能承担多大责任的依据。',
          ),
          const SizedBox(height: 12),
          _ExpertRatingSelector(
            rating: _selfRating,
            title: _ratingTitles[_selfRating - 1],
            description: _ratingDescriptions[_selfRating - 1],
            onChanged: (value) => setState(() => _selfRating = value),
          ),
          const SizedBox(height: 30),
          _ExpertWorkModeCard(
            availabilityOptions: _availabilityOptions,
            availability: _availability,
            budgetText:
                '¥${_formatRate(_rateMin)} - ¥${_formatRate(_rateMax)} / 天',
            rateMin: _rateMin,
            rateMax: _rateMax,
            onAvailabilityChanged: (value) {
              setState(() => _availability = value);
            },
            onRateChanged: (values) {
              setState(() {
                _rateMin = values.start;
                _rateMax = values.end;
              });
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ExpertProfilePreviewCard extends StatelessWidget {
  final String nickname;
  final List<String> skills;
  final List<String> tools;
  final String availability;
  final String rateText;

  const _ExpertProfilePreviewCard({
    required this.nickname,
    required this.skills,
    required this.tools,
    required this.availability,
    required this.rateText,
  });

  @override
  Widget build(BuildContext context) {
    final availabilityText =
        availability.isEmpty ? '排期待确认' : '$availability 可启动';

    return OnboardingDeckCard(
      elevated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'EXPERT PROFILE DRAFT',
                style: AppTextStyles.onboardingMeta.copyWith(
                  color: AppColors.onboardingPrimary,
                ),
              ),
              const Spacer(),
              OnboardingStatusBadge(
                text: skills.isEmpty ? '待完善' : '画像生成中',
                animate: skills.isNotEmpty,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            nickname,
            style: AppTextStyles.h2.copyWith(fontSize: 25),
          ),
          const SizedBox(height: 10),
          Text(
            '让需求方在几秒内理解你的方向、技术栈与合作节奏。',
            style: AppTextStyles.body2.copyWith(
              color: AppColors.onboardingMutedText,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: skills.isEmpty
                ? const [
                    OnboardingSkeletonBlock(
                      width: 86,
                      height: 28,
                      radius: 999,
                      color: AppColors.onboardingSurfaceMuted,
                    ),
                    OnboardingSkeletonBlock(
                      width: 72,
                      height: 28,
                      radius: 999,
                      color: AppColors.onboardingSurfaceMuted,
                    ),
                    OnboardingSkeletonBlock(
                      width: 94,
                      height: 28,
                      radius: 999,
                      color: AppColors.onboardingSurfaceMuted,
                    ),
                  ]
                : skills
                    .take(4)
                    .map(
                      (skill) => OnboardingIconTag(
                        label: skill,
                        icon: onboardingExpertSkillIcon(skill),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 16),
          _PreviewToolStrip(tools: tools),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _PreviewMetric(
                  label: '工作方式',
                  value: availabilityText,
                  icon: Icons.schedule_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PreviewMetric(
                  label: '预期日薪',
                  value: rateText,
                  icon: Icons.payments_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreviewToolStrip extends StatelessWidget {
  final List<String> tools;

  const _PreviewToolStrip({
    required this.tools,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TOOLS',
          style: AppTextStyles.onboardingMeta.copyWith(
            color: AppColors.gray400,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tools.isEmpty
              ? const [
                  OnboardingSkeletonBlock(
                    width: 82,
                    height: 28,
                    radius: 999,
                    color: AppColors.onboardingSurfaceMuted,
                  ),
                  OnboardingSkeletonBlock(
                    width: 94,
                    height: 28,
                    radius: 999,
                    color: AppColors.onboardingSurfaceMuted,
                  ),
                ]
              : tools
                  .take(4)
                  .map(
                    (tool) => OnboardingIconTag(
                      label: tool,
                      icon: onboardingExpertToolIcon(tool),
                      compact: true,
                    ),
                  )
                  .toList(),
        ),
      ],
    );
  }
}

class _PreviewMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;

  const _PreviewMetric({
    required this.label,
    required this.value,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.onboardingSurfaceMuted.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14,
                  color: AppColors.gray400,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: AppTextStyles.onboardingMeta.copyWith(
                  color: AppColors.gray400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.body2.copyWith(
              color: AppColors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpertRatingSelector extends StatelessWidget {
  final int rating;
  final String title;
  final String description;
  final ValueChanged<int> onChanged;

  const _ExpertRatingSelector({
    required this.rating,
    required this.title,
    required this.description,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return OnboardingDeckCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(5, (index) {
              final value = index + 1;
              final isFilled = value <= rating;
              final isCurrent = value == rating;

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index == 4 ? 0 : 8),
                  child: GestureDetector(
                    onTap: () => onChanged(value),
                    child: AnimatedContainer(
                      duration: AppDurations.normal,
                      curve: AppCurves.standard,
                      height: 54,
                      decoration: BoxDecoration(
                        color: isFilled
                            ? (isCurrent
                                ? AppColors.onboardingPrimary
                                : AppColors.black.withValues(alpha: 0.74))
                            : AppColors.onboardingSurfaceMuted,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isCurrent
                              ? AppColors.onboardingPrimary
                              : AppColors.onboardingHairline,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '0$value',
                          style: AppTextStyles.onboardingMeta.copyWith(
                            color:
                                isFilled ? AppColors.white : AppColors.gray500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: AppTextStyles.h3.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: AppTextStyles.body2.copyWith(
              color: AppColors.onboardingMutedText,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpertWorkModeCard extends StatelessWidget {
  final List<String> availabilityOptions;
  final String availability;
  final String budgetText;
  final double rateMin;
  final double rateMax;
  final ValueChanged<String> onAvailabilityChanged;
  final ValueChanged<RangeValues> onRateChanged;

  const _ExpertWorkModeCard({
    required this.availabilityOptions,
    required this.availability,
    required this.budgetText,
    required this.rateMin,
    required this.rateMax,
    required this.onAvailabilityChanged,
    required this.onRateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return OnboardingDeckCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OnboardingSectionHeader(
            title: '工作方式',
            accessory: Text(
              availability.isEmpty ? '排期未选择' : availability,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.onboardingMutedText,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: availabilityOptions.map((item) {
              return OnboardingChip(
                label: item,
                selected: availability == item,
                onTap: () => onAvailabilityChanged(item),
              );
            }).toList(),
          ),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 360) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(budgetText, style: AppTextStyles.onboardingValue),
                    const SizedBox(height: 10),
                    const OnboardingHelperTag(
                      text: '后续可按项目单独报价',
                      icon: Icons.tune_rounded,
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      budgetText,
                      style: AppTextStyles.onboardingValue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Flexible(
                    child: OnboardingHelperTag(
                      text: '后续可按项目单独报价',
                      icon: Icons.tune_rounded,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.onboardingPrimary,
              inactiveTrackColor: AppColors.onboardingHairline,
              trackHeight: 3,
              thumbColor: AppColors.onboardingSurface,
              overlappingShapeStrokeColor: AppColors.onboardingPrimary,
              rangeThumbShape: const RoundRangeSliderThumbShape(
                enabledThumbRadius: 8,
                pressedElevation: 0,
              ),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              activeTickMarkColor: Colors.transparent,
              inactiveTickMarkColor: Colors.transparent,
            ),
            child: RangeSlider(
              values: RangeValues(rateMin, rateMax),
              min: 100,
              max: 5000,
              divisions: 49,
              labels: RangeLabels(
                '¥${rateMin.toInt()}',
                '¥${rateMax.toInt()}',
              ),
              onChanged: onRateChanged,
            ),
          ),
          Row(
            children: [
              Text(
                '¥100',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.onboardingMutedText,
                ),
              ),
              const Spacer(),
              Text(
                '¥5,000',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.onboardingMutedText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
