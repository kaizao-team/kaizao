import '../mock_interceptor.dart';

/// PROJECT 模块 Mock 数据
class ProjectMock {
  ProjectMock._();

  static void register(Map<String, MockHandler> handlers) {
    handlers['GET:/api/v1/projects'] = MockHandler(
      handler: (_) => _projectList(),
    );
  }

  static Map<String, dynamic> _projectList() {
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
          'category': 'app',
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
          'category': 'web',
          'budget_min': 2000,
          'budget_max': 5000,
          'progress': 30,
          'status': 5,
          'tech_requirements': ['Vue.js', 'TailwindCSS'],
          'view_count': 89,
          'bid_count': 3,
          'created_at': '2026-03-18T14:30:00Z',
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
