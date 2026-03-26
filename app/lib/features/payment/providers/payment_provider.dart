import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/payment_models.dart';
import '../repositories/payment_repository.dart';

class PaymentState {
  final bool isLoading;
  final bool isPaying;
  final OrderDetail? order;
  final List<Coupon> coupons;
  final String? selectedCouponId;
  final PaymentMethod? selectedMethod;
  final PaymentResult? result;
  final String? errorMessage;

  const PaymentState({
    this.isLoading = false,
    this.isPaying = false,
    this.order,
    this.coupons = const [],
    this.selectedCouponId,
    this.selectedMethod,
    this.result,
    this.errorMessage,
  });

  PaymentState copyWith({
    bool? isLoading,
    bool? isPaying,
    OrderDetail? order,
    List<Coupon>? coupons,
    String? Function()? selectedCouponId,
    PaymentMethod? Function()? selectedMethod,
    PaymentResult? Function()? result,
    String? Function()? errorMessage,
  }) {
    return PaymentState(
      isLoading: isLoading ?? this.isLoading,
      isPaying: isPaying ?? this.isPaying,
      order: order ?? this.order,
      coupons: coupons ?? this.coupons,
      selectedCouponId: selectedCouponId != null
          ? selectedCouponId()
          : this.selectedCouponId,
      selectedMethod:
          selectedMethod != null ? selectedMethod() : this.selectedMethod,
      result: result != null ? result() : this.result,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  double get discountAmount {
    if (selectedCouponId == null) return 0;
    final coupon = coupons.where((c) => c.id == selectedCouponId).firstOrNull;
    return coupon?.discountAmount ?? 0;
  }

  double get actualAmount =>
      (order?.totalAmount ?? 0) - discountAmount;
}

class PaymentNotifier extends StateNotifier<PaymentState> {
  final PaymentRepository _repository;
  final String orderId;

  PaymentNotifier(this._repository, this.orderId)
      : super(const PaymentState()) {
    _loadAll();
  }

  Future<void> _loadAll() async {
    state = state.copyWith(isLoading: true, errorMessage: () => null);
    try {
      final results = await Future.wait([
        _repository.fetchOrderDetail(orderId),
        _repository.fetchCoupons(),
      ]);
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        order: results[0] as OrderDetail,
        coupons: results[1] as List<Coupon>,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: () => e.toString(),
      );
    }
  }

  void selectCoupon(String? couponId) {
    state = state.copyWith(selectedCouponId: () => couponId);
  }

  void selectPaymentMethod(PaymentMethod method) {
    state = state.copyWith(selectedMethod: () => method);
  }

  Future<bool> pay() async {
    final method = state.selectedMethod;
    if (method == null) return false;
    state = state.copyWith(isPaying: true, errorMessage: () => null);
    try {
      await _repository.createPayment(orderId, method);
      final result = await _repository.checkPaymentStatus(orderId);
      if (!mounted) return false;
      state = state.copyWith(isPaying: false, result: () => result);
      return result.status == PaymentStatus.success;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        isPaying: false,
        result: () => PaymentResult(
          status: PaymentStatus.failed,
          failReason: e.toString(),
        ),
      );
      return false;
    }
  }
}

final paymentProvider = StateNotifierProvider.autoDispose
    .family<PaymentNotifier, PaymentState, String>((ref, orderId) {
  return PaymentNotifier(PaymentRepository(), orderId);
});
