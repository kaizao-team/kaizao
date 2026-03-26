import 'package:dio/dio.dart';
import '../mock_interceptor.dart';

/// USER 模块 Mock 数据
class UserMock {
  UserMock._();

  static Map<String, dynamic> _currentUser = {
    'id': 'user_001',
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
  };

  static Map<String, dynamic> get currentUserData =>
      Map<String, dynamic>.from(_currentUser);

  static void register(Map<String, MockHandler> handlers) {
    handlers['GET:/api/v1/users/me'] = MockHandler(
      handler: (_) => _getCurrentUser(),
    );

    handlers['PUT:/api/v1/users/me'] = MockHandler(
      handler: (options) => _updateUser(options),
    );
  }

  static Map<String, dynamic> _getCurrentUser() {
    return {
      'code': 0,
      'message': 'ok',
      'data': currentUserData,
    };
  }

  static Map<String, dynamic> _updateUser(RequestOptions options) {
    final data = options.data as Map<String, dynamic>? ?? {};
    _currentUser = {
      ..._currentUser,
      ...data,
    };

    return {
      'code': 0,
      'message': '更新成功',
      'data': currentUserData,
    };
  }
}
