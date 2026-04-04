import 'package:dio/dio.dart';
import '../mock_interceptor.dart';

class MatchMock {
  MatchMock._();

  static void register(Map<String, MockHandler> handlers) {
    handlers['GET:/api/v1/projects/:id/bids'] = MockHandler(
      delayMs: 400,
      handler: (options) => _bidList(options),
    );

    handlers['POST:/api/v1/projects/:id/bids'] = MockHandler(
      delayMs: 600,
      handler: (options) => _submitBid(options),
    );

    handlers['POST:/api/v1/bids/:id/accept'] = MockHandler(
      delayMs: 400,
      handler: (_) => _acceptBid(),
    );

    handlers['PUT:/api/v1/bids/:id/withdraw'] = MockHandler(
      delayMs: 400,
      handler: (_) => _withdrawBid(),
    );

    handlers['GET:/api/v1/projects/:id/recommendations'] = MockHandler(
      delayMs: 700,
      handler: (options) => _recommendations(options),
    );

    handlers['POST:/api/v1/projects/:id/quick-match'] = MockHandler(
      delayMs: 700,
      handler: (options) => _quickMatch(options),
    );

    handlers['GET:/api/v1/projects/:id/ai-suggestion'] = MockHandler(
      delayMs: 500,
      handler: (_) => _aiSuggestion(),
    );
  }

  static Map<String, dynamic> _bidList(RequestOptions options) {
    return {
      'code': 0,
      'message': 'ok',
      'data': [
        {
          'id': 'bid_001',
          'user_id': 'user_201',
          'user_name': '张开发',
          'avatar': null,
          'rating': 4.9,
          'completion_rate': 98,
          'match_score': 95,
          'bid_amount': 5000,
          'duration_days': 14,
          'proposal': '拥有5年Flutter开发经验，主导过多个大型App项目。对本项目的技术栈非常熟悉，可以保证高质量交付。',
          'bid_type': 'personal',
          'team_name': null,
          'team_members': [],
          'is_ai_recommended': true,
          'skills': ['Flutter', 'Go', 'WebSocket'],
          'created_at': '2026-03-20T10:00:00Z',
          'status': 1,
        },
        {
          'id': 'bid_002',
          'user_id': 'user_202',
          'user_name': '李设计',
          'avatar': null,
          'rating': 4.7,
          'completion_rate': 95,
          'match_score': 88,
          'bid_amount': 4500,
          'duration_days': 12,
          'proposal': '全栈开发者，擅长从UI设计到后端实现的全流程开发，能快速理解需求并高效交付。',
          'bid_type': 'personal',
          'team_name': null,
          'team_members': [],
          'is_ai_recommended': false,
          'skills': ['Flutter', 'Vue.js', 'Node.js'],
          'created_at': '2026-03-20T12:00:00Z',
          'status': 1,
        },
        {
          'id': 'bid_003',
          'user_id': 'user_203',
          'user_name': '创新工作室',
          'avatar': null,
          'rating': 4.8,
          'completion_rate': 97,
          'match_score': 82,
          'bid_amount': 7000,
          'duration_days': 10,
          'proposal': '我们是一支3人全栈团队，能够并行开发前后端，大幅缩短交付时间。',
          'bid_type': 'team',
          'team_name': '创新工作室',
          'status': 2,
          'team_members': [
            {'name': '王前端', 'role': '前端开发'},
            {'name': '赵后端', 'role': '后端开发'},
            {'name': '陈测试', 'role': '测试'},
          ],
          'is_ai_recommended': false,
          'skills': ['Flutter', 'Go', 'PostgreSQL'],
          'created_at': '2026-03-20T14:00:00Z',
        },
        {
          'id': 'bid_004',
          'user_id': 'user_204',
          'user_name': '周工程师',
          'avatar': null,
          'rating': 4.5,
          'completion_rate': 92,
          'match_score': 76,
          'bid_amount': 3800,
          'duration_days': 18,
          'proposal': '稳扎稳打型开发者，注重代码质量和文档完善，交付后提供30天免费维护。',
          'bid_type': 'personal',
          'team_name': null,
          'team_members': [],
          'is_ai_recommended': false,
          'skills': ['Flutter', 'Python'],
          'created_at': '2026-03-21T09:00:00Z',
          'status': 1,
        },
      ],
    };
  }

  static Map<String, dynamic> _submitBid(RequestOptions options) {
    return {
      'code': 0,
      'message': '投标成功',
      'data': {
        'bid_id': 'bid_new_001',
        'status': 'submitted',
      },
    };
  }

  static Map<String, dynamic> _acceptBid() {
    return {
      'code': 0,
      'message': '已选定团队',
      'data': {'status': 'accepted'},
    };
  }

  static Map<String, dynamic> _withdrawBid() {
    return {
      'code': 0,
      'message': '投标已撤回',
      'data': {'status': 'withdrawn'},
    };
  }

  static List<Map<String, dynamic>> _mockRecommendations() {
    return [
      {
        'provider_id': 'user_201',
        'user_id': 'user_201',
        'rank': 1,
        'match_score': 95,
        'recommendation_reason': '技能栈与项目高度匹配，历史交付稳定。',
        'highlight_skills': ['Flutter', 'Go', 'WebSocket'],
        'team_id': null,
        'team_name': null,
        'nickname': '张开发',
        'avatar_url': null,
        'rating': 4.9,
        'completion_rate': 98,
        'primary_skill': 'Flutter',
        'skill': 'Flutter',
        'bid_type': 'personal',
      },
      {
        'provider_id': 'user_203',
        'user_id': 'user_203',
        'rank': 2,
        'match_score': 88,
        'recommendation_reason': '适合需要更完整协作配合的项目。',
        'highlight_skills': ['Flutter', 'Go', 'PostgreSQL'],
        'team_id': null,
        'team_name': '创新工作室',
        'nickname': '创新工作室',
        'avatar_url': null,
        'rating': 4.8,
        'completion_rate': 97,
        'primary_skill': 'Flutter',
        'skill': 'Flutter',
        'bid_type': 'team',
      },
    ];
  }

  static Map<String, dynamic> _recommendations(RequestOptions options) {
    final pathSegments = options.path.split('/');
    final projectId = pathSegments.length >= 5
        ? pathSegments[pathSegments.length - 2]
        : 'proj_001';
    final items = _mockRecommendations();

    return {
      'code': 0,
      'message': 'ok',
      'data': {
        'demand_id': projectId,
        'match_type': 'recommend_providers',
        'experts': items,
        'recommendations': items,
        'overall_suggestion': '建议优先联系排名靠前的服务方。',
        'no_match_reason': null,
        'meta': {
          'total_candidates_scanned': 12,
          'processing_time_ms': 680,
        },
      },
    };
  }

  static Map<String, dynamic> _quickMatch(RequestOptions options) {
    final chosen = _mockRecommendations().first;
    return {
      'code': 0,
      'message': '快速匹配完成，已选定服务方',
      'data': {
        'status': 'accepted',
        'bid_id': 'bid_quick_001',
        'provider_id': chosen['provider_id'],
        'match_score': chosen['match_score'],
        'recommendation_reason': chosen['recommendation_reason'],
        'highlight_skills': chosen['highlight_skills'],
        'dimension_scores': {
          'skill_match': 95,
          'rating': 90,
          'price_match': 84,
        },
        'agreed_price': 6800,
        'estimated_duration_days': 14,
      },
    };
  }

  static Map<String, dynamic> _aiSuggestion() {
    return {
      'code': 0,
      'message': 'ok',
      'data': {
        'suggested_price_min': 4000,
        'suggested_price_max': 8000,
        'suggested_duration_days': 14,
        'skill_match_score': 85,
        'reason': '基于项目复杂度和市场行情，建议报价 ¥4,000-¥8,000，工期约2周',
      },
    };
  }
}
