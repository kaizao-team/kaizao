import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_chrome.dart';

/// ONBOARD-001: 需求方基础资料编辑
class DemanderProfilePage extends ConsumerStatefulWidget {
  const DemanderProfilePage({super.key});

  @override
  ConsumerState<DemanderProfilePage> createState() =>
      _DemanderProfilePageState();
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
    FocusScope.of(context).unfocus();
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
        borderSide: BorderSide(color: AppColors.onboardingHairline, width: 1),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.onboardingPrimary, width: 1.5),
      ),
      border: const UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.onboardingHairline, width: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);

    return OnboardingScaffold(
      currentStep: 0,
      onBack: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(RoutePaths.roleSelect);
        }
      },
      primaryActionText: '下一步',
      onPrimaryAction: _isValid ? _next : null,
      isPrimaryLoading: state.isLoading,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 36),
          const Text('设置你的昵称', style: AppTextStyles.onboardingTitle),
          const SizedBox(height: 12),
          const Text(
            '让大家认识你，这会是你在开造社区里的专属称呼。',
            style: AppTextStyles.onboardingBody,
          ),
          const SizedBox(height: 48),
          const Text('我的昵称', style: AppTextStyles.onboardingSectionLabel),
          const SizedBox(height: 8),
          TextField(
            controller: _nicknameController,
            maxLength: 16,
            onChanged: (_) => setState(() {}),
            style: AppTextStyles.input,
            decoration: _nicknameDecoration(),
          ),
          const SizedBox(height: 40),
          _AvatarUploadCard(
            avatarUrl: _avatarUrl,
            onTap: () {
              // TODO: 图片上传能力接入后补齐。
            },
          ),
          const SizedBox(height: 16),
          Text(
            '头像和昵称都可以在个人主页里随时修改。',
            style: AppTextStyles.body2.copyWith(
              color: AppColors.onboardingMutedText,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _AvatarUploadCard extends StatelessWidget {
  final String? avatarUrl;
  final VoidCallback onTap;

  const _AvatarUploadCard({
    required this.avatarUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.onboardingSurfaceMuted,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.onboardingHairline.withValues(alpha: 0.65),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.onboardingSurface,
                border: Border.all(
                  color: AppColors.onboardingHairline,
                ),
              ),
              child: avatarUrl == null
                  ? const Icon(
                      Icons.camera_alt_outlined,
                      size: 22,
                      color: AppColors.gray400,
                    )
                  : ClipOval(
                      child: Image.network(
                        avatarUrl!,
                        fit: BoxFit.cover,
                      ),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '上传头像',
                    style: AppTextStyles.h3.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '可选项，先用昵称开始也完全没问题。',
                    style: AppTextStyles.body2.copyWith(
                      color: AppColors.onboardingMutedText,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: AppColors.onboardingPrimary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_rounded,
                size: 18,
                color: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
