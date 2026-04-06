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
import '../providers/auth_provider.dart';
import '../widgets/auth_form_sections.dart';
import '../../onboarding/providers/onboarding_provider.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage>
    with TickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();
  final _phoneFocus = FocusNode();

  late final AnimationController _heroController;
  late final Animation<double> _heroScale;
  late final Animation<double> _heroLift;

  bool _phoneValid = false;
  bool _agreedToTerms = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  static final _usernameRegex = RegExp(r'^[a-zA-Z0-9_]{4,32}$');

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
    _heroController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    _phoneFocus.dispose();
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

  Future<void> _submit() async {
    if (!_agreedToTerms) {
      _showToast('请先同意服务协议', type: VccToastType.warning);
      return;
    }

    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (username.isEmpty) {
      _showToast('请输入用户名', type: VccToastType.warning);
      return;
    }
    if (!_usernameRegex.hasMatch(username)) {
      _showToast('用户名仅支持 4-32 位字母、数字、下划线', type: VccToastType.warning);
      return;
    }
    if (password.isEmpty) {
      _showToast('请输入密码', type: VccToastType.warning);
      return;
    }
    if (password.length < 8) {
      _showToast('密码至少 8 位', type: VccToastType.warning);
      return;
    }
    if (confirmPassword != password) {
      _showToast('两次输入的密码不一致', type: VccToastType.warning);
      return;
    }

    final phoneText = _phoneController.text.trim();
    if (phoneText.isEmpty) {
      _showToast('请输入手机号', type: VccToastType.warning);
      return;
    }
    if (!_phoneValid) {
      _showToast('请输入正确的手机号', type: VccToastType.warning);
      return;
    }
    final phone = phoneText;
    String? smsCode;

    final success =
        await ref.read(authStateProvider.notifier).registerWithPassword(
              username: username,
              password: password,
              phone: phone,
              smsCode: smsCode,
            );

    if (!success || !mounted) {
      if (mounted) {
        final error = ref.read(authStateProvider).errorMessage;
        if (error != null) _showToast(error, type: VccToastType.error);
      }
      return;
    }

    if (phone.isNotEmpty) {
      await ref
          .read(onboardingProvider.notifier)
          .saveDraft({'contact_phone': phone});
    }

    if (!mounted) return;
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
                            // const Text('新用户注册', style: AppTextStyles.h2),
                            // const SizedBox(height: AppSpacing.xs),
                            // Text(
                            //   '创建账号密码即可使用 KAIZO，首次登录后选择你的身份即可开始。',
                            //   style: AppTextStyles.body2.copyWith(
                            //     color: AppColors.gray500,
                            //   ),
                            // ),
                            SizedBox(
                              height: compact ? AppSpacing.lg : AppSpacing.xl,
                            ),
                            _RegisterForm(
                              usernameController: _usernameController,
                              passwordController: _passwordController,
                              confirmPasswordController:
                                  _confirmPasswordController,
                              phoneController: _phoneController,
                              usernameFocus: _usernameFocus,
                              passwordFocus: _passwordFocus,
                              confirmPasswordFocus: _confirmPasswordFocus,
                              phoneFocus: _phoneFocus,
                              obscurePassword: _obscurePassword,
                              obscureConfirm: _obscureConfirm,
                              onPasswordToggle: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              onConfirmToggle: () => setState(
                                () => _obscureConfirm = !_obscureConfirm,
                              ),
                              compact: compact,
                            ),
                            SizedBox(
                              height: keyboardInset > 0
                                  ? AppSpacing.xl
                                  : (compact ? AppSpacing.xxl : 48),
                            ),
                            VccButton(
                              text: '注册',
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

class _RegisterForm extends StatelessWidget {
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final TextEditingController phoneController;
  final FocusNode usernameFocus;
  final FocusNode passwordFocus;
  final FocusNode confirmPasswordFocus;
  final FocusNode phoneFocus;
  final bool obscurePassword;
  final bool obscureConfirm;
  final VoidCallback onPasswordToggle;
  final VoidCallback onConfirmToggle;
  final bool compact;

  const _RegisterForm({
    required this.usernameController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.phoneController,
    required this.usernameFocus,
    required this.passwordFocus,
    required this.confirmPasswordFocus,
    required this.phoneFocus,
    required this.obscurePassword,
    required this.obscureConfirm,
    required this.onPasswordToggle,
    required this.onConfirmToggle,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = compact ? AppSpacing.md : AppSpacing.base;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthFieldShell(
          label: '用户名',
          child: VccInput(
            hint: '4-32 位字母、数字或下划线',
            controller: usernameController,
            focusNode: usernameFocus,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
              LengthLimitingTextInputFormatter(32),
            ],
            onSubmitted: (_) => passwordFocus.requestFocus(),
          ),
        ),
        SizedBox(height: spacing),
        AuthFieldShell(
          label: '密码',
          child: VccInput(
            hint: '至少 8 位',
            controller: passwordController,
            focusNode: passwordFocus,
            obscureText: obscurePassword,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => confirmPasswordFocus.requestFocus(),
            suffixIcon: _EyeToggle(
              obscure: obscurePassword,
              onTap: onPasswordToggle,
            ),
          ),
        ),
        SizedBox(height: spacing),
        AuthFieldShell(
          label: '确认密码',
          child: VccInput(
            hint: '再次输入密码',
            controller: confirmPasswordController,
            focusNode: confirmPasswordFocus,
            obscureText: obscureConfirm,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => phoneFocus.requestFocus(),
            suffixIcon: _EyeToggle(
              obscure: obscureConfirm,
              onTap: onConfirmToggle,
            ),
          ),
        ),
        SizedBox(height: spacing),
        AuthFieldShell(
          label: '手机号',
          child: VccInput(
            hint: '请输入手机号',
            controller: phoneController,
            focusNode: phoneFocus,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
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
          ),
        ),
      ],
    );
  }
}

class _EyeToggle extends StatelessWidget {
  final bool obscure;
  final VoidCallback onTap;

  const _EyeToggle({required this.obscure, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(
          obscure ? Icons.visibility_off_outlined : Icons.remove_red_eye_outlined,
          size: 18,
          color: AppColors.gray500,
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
