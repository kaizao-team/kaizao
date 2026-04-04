import 'package:dio/dio.dart';
import '../mock_interceptor.dart';

class FavoriteMock {
  FavoriteMock._();

  static void register(Map<String, MockHandler> handlers) {
    handlers['POST:/api/v1/favorites'] = MockHandler(
      delayMs: 300,
      handler: (options) => _addFavorite(options),
    );

    handlers['DELETE:/api/v1/favorites'] = MockHandler(
      delayMs: 300,
      handler: (_) => _removeFavorite(),
    );

    handlers['GET:/api/v1/users/me/favorites'] = MockHandler(
      delayMs: 400,
      handler: (options) => _getMyFavorites(options),
    );
  }

  static Map<String, dynamic> _addFavorite(RequestOptions options) {
    return {
      'code': 0,
      'message': '收藏成功',
      'data': {
        'id': 'fav_${DateTime.now().millisecondsSinceEpoch}',
      },
    };
  }

  static Map<String, dynamic> _removeFavorite() {
    return {
      'code': 0,
      'message': '已取消收藏',
      'data': null,
    };
  }

  static Map<String, dynamic> _getMyFavorites(RequestOptions options) {
    final targetType = options.queryParameters['target_type'];

    final allItems = <Map<String, dynamic>>[
      {
        'id': 'fav_001',
        'target_type': 'project',
        'target_id': 'proj_001',
        'created_at': '2026-04-04T12:00:00Z',
        'title': '电商小程序开发',
        'status': 2,
        'category': 'mini-program',
        'budget_min': 5000,
        'budget_max': 10000,
      },
      {
        'id': 'fav_002',
        'target_type': 'project',
        'target_id': 'proj_002',
        'created_at': '2026-04-03T08:00:00Z',
        'title': '企业级 SaaS 管理后台',
        'status': 2,
        'category': 'web-app',
        'budget_min': 15000,
        'budget_max': 30000,
      },
      {
        'id': 'fav_003',
        'target_type': 'expert',
        'target_id': 'user_201',
        'created_at': '2026-04-02T10:00:00Z',
        'nickname': '张开发',
        'avatar_url': null,
        'rating': 4.9,
      },
      {
        'id': 'fav_004',
        'target_type': 'expert',
        'target_id': 'user_202',
        'created_at': '2026-04-01T14:00:00Z',
        'nickname': '李设计',
        'avatar_url': null,
        'rating': 4.7,
      },
    ];

    final filtered = targetType != null
        ? allItems.where((e) => e['target_type'] == targetType).toList()
        : allItems;

    return {
      'code': 0,
      'message': 'success',
      'data': filtered,
      'meta': {
        'page': 1,
        'page_size': 20,
        'total': filtered.length,
        'total_pages': 1,
      },
    };
  }
}
