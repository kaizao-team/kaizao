import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/routes.dart';
import '../../../shared/widgets/vcc_button.dart';
import '../../../shared/widgets/vcc_toast.dart';
import '../providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _phoneFocus = FocusNode();
  final _codeFocus = FocusNode();
  Timer? _countdownTimer;
  int _countdown = 0;
  bool _agreedToTerms = false;
  bool _phoneValid = false;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_validatePhone);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _phoneFocus.dispose();
    _codeFocus.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _validatePhone() {
    final text = _phoneController.text;
    final valid = text.length == 11 && text.startsWith('1');
    if (valid != _phoneValid) {
      setState(() => _phoneValid = valid);
    }
  }

  void _startCountdown() {
    setState(() => _countdown = 60);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      if (_countdown <= 1) {
        timer.cancel();
        setState(() => _countdown = 0);
      } else {
        setState(() => _countdown--);
      }
    });
  }

  Future<void> _sendCode() async {
    if (!_phoneValid) return;
    final success = await ref.read(authStateProvider.notifier).sendSmsCode(
          _phoneController.text,
        );
    if (!mounted) return;
    if (success) {
      _startCountdown();
      _codeFocus.requestFocus();
    }
  }

  Future<void> _login() async {
    if (!_agreedToTerms) {
      VccToast.show(context, message: '请先同意服务协议', type: VccToastType.warning);
      return;
    }
    if (_codeController.text.length < 4) {
      VccToast.show(context, message: '请输入验证码', type: VccToastType.warning);
      return;
    }

    final success = await ref.read(authStateProvider.notifier).loginWithPhone(
          _phoneController.text,
          _codeController.text,
        );
    if (success && mounted) {
      final authState = ref.read(authStateProvider);
      if (authState.userRole == 0) {
        context.go(RoutePaths.roleSelect);
      } else {
        context.go(RoutePaths.home);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.black,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'V',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.white,
                      height: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                '欢迎来到开造',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '让每一个好想法都能被造出来',
                style: TextStyle(fontSize: 15, color: AppColors.gray500),
              ),
              const SizedBox(height: 48),

              // Phone
              const Text(
                '手机号',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.gray700),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                focusNode: _phoneFocus,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                style: const TextStyle(fontSize: 16, color: AppColors.black),
                decoration: InputDecoration(
                  hintText: '请输入手机号',
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(left: 16, right: 8),
                    child: Text('+86', style: TextStyle(fontSize: 16, color: AppColors.gray500)),
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 56),
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
              const SizedBox(height: 16),

              // Code
              const Text(
                '验证码',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.gray700),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _codeController,
                focusNode: _codeFocus,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                style: const TextStyle(fontSize: 16, color: AppColors.black),
                decoration: InputDecoration(
                  hintText: '请输入验证码',
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
                  suffixIcon: Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: TextButton(
                      onPressed: _countdown > 0 || !_phoneValid ? null : _sendCode,
                      child: Text(
                        _countdown > 0 ? '${_countdown}s' : '获取验证码',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _countdown > 0 || !_phoneValid
                              ? AppColors.gray400
                              : AppColors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              VccButton(
                text: '登录 / 注册',
                onPressed: _login,
                isLoading: authState.isLoading,
              ),

              if (authState.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    authState.errorMessage!,
                    style: const TextStyle(fontSize: 14, color: AppColors.error),
                  ),
                ),

              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: Checkbox(
                          value: _agreedToTerms,
                          onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
                          activeColor: AppColors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          side: const BorderSide(color: AppColors.gray300),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text('我已阅读并同意 ', style: TextStyle(fontSize: 12, color: AppColors.gray400)),
                      GestureDetector(
                        onTap: () {},
                        child: const Text(
                          '服务协议',
                          style: TextStyle(fontSize: 12, color: AppColors.accent, fontWeight: FontWeight.w500),
                        ),
                      ),
                      const Text(' 和 ', style: TextStyle(fontSize: 12, color: AppColors.gray400)),
                      GestureDetector(
                        onTap: () {},
                        child: const Text(
                          '隐私政策',
                          style: TextStyle(fontSize: 12, color: AppColors.accent, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
