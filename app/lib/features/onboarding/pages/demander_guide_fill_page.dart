import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/routes.dart';
import '../../../shared/widgets/vcc_button.dart';
import '../../../shared/widgets/vcc_step_indicator.dart';
import '../../../shared/widgets/vcc_toast.dart';
import '../providers/onboarding_provider.dart';

/// ONBOARD-003: 引导需求方填写需求资料和预算
class DemanderGuideFillPage extends ConsumerStatefulWidget {
  const DemanderGuideFillPage({super.key});

  @override
  ConsumerState<DemanderGuideFillPage> createState() => _DemanderGuideFillPageState();
}

class _DemanderGuideFillPageState extends ConsumerState<DemanderGuideFillPage> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedCategory = '';
  double _budgetMin = 1000;
  double _budgetMax = 5000;

  final _categories = ['APP开发', '网站开发', '小程序', 'UI设计', '数据分析', '技术指导'];

  @override
  void initState() {
    super.initState();
    final draft = ref.read(onboardingProvider).draft;
    _titleController.text = draft['project_title'] as String? ?? '';
    _descController.text = draft['project_desc'] as String? ?? '';
    _selectedCategory = draft['category'] as String? ?? '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  bool get _isValid => _titleController.text.trim().isNotEmpty && _selectedCategory.isNotEmpty;

  Future<void> _submit() async {
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
    } else {
      VccToast.show(context, message: '保存失败，已记录草稿', type: VccToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: VccStepIndicator(
                totalSteps: 4,
                currentStep: 2,
                labels: const ['资料', '创建需求', '填写信息', '完成'],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '描述你的需求',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.black),
                    ),
                    const SizedBox(height: 24),

                    // Category
                    const Text('选择分类', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.gray700)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories.map((cat) {
                        final selected = _selectedCategory == cat;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCategory = cat),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: selected ? AppColors.black : AppColors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: selected ? AppColors.black : AppColors.gray200,
                              ),
                            ),
                            child: Text(
                              cat,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: selected ? AppColors.white : AppColors.gray600,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    const Text('需求标题', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.gray700)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _titleController,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(fontSize: 16, color: AppColors.black),
                      decoration: InputDecoration(
                        hintText: '一句话描述你想要实现的功能',
                        filled: true,
                        fillColor: AppColors.gray50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.gray200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.gray200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.black, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Description
                    const Text('详细描述（可选）', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.gray700)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _descController,
                      maxLines: 4,
                      style: const TextStyle(fontSize: 16, color: AppColors.black),
                      decoration: InputDecoration(
                        hintText: '描述更多细节...',
                        filled: true,
                        fillColor: AppColors.gray50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.gray200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.gray200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.black, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Budget
                    const Text('预算范围', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.gray700)),
                    const SizedBox(height: 4),
                    Text(
                      '¥${_budgetMin.toInt()} - ¥${_budgetMax.toInt()}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.black),
                    ),
                    RangeSlider(
                      values: RangeValues(_budgetMin, _budgetMax),
                      min: 500,
                      max: 50000,
                      divisions: 99,
                      activeColor: AppColors.black,
                      inactiveColor: AppColors.gray200,
                      onChanged: (values) {
                        setState(() {
                          _budgetMin = values.start;
                          _budgetMax = values.end;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: VccButton(
                text: '发布需求',
                onPressed: _isValid ? _submit : null,
                isLoading: state.isLoading,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
