class WalletBalance {
  final double available;
  final double frozen;
  final double totalEarned;
  final double totalWithdrawn;

  const WalletBalance({
    this.available = 0,
    this.frozen = 0,
    this.totalEarned = 0,
    this.totalWithdrawn = 0,
  });

  double get total => available + frozen;

  factory WalletBalance.fromJson(Map<String, dynamic> json) {
    return WalletBalance(
      available: (json['available'] as num?)?.toDouble() ?? 0,
      frozen: (json['frozen'] as num?)?.toDouble() ?? 0,
      totalEarned: (json['total_earned'] as num?)?.toDouble() ?? 0,
      totalWithdrawn: (json['total_withdrawn'] as num?)?.toDouble() ?? 0,
    );
  }
}

enum TransactionType { income, withdraw, fee }

class Transaction {
  final String id;
  final TransactionType type;
  final String title;
  final double amount;
  final String status;
  final String createdAt;

  const Transaction({
    required this.id,
    required this.type,
    required this.title,
    required this.amount,
    this.status = 'completed',
    this.createdAt = '',
  });

  bool get isPositive => amount > 0;

  factory Transaction.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? 'income';
    return Transaction(
      id: json['id'] as String? ?? '',
      type: switch (typeStr) {
        'withdraw' => TransactionType.withdraw,
        'fee' => TransactionType.fee,
        _ => TransactionType.income,
      },
      title: json['title'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? 'completed',
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

class WithdrawResult {
  final String withdrawId;
  final double amount;
  final String method;
  final String status;
  final String estimatedArrival;

  const WithdrawResult({
    required this.withdrawId,
    required this.amount,
    required this.method,
    this.status = 'processing',
    this.estimatedArrival = '',
  });

  factory WithdrawResult.fromJson(Map<String, dynamic> json) {
    return WithdrawResult(
      withdrawId: json['withdraw_id'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      method: json['method'] as String? ?? '',
      status: json['status'] as String? ?? 'processing',
      estimatedArrival: json['estimated_arrival'] as String? ?? '',
    );
  }
}
