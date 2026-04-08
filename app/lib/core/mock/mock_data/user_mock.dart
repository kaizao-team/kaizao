import 'package:dio/dio.dart';
import '../mock_interceptor.dart';

/// USER 模块 Mock 数据
class UserMock {
  UserMock._();

  static Map<String, dynamic> _currentUser = {
    'id': 'user_001',
    'uuid': 'user_001',
    'nickname': 'KAIZO 用户',
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

  static void mergeCurrentUser(Map<String, dynamic> data) {
    _currentUser = {
      ..._currentUser,
      ...data,
    };
  }

  static void register(Map<String, MockHandler> handlers) {
    handlers['GET:/api/v1/users/me'] = MockHandler(
      handler: (_) => _getCurrentUser(),
    );

    handlers['PUT:/api/v1/users/me'] = MockHandler(
      handler: (options) => _updateUser(options),
    );
  }

  static Map<String, dynamic> _getCurrentUser() {
    final role = _currentUser['role'] as int? ?? 1;
    final isTeam = role == 2 || role == 3;
    final data = <String, dynamic>{
      'id': _currentUser['uuid'] ?? 'user_001',
      'uuid': _currentUser['uuid'] ?? 'user_001',
      'nickname': _currentUser['nickname'] ?? '张恒',
      'avatar_url': _currentUser['avatar_url'],
      'role': role,
      'bio': _currentUser['bio'] ?? '5年全栈开发经验，擅长 Flutter 和 Go 后端开发。',
      'city': _currentUser['city'],
      'is_verified': _currentUser['is_verified'] ?? true,
      'credit_score': _currentUser['credit_score'] ?? 920,
      'level': _currentUser['level'] ?? 1,
      'total_orders': isTeam ? 12 : 0,
      'completed_orders': isTeam ? 12 : 0,
      'completion_rate': isTeam ? 100.0 : 0.0,
      'avg_rating': 4.9,
      'hourly_rate': isTeam ? (_currentUser['hourly_rate'] ?? 300) : null,
      'available_status': _currentUser['available_status'] ?? 1,
      'onboarding_status': 2,
      'skills': _currentUser['skills'] ?? <String>[],
      'role_tags': _currentUser['role_tags'] ?? <String>[],
      'phone': '138****8888',
      'wechat_bound': true,
      'tagline': '全栈 Vibe Coder',
      'stats': {
        'completed_projects': isTeam ? 12 : 0,
        'approval_rate': 98,
        'avg_delivery_days': 3.2,
        'total_earnings': isTeam ? 86500.0 : 0.0,
        'published_projects': role == 1 ? 5 : 0,
        'total_spent': role == 1 ? 42000.0 : 0.0,
        'days_on_platform': 285,
      },
      'created_at': '2025-06-15T10:00:00Z',
    };
    return {
      'code': 0,
      'message': 'ok',
      'data': data,
    };
  }

  static Map<String, dynamic> _updateUser(RequestOptions options) {
    final data = options.data as Map<String, dynamic>? ?? {};
    final normalized = Map<String, dynamic>.from(data);
    if (normalized['avatar_url'] == '') {
      normalized['avatar_url'] = null;
    }
    mergeCurrentUser(normalized);

    return {
      'code': 0,
      'message': '更新成功',
      'data': currentUserData,
    };
  }
}
