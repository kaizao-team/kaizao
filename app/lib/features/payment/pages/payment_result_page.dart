import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/vcc_button.dart';
import '../providers/payment_provider.dart';
import '../models/payment_models.dart';

class PaymentResultPage extends ConsumerStatefulWidget {
  final String orderId;
  const PaymentResultPage({super.key, required this.orderId});

  @override
  ConsumerState<PaymentResultPage> createState() => _PaymentResultPageState();
}

class _PaymentResultPageState extends ConsumerState<PaymentResultPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paymentProvider(widget.orderId));
    final result = state.result;
    final isSuccess = result?.status == PaymentStatus.success;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const Spacer(),
              ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color:
                        isSuccess ? AppColors.successBg : AppColors.errorBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSuccess ? Icons.check_circle : Icons.cancel,
                    size: 48,
                    color: isSuccess ? AppColors.success : AppColors.error,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    Text(
                      isSuccess ? '支付成功' : '支付失败',
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.black),
                    ),
                    const SizedBox(height: 8),
                    if (isSuccess && result?.paidAmount != null)
                      Text(
                        '¥${result!.paidAmount!.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: AppColors.accent),
                      ),
                    if (!isSuccess)
                      Text(
                        result?.failReason ?? '请稍后重试',
                        style: const TextStyle(
                            fontSize: 14, color: AppColors.gray500),
                      ),
                    if (isSuccess) ...[
                      const SizedBox(height: 4),
                      const Text('资金已进入托管账户',
                          style: TextStyle(
                              fontSize: 14, color: AppColors.gray500)),
                    ],
                  ],
                ),
              ),
              const Spacer(flex: 2),
              FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: VccButton(
                        text: isSuccess ? '查看项目' : '重新支付',
                        onPressed: () {
                          if (isSuccess) {
                            context.go('/projects');
                          } else {
                            context.pop();
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: VccButton(
                        text: '返回首页',
                        type: VccButtonType.secondary,
                        onPressed: () => context.go('/home'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
