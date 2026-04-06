import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/auth/auth_session_manager.dart';
import '../../../shared/widgets/vcc_button.dart';
import '../../../shared/widgets/vcc_input.dart';
import '../../../shared/widgets/vcc_toast.dart';
import '../providers/auth_provider.dart';
import '../repositories/auth_repository.dart';
import '../widgets/captcha_field.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with TickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _captchaCodeController = TextEditingController();

  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _captchaFocus = FocusNode();

  late final AnimationController _heroController;
  late final Animation<double> _heroScale;
  late final Animation<double> _heroLift;

  bool _obscurePassword = true;
  bool _agreedToTerms = false;

  CaptchaResult? _captcha;
  bool _isLoadingCaptcha = false;

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
    _showSessionExpiredToast();
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
    _loadCaptcha();
  }

  @override
  void dispose() {
    _heroController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _captchaCodeController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    _captchaFocus.dispose();
    super.dispose();
  }

  void _showSessionExpiredToast() {
    final message = AuthSessionManager().consumePendingMessage();
    if (message != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        VccToast.show(context, message: message);
      });
    }
  }

  void _showToast(
    String message, {
    VccToastType type = VccToastType.info,
  }) {
    VccToast.show(context, message: message, type: type);
  }

  Future<void> _loadCaptcha() async {
    if (_isLoadingCaptcha) return;
    setState(() => _isLoadingCaptcha = true);
    final result =
        await ref.read(authStateProvider.notifier).getCaptcha();
    if (!mounted) return;
    setState(() {
      _captcha = result;
      _isLoadingCaptcha = false;
      _captchaCodeController.clear();
    });
  }

  Future<void> _submit() async {
    if (!_agreedToTerms) {
      _showToast('请先同意服务协议', type: VccToastType.warning);
      return;
    }

    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final captchaCode = _captchaCodeController.text.trim();

    if (username.isEmpty) {
      _showToast('请输入用户名', type: VccToastType.warning);
      return;
    }
    if (password.isEmpty) {
      _showToast('请输入密码', type: VccToastType.warning);
      return;
    }
    if (_captcha == null || _captcha!.captchaId.isEmpty) {
      _showToast('请先获取验证码', type: VccToastType.warning);
      return;
    }
    if (captchaCode.isEmpty) {
      _showToast('请输入图形验证码', type: VccToastType.warning);
      return;
    }

    final success =
        await ref.read(authStateProvider.notifier).loginWithPassword(
              identity: username,
              password: password,
              captchaId: _captcha!.captchaId,
              captchaCode: captchaCode,
            );

    if (!success || !mounted) {
      _loadCaptcha();
      if (mounted) {
        final error = ref.read(authStateProvider).errorMessage;
        if (error != null) _showToast(error, type: VccToastType.error);
      }
      return;
    }

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
    final isSubmitting = authState.isLoading;
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    final compact = screenHeight < 820 || keyboardInset > 0;

    return Scaffold(
      backgroundColor: const Color(0xFFFEFCFD),
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
                              const _LoginMetaBar(),
                              const Spacer(flex: 2),
                              _LoginHero(
                                compact: compact,
                                scale: _heroScale,
                                lift: _heroLift,
                              ),
                              const Spacer(flex: 2),
                              // Align(
                              //   alignment: Alignment.centerLeft,
                              //   child: Padding(
                              //     padding: const EdgeInsets.only(
                              //       bottom: AppSpacing.xs,
                              //     ),
                              //     child: Text(
                              //       '账号密码登录',
                              //       style: AppTextStyles.body1.copyWith(
                              //         fontWeight: FontWeight.w700,
                              //         color: AppColors.black,
                              //       ),
                              //     ),
                              //   ),
                              // ),
                              SizedBox(
                                height:
                                    compact ? AppSpacing.md : AppSpacing.base,
                              ),
                              _PasswordPanel(
                                usernameController: _usernameController,
                                passwordController: _passwordController,
                                captchaCodeController: _captchaCodeController,
                                usernameFocus: _usernameFocus,
                                passwordFocus: _passwordFocus,
                                captchaFocus: _captchaFocus,
                                obscurePassword: _obscurePassword,
                                onPasswordToggle: () {
                                  setState(
                                    () =>
                                        _obscurePassword = !_obscurePassword,
                                  );
                                },
                                compact: compact,
                                captcha: _captcha,
                                isLoadingCaptcha: _isLoadingCaptcha,
                                onRefreshCaptcha: _loadCaptcha,
                              ),
                              SizedBox(
                                height:
                                    compact ? AppSpacing.xl : AppSpacing.xxl,
                              ),
                              if (!compact) const Spacer(flex: 3),
                              VccButton(
                                text: '登录',
                                onPressed: _submit,
                                isLoading: isSubmitting,
                              ),
                              const SizedBox(height: AppSpacing.base),
                              _AgreementRow(
                                isChecked: _agreedToTerms,
                                onUserAgreementTap: () {
                                  context.push(RoutePaths.userAgreement);
                                },
                                onPrivacyPolicyTap: () {
                                  context.push(RoutePaths.privacyPolicy);
                                },
                                onToggle: () {
                                  setState(
                                    () => _agreedToTerms = !_agreedToTerms,
                                  );
                                },
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              _LoginFooter(
                                onRegisterTap: () {
                                  context.push(RoutePaths.register);
                                },
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
  const _LoginMetaBar();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        'KAIZO',
        style: AppTextStyles.overline.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 1.8,
          color: AppColors.black,
        ),
      ),
    );
  }
}

class _LoginHero extends StatelessWidget {
  final bool compact;
  final Animation<double> scale;
  final Animation<double> lift;

  const _LoginHero({
    required this.compact,
    required this.scale,
    required this.lift,
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
            filterQuality: FilterQuality.high,
            isAntiAlias: true,
          ),
        ),
        SizedBox(height: compact ? 6 : 10),
        Text(
          '欢迎来到开造',
          style: AppTextStyles.body1.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.gray500,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
      ],
    );
  }
}

class _PasswordPanel extends StatelessWidget {
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final TextEditingController captchaCodeController;
  final FocusNode usernameFocus;
  final FocusNode passwordFocus;
  final FocusNode captchaFocus;
  final bool obscurePassword;
  final VoidCallback onPasswordToggle;
  final bool compact;
  final CaptchaResult? captcha;
  final bool isLoadingCaptcha;
  final VoidCallback onRefreshCaptcha;

  const _PasswordPanel({
    super.key,
    required this.usernameController,
    required this.passwordController,
    required this.captchaCodeController,
    required this.usernameFocus,
    required this.passwordFocus,
    required this.captchaFocus,
    required this.obscurePassword,
    required this.onPasswordToggle,
    required this.compact,
    required this.captcha,
    required this.isLoadingCaptcha,
    required this.onRefreshCaptcha,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FieldShell(
          label: '用户名',
          child: VccInput(
            hint: '请输入用户名',
            controller: usernameController,
            focusNode: usernameFocus,
            keyboardType: TextInputType.text,
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
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => captchaFocus.requestFocus(),
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
        SizedBox(height: compact ? AppSpacing.md : AppSpacing.base),
        CaptchaField(
          captcha: captcha,
          controller: captchaCodeController,
          focusNode: captchaFocus,
          onRefresh: onRefreshCaptcha,
          isLoading: isLoadingCaptcha,
          compact: compact,
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
  final VoidCallback onUserAgreementTap;
  final VoidCallback onPrivacyPolicyTap;

  const _AgreementRow({
    required this.isChecked,
    required this.onToggle,
    required this.onUserAgreementTap,
    required this.onPrivacyPolicyTap,
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
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '登录即代表同意 ',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.gray500,
                  ),
                ),
                _InlineLegalLink(
                  text: '《用户协议》',
                  onTap: onUserAgreementTap,
                ),
                Text(
                  ' 与 ',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.gray500,
                  ),
                ),
                _InlineLegalLink(
                  text: '《隐私政策》',
                  onTap: onPrivacyPolicyTap,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineLegalLink extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _InlineLegalLink({
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.black,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _LoginFooter extends StatelessWidget {
  final VoidCallback onRegisterTap;

  const _LoginFooter({required this.onRegisterTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '第一次使用 KAIZO？',
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
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}
