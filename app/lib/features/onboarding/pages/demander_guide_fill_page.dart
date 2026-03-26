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

class _DemanderGuideFillPageState extends ConsumerState<DemanderGuideFillPage>
    with SingleTickerProviderStateMixin {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  String _selectedCategory = '';
  double _budgetMin = 1000;
  double _budgetMax = 5000;

  final _categories = const ['APP开发', '网站开发', '小程序', 'UI设计', '品牌设计', '技术指导'];
  final _categoryDescriptions = const {
    'APP开发': '适合移动端产品、会员体系和完整功能交付。',
    '网站开发': '适合官网、品牌页、活动页这类对外展示项目。',
    '小程序': '适合微信场景里的轻服务、轻交互和快速验证。',
    'UI设计': '适合把界面体验、交互节奏和视觉统一梳顺。',
    '品牌设计': '适合把品牌气质、包装物料和视觉基调定下来。',
    '技术指导': '适合先拆方案、定路线，再啃关键难点。',
  };

  @override
  void initState() {
    super.initState();
    final draft = ref.read(onboardingProvider).draft;
    _titleController.text = draft['project_title'] as String? ?? '';
    _descController.text = draft['project_desc'] as String? ?? '';
    _selectedCategory = draft['category'] as String? ?? '';
    _budgetMin = (draft['budget_min'] as num?)?.toDouble() ?? 1000;
    _budgetMax = (draft['budget_max'] as num?)?.toDouble() ?? 5000;
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
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
      hintText: '例如：为高端家居品牌制作一套官网',
      hintStyle: AppTextStyles.inputHint.copyWith(color: AppColors.gray300),
      contentPadding: const EdgeInsets.only(bottom: 14),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.onboardingHairline),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(
          color: AppColors.onboardingPrimary,
          width: 1.4,
        ),
      ),
      border: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.onboardingHairline),
      ),
    );
  }

  InputDecoration _descriptionDecoration() {
    return InputDecoration(
      hintText: '讲清目标、风格、参考案例或必须实现的功能。',
      hintStyle: AppTextStyles.body2.copyWith(color: AppColors.gray400),
      contentPadding: const EdgeInsets.all(14),
      filled: true,
      fillColor: AppColors.onboardingSurfaceMuted.withValues(alpha: 0.68),
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

  Widget _stagger({
    required Widget child,
    required double start,
    required double end,
    double beginY = 16,
  }) {
    return AnimatedBuilder(
      animation: _controller,
      child: child,
      builder: (context, child) {
        final reduceMotion = onboardingReduceMotionOf(context);
        if (reduceMotion) return child!;

        final animation = CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: AppCurves.standard),
        );
        final value = animation.value;

        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * beginY),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    final title = _titleController.text.trim();
    final hasTitle = title.isNotEmpty;
    final budgetText =
        '¥${_formatBudget(_budgetMin)} - ¥${_formatBudget(_budgetMax)}';
    final categoryHint = _selectedCategory.isEmpty
        ? '先点亮一个方向，后面的匹配才有抓手。'
        : _categoryDescriptions[_selectedCategory]!;
    final briefStatusText =
        _selectedCategory.isEmpty ? '等待起笔' : (hasTitle ? '匹配准备中' : '方向已点亮');
    final titleHelperText =
        hasTitle ? '很好，这一行已经让人知道你要做什么了。' : '先抛出一句干净有力的话，让项目先站住。';
    final footnoteText = _isValid
        ? '骨架已经立住了，再补两句语境，系统会更快把你推到合适的人面前。'
        : '先把方向和预算定住，这一页 brief 就会自己长起来。';

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
          const SizedBox(height: 30),
          const Text('把想法推成一页 Brief', style: AppTextStyles.onboardingTitle),
          const SizedBox(height: 10),
          const Text(
            '不用一次写满。先把方向、预算和语境推出来，系统就能开始替你匹配。',
            style: AppTextStyles.onboardingBody,
          ),
          const SizedBox(height: 24),
          OnboardingDeckCard(
            elevated: true,
            animateOnAppear: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _stagger(
                  start: 0,
                  end: 0.24,
                  beginY: 10,
                  child: Row(
                    children: [
                      Text(
                        'PROJECT BRIEF',
                        style: AppTextStyles.onboardingMeta.copyWith(
                          color: AppColors.onboardingPrimary,
                        ),
                      ),
                      const Spacer(),
                      OnboardingStatusBadge(
                        text: briefStatusText,
                        animate: hasTitle || _selectedCategory.isNotEmpty,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _stagger(
                  start: 0.08,
                  end: 0.34,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _titleController,
                        onChanged: (_) => setState(() {}),
                        style: AppTextStyles.h1.copyWith(fontSize: 32),
                        decoration: _titleDecoration(),
                      ),
                      const SizedBox(height: 10),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: Text(
                          titleHelperText,
                          key: ValueKey(titleHelperText),
                          style: AppTextStyles.body2.copyWith(
                            color: AppColors.onboardingMutedText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Divider(
                  color: AppColors.onboardingHairline.withValues(alpha: 0.8),
                ),
                const SizedBox(height: 18),
                _stagger(
                  start: 0.18,
                  end: 0.48,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _ComposerSectionLabel(
                        index: '01',
                        title: '项目方向',
                        hint: '先把赛道点亮，后面才会越填越快',
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _categories.map((category) {
                          return OnboardingChip(
                            label: category,
                            selected: _selectedCategory == category,
                            onTap: () =>
                                setState(() => _selectedCategory = category),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: Text(
                          categoryHint,
                          key: ValueKey(categoryHint),
                          style: AppTextStyles.body2.copyWith(
                            color: AppColors.onboardingMutedText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Divider(
                  color: AppColors.onboardingHairline.withValues(alpha: 0.8),
                ),
                const SizedBox(height: 18),
                _stagger(
                  start: 0.32,
                  end: 0.64,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _ComposerSectionLabel(
                        index: '02',
                        title: '预算范围',
                        hint: '给匹配一个清晰区间',
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            budgetText,
                            maxLines: 1,
                            softWrap: false,
                            style: AppTextStyles.h1.copyWith(
                              fontSize: 36,
                              letterSpacing: -1.1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '系统会先按这个预算段为你收拢合适的人',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.onboardingMutedText,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppColors.onboardingPrimary,
                          inactiveTrackColor: AppColors.onboardingHairline,
                          trackHeight: 3,
                          rangeTrackShape:
                              const RoundedRectRangeSliderTrackShape(),
                          thumbColor: AppColors.onboardingSurface,
                          overlappingShapeStrokeColor:
                              AppColors.onboardingPrimary,
                          rangeThumbShape: const RoundRangeSliderThumbShape(
                            enabledThumbRadius: 8,
                            pressedElevation: 0,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 16,
                          ),
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
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Divider(
                  color: AppColors.onboardingHairline.withValues(alpha: 0.8),
                ),
                const SizedBox(height: 18),
                _stagger(
                  start: 0.46,
                  end: 0.84,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _ComposerSectionLabel(
                        index: '03',
                        title: '项目语境',
                        hint: '目标、气质、参考案例，慢慢补进来',
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _descController,
                        maxLines: 5,
                        style: AppTextStyles.input.copyWith(fontSize: 15),
                        decoration: _descriptionDecoration(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Text(
              footnoteText,
              key: ValueKey(footnoteText),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.onboardingMutedText,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ComposerSectionLabel extends StatelessWidget {
  final String index;
  final String title;
  final String hint;

  const _ComposerSectionLabel({
    required this.index,
    required this.title,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          index,
          style: AppTextStyles.onboardingMeta.copyWith(
            color: AppColors.gray400,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.onboardingSectionLabel.copyWith(
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                hint,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.onboardingMutedText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
