import 'package:dio/dio.dart';
import '../mock_interceptor.dart';

class TeamMock {
  TeamMock._();

  static void register(Map<String, MockHandler> handlers) {
    handlers['GET:/api/v1/teams'] = MockHandler(
      delayMs: 300,
      handler: (options) => _getTeamHall(options),
    );

    handlers['GET:/api/v1/teams/:id'] = MockHandler(
      delayMs: 250,
      handler: (options) => _getTeamDetail(options),
    );

    handlers['POST:/api/v1/team-posts'] = MockHandler(
      delayMs: 400,
      handler: (options) => _createTeamPost(options),
    );

    handlers['PUT:/api/v1/teams/:id/split-ratio'] = MockHandler(
      delayMs: 300,
      handler: (options) => _updateSplitRatio(options),
    );

    handlers['POST:/api/v1/teams/:id/invite'] = MockHandler(
      delayMs: 400,
      handler: (_) => _confirmTeam(),
    );

    handlers['POST:/api/v1/team-invites/:id'] = MockHandler(
      delayMs: 300,
      handler: (options) => _respondInvite(options),
    );

    handlers['GET:/api/v1/teams/ai-recommend'] = MockHandler(
      delayMs: 500,
      handler: (_) => _aiRecommend(),
    );
  }

  static Map<String, dynamic> _getTeamHall(RequestOptions options) {
    final role = options.queryParameters['role'] as String?;
    var posts = _allPosts();
    if (role != null && role.isNotEmpty) {
      posts = posts
          .where((p) {
            final roles = p['needed_roles'];
            if (roles is! List) return false;
            return roles.any((r) => r is Map && r['name'] == role);
          })
          .toList();
    }
    return {
      'code': 0,
      'message': 'ok',
      'data': {
        'ai_recommended': [_allPosts().first],
        'posts': posts,
      },
    };
  }

  static List<Map<String, dynamic>> _allPosts() {
    return [
      {
        'id': 'tp_001',
        'project_name': '智能客服系统 v2.0',
        'project_id': 'proj_001',
        'creator': {
          'id': 'user_002',
          'nickname': '李开发',
          'avatar': null,
        },
        'needed_roles': [
          {'name': 'Flutter开发', 'ratio': 40, 'filled': true},
          {'name': '后端开发', 'ratio': 35, 'filled': false},
          {'name': 'UI设计', 'ratio': 25, 'filled': false},
        ],
        'description': '寻找后端和UI同学组队，项目预算充足，已有需求文档',
        'filled_count': 1,
        'total_count': 3,
        'is_ai_recommended': true,
        'match_score': 92,
        'status': 'recruiting',
        'created_at': '2026-03-22T10:00:00Z',
      },
      {
        'id': 'tp_002',
        'project_name': '企业 ERP 管理系统',
        'project_id': 'proj_002',
        'creator': {
          'id': 'user_003',
          'nickname': '王产品',
          'avatar': null,
        },
        'needed_roles': [
          {'name': '全栈开发', 'ratio': 50, 'filled': false},
          {'name': '测试工程师', 'ratio': 20, 'filled': false},
          {'name': '产品经理', 'ratio': 30, 'filled': true},
        ],
        'description': '大型ERP项目，需要全栈和测试同学，周期3个月',
        'filled_count': 1,
        'total_count': 3,
        'is_ai_recommended': false,
        'match_score': 78,
        'status': 'recruiting',
        'created_at': '2026-03-21T15:30:00Z',
      },
      {
        'id': 'tp_003',
        'project_name': '社交电商小程序',
        'project_id': 'proj_003',
        'creator': {
          'id': 'user_004',
          'nickname': '赵设计',
          'avatar': null,
        },
        'needed_roles': [
          {'name': 'Flutter开发', 'ratio': 45, 'filled': false},
          {'name': 'UI设计', 'ratio': 30, 'filled': true},
          {'name': '后端开发', 'ratio': 25, 'filled': true},
        ],
        'description': '差一个Flutter开发就齐了，UI和后端已就位',
        'filled_count': 2,
        'total_count': 3,
        'is_ai_recommended': false,
        'match_score': 85,
        'status': 'recruiting',
        'created_at': '2026-03-20T09:00:00Z',
      },
      {
        'id': 'tp_004',
        'project_name': '在线教育平台',
        'project_id': 'proj_004',
        'creator': {
          'id': 'user_005',
          'nickname': '孙老师',
          'avatar': null,
        },
        'needed_roles': [
          {'name': '前端开发', 'ratio': 35, 'filled': false},
          {'name': '后端开发', 'ratio': 35, 'filled': false},
          {'name': 'DevOps', 'ratio': 15, 'filled': false},
          {'name': '产品经理', 'ratio': 15, 'filled': true},
        ],
        'description': '教育领域项目，有成熟的商业模式，欢迎各角色加入',
        'filled_count': 1,
        'total_count': 4,
        'is_ai_recommended': false,
        'match_score': 70,
        'status': 'recruiting',
        'created_at': '2026-03-19T14:20:00Z',
      },
    ];
  }

  static Map<String, dynamic> _getTeamDetail(RequestOptions options) {
    return {
      'code': 0,
      'message': 'ok',
      'data': {
        'id': 'team_001',
        'project_name': '智能客服系统 v2.0',
        'project_id': 'proj_001',
        'status': 'confirming',
        'members': [
          {
            'id': 'user_002',
            'nickname': '李开发',
            'avatar': null,
            'role': 'Flutter开发',
            'ratio': 40,
            'is_leader': true,
            'status': 'accepted',
          },
          {
            'id': 'user_001',
            'nickname': '张恒',
            'avatar': null,
            'role': '后端开发',
            'ratio': 35,
            'is_leader': false,
            'status': 'accepted',
          },
          {
            'id': 'user_006',
            'nickname': '周设计',
            'avatar': null,
            'role': 'UI设计',
            'ratio': 25,
            'is_leader': false,
            'status': 'accepted',
          },
        ],
        'created_at': '2026-03-22T10:00:00Z',
      },
    };
  }

  static Map<String, dynamic> _createTeamPost(RequestOptions options) {
    return {
      'code': 0,
      'message': '寻人帖发布成功',
      'data': {
        'id': 'tp_${DateTime.now().millisecondsSinceEpoch}',
        'status': 'recruiting',
      },
    };
  }

  static Map<String, dynamic> _updateSplitRatio(RequestOptions options) {
    return {
      'code': 0,
      'message': '分成比例已更新',
      'data': options.data,
    };
  }

  static Map<String, dynamic> _confirmTeam() {
    return {
      'code': 0,
      'message': '组队确认成功，已通知所有成员',
      'data': {'status': 'confirmed'},
    };
  }

  static Map<String, dynamic> _respondInvite(RequestOptions options) {
    final accept = (options.data as Map<String, dynamic>?)?['accept'] ?? true;
    return {
      'code': 0,
      'message': accept ? '已接受邀请' : '已拒绝邀请',
      'data': {'status': accept ? 'accepted' : 'rejected'},
    };
  }

  static Map<String, dynamic> _aiRecommend() {
    return {
      'code': 0,
      'message': 'ok',
      'data': [
        {
          'team_post_id': 'tp_001',
          'match_score': 92,
          'reason': '您的 Go 和 Flutter 技能与项目需求高度匹配',
        },
      ],
    };
  }
}
