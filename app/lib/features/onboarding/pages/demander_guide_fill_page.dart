import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_chrome.dart';

/// ONBOARD-003: 引导需求方填写需求资料和预算
class DemanderGuideFillPage extends ConsumerStatefulWidget {
  const DemanderGuideFillPage({super.key});

  @override
  ConsumerState<DemanderGuideFillPage> createState() =>
      _DemanderGuideFillPageState();
}

class _DemanderGuideFillPageState extends ConsumerState<DemanderGuideFillPage> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  String _selectedCategory = '';
  double _budgetMin = 1000;
  double _budgetMax = 5000;

  final _categories = ['APP开发', '网站开发', '小程序', 'UI设计', '品牌设计', '技术指导'];

  @override
  void initState() {
    super.initState();
    final draft = ref.read(onboardingProvider).draft;
    _titleController.text = draft['project_title'] as String? ?? '';
    _descController.text = draft['project_desc'] as String? ?? '';
    _selectedCategory = draft['category'] as String? ?? '';
    _budgetMin = (draft['budget_min'] as num?)?.toDouble() ?? 1000;
    _budgetMax = (draft['budget_max'] as num?)?.toDouble() ?? 5000;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _titleController.text.trim().isNotEmpty && _selectedCategory.isNotEmpty;

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_isValid) return;

    final notifier = ref.read(onboardingProvider.notifier);
    final success = await notifier.submitData({
      'project_title': _titleController.text.trim(),
      'project_desc': _descController.text.trim(),
      'category': _selectedCategory,
      'budget_min': _budgetMin,
      'budget_max': _budgetMax,
    });
    if (!mounted) return;

    if (success) {
      await notifier.nextStep();
      if (mounted) context.go(RoutePaths.demanderOnboarding4);
    }
  }

  String _formatBudget(double value) {
    final amount = value.toInt().toString();
    final chars = amount.split('').reversed.toList();
    final buffer = StringBuffer();
    for (var i = 0; i < chars.length; i++) {
      if (i > 0 && i % 3 == 0) buffer.write(',');
      buffer.write(chars[i]);
    }
    return buffer.toString().split('').reversed.join();
  }

  InputDecoration _titleDecoration() {
    return InputDecoration(
      hintText: '例如：开发一个高端品牌官网',
      hintStyle: AppTextStyles.inputHint.copyWith(color: AppColors.gray300),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      filled: true,
      fillColor: AppColors.onboardingSurface,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: AppColors.onboardingHairline,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: AppColors.onboardingPrimary,
          width: 1.4,
        ),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: AppColors.onboardingHairline,
        ),
      ),
    );
  }

  InputDecoration _descriptionDecoration() {
    return InputDecoration(
      hintText: '讲清这项功能的目标和预期，设计风格也欢迎补充。',
      hintStyle: AppTextStyles.body2.copyWith(color: AppColors.gray400),
      contentPadding: const EdgeInsets.all(14),
      filled: true,
      fillColor: AppColors.onboardingSurfaceMuted.withValues(alpha: 0.65),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: AppColors.onboardingHairline.withValues(alpha: 0.55),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColors.onboardingPrimary,
          width: 1.2,
        ),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: AppColors.onboardingHairline.withValues(alpha: 0.55),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    final budgetText =
        '¥${_formatBudget(_budgetMin)} - ¥${_formatBudget(_budgetMax)}';

    return OnboardingScaffold(
      currentStep: 2,
      onBack: () async {
        await ref.read(onboardingProvider.notifier).goToStep(1);
        if (context.mounted) {
          context.go(RoutePaths.demanderOnboarding2);
        }
      },
      primaryActionText: '发布需求',
      onPrimaryAction: _isValid ? _submit : null,
      isPrimaryLoading: state.isLoading,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 28),
          const Text('完善你的需求信息', style: AppTextStyles.onboardingTitle),
          const SizedBox(height: 10),
          const Text(
            '让服务方更快理解范围，AI 也会据此帮你整理一版更清晰的需求结构。',
            style: AppTextStyles.onboardingBody,
          ),
          const SizedBox(height: 26),
          const Text('选择分类', style: AppTextStyles.onboardingSectionLabel),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _categories.map((category) {
              return OnboardingChip(
                label: category,
                selected: _selectedCategory == category,
                onTap: () => setState(() => _selectedCategory = category),
              );
            }).toList(),
          ),
          const SizedBox(height: 30),
          const Text('需求标题', style: AppTextStyles.onboardingSectionLabel),
          const SizedBox(height: 10),
          TextField(
            controller: _titleController,
            onChanged: (_) => setState(() {}),
            style: AppTextStyles.input,
            decoration: _titleDecoration(),
          ),
          const SizedBox(height: 28),
          const Text('预算范围', style: AppTextStyles.onboardingSectionLabel),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(budgetText, style: AppTextStyles.onboardingValue),
              const Spacer(),
              Text(
                '更容易匹配合适服务方',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.onboardingMutedText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.onboardingPrimary,
              inactiveTrackColor: AppColors.onboardingHairline,
              trackHeight: 3,
              rangeTrackShape: const RoundedRectRangeSliderTrackShape(),
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
              values: RangeValues(_budgetMin, _budgetMax),
              min: 500,
              max: 50000,
              divisions: 99,
              labels: RangeLabels(
                '¥${_formatBudget(_budgetMin)}',
                '¥${_formatBudget(_budgetMax)}',
              ),
              onChanged: (values) {
                setState(() {
                  _budgetMin = values.start;
                  _budgetMax = values.end;
                });
              },
            ),
          ),
          Row(
            children: [
              Text(
                '¥500',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.onboardingMutedText,
                ),
              ),
              const Spacer(),
              Text(
                '¥50,000',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.onboardingMutedText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const Row(
            children: [
              Text(
                '详细描述（选填）',
                style: AppTextStyles.onboardingSectionLabel,
              ),
              Spacer(),
              OnboardingHelperTag(text: 'AI 已开启智能格式化辅助'),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _descController,
            maxLines: 4,
            style: AppTextStyles.input.copyWith(fontSize: 15),
            decoration: _descriptionDecoration(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
