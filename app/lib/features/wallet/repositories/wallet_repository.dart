import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/wallet_models.dart';

class WalletRepository {
  final ApiClient _client = ApiClient();

  Future<WalletBalance> fetchBalance() async {
    final response = await _client.get(ApiEndpoints.walletBalance);
    return WalletBalance.fromJson(response.data as Map<String, dynamic>? ?? {});
  }

  Future<List<Transaction>> fetchTransactions({int page = 1}) async {
    final response = await _client.get(
      ApiEndpoints.walletTransactions,
      queryParameters: {'page': page, 'page_size': 20},
    );
    final list = response.data as List? ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .map((e) => Transaction.fromJson(e))
        .toList();
  }

  Future<WithdrawResult> withdraw({
    required double amount,
    required String method,
  }) async {
    final response = await _client.post(
      ApiEndpoints.walletWithdraw,
      data: {'amount': amount, 'method': method},
    );
    return WithdrawResult.fromJson(
        response.data as Map<String, dynamic>? ?? {});
  }
}
