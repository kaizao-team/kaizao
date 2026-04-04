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

    handlers['GET:/api/v1/auth/password-key'] = MockHandler(
      delayMs: 300,
      handler: (_) => _passwordKey(),
    );

    handlers['GET:/api/v1/auth/captcha'] = MockHandler(
      delayMs: 400,
      handler: (_) => _captcha(),
    );

    handlers['POST:/api/v1/auth/login-password'] = MockHandler(
      delayMs: 800,
      handler: (options) => _loginPassword(options),
    );

    handlers['POST:/api/v1/auth/register-password'] = MockHandler(
      delayMs: 800,
      handler: (options) => _registerPassword(options),
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
    final code = data?['sms_code']?.toString() ?? '';

    final isNewUser = code == '123456';

    return {
      'code': 0,
      'message': '登录成功',
      'data': {
        'access_token':
            'mock_access_token_${DateTime.now().millisecondsSinceEpoch}',
        'refresh_token':
            'mock_refresh_token_${DateTime.now().millisecondsSinceEpoch}',
        'expires_in': 7200,
        'user': {
          'uuid': 'user_001',
          'nickname': isNewUser ? '新项目方' : 'KAIZO 用户',
          'avatar_url': null,
          'role': isNewUser ? 0 : 1,
          'level': 1,
          'credit_score': 500,
          'is_verified': false,
        },
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
        'access_token':
            'mock_refreshed_token_${DateTime.now().millisecondsSinceEpoch}',
        'refresh_token':
            'mock_refreshed_refresh_${DateTime.now().millisecondsSinceEpoch}',
      },
    };
  }

  static Map<String, dynamic> _passwordKey() {
    return {
      'code': 0,
      'message': 'ok',
      'data': {
        'key_id': 'v1',
        'algorithm': 'RSA-OAEP-SHA256',
        'public_key_pem': _mockPublicKeyPem,
      },
    };
  }

  static Map<String, dynamic> _captcha() {
    return {
      'code': 0,
      'message': 'ok',
      'data': {
        'captcha_id':
            'mock_captcha_${DateTime.now().millisecondsSinceEpoch}',
        'image_base64': _mockCaptchaBase64,
        'expires_in': 300,
      },
    };
  }

  static Map<String, dynamic> _loginPassword(RequestOptions options) {
    return {
      'code': 0,
      'message': '登录成功',
      'data': {
        'access_token':
            'mock_pwd_token_${DateTime.now().millisecondsSinceEpoch}',
        'refresh_token':
            'mock_pwd_refresh_${DateTime.now().millisecondsSinceEpoch}',
        'expires_in': 7200,
        'user': {
          'uuid': 'user_001',
          'nickname': 'KAIZO 用户',
          'avatar_url': null,
          'role': 1,
          'level': 1,
          'credit_score': 500,
          'is_verified': false,
        },
      },
    };
  }

  static Map<String, dynamic> _registerPassword(RequestOptions options) {
    return {
      'code': 0,
      'message': '注册成功',
      'data': {
        'access_token':
            'mock_reg_token_${DateTime.now().millisecondsSinceEpoch}',
        'refresh_token':
            'mock_reg_refresh_${DateTime.now().millisecondsSinceEpoch}',
        'expires_in': 7200,
        'user': {
          'uuid': 'user_new_${DateTime.now().millisecondsSinceEpoch}',
          'nickname': (options.data as Map<String, dynamic>?)?['username'] ??
              'KAIZO 用户',
          'avatar_url': null,
          'role': 0,
          'level': 1,
          'credit_score': 500,
          'is_verified': false,
        },
      },
    };
  }

  // 1024-bit RSA test key pair (for mock/dev only)
  static const _mockPublicKeyPem = '''-----BEGIN RSA PUBLIC KEY-----
MIGJAoGBAM1Kf5RBkj7VdMrkvv5PsYCwACqfZF2v01T0rPMy8wPqoN1GF0dN+4
aO6WD7P3GJWLRFUbfUWp7c9eCR0FnzWLNLB+Ri7T2hQ5Y3DCXE7WiX8+k8tWx
cNQ3TPH1S9eHhKLFvn7gcCb5tXq4s6pZMv2H2VePTx2PcxPGbp8m7fAgMBAAE=
-----END RSA PUBLIC KEY-----''';

  // 1x1 transparent PNG as placeholder captcha
  static const _mockCaptchaBase64 =
      'iVBORw0KGgoAAAANSUhEUgAAAHgAAAAoCAYAAAA16j4lAAAA'
      'R0lEQVR42u3PMQEAAAgDoC251Y3g34MCCAAAAAAAAAAAAAAA'
      'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAB4Gg8x'
      'AAEB0VHbAAAAAElFTkSuQmCC';
}
