import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../shared/widgets/vcc_button.dart';
import '../../../shared/widgets/vcc_input.dart';
import '../../../shared/widgets/vcc_toast.dart';
import '../../onboarding/providers/onboarding_provider.dart';
import '../providers/auth_provider.dart';

enum _AuthMode { password, phone }

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with TickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();

  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _codeFocus = FocusNode();

  late final AnimationController _heroController;
  late final Animation<double> _heroScale;
  late final Animation<double> _heroLift;

  Timer? _countdownTimer;
  int _countdown = 0;
  bool _obscurePassword = true;
  bool _agreedToTerms = false;
  bool _phoneValid = false;
  bool _isSendingCode = false;
  _AuthMode _mode = _AuthMode.password;

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
    _usernameController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _codeController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
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

  void _showToast(
    String message, {
    VccToastType type = VccToastType.info,
  }) {
    VccToast.show(context, message: message, type: type);
  }

  void _switchMode(_AuthMode mode) {
    if (_mode == mode) return;
    FocusScope.of(context).unfocus();
    setState(() => _mode = mode);
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

    if (_mode == _AuthMode.password) {
      _showToast('账号密码登录暂未开放', type: VccToastType.info);
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

  Future<void> _restartOnboardingFlow() async {
    await ref.read(authStateProvider.notifier).resetForFreshStart();
    await ref.read(onboardingProvider.notifier).reset();
    if (!mounted) return;
    context.go(RoutePaths.onboarding);
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
                    child: CustomScrollView(
                      slivers: [
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: AppSpacing.sm),
                              _LoginMetaBar(
                                onHelpTap: () => _showToast(
                                  '帮助中心即将开放',
                                  type: VccToastType.info,
                                ),
                              ),
                              const Spacer(flex: 2),
                              _LoginHero(
                                compact: compact,
                                scale: _heroScale,
                                lift: _heroLift,
                                mode: _mode,
                              ),
                              const Spacer(flex: 2),
                              _ModeTabs(
                                mode: _mode,
                                onModeChanged: _switchMode,
                              ),
                              SizedBox(
                                height:
                                    compact ? AppSpacing.md : AppSpacing.base,
                              ),
                              AnimatedSwitcher(
                                duration: AppDurations.normal,
                                switchInCurve: AppCurves.standard,
                                switchOutCurve: AppCurves.standard,
                                transitionBuilder: (child, animation) {
                                  final slide = Tween<Offset>(
                                    begin: const Offset(0.02, 0),
                                    end: Offset.zero,
                                  ).animate(animation);
                                  return FadeTransition(
                                    opacity: animation,
                                    child: SlideTransition(
                                      position: slide,
                                      child: child,
                                    ),
                                  );
                                },
                                child: _mode == _AuthMode.password
                                    ? _PasswordPanel(
                                        key: const ValueKey('password-panel'),
                                        usernameController: _usernameController,
                                        passwordController: _passwordController,
                                        usernameFocus: _usernameFocus,
                                        passwordFocus: _passwordFocus,
                                        obscurePassword: _obscurePassword,
                                        onPasswordToggle: () {
                                          setState(
                                            () => _obscurePassword =
                                                !_obscurePassword,
                                          );
                                        },
                                        compact: compact,
                                      )
                                    : _PhonePanel(
                                        key: const ValueKey('phone-panel'),
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
                              ),
                              if (_mode == _AuthMode.phone &&
                                  authState.errorMessage != null) ...[
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  authState.errorMessage!,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.error,
                                  ),
                                ),
                              ],
                              const Spacer(flex: 3),
                              VccButton(
                                text: _mode == _AuthMode.password
                                    ? '登录'
                                    : '登录 / 注册',
                                onPressed: _submit,
                                isLoading: isSubmitting,
                              ),
                              const SizedBox(height: AppSpacing.base),
                              _AgreementRow(
                                isChecked: _agreedToTerms,
                                onToggle: () {
                                  setState(
                                    () => _agreedToTerms = !_agreedToTerms,
                                  );
                                },
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              _LoginFooter(
                                onRegisterTap: _restartOnboardingFlow,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                            ],
                          ),
                        ),
                      ],
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

class _LoginMetaBar extends StatelessWidget {
  final VoidCallback onHelpTap;

  const _LoginMetaBar({required this.onHelpTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text.rich(
            TextSpan(
              style: AppTextStyles.overline.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 1.6,
                color: AppColors.gray400,
              ),
              children: [
                const TextSpan(text: 'KAIZAO'),
                const TextSpan(text: '  /  '),
                TextSpan(
                  text: 'AUTHENTICATION',
                  style: AppTextStyles.overline.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                    color: AppColors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
        TextButton(
          onPressed: onHelpTap,
          style: TextButton.styleFrom(
            minimumSize: Size.zero,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.xs,
            ),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'HELP',
            style: AppTextStyles.overline.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 1.6,
              color: AppColors.black,
            ),
          ),
        ),
      ],
    );
  }
}

class _LoginHero extends StatelessWidget {
  final bool compact;
  final Animation<double> scale;
  final Animation<double> lift;
  final _AuthMode mode;

  const _LoginHero({
    required this.compact,
    required this.scale,
    required this.lift,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    final logoSize = compact ? 140.0 : 160.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: Listenable.merge([scale, lift]),
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, lift.value),
              child: Transform.scale(scale: scale.value, child: child),
            );
          },
          child: Image.asset(
            'assets/branding/app_launch_static_transparent_cropped.png',
            width: logoSize,
            height: logoSize,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          'VCC',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: compact ? 20 : 22,
            fontWeight: FontWeight.w700,
            color: AppColors.black,
            letterSpacing: 5,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          '开造',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: compact ? 13 : 14,
            fontWeight: FontWeight.w500,
            color: AppColors.gray500,
            letterSpacing: 2,
          ),
        ),
        SizedBox(height: compact ? AppSpacing.lg : AppSpacing.xl),
        Text(
          '欢迎回来',
          textAlign: TextAlign.center,
          style: AppTextStyles.h1.copyWith(height: 1.1),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          mode == _AuthMode.phone ? '输入手机号，把想法推进到开造流程。' : '登录你的账号，继续开造之旅。',
          textAlign: TextAlign.center,
          style: AppTextStyles.body2.copyWith(color: AppColors.gray400),
        ),
      ],
    );
  }
}

class _ModeTabs extends StatelessWidget {
  final _AuthMode mode;
  final ValueChanged<_AuthMode> onModeChanged;

  const _ModeTabs({
    required this.mode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ModeTabButton(
            label: '账号密码登录',
            isActive: mode == _AuthMode.password,
            onTap: () => onModeChanged(_AuthMode.password),
          ),
        ),
        const SizedBox(width: AppSpacing.xl),
        Expanded(
          child: _ModeTabButton(
            label: '手机号登录',
            isActive: mode == _AuthMode.phone,
            onTap: () => onModeChanged(_AuthMode.phone),
          ),
        ),
      ],
    );
  }
}

class _ModeTabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ModeTabButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppDurations.normal,
        alignment: Alignment.center,
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? AppColors.black : Colors.transparent,
              width: 1.6,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? AppColors.black : AppColors.gray400,
          ),
        ),
      ),
    );
  }
}

class _PasswordPanel extends StatelessWidget {
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final FocusNode usernameFocus;
  final FocusNode passwordFocus;
  final bool obscurePassword;
  final VoidCallback onPasswordToggle;
  final bool compact;

  const _PasswordPanel({
    super.key,
    required this.usernameController,
    required this.passwordController,
    required this.usernameFocus,
    required this.passwordFocus,
    required this.obscurePassword,
    required this.onPasswordToggle,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FieldShell(
          label: '账号',
          child: VccInput(
            hint: '用户名或邮箱',
            controller: usernameController,
            focusNode: usernameFocus,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => passwordFocus.requestFocus(),
          ),
        ),
        SizedBox(height: compact ? AppSpacing.md : AppSpacing.base),
        _FieldShell(
          label: '密码',
          child: VccInput(
            hint: '••••••••',
            controller: passwordController,
            focusNode: passwordFocus,
            obscureText: obscurePassword,
            textInputAction: TextInputAction.done,
            suffixIcon: GestureDetector(
              onTap: onPasswordToggle,
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(
                  Icons.remove_red_eye_outlined,
                  size: 18,
                  color: AppColors.gray500,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PhonePanel extends StatelessWidget {
  final TextEditingController phoneController;
  final TextEditingController codeController;
  final FocusNode phoneFocus;
  final FocusNode codeFocus;
  final int countdown;
  final bool isPhoneValid;
  final bool isSendingCode;
  final VoidCallback onSendCode;
  final bool compact;

  const _PhonePanel({
    super.key,
    required this.phoneController,
    required this.codeController,
    required this.phoneFocus,
    required this.codeFocus,
    required this.countdown,
    required this.isPhoneValid,
    required this.isSendingCode,
    required this.onSendCode,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FieldShell(
          label: '手机号',
          child: VccInput(
            hint: '请输入手机号',
            controller: phoneController,
            focusNode: phoneFocus,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(11),
            ],
            prefixIcon: const Padding(
              padding: EdgeInsets.only(left: 16, right: 8),
              child: Center(
                widthFactor: 1,
                child: Text(
                  '+86',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray500,
                  ),
                ),
              ),
            ),
            onSubmitted: (_) => codeFocus.requestFocus(),
          ),
        ),
        SizedBox(height: compact ? AppSpacing.md : AppSpacing.base),
        _FieldShell(
          label: '验证码',
          child: VccInput(
            hint: '请输入短信验证码',
            controller: codeController,
            focusNode: codeFocus,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            suffixIcon: TextButton(
              onPressed: isPhoneValid && countdown == 0 && !isSendingCode
                  ? onSendCode
                  : null,
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                isSendingCode
                    ? '发送中...'
                    : countdown > 0
                        ? '${countdown}s'
                        : '获取验证码',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isPhoneValid && countdown == 0 && !isSendingCode
                      ? AppColors.black
                      : AppColors.gray400,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FieldShell extends StatelessWidget {
  final String label;
  final Widget child;

  const _FieldShell({
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: AppSpacing.xs),
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.gray500,
            ),
          ),
        ),
        Theme(
          data: theme.copyWith(
            inputDecorationTheme: theme.inputDecorationTheme.copyWith(
              fillColor: AppColors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base,
                vertical: AppSpacing.base,
              ),
              hintStyle: AppTextStyles.inputHint.copyWith(
                color: AppColors.gray300,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(
                  color: AppColors.gray200,
                  width: 1.2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(
                  color: AppColors.black,
                  width: 1.4,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(
                  color: AppColors.gray200,
                  width: 1.2,
                ),
              ),
            ),
          ),
          child: child,
        ),
      ],
    );
  }
}

class _AgreementRow extends StatelessWidget {
  final bool isChecked;
  final VoidCallback onToggle;

  const _AgreementRow({
    required this.isChecked,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              color: isChecked ? AppColors.black : AppColors.white,
              borderRadius: BorderRadius.circular(AppRadius.xs),
              border: Border.all(
                color: isChecked ? AppColors.black : AppColors.gray300,
              ),
            ),
            child: isChecked
                ? const Icon(Icons.check, size: 12, color: AppColors.white)
                : null,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: AppTextStyles.caption.copyWith(color: AppColors.gray500),
                children: [
                  const TextSpan(text: '登录即代表同意 '),
                  TextSpan(
                    text: '《用户协议》',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const TextSpan(text: ' 与 '),
                  TextSpan(
                    text: '《隐私政策》',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginFooter extends StatelessWidget {
  final VoidCallback onRegisterTap;

  const _LoginFooter({required this.onRegisterTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '第一次使用开造？',
          style: AppTextStyles.body2.copyWith(color: AppColors.gray500),
        ),
        TextButton(
          onPressed: onRegisterTap,
          style: TextButton.styleFrom(
            minimumSize: Size.zero,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            '新用户注册',
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
