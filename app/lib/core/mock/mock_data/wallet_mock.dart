import 'package:dio/dio.dart';
import '../mock_interceptor.dart';

class WalletMock {
  WalletMock._();

  static void register(Map<String, MockHandler> handlers) {
    handlers['GET:/api/v1/wallet/balance'] = MockHandler(
      delayMs: 200,
      handler: (_) => _getBalance(),
    );

    handlers['GET:/api/v1/wallet/transactions'] = MockHandler(
      delayMs: 300,
      handler: (options) => _getTransactions(options),
    );

    handlers['POST:/api/v1/wallet/withdraw'] = MockHandler(
      delayMs: 500,
      handler: (options) => _withdraw(options),
    );
  }

  static Map<String, dynamic> _getBalance() {
    return {
      'code': 0,
      'message': 'ok',
      'data': {
        'available': 23680.0,
        'frozen': 15000.0,
        'total_earned': 86500.0,
        'total_withdrawn': 47820.0,
      },
    };
  }

  static Map<String, dynamic> _getTransactions(RequestOptions options) {
    final page = options.queryParameters['page'] ?? 1;
    return {
      'code': 0,
      'message': 'ok',
      'data': [
        {
          'id': 'txn_01',
          'type': 'income',
          'title': '项目验收 - 智能客服系统（里程碑1）',
          'amount': 3000.0,
          'status': 'completed',
          'created_at': '2026-03-20T14:30:00Z',
        },
        {
          'id': 'txn_02',
          'type': 'income',
          'title': '项目验收 - 企业官网改版（里程碑2）',
          'amount': 2500.0,
          'status': 'completed',
          'created_at': '2026-03-18T10:15:00Z',
        },
        {
          'id': 'txn_03',
          'type': 'withdraw',
          'title': '提现到微信',
          'amount': -5000.0,
          'status': 'completed',
          'created_at': '2026-03-15T09:00:00Z',
        },
        {
          'id': 'txn_04',
          'type': 'income',
          'title': '项目验收 - 智能客服系统（里程碑2）',
          'amount': 5000.0,
          'status': 'completed',
          'created_at': '2026-03-12T16:00:00Z',
        },
        {
          'id': 'txn_05',
          'type': 'fee',
          'title': '平台服务费',
          'amount': -300.0,
          'status': 'completed',
          'created_at': '2026-03-12T16:00:01Z',
        },
        {
          'id': 'txn_06',
          'type': 'withdraw',
          'title': '提现到支付宝',
          'amount': -8000.0,
          'status': 'processing',
          'created_at': '2026-03-10T11:30:00Z',
        },
        {
          'id': 'txn_07',
          'type': 'income',
          'title': '项目验收 - 短视频社区（尾款）',
          'amount': 12000.0,
          'status': 'completed',
          'created_at': '2026-03-05T13:20:00Z',
        },
      ],
      'meta': {
        'page': page,
        'page_size': 10,
        'total': 7,
        'total_pages': 1,
      },
    };
  }

  static Map<String, dynamic> _withdraw(RequestOptions options) {
    return {
      'code': 0,
      'message': '提现申请已提交',
      'data': {
        'withdraw_id': 'wd_${DateTime.now().millisecondsSinceEpoch}',
        'amount': (options.data as Map<String, dynamic>?)?['amount'] ?? 0,
        'method': (options.data as Map<String, dynamic>?)?['method'] ?? 'wechat',
        'status': 'processing',
        'estimated_arrival': 'T+1个工作日',
      },
    };
  }
}
