enum PaymentMethod { wechat, alipay }

enum PaymentStatus { pending, success, failed, cancelled }

class OrderDetail {
  final String id;
  final String projectId;
  final String projectTitle;
  final String payeeName;
  final double projectAmount;
  final double platformFee;
  final double discount;
  final double totalAmount;
  final List<MilestonePayment> milestones;
  final String guaranteeText;
  final String status;

  const OrderDetail({
    required this.id,
    required this.projectId,
    required this.projectTitle,
    required this.payeeName,
    required this.projectAmount,
    required this.platformFee,
    required this.discount,
    required this.totalAmount,
    required this.milestones,
    required this.guaranteeText,
    required this.status,
  });

  double get actualAmount => totalAmount - discount;

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    return OrderDetail(
      id: json['id'] as String? ?? '',
      projectId: json['project_id'] as String? ?? '',
      projectTitle: json['project_title'] as String? ?? '',
      payeeName: json['payee_name'] as String? ?? '',
      projectAmount: (json['project_amount'] as num?)?.toDouble() ?? 0,
      platformFee: (json['platform_fee'] as num?)?.toDouble() ?? 0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
      milestones: (json['milestones'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map((e) => MilestonePayment.fromJson(e))
              .toList() ??
          [],
      guaranteeText: json['guarantee_text'] as String? ?? '',
      status: json['status'] as String? ?? '',
    );
  }
}

class MilestonePayment {
  final String title;
  final double amount;
  final String status;

  const MilestonePayment({
    required this.title,
    required this.amount,
    required this.status,
  });

  bool get isPaid => status == 'paid';
  bool get isCurrent => status == 'current';

  factory MilestonePayment.fromJson(Map<String, dynamic> json) {
    return MilestonePayment(
      title: json['title'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? '',
    );
  }
}

class Coupon {
  final String id;
  final String title;
  final double discountAmount;
  final double minOrderAmount;
  final String expireDate;
  final bool isAvailable;
  final String? reason;

  const Coupon({
    required this.id,
    required this.title,
    required this.discountAmount,
    required this.minOrderAmount,
    required this.expireDate,
    required this.isAvailable,
    this.reason,
  });

  factory Coupon.fromJson(Map<String, dynamic> json) {
    return Coupon(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0,
      minOrderAmount: (json['min_order_amount'] as num?)?.toDouble() ?? 0,
      expireDate: json['expire_date'] as String? ?? '',
      isAvailable: json['is_available'] as bool? ?? false,
      reason: json['reason'] as String?,
    );
  }
}

class PaymentResult {
  final PaymentStatus status;
  final double? paidAmount;
  final String? paidAt;
  final String? failReason;

  const PaymentResult({
    required this.status,
    this.paidAmount,
    this.paidAt,
    this.failReason,
  });
}
