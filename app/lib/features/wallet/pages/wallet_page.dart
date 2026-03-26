import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/vcc_loading.dart';
import '../../../shared/widgets/vcc_empty_state.dart';
import '../../../shared/widgets/vcc_toast.dart';
import '../models/wallet_models.dart';
import '../providers/wallet_provider.dart';
import '../widgets/balance_card.dart';
import '../widgets/transaction_item.dart';
import '../widgets/withdraw_sheet.dart';

class WalletPage extends ConsumerWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(walletProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '我的钱包',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      body: state.isLoading && state.balance == null
          ? const VccLoading()
          : state.errorMessage != null && state.balance == null
              ? VccEmptyState(
                  icon: Icons.error_outline,
                  title: '加载失败',
                  subtitle: state.errorMessage ?? '',
                  buttonText: '重试',
                  onButtonPressed: () =>
                      ref.read(walletProvider.notifier).loadWallet(),
                )
              : RefreshIndicator(
                  color: AppColors.black,
                  onRefresh: () =>
                      ref.read(walletProvider.notifier).loadWallet(),
                  child: ListView(
                    children: [
                      if (state.balance != null)
                        BalanceCard(
                          balance: state.balance!,
                          onWithdraw: () =>
                              _showWithdraw(context, ref, state.balance!),
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                        child: Row(
                          children: [
                            const Text(
                              '交易记录',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.black,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '共 ${state.transactions.length} 条',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.gray400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (state.transactions.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 60),
                          child: VccEmptyState(
                            icon: Icons.receipt_long_outlined,
                            title: '暂无交易记录',
                            subtitle: '完成项目验收后将在这里显示收入',
                          ),
                        )
                      else
                        ...state.transactions.map(
                          (txn) => TransactionItem(transaction: txn),
                        ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
    );
  }

  void _showWithdraw(
    BuildContext context,
    WidgetRef ref,
    WalletBalance balance,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => WithdrawSheet(
        maxAmount: balance.available,
        onSubmit: (amount, method) async {
          final result = await ref
              .read(walletProvider.notifier)
              .withdraw(amount: amount, method: method);
          if (!context.mounted) return false;
          if (result != null) {
            VccToast.show(
              context,
              message: '提现申请已提交，${result.estimatedArrival}',
              type: VccToastType.success,
            );
            return true;
          }
          VccToast.show(
            context,
            message: '提现失败，请稍后重试',
            type: VccToastType.error,
          );
          return false;
        },
      ),
    );
  }
}
