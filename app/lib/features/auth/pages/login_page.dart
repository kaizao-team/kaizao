import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/auth/auth_session_manager.dart';
import '../../../shared/widgets/vcc_button.dart';
import '../../../shared/widgets/vcc_input.dart';
import '../../../shared/widgets/vcc_toast.dart';
import '../providers/auth_provider.dart';
import '../repositories/auth_repository.dart';
import '../widgets/auth_form_sections.dart';
import '../widgets/auth_page_shell.dart';
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
        systemNavigationBarColor: AppColors.surfaceCanvas,
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
    final result = await ref.read(authStateProvider.notifier).getCaptcha();
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

    return AuthPageShell(
      mode: AuthScreenMode.login,
      compact: compact,
      keyboardInset: keyboardInset,
      heroTitle: '回来继续\nKAIZO',
      heroDescription: '项目进度、协作消息和匹配节奏，都在这里接上。',
      heroScale: _heroScale,
      heroLift: _heroLift,
      onLoginTap: () {},
      onRegisterTap: () {
        context.go(RoutePaths.register);
      },
      form: _PasswordPanel(
        usernameController: _usernameController,
        passwordController: _passwordController,
        captchaCodeController: _captchaCodeController,
        usernameFocus: _usernameFocus,
        passwordFocus: _passwordFocus,
        captchaFocus: _captchaFocus,
        obscurePassword: _obscurePassword,
        onPasswordToggle: () {
          setState(() => _obscurePassword = !_obscurePassword);
        },
        compact: compact,
        captcha: _captcha,
        isLoadingCaptcha: _isLoadingCaptcha,
        onRefreshCaptcha: _loadCaptcha,
      ),
      primaryAction: VccButton(
        text: '登录',
        onPressed: _submit,
        isLoading: isSubmitting,
      ),
      agreement: AuthAgreementRow(
        isChecked: _agreedToTerms,
        prefixText: '登录即代表同意',
        onUserAgreementTap: () {
          context.push(RoutePaths.userAgreement);
        },
        onPrivacyPolicyTap: () {
          context.push(RoutePaths.privacyPolicy);
        },
        onToggle: () {
          setState(() => _agreedToTerms = !_agreedToTerms);
        },
      ),
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
        AuthFieldShell(
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
        AuthFieldShell(
          label: '密码',
          child: VccInput(
            hint: '••••••••',
            controller: passwordController,
            focusNode: passwordFocus,
            obscureText: obscurePassword,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => captchaFocus.requestFocus(),
            suffixIcon: AuthVisibilityToggle(
              obscure: obscurePassword,
              onTap: onPasswordToggle,
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
