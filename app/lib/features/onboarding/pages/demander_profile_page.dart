import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/routes.dart';
import '../../../shared/widgets/vcc_button.dart';
import '../../../shared/widgets/vcc_step_indicator.dart';
import '../../../shared/widgets/vcc_toast.dart';
import '../providers/onboarding_provider.dart';

/// ONBOARD-001: 需求方基础资料编辑
class DemanderProfilePage extends ConsumerStatefulWidget {
  const DemanderProfilePage({super.key});

  @override
  ConsumerState<DemanderProfilePage> createState() => _DemanderProfilePageState();
}

class _DemanderProfilePageState extends ConsumerState<DemanderProfilePage> {
  final _nicknameController = TextEditingController();
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(onboardingProvider).draft;
    _nicknameController.text = draft['nickname'] as String? ?? '';
    _avatarUrl = draft['avatar_url'] as String?;
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  bool get _isValid {
    final name = _nicknameController.text.trim();
    return name.length >= 2 && name.length <= 16;
  }

  Future<void> _next() async {
    if (!_isValid) return;
    final notifier = ref.read(onboardingProvider.notifier);
    final success = await notifier.submitData({
      'nickname': _nicknameController.text.trim(),
      'avatar_url': _avatarUrl,
    });
    if (!mounted) return;
    if (success) {
      await notifier.nextStep();
      if (mounted) context.go(RoutePaths.demanderOnboarding2);
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
                currentStep: 0,
                labels: const ['资料', '创建需求', '填写信息', '完成'],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    const Text(
                      '设置你的昵称',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.black),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '让大家认识你',
                      style: TextStyle(fontSize: 15, color: AppColors.gray500),
                    ),
                    const SizedBox(height: 32),

                    // Avatar
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          // TODO: 图片选择
                        },
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.gray100,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.gray200),
                          ),
                          child: _avatarUrl != null
                              ? const ClipOval(child: SizedBox())
                              : const Icon(Icons.camera_alt_outlined, size: 28, color: AppColors.gray400),
                        ),
                      ),
                    ),
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text('点击上传头像（可选）', style: TextStyle(fontSize: 12, color: AppColors.gray400)),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Nickname
                    const Text(
                      '昵称',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.gray700),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nicknameController,
                      maxLength: 16,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(fontSize: 16, color: AppColors.black),
                      decoration: InputDecoration(
                        hintText: '2-16个字符',
                        counterText: '${_nicknameController.text.length}/16',
                        counterStyle: const TextStyle(fontSize: 12, color: AppColors.gray400),
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
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: VccButton(
                text: '下一步',
                onPressed: _isValid ? _next : null,
                isLoading: state.isLoading,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
