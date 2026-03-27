import 'package:dio/dio.dart';
import '../mock_interceptor.dart';
import 'market_mock.dart';

class PostMock {
  PostMock._();

  static int _draftCount = 0;

  static void register(Map<String, MockHandler> handlers) {
    handlers['POST:/api/v1/projects/ai-chat'] = MockHandler(
      delayMs: 800,
      handler: (options) => _aiChat(options),
    );

    handlers['POST:/api/v1/projects/generate-prd'] = MockHandler(
      delayMs: 2000,
      handler: (options) => _generatePrd(options),
    );

    handlers['POST:/api/v1/projects/draft'] = MockHandler(
      delayMs: 300,
      handler: (options) => _saveDraft(options),
    );

    handlers['PUT:/api/v1/projects/:id'] = MockHandler(
      delayMs: 300,
      handler: (options) => _updateDraft(options),
    );

    handlers['POST:/api/v1/projects/:id/publish'] = MockHandler(
      delayMs: 300,
      handler: (options) => _publishDraft(options),
    );

    handlers['POST:/api/v1/projects'] = MockHandler(
      delayMs: 500,
      handler: (options) => _publishProject(options),
    );
  }

  static int _turnCount = 0;

  static Map<String, dynamic> _aiChat(RequestOptions options) {
    final data = options.data as Map<String, dynamic>? ?? {};
    final userMessage = data['message'] as String? ?? '';
    _turnCount++;

    String reply;
    bool canGeneratePrd = false;

    if (_turnCount == 1) {
      reply = '好的，我来帮你梳理需求。你提到「$userMessage」，能详细说说你期望的核心功能有哪些吗？比如用户端需要哪些主要页面？';
    } else if (_turnCount == 2) {
      reply =
          '明白了，我整理一下：\n\n1. **用户注册/登录** — 手机号 + 短信验证\n2. **首页推荐** — 个性化内容推荐\n3. **核心功能模块** — 根据你描述的业务场景\n4. **个人中心** — 账号管理与设置\n\n你对技术栈有偏好吗？需要支持哪些平台？';
    } else if (_turnCount == 3) {
      reply =
          '需求已经比较清晰了！我帮你总结一下：\n\n📋 **项目概要**\n- 平台：移动端 (iOS + Android)\n- 核心模块：3-4个主要功能\n- 预计工期：4-6周\n- 技术建议：Flutter + Go 后端\n\n信息足够生成 PRD 了，你可以点击「生成PRD」按钮，我会帮你生成完整的需求文档。';
      canGeneratePrd = true;
    } else {
      reply = '好的，我已经记录了你的补充。你还有其他要补充的吗？信息已经足够生成 PRD 了。';
      canGeneratePrd = true;
    }

    return {
      'code': 0,
      'message': 'ok',
      'data': {
        'reply': reply,
        'can_generate_prd': canGeneratePrd,
        'turn': _turnCount,
      },
    };
  }

  static Map<String, dynamic> _generatePrd(RequestOptions options) {
    _turnCount = 0;
    return {
      'code': 0,
      'message': 'ok',
      'data': {
        'prd_id': 'prd_mock_001',
        'title': '智能协作平台 PRD',
        'modules': [
          {
            'id': 'mod_auth',
            'name': '认证模块',
            'cards': [
              {
                'id': 'card_001',
                'module_id': 'mod_auth',
                'title': '手机号登录',
                'type': 'event',
                'priority': 'P0',
                'description': '用户通过手机号和短信验证码完成登录',
                'event': '用户输入手机号并点击获取验证码',
                'action': '系统发送短信验证码，用户输入后验证',
                'response': '验证成功跳转首页，失败提示错误',
                'state_change': '用户状态从未登录变为已登录',
                'acceptance_criteria': [
                  {
                    'id': 'ac_001',
                    'content': '手机号格式校验（11位数字）',
                    'checked': false
                  },
                  {'id': 'ac_002', 'content': '验证码60秒倒计时', 'checked': false},
                  {'id': 'ac_003', 'content': '3次错误后锁定5分钟', 'checked': false},
                ],
                'roles': ['frontend', 'backend'],
                'effort_hours': 8,
                'dependencies': [],
                'tech_tags': ['Flutter', 'SMS SDK'],
                'status': 'pending',
              },
              {
                'id': 'card_002',
                'module_id': 'mod_auth',
                'title': '自动登录',
                'type': 'state',
                'priority': 'P1',
                'description': 'App启动时检查Token有效性，自动登录',
                'event': 'App冷启动',
                'action': '检查本地Token是否存在且未过期',
                'response': 'Token有效直接进入首页，无效跳转登录页',
                'state_change': '从启动态切换为已登录或未登录',
                'acceptance_criteria': [
                  {'id': 'ac_004', 'content': 'Token过期自动刷新', 'checked': false},
                  {'id': 'ac_005', 'content': '刷新失败跳转登录页', 'checked': false},
                ],
                'roles': ['frontend'],
                'effort_hours': 4,
                'dependencies': ['card_001'],
                'tech_tags': ['JWT', 'SharedPreferences'],
                'status': 'pending',
              },
            ],
          },
          {
            'id': 'mod_home',
            'name': '首页模块',
            'cards': [
              {
                'id': 'card_003',
                'module_id': 'mod_home',
                'title': '个性化推荐',
                'type': 'response',
                'priority': 'P0',
                'description': '首页展示个性化推荐内容',
                'event': '用户进入首页',
                'action': '根据用户画像和浏览历史请求推荐数据',
                'response': '展示推荐卡片列表，支持下拉刷新',
                'state_change': '首页数据加载完成',
                'acceptance_criteria': [
                  {'id': 'ac_006', 'content': '首屏加载时间 < 2秒', 'checked': false},
                  {'id': 'ac_007', 'content': '支持下拉刷新', 'checked': false},
                  {'id': 'ac_008', 'content': '无数据时展示空状态', 'checked': false},
                ],
                'roles': ['frontend', 'backend', 'algorithm'],
                'effort_hours': 12,
                'dependencies': ['card_001'],
                'tech_tags': ['Flutter', '推荐算法'],
                'status': 'pending',
              },
              {
                'id': 'card_004',
                'module_id': 'mod_home',
                'title': '分类导航',
                'type': 'action',
                'priority': 'P1',
                'description': '首页顶部分类导航栏',
                'event': '用户点击分类标签',
                'action': '切换分类并加载对应数据',
                'response': '列表内容切换为对应分类',
                'state_change': '当前分类标记更新',
                'acceptance_criteria': [
                  {'id': 'ac_009', 'content': '分类切换无闪烁', 'checked': false},
                  {'id': 'ac_010', 'content': '当前分类高亮显示', 'checked': false},
                ],
                'roles': ['frontend'],
                'effort_hours': 6,
                'dependencies': ['card_003'],
                'tech_tags': ['Flutter'],
                'status': 'pending',
              },
            ],
          },
          {
            'id': 'mod_core',
            'name': '核心业务模块',
            'cards': [
              {
                'id': 'card_005',
                'module_id': 'mod_core',
                'title': '需求发布',
                'type': 'event',
                'priority': 'P0',
                'description': '用户发布项目需求',
                'event': '用户点击发布按钮并填写需求表单',
                'action': '验证必填项，提交需求数据',
                'response': '发布成功跳转需求详情页',
                'state_change': '需求状态变为已发布',
                'acceptance_criteria': [
                  {'id': 'ac_011', 'content': '标题字数限制50字', 'checked': false},
                  {'id': 'ac_012', 'content': '描述支持富文本', 'checked': false},
                  {'id': 'ac_013', 'content': '预算范围选择', 'checked': false},
                  {'id': 'ac_014', 'content': '附件上传（图片/文档）', 'checked': false},
                ],
                'roles': ['frontend', 'backend'],
                'effort_hours': 16,
                'dependencies': ['card_001'],
                'tech_tags': ['Flutter', 'OSS'],
                'status': 'pending',
              },
              {
                'id': 'card_006',
                'module_id': 'mod_core',
                'title': '需求匹配',
                'type': 'response',
                'priority': 'P0',
                'description': 'AI自动匹配合适的团队',
                'event': '需求发布后',
                'action': 'AI分析项目特征，匹配团队库',
                'response': '展示匹配结果列表，按匹配度排序',
                'state_change': '需求状态变为匹配中',
                'acceptance_criteria': [
                  {'id': 'ac_015', 'content': '匹配结果在30秒内返回', 'checked': false},
                  {'id': 'ac_016', 'content': '展示匹配度百分比', 'checked': false},
                  {'id': 'ac_017', 'content': '支持手动筛选', 'checked': false},
                ],
                'roles': ['frontend', 'backend', 'algorithm'],
                'effort_hours': 20,
                'dependencies': ['card_005'],
                'tech_tags': ['Flutter', 'ML', 'Go'],
                'status': 'pending',
              },
            ],
          },
        ],
        'budget_suggestion': {
          'min': 5000,
          'max': 15000,
          'reason': '基于项目复杂度和市场行情，建议预算范围为 ¥5,000 - ¥15,000',
        },
      },
    };
  }

  static Map<String, dynamic> _saveDraft(RequestOptions options) {
    _draftCount += 1;
    final data = options.data as Map<String, dynamic>? ?? {};
    final now = DateTime.now().toIso8601String();
    final projectId = 'proj_draft_${_draftCount.toString().padLeft(3, '0')}';

    final project = <String, dynamic>{
      'id': projectId,
      'uuid': projectId,
      'owner_id': 'user_001',
      'owner_name': 'KAIZAO 用户',
      'title': '未命名需求草稿',
      'description': '项目方正在完善项目描述，发布后会补充完整的业务背景、目标与交付要求。',
      'category': data['category']?.toString() ?? 'web',
      'budget_min': (data['budget_min'] as num?)?.toDouble() ?? 1000,
      'budget_max': (data['budget_max'] as num?)?.toDouble() ?? 5000,
      'match_mode': data['match_mode'] as int? ?? 1,
      'status': 1,
      'status_text': '草稿',
      'tech_requirements': <String>[],
      'view_count': 0,
      'bid_count': 0,
      'created_at': now,
    };
    MarketMock.upsertProject(project);

    return {
      'code': 0,
      'message': '草稿已保存',
      'data': {
        ...project,
        'saved_at': now,
      },
    };
  }

  static Map<String, dynamic> _updateDraft(RequestOptions options) {
    final path = options.path;
    final projectId = path.split('/').last;
    final current = MarketMock.findProject(projectId) ??
        <String, dynamic>{
          'id': projectId,
          'uuid': projectId,
          'owner_id': 'user_001',
          'owner_name': 'KAIZAO 用户',
          'status': 1,
          'created_at': DateTime.now().toIso8601String(),
          'tech_requirements': <String>[],
          'view_count': 0,
          'bid_count': 0,
        };
    final data = options.data as Map<String, dynamic>? ?? {};

    final updated = <String, dynamic>{
      ...current,
      ...data,
      'id': current['id'] ?? projectId,
      'uuid': current['uuid'] ?? projectId,
      'status': current['status'] ?? 1,
      'status_text': '草稿',
    };
    MarketMock.upsertProject(updated);

    return {
      'code': 0,
      'message': '草稿更新成功',
      'data': updated,
    };
  }

  static Map<String, dynamic> _publishDraft(RequestOptions options) {
    final pathParts = options.path.split('/');
    final projectId = pathParts[pathParts.length - 2];
    final current = MarketMock.findProject(projectId) ??
        <String, dynamic>{
          'id': projectId,
          'uuid': projectId,
          'owner_id': 'user_001',
          'owner_name': 'KAIZAO 用户',
          'title': '未命名需求',
          'description': '项目方正在完善项目描述，发布后会补充完整的业务背景、目标与交付要求。',
          'category': 'web',
          'budget_min': 1000,
          'budget_max': 5000,
          'match_mode': 1,
          'tech_requirements': <String>[],
          'view_count': 0,
          'bid_count': 0,
          'created_at': DateTime.now().toIso8601String(),
        };
    final published = <String, dynamic>{
      ...current,
      'status': 2,
      'status_text': '已发布',
      'published_at': DateTime.now().toIso8601String(),
    };
    MarketMock.upsertProject(published);

    return {
      'code': 0,
      'message': '项目发布成功',
      'data': published,
    };
  }

  static Map<String, dynamic> _publishProject(RequestOptions options) {
    final data = options.data as Map<String, dynamic>? ?? {};
    _draftCount += 1;
    final now = DateTime.now().toIso8601String();
    final projectId = 'proj_new_${_draftCount.toString().padLeft(3, '0')}';
    final project = <String, dynamic>{
      'id': projectId,
      'uuid': projectId,
      'owner_id': 'user_001',
      'owner_name': 'KAIZAO 用户',
      'title': data['title'] ?? 'AI 生成需求',
      'description': data['description'] ?? '来自发布流的需求描述',
      'category': data['category']?.toString() ?? 'web',
      'budget_min': (data['budget_min'] as num?)?.toDouble() ?? 5000,
      'budget_max': (data['budget_max'] as num?)?.toDouble() ?? 15000,
      'match_mode': data['match_mode'] as int? ?? 1,
      'status': 2,
      'status_text': '已发布',
      'tech_requirements': <String>[],
      'view_count': 0,
      'bid_count': 0,
      'published_at': now,
      'created_at': now,
    };
    MarketMock.upsertProject(project);

    return {
      'code': 0,
      'message': '项目发布成功',
      'data': project,
    };
  }
}
