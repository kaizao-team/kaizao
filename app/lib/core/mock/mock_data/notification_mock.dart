import '../mock_interceptor.dart';

class NotificationMock {
  NotificationMock._();

  static void register(Map<String, MockHandler> handlers) {
    handlers['GET:/api/v1/notifications'] = MockHandler(
      delayMs: 300,
      handler: (_) => _notifications(),
    );
  }

  static Map<String, dynamic> _notifications() {
    return {
      'code': 0,
      'message': 'ok',
      'data': [
        {
          'id': 'ntf_001',
          'title': '新投标通知',
          'body': '「在线教育平台」收到了来自张开发的投标，报价 ¥5,000，请及时查看。',
          'type': 'bid',
          'is_read': false,
          'created_at': '2026-03-22T10:30:00Z',
        },
        {
          'id': 'ntf_002',
          'title': '项目状态更新',
          'body': '「SaaS 管理后台」已进入 UI 设计阶段，当前进度 60%。',
          'type': 'project',
          'is_read': false,
          'created_at': '2026-03-21T16:00:00Z',
        },
        {
          'id': 'ntf_003',
          'title': '系统通知',
          'body': '你的账户资料已通过审核，现在可以开始接单了。',
          'type': 'system',
          'is_read': false,
          'created_at': '2026-03-20T09:15:00Z',
        },
        {
          'id': 'ntf_004',
          'title': '投标被采纳',
          'body': '恭喜！你对「智能家居控制 App」的投标已被项目方采纳。',
          'type': 'bid',
          'is_read': true,
          'created_at': '2026-03-19T14:20:00Z',
        },
        {
          'id': 'ntf_005',
          'title': '里程碑完成',
          'body': '「品牌官网视觉升级」的"需求确认"里程碑已完成。',
          'type': 'project',
          'is_read': true,
          'created_at': '2026-03-18T11:00:00Z',
        },
      ],
    };
  }
}
