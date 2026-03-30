import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../shared/widgets/vcc_button.dart';
import '../../../shared/widgets/vcc_toast.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_form_sections.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage>
    with TickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _phoneFocus = FocusNode();
  final _codeFocus = FocusNode();

  late final AnimationController _heroController;
  late final Animation<double> _heroScale;
  late final Animation<double> _heroLift;

  Timer? _countdownTimer;
  int _countdown = 0;
  bool _phoneValid = false;
  bool _isSendingCode = false;
  bool _agreedToTerms = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    _phoneController.addListener(_validatePhone);
    _heroController = AnimationController(
      duration: const Duration(milliseconds: 2400),
      vsync: this,
    )..repeat(reverse: true);
    _heroScale = Tween<double>(begin: 0.985, end: 1.02).animate(
      CurvedAnimation(parent: _heroController, curve: AppCurves.easeInOut),
    );
    _heroLift = Tween<double>(begin: 3, end: -5).animate(
      CurvedAnimation(parent: _heroController, curve: AppCurves.easeInOut),
    );
  }

  @override
  void dispose() {
    _phoneController.removeListener(_validatePhone);
    _countdownTimer?.cancel();
    _heroController.dispose();
    _phoneController.dispose();
    _codeController.dispose();
    _phoneFocus.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  void _validatePhone() {
    final value = _phoneController.text.trim();
    final isValid = value.length == 11 && value.startsWith('1');
    if (_phoneValid != isValid && mounted) {
      setState(() => _phoneValid = isValid);
    }
  }

  void _showToast(String message, {VccToastType type = VccToastType.info}) {
    VccToast.show(context, message: message, type: type);
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _countdown = 60);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdown <= 1) {
        timer.cancel();
        setState(() => _countdown = 0);
        return;
      }
      setState(() => _countdown -= 1);
    });
  }

  Future<void> _sendCode() async {
    if (!_phoneValid || _countdown > 0 || _isSendingCode) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _isSendingCode = true);
    final success = await ref
        .read(authStateProvider.notifier)
        .sendSmsCode(_phoneController.text.trim());
    if (!mounted) return;
    setState(() => _isSendingCode = false);
    if (success) {
      _showToast('验证码已发送', type: VccToastType.success);
      _startCountdown();
      _codeFocus.requestFocus();
    }
  }

  Future<void> _submit() async {
    if (!_agreedToTerms) {
      _showToast('请先同意服务协议', type: VccToastType.warning);
      return;
    }
    if (!_phoneValid) {
      _showToast('请输入正确的手机号', type: VccToastType.warning);
      return;
    }
    if (_codeController.text.trim().length != 6) {
      _showToast('请输入 6 位短信验证码', type: VccToastType.warning);
      return;
    }

    final success = await ref.read(authStateProvider.notifier).loginWithPhone(
          _phoneController.text.trim(),
          _codeController.text.trim(),
        );
    if (!success || !mounted) return;

    final authState = ref.read(authStateProvider);
    if (authState.userRole == 0) {
      context.go(RoutePaths.roleSelect);
      return;
    }
    context.go(RoutePaths.home);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isSubmitting = authState.isLoading && !_isSendingCode;
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    final compact = screenHeight < 820 || keyboardInset > 0;

    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 392),
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.only(
                        bottom: keyboardInset > 0 ? AppSpacing.lg : 0,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              height: compact ? AppSpacing.sm : AppSpacing.md,
                            ),
                            const AuthMetaBar(),
                            SizedBox(height: compact ? 32 : 52),
                            AuthBrandHero(
                              compact: compact,
                              scale: _heroScale,
                              lift: _heroLift,
                            ),
                            SizedBox(
                              height: compact ? AppSpacing.xl : AppSpacing.xxxl,
                            ),
                            const Text('新用户注册', style: AppTextStyles.h2),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              '使用手机号验证码完成注册，首次登录后选择你的身份即可开始使用 Kaizo。',
                              style: AppTextStyles.body2.copyWith(
                                color: AppColors.gray500,
                              ),
                            ),
                            SizedBox(
                              height: compact ? AppSpacing.lg : AppSpacing.xl,
                            ),
                            AuthPhonePanel(
                              phoneController: _phoneController,
                              codeController: _codeController,
                              phoneFocus: _phoneFocus,
                              codeFocus: _codeFocus,
                              countdown: _countdown,
                              isPhoneValid: _phoneValid,
                              isSendingCode: _isSendingCode,
                              onSendCode: _sendCode,
                              compact: compact,
                            ),
                            if (authState.errorMessage != null) ...[
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                authState.errorMessage!,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.error,
                                ),
                              ),
                            ],
                            SizedBox(
                              height: keyboardInset > 0
                                  ? AppSpacing.xl
                                  : (compact ? AppSpacing.xxl : 72),
                            ),
                            VccButton(
                              text: '登录 / 注册',
                              onPressed: _submit,
                              isLoading: isSubmitting,
                            ),
                            const SizedBox(height: AppSpacing.base),
                            AuthAgreementRow(
                              isChecked: _agreedToTerms,
                              prefixText: '注册即代表同意',
                              onToggle: () {
                                setState(
                                  () => _agreedToTerms = !_agreedToTerms,
                                );
                              },
                              onUserAgreementTap: () {
                                context.push(RoutePaths.userAgreement);
                              },
                              onPrivacyPolicyTap: () {
                                context.push(RoutePaths.privacyPolicy);
                              },
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _RegisterFooter(
                              onLoginTap: () => context.go(RoutePaths.login),
                            ),
                            SizedBox(
                              height: keyboardInset > 0
                                  ? AppSpacing.xl
                                  : AppSpacing.lg,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RegisterFooter extends StatelessWidget {
  final VoidCallback onLoginTap;

  const _RegisterFooter({required this.onLoginTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '已有账号？',
          style: AppTextStyles.body2.copyWith(color: AppColors.gray500),
        ),
        TextButton(
          onPressed: onLoginTap,
          style: TextButton.styleFrom(
            minimumSize: Size.zero,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            '返回登录',
            style: AppTextStyles.body2.copyWith(
              color: AppColors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
