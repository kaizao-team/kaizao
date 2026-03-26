import 'package:dio/dio.dart';
import '../mock_interceptor.dart';

class PaymentMock {
  PaymentMock._();

  static void register(Map<String, MockHandler> handlers) {
    handlers['GET:/api/v1/orders/:id'] = MockHandler(
      delayMs: 300,
      handler: (_) => _orderDetail(),
    );

    handlers['POST:/api/v1/orders/:id/prepay'] = MockHandler(
      delayMs: 600,
      handler: (options) => _prepay(options),
    );

    handlers['GET:/api/v1/orders/:id/status'] = MockHandler(
      delayMs: 300,
      handler: (_) => _paymentStatus(),
    );

    handlers['GET:/api/v1/coupons'] = MockHandler(
      delayMs: 300,
      handler: (_) => _couponList(),
    );
  }

  static Map<String, dynamic> _orderDetail() {
    return {
      'code': 0,
      'data': {
        'id': 'order_001',
        'project_id': '1',
        'project_title': '智能客服系统',
        'payee_name': '张开发',
        'project_amount': 8000,
        'platform_fee': 400,
        'discount': 0,
        'total_amount': 8400,
        'milestones': [
          {'title': '需求确认 & 基础框架', 'amount': 1500, 'status': 'paid'},
          {'title': '核心功能开发', 'amount': 3000, 'status': 'current'},
          {'title': '通信 & 支付模块', 'amount': 2000, 'status': 'pending'},
          {'title': '测试 & 上线', 'amount': 1500, 'status': 'pending'},
        ],
        'guarantee_text': '资金由平台托管，验收通过后释放给供给方',
        'status': 'pending',
      },
    };
  }

  static Map<String, dynamic> _prepay(RequestOptions options) {
    final method = options.data?['payment_method'] ?? 'wechat';
    return {
      'code': 0,
      'message': 'ok',
      'data': {
        'payment_id': 'pay_001',
        'payment_method': method,
        'payment_url': 'https://pay.example.com/mock',
        'status': 'success',
      },
    };
  }

  static Map<String, dynamic> _paymentStatus() {
    return {
      'code': 0,
      'data': {
        'status': 'success',
        'paid_amount': 3000,
        'paid_at': '2026-03-23T15:00:00Z',
      },
    };
  }

  static Map<String, dynamic> _couponList() {
    return {
      'code': 0,
      'data': [
        {'id': 'cpn_001', 'title': '新用户专享', 'discount_amount': 200, 'min_order_amount': 1000, 'expire_date': '2026-04-30', 'is_available': true, 'reason': null},
        {'id': 'cpn_002', 'title': '平台回馈券', 'discount_amount': 100, 'min_order_amount': 500, 'expire_date': '2026-04-15', 'is_available': true, 'reason': null},
        {'id': 'cpn_003', 'title': '限时折扣', 'discount_amount': 500, 'min_order_amount': 5000, 'expire_date': '2026-03-25', 'is_available': false, 'reason': '订单金额未达到使用门槛'},
      ],
    };
  }
}
