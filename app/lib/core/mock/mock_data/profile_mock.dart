import 'package:dio/dio.dart';
import '../mock_interceptor.dart';

class ProfileMock {
  ProfileMock._();

  static void register(Map<String, MockHandler> handlers) {
    handlers['GET:/api/v1/users/:id'] = MockHandler(
      delayMs: 300,
      handler: (options) => _getUserProfile(options),
    );

    handlers['PUT:/api/v1/users/:id'] = MockHandler(
      delayMs: 400,
      handler: (options) => _updateProfile(options),
    );

    handlers['GET:/api/v1/users/:id/skills'] = MockHandler(
      delayMs: 200,
      handler: (_) => _getSkills(),
    );

    handlers['PUT:/api/v1/users/:id/skills'] = MockHandler(
      delayMs: 300,
      handler: (options) => _updateSkills(options),
    );

    handlers['GET:/api/v1/users/:id/portfolios'] = MockHandler(
      delayMs: 300,
      handler: (_) => _getPortfolios(),
    );

    handlers['GET:/api/v1/users/me'] = MockHandler(
      delayMs: 200,
      handler: (_) => _getCurrentUser(),
    );
  }

  static Map<String, dynamic> _getUserProfile(RequestOptions options) {
    final pathParts = options.path.split('/');
    final userId = pathParts[4];
    final isSelf = userId == 'user_001';

    return {
      'code': 0,
      'message': 'ok',
      'data': {
        'id': userId,
        'nickname': isSelf ? '张恒' : '李开发',
        'avatar': null,
        'tagline': isSelf ? '全栈 Vibe Coder' : 'Flutter 资深工程师',
        'role': isSelf ? 1 : 2,
        'rating': isSelf ? 4.9 : 4.7,
        'credit_score': isSelf ? 920 : 880,
        'is_verified': true,
        'phone': '138****8888',
        'wechat_bound': true,
        'stats': {
          'completed_projects': isSelf ? 12 : 28,
          'approval_rate': isSelf ? 98 : 95,
          'avg_delivery_days': isSelf ? 3.2 : 4.1,
          'total_earnings': isSelf ? 86500.0 : 156800.0,
        },
        'bio': isSelf
            ? '5年全栈开发经验，擅长 Flutter 和 Go 后端开发，热衷于用 AI 提升开发效率。'
            : '资深移动端开发者，主攻 Flutter 跨平台方案，交付过20+商业项目。',
        'created_at': '2025-06-15T10:00:00Z',
      },
    };
  }

  static Map<String, dynamic> _getCurrentUser() {
    return {
      'code': 0,
      'message': 'ok',
      'data': {
        'id': 'user_001',
        'nickname': '张恒',
        'avatar': null,
        'tagline': '全栈 Vibe Coder',
        'role': 1,
        'rating': 4.9,
        'credit_score': 920,
        'is_verified': true,
        'phone': '138****8888',
        'wechat_bound': true,
        'stats': {
          'completed_projects': 12,
          'approval_rate': 98,
          'avg_delivery_days': 3.2,
          'total_earnings': 86500.0,
        },
        'bio': '5年全栈开发经验，擅长 Flutter 和 Go 后端开发。',
        'created_at': '2025-06-15T10:00:00Z',
      },
    };
  }

  static Map<String, dynamic> _updateProfile(RequestOptions options) {
    return {
      'code': 0,
      'message': '资料更新成功',
      'data': options.data,
    };
  }

  static Map<String, dynamic> _getSkills() {
    return {
      'code': 0,
      'message': 'ok',
      'data': [
        {'id': 'skill_01', 'name': 'Flutter', 'category': 'mobile'},
        {'id': 'skill_02', 'name': 'Go', 'category': 'backend'},
        {'id': 'skill_03', 'name': 'React', 'category': 'frontend'},
        {'id': 'skill_04', 'name': 'Node.js', 'category': 'backend'},
        {'id': 'skill_05', 'name': 'PostgreSQL', 'category': 'database'},
        {'id': 'skill_06', 'name': 'AI/ML', 'category': 'ai'},
        {'id': 'skill_07', 'name': 'Docker', 'category': 'devops'},
        {'id': 'skill_08', 'name': 'Figma', 'category': 'design'},
      ],
    };
  }

  static Map<String, dynamic> _updateSkills(RequestOptions options) {
    return {
      'code': 0,
      'message': '技能更新成功',
      'data': options.data,
    };
  }

  static Map<String, dynamic> _getPortfolios() {
    return {
      'code': 0,
      'message': 'ok',
      'data': [
        {
          'id': 'pf_01',
          'title': '智能客服系统',
          'cover_url': 'https://picsum.photos/seed/pf01/400/300',
          'description': '基于 GPT-4 的多轮对话客服系统',
          'tags': ['Flutter', 'AI', 'WebSocket'],
          'created_at': '2026-01-15T10:00:00Z',
        },
        {
          'id': 'pf_02',
          'title': '企业 SaaS 平台',
          'cover_url': 'https://picsum.photos/seed/pf02/400/300',
          'description': '面向中小企业的项目管理和协作工具',
          'tags': ['React', 'Go', 'PostgreSQL'],
          'created_at': '2025-11-20T10:00:00Z',
        },
        {
          'id': 'pf_03',
          'title': '短视频社区 App',
          'cover_url': 'https://picsum.photos/seed/pf03/400/300',
          'description': '日活10万+的短视频UGC社区',
          'tags': ['Flutter', 'FFmpeg', 'CDN'],
          'created_at': '2025-08-10T10:00:00Z',
        },
        {
          'id': 'pf_04',
          'title': '智慧物流调度系统',
          'cover_url': 'https://picsum.photos/seed/pf04/400/300',
          'description': 'AI驱动的物流路径优化和订单调度',
          'tags': ['Go', 'ML', 'GIS'],
          'created_at': '2025-05-01T10:00:00Z',
        },
      ],
    };
  }
}
