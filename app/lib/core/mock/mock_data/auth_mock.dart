import 'package:dio/dio.dart';
import '../mock_interceptor.dart';

/// AUTH 模块 Mock 数据
class AuthMock {
  AuthMock._();

  static void register(Map<String, MockHandler> handlers) {
    handlers['POST:/api/v1/auth/sms-code'] = MockHandler(
      delayMs: 500,
      handler: (_) => _sendSmsCode(),
    );

    handlers['POST:/api/v1/auth/login'] = MockHandler(
      delayMs: 800,
      handler: (options) => _login(options),
    );

    handlers['POST:/api/v1/auth/logout'] = MockHandler(
      handler: (_) => _logout(),
    );

    handlers['POST:/api/v1/auth/refresh'] = MockHandler(
      handler: (_) => _refresh(),
    );
  }

  static Map<String, dynamic> _sendSmsCode() {
    return {
      'code': 0,
      'message': '验证码已发送',
      'data': null,
    };
  }

  static Map<String, dynamic> _login(RequestOptions options) {
    final data = options.data as Map<String, dynamic>?;
    final code = data?['code']?.toString() ?? '';

    // 验证码 "1234" 模拟新用户，其余模拟老用户
    final isNewUser = code == '1234';

    return {
      'code': 0,
      'message': '登录成功',
      'data': {
        'access_token': 'mock_access_token_${DateTime.now().millisecondsSinceEpoch}',
        'refresh_token': 'mock_refresh_token_${DateTime.now().millisecondsSinceEpoch}',
        'user_id': 'user_001',
        'role': isNewUser ? 0 : 1,
        'is_new_user': isNewUser,
      },
    };
  }

  static Map<String, dynamic> _logout() {
    return {
      'code': 0,
      'message': '退出成功',
      'data': null,
    };
  }

  static Map<String, dynamic> _refresh() {
    return {
      'code': 0,
      'message': 'ok',
      'data': {
        'access_token': 'mock_refreshed_token_${DateTime.now().millisecondsSinceEpoch}',
        'refresh_token': 'mock_refreshed_refresh_${DateTime.now().millisecondsSinceEpoch}',
      },
    };
  }
}
