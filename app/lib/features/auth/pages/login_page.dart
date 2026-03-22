import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/routes.dart';
import '../../../shared/widgets/vcc_button.dart';
import '../../../shared/widgets/vcc_input.dart';
import '../providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  Timer? _countdownTimer;
  int _countdown = 0;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    setState(() => _countdown = 60);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown <= 1) {
        timer.cancel();
        setState(() => _countdown = 0);
      } else {
        setState(() => _countdown--);
      }
    });
  }

  Future<void> _sendCode() async {
    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入手机号')),
      );
      return;
    }
    final success = await ref.read(authStateProvider.notifier).sendSmsCode(
          _phoneController.text,
        );
    if (success) _startCountdown();
  }

  Future<void> _login() async {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先同意服务协议')),
      );
      return;
    }
    final success = await ref.read(authStateProvider.notifier).loginWithPhone(
          _phoneController.text,
          _codeController.text,
        );
    if (success && mounted) {
      context.go(RoutePaths.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const SizedBox(height: 48),
              // Logo + 品牌名
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppGradients.primaryButton,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.rocket_launch, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 8),
              const Text(
                '开造',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.gray800),
              ),
              const SizedBox(height: 24),
              const Text(
                '欢迎来到开造',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.gray800),
              ),
              const SizedBox(height: 8),
              const Text(
                '让每一个好想法都能被造出来',
                style: TextStyle(fontSize: 14, color: AppColors.gray500),
              ),
              const SizedBox(height: 48),

              // 手机号输入
              VccInput(
                label: '手机号',
                hint: '请输入手机号',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(left: 16, right: 8),
                  child: Text('+86', style: TextStyle(fontSize: 16, color: AppColors.gray600)),
                ),
              ),
              const SizedBox(height: 12),

              // 验证码输入
              VccInput(
                label: '验证码',
                hint: '请输入验证码',
                controller: _codeController,
                keyboardType: TextInputType.number,
                suffixIcon: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: TextButton(
                    onPressed: _countdown > 0 ? null : _sendCode,
                    child: Text(
                      _countdown > 0 ? '${_countdown}s后重发' : '获取验证码',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _countdown > 0 ? AppColors.gray400 : AppColors.brandPurple,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 登录按钮
              VccButton(
                text: '登录 / 注册',
                onPressed: _login,
                isLoading: authState.isLoading,
              ),

              // 错误信息
              if (authState.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    authState.errorMessage!,
                    style: const TextStyle(fontSize: 14, color: AppColors.error),
                  ),
                ),

              // 服务协议
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: _agreedToTerms,
                      onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
                      activeColor: AppColors.brandPurple,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text('我已阅读并同意', style: TextStyle(fontSize: 12, color: AppColors.gray400)),
                  GestureDetector(
                    onTap: () {},
                    child: const Text(
                      '服务协议',
                      style: TextStyle(fontSize: 12, color: AppColors.info),
                    ),
                  ),
                  const Text(' 和 ', style: TextStyle(fontSize: 12, color: AppColors.gray400)),
                  GestureDetector(
                    onTap: () {},
                    child: const Text(
                      '隐私政策',
                      style: TextStyle(fontSize: 12, color: AppColors.info),
                    ),
                  ),
                ],
              ),

              // 第三方登录
              const SizedBox(height: 32),
              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.gray200)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('或', style: TextStyle(fontSize: 14, color: AppColors.gray400)),
                  ),
                  const Expanded(child: Divider(color: AppColors.gray200)),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSocialButton(
                    icon: Icons.wechat,
                    color: AppColors.wechatGreen,
                    onTap: () {},
                  ),
                  if (defaultTargetPlatform == TargetPlatform.iOS) ...[
                    const SizedBox(width: 24),
                    _buildSocialButton(
                      icon: Icons.apple,
                      color: AppColors.appleBlack,
                      onTap: () {},
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}
