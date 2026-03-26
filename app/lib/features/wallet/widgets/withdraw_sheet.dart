import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/vcc_button.dart';

class WithdrawSheet extends StatefulWidget {
  final double maxAmount;
  final Future<bool> Function(double amount, String method) onSubmit;

  const WithdrawSheet({
    super.key,
    required this.maxAmount,
    required this.onSubmit,
  });

  @override
  State<WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends State<WithdrawSheet> {
  final _amountController = TextEditingController();
  String _method = 'wechat';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  double get _amount => double.tryParse(_amountController.text) ?? 0;
  bool get _valid => _amount > 0 && _amount <= widget.maxAmount;

  Future<void> _submit() async {
    if (!_valid || _isSubmitting) return;
    setState(() => _isSubmitting = true);
    final success = await widget.onSubmit(_amount, _method);
    if (!mounted) return;
    if (success) {
      Navigator.pop(context, true);
    } else {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.gray300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '提现',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '可提现余额 ¥${widget.maxAmount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 13, color: AppColors.gray500),
            ),
            const SizedBox(height: 20),
            const Text(
              '提现金额',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.gray700,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}'),
                      ),
                    ],
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                    ),
                    decoration: InputDecoration(
                      prefixText: '¥ ',
                      prefixStyle: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                      ),
                      hintText: '0.00',
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
                        borderSide: const BorderSide(
                          color: AppColors.black,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () {
                    _amountController.text =
                        widget.maxAmount.toStringAsFixed(2);
                    setState(() {});
                  },
                  child: const Text(
                    '全部提现',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              '收款方式',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.gray700,
              ),
            ),
            const SizedBox(height: 8),
            _MethodOption(
              icon: Icons.chat_bubble,
              label: '微信',
              selected: _method == 'wechat',
              onTap: () => setState(() => _method = 'wechat'),
            ),
            const SizedBox(height: 8),
            _MethodOption(
              icon: Icons.account_balance,
              label: '支付宝',
              selected: _method == 'alipay',
              onTap: () => setState(() => _method = 'alipay'),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.gray50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.gray400),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '提现将于 T+1 个工作日到账',
                      style: TextStyle(fontSize: 12, color: AppColors.gray500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: VccButton(
                text: '确认提现',
                isLoading: _isSubmitting,
                onPressed: _valid ? _submit : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MethodOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? AppColors.black : AppColors.gray200,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.gray600),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(fontSize: 15, color: AppColors.black),
            ),
            const Spacer(),
            if (selected)
              const Icon(Icons.check_circle, size: 20, color: AppColors.black),
          ],
        ),
      ),
    );
  }
}
