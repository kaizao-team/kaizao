import 'package:dio/dio.dart';
import '../mock_interceptor.dart';

class NotificationMock {
  NotificationMock._();

  static final List<Map<String, dynamic>> _allNotifications = [
    {
      'id': 'ntf_001',
      'uuid': 'ntf_001',
      'title': '新投标通知',
      'content': '「在线教育平台」收到了来自张开发的投标，报价 ¥5,000，请及时查看。',
      'type': 23,
      'notification_type': 23,
      'is_read': false,
      'target_type': 'project',
      'target_id': 'proj_010',
      'created_at': '2026-03-22T10:30:00Z',
    },
    {
      'id': 'ntf_002',
      'uuid': 'ntf_002',
      'title': '项目状态更新',
      'content': '「SaaS 管理后台」已进入 UI 设计阶段，当前进度 60%。',
      'type': 20,
      'notification_type': 20,
      'is_read': false,
      'target_type': 'project',
      'target_id': 'proj_011',
      'created_at': '2026-03-21T16:00:00Z',
    },
    {
      'id': 'ntf_003',
      'uuid': 'ntf_003',
      'title': '系统通知',
      'content': '你的账户资料已通过审核，现在可以开始接单了。',
      'type': 0,
      'notification_type': 0,
      'is_read': false,
      'target_type': null,
      'target_id': null,
      'created_at': '2026-03-20T09:15:00Z',
    },
    {
      'id': 'ntf_004',
      'uuid': 'ntf_004',
      'title': '投标被采纳',
      'content': '恭喜！你对「智能家居控制 App」的投标已被项目方采纳。',
      'type': 20,
      'notification_type': 20,
      'is_read': true,
      'target_type': 'project',
      'target_id': 'proj_012',
      'created_at': '2026-03-19T14:20:00Z',
    },
    {
      'id': 'ntf_005',
      'uuid': 'ntf_005',
      'title': '里程碑完成',
      'content': '「品牌官网视觉升级」的"需求确认"里程碑已完成。',
      'type': 22,
      'notification_type': 22,
      'is_read': true,
      'target_type': 'milestone',
      'target_id': 'mile_014',
      'created_at': '2026-03-18T11:00:00Z',
    },
    {
      'id': 'ntf_006',
      'uuid': 'ntf_006',
      'title': '待支付提醒',
      'content': '项目「品牌官网升级」还有一笔待支付款项，请尽快处理。',
      'type': 21,
      'notification_type': 21,
      'is_read': true,
      'target_type': 'order',
      'target_id': 'order_001',
      'created_at': '2026-03-17T09:00:00Z',
    },
    {
      'id': 'ntf_007',
      'uuid': 'ntf_007',
      'title': '团队邀请',
      'content': '创新工作室邀请你加入「AI 写作助手」项目团队。',
      'type': 0,
      'notification_type': 0,
      'is_read': true,
      'target_type': 'project',
      'target_id': 'proj_017',
      'created_at': '2026-03-16T15:30:00Z',
    },
    {
      'id': 'ntf_008',
      'uuid': 'ntf_008',
      'title': '项目验收提醒',
      'content': '「电商数据大屏」的"前端开发"里程碑已提交验收，请及时审核。',
      'type': 22,
      'notification_type': 22,
      'is_read': true,
      'target_type': 'milestone',
      'target_id': 'mile_015',
      'created_at': '2026-03-15T10:45:00Z',
    },
  ];

  static void register(Map<String, MockHandler> handlers) {
    handlers['GET:/api/v1/notifications'] = MockHandler(
      delayMs: 300,
      handler: (options) => _notifications(options),
    );

    handlers['GET:/api/v1/notifications/unread-count'] = MockHandler(
      delayMs: 120,
      handler: (_) => _unreadCount(),
    );

    handlers['PUT:/api/v1/notifications/:id/read'] = MockHandler(
      delayMs: 100,
      handler: (options) => _markRead(options),
    );

    handlers['PUT:/api/v1/notifications/read-all'] = MockHandler(
      delayMs: 200,
      handler: (_) => _markAllRead(),
    );
  }

  static Map<String, dynamic> _notifications(RequestOptions options) {
    final queryParams = options.queryParameters;
    final page = int.tryParse(queryParams['page']?.toString() ?? '1') ?? 1;
    final pageSize =
        int.tryParse(queryParams['page_size']?.toString() ?? '10') ?? 10;

    final total = _allNotifications.length;
    final totalPages = (total / pageSize).ceil();
    final start = (page - 1) * pageSize;
    final end = start + pageSize > total ? total : start + pageSize;
    final pageData = start < total
        ? _allNotifications.sublist(start, end)
        : <Map<String, dynamic>>[];

    return {
      'code': 0,
      'message': 'ok',
      'data': pageData,
      'meta': {
        'page': page,
        'page_size': pageSize,
        'total': total,
        'total_pages': totalPages,
      },
    };
  }

  static Map<String, dynamic> _markRead(RequestOptions options) {
    final path = options.path;
    final segments = path.split('/');
    final id = segments[segments.length - 2];

    for (final n in _allNotifications) {
      if (n['id'] == id) {
        n['is_read'] = true;
        break;
      }
    }
    return {'code': 0, 'message': 'ok', 'data': null};
  }

  static Map<String, dynamic> _unreadCount() {
    final unread = _allNotifications.where((n) => n['is_read'] != true).length;
    return {
      'code': 0,
      'message': 'ok',
      'data': {
        'unread_count': unread,
      },
    };
  }

  static Map<String, dynamic> _markAllRead() {
    for (final n in _allNotifications) {
      n['is_read'] = true;
    }
    return {'code': 0, 'message': 'ok', 'data': null};
  }
}
