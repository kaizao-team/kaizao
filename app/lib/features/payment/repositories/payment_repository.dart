import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/payment_models.dart';

class PaymentRepository {
  final ApiClient _client = ApiClient();

  Future<OrderDetail> fetchOrderDetail(String orderId) async {
    final response = await _client.get(ApiEndpoints.orderDetail(orderId));
    return OrderDetail.fromJson(response.data as Map<String, dynamic>? ?? {});
  }

  Future<Map<String, dynamic>> createPayment(
      String orderId, PaymentMethod method) async {
    final response = await _client.post(
      ApiEndpoints.orderPrepay(orderId),
      data: {'payment_method': method.name},
    );
    return response.data as Map<String, dynamic>? ?? {};
  }

  Future<PaymentResult> checkPaymentStatus(String orderId) async {
    final response = await _client.get(ApiEndpoints.orderStatus(orderId));
    final data = response.data as Map<String, dynamic>? ?? {};
    final statusStr = data['status'] as String? ?? '';
    return PaymentResult(
      status: statusStr == 'success'
          ? PaymentStatus.success
          : statusStr == 'failed'
              ? PaymentStatus.failed
              : PaymentStatus.pending,
      paidAmount: (data['paid_amount'] as num?)?.toDouble(),
      paidAt: data['paid_at'] as String?,
    );
  }

  Future<List<Coupon>> fetchCoupons() async {
    final response = await _client.get(ApiEndpoints.coupons);
    final list = response.data as List? ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .map((e) => Coupon.fromJson(e))
        .toList();
  }
}
