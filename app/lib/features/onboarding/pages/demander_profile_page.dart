import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../shared/widgets/vcc_toast.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/onboarding_chrome.dart';

/// ONBOARD-001: 项目方基础资料编辑
class DemanderProfilePage extends ConsumerStatefulWidget {
  const DemanderProfilePage({super.key});

  @override
  ConsumerState<DemanderProfilePage> createState() =>
      _DemanderProfilePageState();
}

class _DemanderProfilePageState extends ConsumerState<DemanderProfilePage> {
  final _nicknameController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _avatarUrl;
  final _nicknameSuggestions = const [
    'Dylan',
    'KAIZO Studio',
    'Aurora Studio'
  ];

  @override
  void initState() {
    super.initState();
    final draft = ref.read(onboardingProvider).draft;
    _nicknameController.text = draft['nickname'] as String? ?? '';
    _phoneController.text = draft['contact_phone'] as String? ?? '';
    _avatarUrl = draft['avatar_url'] as String?;
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _phoneController.dispose();
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
    final success = await notifier.submitDemanderProfile(
      nickname: _nicknameController.text.trim(),
      avatarUrl: _avatarUrl,
      contactPhone: _phoneController.text.trim(),
    );
    if (!mounted) return;

    if (success) {
      await notifier.nextStep();
      if (mounted) context.go(RoutePaths.demanderOnboarding2);
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
    final nickname = _nicknameController.text.trim();
    final hasNickname = nickname.isNotEmpty;
    final state = ref.watch(onboardingProvider);
    final nicknamePreview = hasNickname ? nickname : '等待命名的项目方';
    final nicknameHelperText = !hasNickname
        ? '先定一个称呼，身份卡就会立起来。'
        : _isValid
            ? '这个名字会一路跟着你的项目出现。'
            : '再收一下，2 到 16 个字符最利落。';

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
          const SizedBox(height: 32),
          const Text('先亮出你的身份', style: AppTextStyles.onboardingTitle),
          const SizedBox(height: 12),
          const Text(
            '给自己一个会被记住的称呼。后面每一个项目、每一次沟通，都会带着它往前走。',
            style: AppTextStyles.onboardingBody,
          ),
          const SizedBox(height: 24),
          _IdentityFocusCard(
            nickname: nicknamePreview,
            avatarUrl: _avatarUrl,
            isNamed: hasNickname,
          ),
          const SizedBox(height: 28),
          Text(
            '你的称呼',
            style: AppTextStyles.onboardingSectionLabel.copyWith(
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _nicknameController,
            maxLength: 16,
            onChanged: (_) => setState(() {}),
            style: AppTextStyles.h2.copyWith(fontSize: 26),
            decoration: _nicknameDecoration(),
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Text(
              nicknameHelperText,
              key: ValueKey(nicknameHelperText),
              style: AppTextStyles.body2.copyWith(
                color: AppColors.onboardingMutedText,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _nicknameSuggestions.map((item) {
              return GestureDetector(
                onTap: () {
                  _nicknameController.text = item;
                  _nicknameController.selection = TextSelection.collapsed(
                    offset: item.length,
                  );
                  setState(() {});
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.onboardingSurface,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(
                      color: AppColors.onboardingHairline,
                    ),
                  ),
                  child: Text(
                    item,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.gray700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),
          Text(
            '联系手机号',
            style: AppTextStyles.onboardingSectionLabel.copyWith(
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            maxLength: 11,
            onChanged: (_) => setState(() {}),
            style: AppTextStyles.h2.copyWith(fontSize: 22),
            decoration: InputDecoration(
              hintText: '请输入手机号',
              hintStyle: AppTextStyles.inputHint
                  .copyWith(color: AppColors.gray300),
              counterText: '',
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
              prefixIcon: const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(
                  Icons.phone_outlined,
                  size: 20,
                  color: AppColors.gray400,
                ),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 28,
                minHeight: 0,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '便于撮合后第一时间联系你，仅对匹配方可见。',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.onboardingMutedText,
            ),
          ),
          const SizedBox(height: 22),
          _AvatarInlinePrompt(
            avatarUrl: _avatarUrl,
            onTap: () {
              // TODO: 图片上传能力接入后补齐。
            },
          ),
          const SizedBox(height: 16),
          Text(
            '先把称呼定下来就能继续，头像随时再补。',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.onboardingMutedText,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _IdentityFocusCard extends StatefulWidget {
  final String nickname;
  final String? avatarUrl;
  final bool isNamed;

  const _IdentityFocusCard({
    required this.nickname,
    required this.avatarUrl,
    required this.isNamed,
  });

  @override
  State<_IdentityFocusCard> createState() => _IdentityFocusCardState();
}

class _IdentityFocusCardState extends State<_IdentityFocusCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _slideIn({
    required Widget child,
    required double beginX,
    required double start,
    required double end,
  }) {
    final animation = CurvedAnimation(
      parent: _controller,
      curve: Interval(start, end, curve: AppCurves.standard),
    );

    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final reduceMotion = onboardingReduceMotionOf(context);
        if (reduceMotion) return child!;

        final value = animation.value;
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset((1 - value) * beginX, 0),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.onboardingSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.onboardingHairline.withValues(alpha: 0.75),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _slideIn(
            beginX: 16,
            start: 0,
            end: 0.38,
            child: Row(
              children: [
                Text(
                  'IDENTITY CARD',
                  style: AppTextStyles.onboardingMeta.copyWith(
                    color: AppColors.onboardingPrimary,
                  ),
                ),
                const Spacer(),
                OnboardingStatusBadge(
                  text: widget.isNamed ? '身份成形中' : '等待命名',
                  animate: widget.isNamed,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _slideIn(
                beginX: -18,
                start: 0.08,
                end: 0.52,
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.onboardingSurfaceMuted,
                    border: Border.all(
                      color: AppColors.onboardingHairline,
                    ),
                  ),
                  child: widget.avatarUrl == null
                      ? const Icon(
                          Icons.person_outline_rounded,
                          size: 28,
                          color: AppColors.gray400,
                        )
                      : ClipOval(
                          child: Image.network(
                            widget.avatarUrl!,
                            fit: BoxFit.cover,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _slideIn(
                      beginX: 20,
                      start: 0.18,
                      end: 0.62,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.08, 0),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: Text(
                          widget.nickname,
                          key: ValueKey(widget.nickname),
                          style: AppTextStyles.h2.copyWith(fontSize: 24),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _slideIn(
                      beginX: 26,
                      start: 0.26,
                      end: 0.72,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: Text(
                          widget.isNamed
                              ? '你的项目会带着这个身份出现，团队第一眼先看到的就是它。'
                              : '先起一个称呼，整张身份卡就会开始成形。',
                          key: ValueKey(widget.isNamed),
                          style: AppTextStyles.body2.copyWith(
                            color: AppColors.onboardingMutedText,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _slideIn(
            beginX: 28,
            start: 0.34,
            end: 0.86,
            child: const Column(
              children: [
                _IdentityTrack(
                  label: '项目卡片会先展示这个身份',
                  widthFactor: 1,
                ),
                SizedBox(height: 8),
                _IdentityTrack(
                  label: '项目详情会继续沿用这个称呼',
                  widthFactor: 0.82,
                ),
                SizedBox(height: 8),
                _IdentityTrack(
                  label: '进入沟通后也会这样称呼你',
                  widthFactor: 0.68,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IdentityTrack extends StatelessWidget {
  final String label;
  final double widthFactor;

  const _IdentityTrack({
    required this.label,
    required this.widthFactor,
  });

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.onboardingSurfaceMuted.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.gray700,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _AvatarInlinePrompt extends StatelessWidget {
  final String? avatarUrl;
  final VoidCallback onTap;

  const _AvatarInlinePrompt({
    required this.avatarUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: AppColors.onboardingHairline.withValues(alpha: 0.9),
            ),
            bottom: BorderSide(
              color: AppColors.onboardingHairline.withValues(alpha: 0.9),
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.onboardingSurfaceMuted,
                border: Border.all(
                  color: AppColors.onboardingHairline,
                ),
              ),
              child: avatarUrl == null
                  ? const Icon(
                      Icons.camera_alt_outlined,
                      size: 20,
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
                    '再补一张头像',
                    style: AppTextStyles.body1.copyWith(
                      color: AppColors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '加上头像，整张身份卡会立刻更有存在感。',
                    style: AppTextStyles.body2.copyWith(
                      color: AppColors.onboardingMutedText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(
              Icons.add_rounded,
              size: 20,
              color: AppColors.black,
            ),
          ],
        ),
      ),
    );
  }
}
