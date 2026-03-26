import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/routes.dart';
import '../providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  Timer? _countdownTimer;
  int _countdown = 0;
  bool _agreedToTerms = false;
  late AnimationController _panelController;
  late Animation<Offset> _panelSlide;
  late Animation<double> _panelFade;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),);
    _panelController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _panelSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _panelController, curve: Curves.easeOutCubic));
    _panelFade = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _panelController, curve: Curves.easeOut));
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _panelController.forward();
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _countdownTimer?.cancel();
    _panelController.dispose();
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
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请输入手机号')));
      return;
    }
    final success = await ref
        .read(authStateProvider.notifier)
        .sendSmsCode(_phoneController.text);
    if (success) _startCountdown();
  }

  Future<void> _login() async {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请先同意服务协议')));
      return;
    }
    final success = await ref
        .read(authStateProvider.notifier)
        .loginWithPhone(_phoneController.text, _codeController.text);
    if (success && mounted) context.go(RoutePaths.home);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    final topHeight = size.height * 0.30;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Top dark header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topHeight + 40,
            child: _buildTopArea(padding),
          ),
          // White sliding panel
          Positioned(
            top: topHeight,
            left: 0,
            right: 0,
            bottom: 0,
            child: FadeTransition(
              opacity: _panelFade,
              child: SlideTransition(
                position: _panelSlide,
                child: _buildPanel(padding),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopArea(EdgeInsets padding) {
    return Padding(
      padding: EdgeInsets.only(top: padding.top + 44),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: CustomPaint(painter: _MiniLogoPainter()),
          ),
          const SizedBox(height: 12),
          const Text(
            'VCC',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            '欢迎回来',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF9CA3AF),
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanel(EdgeInsets padding) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(28, 32, 28, padding.bottom + 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '登录 / 注册',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '未注册的手机号将自动创建账号',
              style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
            ),
            const SizedBox(height: 28),

            // Phone
            const Text(
              '手机号',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 8),
            _PhoneField(controller: _phoneController),
            const SizedBox(height: 20),

            // Code
            const Text(
              '验证码',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 8),
            _CodeField(
              controller: _codeController,
              countdown: _countdown,
              onSendCode: _sendCode,
            ),
            const SizedBox(height: 32),

            // Login button
            _buildLoginButton(),
            const SizedBox(height: 24),

            // Divider
            const Row(
              children: [
                Expanded(child: Divider(color: Color(0xFFE5E5E5))),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    '其他方式',
                    style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                  ),
                ),
                Expanded(child: Divider(color: Color(0xFFE5E5E5))),
              ],
            ),
            const SizedBox(height: 24),

            // Social buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SocialButton(
                  icon: Icons.wechat,
                  iconColor: const Color(0xFF07C160),
                  label: '微信',
                  onTap: () {},
                ),
                if (defaultTargetPlatform == TargetPlatform.iOS) ...
                  [
                    const SizedBox(width: 20),
                    _SocialButton(
                      icon: Icons.apple,
                      iconColor: const Color(0xFF1A1A1A),
                      label: 'Apple',
                      onTap: () {},
                    ),
                  ],
              ],
            ),
            const SizedBox(height: 28),

            // Terms
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 18,
                    height: 18,
                    margin: const EdgeInsets.only(top: 1),
                    decoration: BoxDecoration(
                      color: _agreedToTerms
                          ? const Color(0xFF1A1A1A)
                          : Colors.white,
                      border: Border.all(
                        color: _agreedToTerms
                            ? const Color(0xFF1A1A1A)
                            : const Color(0xFFD4D4D4),
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: _agreedToTerms
                        ? const Icon(Icons.check,
                            size: 12, color: Colors.white,)
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: TextStyle(
                          fontSize: 12, color: Color(0xFF9CA3AF),),
                      children: [
                        TextSpan(text: '我已阅读并同意'),
                        TextSpan(
                          text: '《用户协议》',
                          style: TextStyle(color: Color(0xFF1A1A1A)),
                        ),
                        TextSpan(text: '和'),
                        TextSpan(
                          text: '《隐私政策》',
                          style: TextStyle(color: Color(0xFF1A1A1A)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    final authState = ref.watch(authStateProvider);
    final isLoading = authState.isLoading;
    return GestureDetector(
      onTap: isLoading ? null : _login,
      child: AnimatedOpacity(
        opacity: isLoading ? 0.6 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  '登录 / 注册',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}

class _PhoneField extends StatelessWidget {
  final TextEditingController controller;
  const _PhoneField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0F1F1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.phone,
        style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A1A)),
        decoration: const InputDecoration(
          hintText: '请输入手机号',
          hintStyle: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
          prefixText: '+86  ',
          prefixStyle: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,),
          border: InputBorder.none,
          contentPadding:
              EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

class _CodeField extends StatelessWidget {
  final TextEditingController controller;
  final int countdown;
  final VoidCallback onSendCode;
  const _CodeField({
    required this.controller,
    required this.countdown,
    required this.onSendCode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0F1F1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A1A)),
              decoration: const InputDecoration(
                hintText: '请输入验证码',
                hintStyle:
                    TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          GestureDetector(
            onTap: countdown > 0 ? null : onSendCode,
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                countdown > 0 ? '${countdown}s' : '获取验证码',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: countdown > 0
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF1A1A1A),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;
  const _SocialButton({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F1F1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = const Color(0xFF1A1A1A);
    canvas.drawPath(
      Path()
        ..moveTo(0, h)
        ..lineTo(w * 0.5, 0)
        ..lineTo(w * 0.36, h)
        ..close(),
      paint,
    );
    paint.color = const Color(0xFF6B7280);
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.33, h)
        ..lineTo(w * 0.67, h)
        ..lineTo(w * 0.5, h * 0.32)
        ..close(),
      paint,
    );
    paint.color = const Color(0xFFD4D4D4);
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.64, h)
        ..lineTo(w, h)
        ..lineTo(w * 0.5, 0)
        ..close(),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
