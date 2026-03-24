import 'package:dio/dio.dart';
import '../mock_interceptor.dart';

/// USER 模块 Mock 数据
class UserMock {
  UserMock._();

  static void register(Map<String, MockHandler> handlers) {
    handlers['GET:/api/v1/users/me'] = MockHandler(
      handler: (_) => _currentUser(),
    );

    handlers['PUT:/api/v1/users/me'] = MockHandler(
      handler: (options) => _updateUser(options),
    );
  }

  static Map<String, dynamic> _currentUser() {
    return {
      'code': 0,
      'message': 'ok',
      'data': {
        'id': '1',
        'uuid': 'user_001',
        'nickname': '开造用户',
        'avatar_url': null,
        'role': 1,
        'bio': null,
        'city': null,
        'is_verified': false,
        'credit_score': 500,
        'level': 1,
        'total_orders': 0,
        'completed_orders': 0,
        'completion_rate': 0.0,
        'avg_rating': 0.0,
        'hourly_rate': null,
        'available_status': 1,
        'skills': <String>[],
        'role_tags': <String>[],
      },
    };
  }

  static Map<String, dynamic> _updateUser(RequestOptions options) {
    return {
      'code': 0,
      'message': '更新成功',
      'data': null,
    };
  }
}
