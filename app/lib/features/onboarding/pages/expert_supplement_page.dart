import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/routes.dart';
import '../../../shared/widgets/vcc_button.dart';
import '../../../shared/widgets/vcc_step_indicator.dart';
import '../providers/onboarding_provider.dart';

/// ONBOARD-006: 引导专家补充评估信息
class ExpertSupplementPage extends ConsumerStatefulWidget {
  const ExpertSupplementPage({super.key});

  @override
  ConsumerState<ExpertSupplementPage> createState() => _ExpertSupplementPageState();
}

class _ExpertSupplementPageState extends ConsumerState<ExpertSupplementPage> {
  final _bioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final draft = ref.read(onboardingProvider).draft;
    _bioController.text = draft['bio'] as String? ?? '';
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final notifier = ref.read(onboardingProvider.notifier);
    await notifier.submitData({'bio': _bioController.text.trim()});
    if (!mounted) return;
    await notifier.nextStep();
    if (mounted) context.go(RoutePaths.expertOnboarding3);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: VccStepIndicator(
                totalSteps: 3,
                currentStep: 1,
                labels: const ['专家资料', '补充信息', '等级评定'],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '补充更多信息',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.black),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '完善更多信息，让需求方更了解你的能力',
                      style: TextStyle(fontSize: 15, color: AppColors.gray500),
                    ),
                    const SizedBox(height: 32),

                    // Portfolio upload placeholder
                    const Text('作品集（最多5张）', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.gray700)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12, runSpacing: 12,
                      children: [
                        _buildUploadPlaceholder(),
                        _buildUploadPlaceholder(),
                        _buildUploadPlaceholder(),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Bio
                    const Text('个人简介', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.gray700)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _bioController,
                      maxLines: 5,
                      maxLength: 200,
                      style: const TextStyle(fontSize: 16, color: AppColors.black),
                      decoration: InputDecoration(
                        hintText: '介绍你的经验、擅长领域和过往项目...',
                        filled: true,
                        fillColor: AppColors.gray50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.gray200)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.gray200)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.black, width: 1.5)),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: VccButton(text: '提交', onPressed: _submit),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: VccButton(
                text: '跳过',
                type: VccButtonType.ghost,
                onPressed: () async {
                  await ref.read(onboardingProvider.notifier).nextStep();
                  if (!context.mounted) return;
                  context.go(RoutePaths.expertOnboarding3);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadPlaceholder() {
    return GestureDetector(
      onTap: () {
        // TODO: 图片上传
      },
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.gray50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gray200, style: BorderStyle.solid),
        ),
        child: const Icon(Icons.add_photo_alternate_outlined, size: 28, color: AppColors.gray400),
      ),
    );
  }
}
