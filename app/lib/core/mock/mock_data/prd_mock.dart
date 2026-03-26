import 'package:dio/dio.dart';
import '../mock_interceptor.dart';

class PrdMock {
  PrdMock._();

  static void register(Map<String, MockHandler> handlers) {
    handlers['GET:/api/v1/projects/:id/prd'] = MockHandler(
      delayMs: 500,
      handler: (options) => _getPrd(options),
    );

    handlers['PUT:/api/v1/projects/:id/prd/cards/:cardId'] = MockHandler(
      delayMs: 200,
      handler: (options) => _updateCard(options),
    );
  }

  static Map<String, dynamic> _getPrd(RequestOptions options) {
    return {
      'code': 0,
      'message': 'ok',
      'data': {
        'prd_id': 'prd_001',
        'project_id': options.path.split('/')[4],
        'title': '智能协作平台 PRD',
        'version': '1.0',
        'created_at': '2026-03-20T10:00:00Z',
        'modules': [
          {
            'id': 'mod_auth',
            'name': '认证模块',
            'icon': 'lock',
            'order': 1,
            'cards': [
              _makeCard('card_001', 'mod_auth', '手机号登录', 'event', 'P0',
                  description: '用户通过手机号和短信验证码完成登录',
                  event: '用户输入手机号并点击获取验证码',
                  action: '系统发送短信验证码，用户输入后验证',
                  response: '验证成功跳转首页，失败提示错误',
                  stateChange: '用户状态从未登录变为已登录',
                  criteria: [
                    {'id': 'ac_001', 'content': '手机号格式校验（11位数字）', 'checked': true},
                    {'id': 'ac_002', 'content': '验证码60秒倒计时', 'checked': true},
                    {'id': 'ac_003', 'content': '3次错误后锁定5分钟', 'checked': false},
                  ],
                  roles: ['frontend', 'backend'],
                  hours: 8,
                  deps: [],
                  tags: ['Flutter', 'SMS SDK'],
                  status: 'in_progress'),
              _makeCard('card_002', 'mod_auth', '自动登录', 'state', 'P1',
                  description: 'App启动时检查Token有效性',
                  event: 'App冷启动',
                  action: '检查本地Token是否存在且未过期',
                  response: 'Token有效直接进入首页',
                  stateChange: '从启动态切换为已登录或未登录',
                  criteria: [
                    {'id': 'ac_004', 'content': 'Token过期自动刷新', 'checked': true},
                    {'id': 'ac_005', 'content': '刷新失败跳转登录页', 'checked': true},
                  ],
                  roles: ['frontend'],
                  hours: 4,
                  deps: ['card_001'],
                  tags: ['JWT', 'SharedPreferences'],
                  status: 'completed'),
            ],
          },
          {
            'id': 'mod_home',
            'name': '首页模块',
            'icon': 'home',
            'order': 2,
            'cards': [
              _makeCard('card_003', 'mod_home', '个性化推荐', 'response', 'P0',
                  description: '首页展示个性化推荐内容',
                  event: '用户进入首页',
                  action: '根据用户画像请求推荐数据',
                  response: '展示推荐卡片列表',
                  stateChange: '首页数据加载完成',
                  criteria: [
                    {'id': 'ac_006', 'content': '首屏加载时间 < 2秒', 'checked': false},
                    {'id': 'ac_007', 'content': '支持下拉刷新', 'checked': false},
                    {'id': 'ac_008', 'content': '无数据时展示空状态', 'checked': false},
                  ],
                  roles: ['frontend', 'backend', 'algorithm'],
                  hours: 12,
                  deps: ['card_001'],
                  tags: ['Flutter', '推荐算法'],
                  status: 'pending'),
              _makeCard('card_004', 'mod_home', '分类导航', 'action', 'P1',
                  description: '首页顶部分类导航栏',
                  event: '用户点击分类标签',
                  action: '切换分类并加载对应数据',
                  response: '列表内容切换',
                  stateChange: '当前分类标记更新',
                  criteria: [
                    {'id': 'ac_009', 'content': '分类切换无闪烁', 'checked': false},
                    {'id': 'ac_010', 'content': '当前分类高亮显示', 'checked': false},
                  ],
                  roles: ['frontend'],
                  hours: 6,
                  deps: ['card_003'],
                  tags: ['Flutter'],
                  status: 'pending'),
            ],
          },
          {
            'id': 'mod_core',
            'name': '核心业务模块',
            'icon': 'business',
            'order': 3,
            'cards': [
              _makeCard('card_005', 'mod_core', '需求发布', 'event', 'P0',
                  description: '用户发布项目需求',
                  event: '用户填写需求表单并提交',
                  action: '验证必填项，提交数据',
                  response: '发布成功跳转详情页',
                  stateChange: '需求状态变为已发布',
                  criteria: [
                    {'id': 'ac_011', 'content': '标题字数限制50字', 'checked': false},
                    {'id': 'ac_012', 'content': '描述支持富文本', 'checked': false},
                    {'id': 'ac_013', 'content': '预算范围选择', 'checked': false},
                    {'id': 'ac_014', 'content': '附件上传', 'checked': false},
                  ],
                  roles: ['frontend', 'backend'],
                  hours: 16,
                  deps: ['card_001'],
                  tags: ['Flutter', 'OSS'],
                  status: 'pending'),
              _makeCard('card_006', 'mod_core', '需求匹配', 'response', 'P0',
                  description: 'AI自动匹配合适的专家',
                  event: '需求发布后',
                  action: 'AI分析需求特征，匹配专家库',
                  response: '展示匹配结果列表',
                  stateChange: '需求状态变为匹配中',
                  criteria: [
                    {'id': 'ac_015', 'content': '匹配结果在30秒内返回', 'checked': false},
                    {'id': 'ac_016', 'content': '展示匹配度百分比', 'checked': false},
                    {'id': 'ac_017', 'content': '支持手动筛选', 'checked': false},
                  ],
                  roles: ['frontend', 'backend', 'algorithm'],
                  hours: 20,
                  deps: ['card_005'],
                  tags: ['Flutter', 'ML', 'Go'],
                  status: 'pending'),
            ],
          },
          {
            'id': 'mod_profile',
            'name': '个人中心模块',
            'icon': 'person',
            'order': 4,
            'cards': [
              _makeCard('card_007', 'mod_profile', '个人资料编辑', 'event', 'P1',
                  description: '用户编辑个人资料信息',
                  event: '用户点击编辑按钮',
                  action: '进入编辑模式，修改表单字段',
                  response: '保存成功后展示更新后的资料',
                  stateChange: '用户资料更新',
                  criteria: [
                    {'id': 'ac_018', 'content': '昵称长度限制20字', 'checked': false},
                    {'id': 'ac_019', 'content': '头像支持裁剪', 'checked': false},
                  ],
                  roles: ['frontend', 'backend'],
                  hours: 8,
                  deps: ['card_001'],
                  tags: ['Flutter'],
                  status: 'pending'),
            ],
          },
        ],
      },
    };
  }

  static Map<String, dynamic> _makeCard(
    String id,
    String moduleId,
    String title,
    String type,
    String priority, {
    required String description,
    required String event,
    required String action,
    required String response,
    required String stateChange,
    required List<Map<String, dynamic>> criteria,
    required List<String> roles,
    required int hours,
    required List<String> deps,
    required List<String> tags,
    required String status,
  }) {
    return {
      'id': id,
      'module_id': moduleId,
      'title': title,
      'type': type,
      'priority': priority,
      'description': description,
      'event': event,
      'action': action,
      'response': response,
      'state_change': stateChange,
      'acceptance_criteria': criteria,
      'roles': roles,
      'effort_hours': hours,
      'dependencies': deps,
      'tech_tags': tags,
      'status': status,
    };
  }

  static Map<String, dynamic> _updateCard(RequestOptions options) {
    return {
      'code': 0,
      'message': '更新成功',
      'data': options.data,
    };
  }
}
