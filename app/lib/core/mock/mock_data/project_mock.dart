import '../mock_interceptor.dart';

class ProjectMock {
  ProjectMock._();

  static void register(Map<String, MockHandler> handlers) {
    handlers['GET:/api/v1/projects'] = MockHandler(
      handler: (options) {
        final role = options.queryParameters['role']?.toString() ?? '1';
        if (role == '2') return _expertProjectList();
        return _demanderProjectList();
      },
    );
  }

  static Map<String, dynamic> _demanderProjectList() {
    return {
      'code': 0,
      'message': 'ok',
      'data': [
        {
          'id': '1',
          'uuid': 'proj_001',
          'owner_id': 'user_001',
          'title': '智能客服系统',
          'description': '开发一款基于AI的智能客服聊天机器人，支持多轮对话和知识库检索',
          'category': 'dev',
          'budget_min': 3000,
          'budget_max': 8000,
          'progress': 68,
          'status': 5,
          'tech_requirements': ['Flutter', 'GPT-4', 'WebSocket'],
          'view_count': 126,
          'bid_count': 5,
          'created_at': '2026-03-15T10:00:00Z',
        },
        {
          'id': '2',
          'uuid': 'proj_002',
          'owner_id': 'user_001',
          'title': '企业官网改版',
          'description': '将现有官网升级为响应式设计，适配移动端和PC端',
          'category': 'dev',
          'budget_min': 2000,
          'budget_max': 5000,
          'progress': 30,
          'status': 5,
          'tech_requirements': ['Vue.js', 'TailwindCSS'],
          'view_count': 89,
          'bid_count': 3,
          'created_at': '2026-03-18T14:30:00Z',
        },
        {
          'id': '3',
          'uuid': 'proj_003',
          'owner_id': 'user_001',
          'title': 'AI写作助手',
          'description': '基于大语言模型的智能写作辅助工具',
          'category': 'dev',
          'budget_min': 5000,
          'budget_max': 10000,
          'progress': 0,
          'status': 2,
          'tech_requirements': ['React', 'OpenAI', 'Python'],
          'view_count': 45,
          'bid_count': 0,
          'created_at': '2026-03-22T09:00:00Z',
        },
      ],
      'meta': {
        'page': 1,
        'page_size': 20,
        'total': 3,
        'total_pages': 1,
      },
    };
  }

  static Map<String, dynamic> _expertProjectList() {
    return {
      'code': 0,
      'message': 'ok',
      'data': [
        {
          'id': '10',
          'uuid': 'proj_010',
          'owner_id': 'user_010',
          'provider_id': 'user_self',
          'title': '在线教育平台',
          'description': '支持直播、录播、互动课堂的教育平台',
          'category': 'dev',
          'budget_min': 8000,
          'budget_max': 15000,
          'agreed_price': 12000,
          'progress': 45,
          'status': 5,
          'tech_requirements': ['Flutter', 'WebRTC', 'Node.js'],
          'view_count': 56,
          'bid_count': 2,
          'created_at': '2026-03-10T09:00:00Z',
        },
        {
          'id': '11',
          'uuid': 'proj_011',
          'owner_id': 'user_011',
          'provider_id': 'user_self',
          'title': 'SaaS 管理后台',
          'description': '企业级SaaS后台管理系统',
          'category': 'dev',
          'budget_min': 5000,
          'budget_max': 12000,
          'agreed_price': 9500,
          'progress': 80,
          'status': 5,
          'tech_requirements': ['React', 'TypeScript', 'Go'],
          'view_count': 43,
          'bid_count': 4,
          'created_at': '2026-03-05T15:00:00Z',
        },
      ],
      'meta': {
        'page': 1,
        'page_size': 20,
        'total': 2,
        'total_pages': 1,
      },
    };
  }
}
