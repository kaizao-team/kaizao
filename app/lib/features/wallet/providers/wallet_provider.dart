import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/wallet_models.dart';
import '../repositories/wallet_repository.dart';

class WalletState {
  final bool isLoading;
  final WalletBalance? balance;
  final List<Transaction> transactions;
  final bool isWithdrawing;
  final String? errorMessage;

  const WalletState({
    this.isLoading = false,
    this.balance,
    this.transactions = const [],
    this.isWithdrawing = false,
    this.errorMessage,
  });

  WalletState copyWith({
    bool? isLoading,
    WalletBalance? balance,
    List<Transaction>? transactions,
    bool? isWithdrawing,
    String? Function()? errorMessage,
  }) {
    return WalletState(
      isLoading: isLoading ?? this.isLoading,
      balance: balance ?? this.balance,
      transactions: transactions ?? this.transactions,
      isWithdrawing: isWithdrawing ?? this.isWithdrawing,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }
}

class WalletNotifier extends StateNotifier<WalletState> {
  final WalletRepository _repository;

  WalletNotifier(this._repository) : super(const WalletState()) {
    loadWallet();
  }

  Future<void> loadWallet() async {
    state = state.copyWith(isLoading: true, errorMessage: () => null);
    try {
      final balance = await _repository.fetchBalance();
      if (!mounted) return;
      final transactions = await _repository.fetchTransactions();
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        balance: balance,
        transactions: transactions,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: () => e.toString(),
      );
    }
  }

  Future<WithdrawResult?> withdraw({
    required double amount,
    required String method,
  }) async {
    state = state.copyWith(isWithdrawing: true, errorMessage: () => null);
    try {
      final result = await _repository.withdraw(
        amount: amount,
        method: method,
      );
      if (!mounted) return null;
      await loadWallet();
      if (!mounted) return null;
      state = state.copyWith(isWithdrawing: false);
      return result;
    } catch (e) {
      if (!mounted) return null;
      state = state.copyWith(
        isWithdrawing: false,
        errorMessage: () => e.toString(),
      );
      return null;
    }
  }
}

final walletProvider =
    StateNotifierProvider.autoDispose<WalletNotifier, WalletState>((ref) {
  return WalletNotifier(WalletRepository());
});
