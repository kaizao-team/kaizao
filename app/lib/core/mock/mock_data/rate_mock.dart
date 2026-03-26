import 'package:dio/dio.dart';
import '../mock_interceptor.dart';

class RateMock {
  RateMock._();

  static void register(Map<String, MockHandler> handlers) {
    handlers['POST:/api/v1/reviews'] = MockHandler(
      delayMs: 400,
      handler: (options) => _submitReview(options),
    );

    handlers['GET:/api/v1/projects/:id/reviews'] = MockHandler(
      delayMs: 300,
      handler: (options) => _getProjectReviews(options),
    );
  }

  static Map<String, dynamic> _submitReview(RequestOptions options) {
    return {
      'code': 0,
      'message': '评价提交成功',
      'data': {
        'review_id': 'rev_${DateTime.now().millisecondsSinceEpoch}',
        'status': 'published',
      },
    };
  }

  static Map<String, dynamic> _getProjectReviews(RequestOptions options) {
    return {
      'code': 0,
      'message': 'ok',
      'data': [
        {
          'id': 'rev_001',
          'reviewer': {
            'id': 'user_001',
            'nickname': '张恒',
            'avatar': null,
            'role': 'demander',
          },
          'reviewee': {
            'id': 'user_002',
            'nickname': '李开发',
            'avatar': null,
            'role': 'expert',
          },
          'overall_rating': 4.5,
          'dimensions': [
            {'name': '代码质量', 'rating': 5.0},
            {'name': '沟通效率', 'rating': 4.0},
            {'name': '交付时效', 'rating': 4.5},
          ],
          'comment': '非常专业的开发者，代码质量很高，沟通也很顺畅，按时交付了所有功能。',
          'created_at': '2026-03-20T10:00:00Z',
        },
        {
          'id': 'rev_002',
          'reviewer': {
            'id': 'user_002',
            'nickname': '李开发',
            'avatar': null,
            'role': 'expert',
          },
          'reviewee': {
            'id': 'user_001',
            'nickname': '张恒',
            'avatar': null,
            'role': 'demander',
          },
          'overall_rating': 5.0,
          'dimensions': [
            {'name': '需求清晰度', 'rating': 5.0},
            {'name': '付款及时性', 'rating': 5.0},
          ],
          'comment': '非常好的甲方，需求文档详尽清晰，付款及时，沟通高效，期待下次合作！',
          'created_at': '2026-03-20T10:30:00Z',
        },
      ],
    };
  }
}
