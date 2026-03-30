import 'package:dio/dio.dart';
import '../mock_interceptor.dart';

class ChatMock {
  ChatMock._();

  static void register(Map<String, MockHandler> handlers) {
    handlers['GET:/api/v1/conversations'] = MockHandler(
      delayMs: 300,
      handler: (_) => _conversationList(),
    );

    handlers['GET:/api/v1/conversations/:id/messages'] = MockHandler(
      delayMs: 300,
      handler: (options) => _messages(options),
    );

    handlers['POST:/api/v1/conversations/:id/messages'] = MockHandler(
      delayMs: 200,
      handler: (options) => _sendMessage(options),
    );

    handlers['POST:/api/v1/conversations/:id/read'] = MockHandler(
      delayMs: 100,
      handler: (_) => _markRead(),
    );

    handlers['DELETE:/api/v1/conversations/:id'] = MockHandler(
      delayMs: 200,
      handler: (_) => {'code': 0, 'message': '已删除'},
    );
  }

  static Map<String, dynamic> _conversationList() {
    return {
      'code': 0,
      'data': [
        {'id': 'conv_001', 'peer_id': 'user_201', 'peer_name': '张开发', 'peer_avatar': null, 'last_message': '好的，我今天先完成看板页面的开发', 'last_message_time': '2026-03-23T14:30:00Z', 'unread_count': 3, 'project_title': '智能客服系统'},
        {'id': 'conv_002', 'peer_id': 'user_202', 'peer_name': '李设计', 'peer_avatar': null, 'last_message': 'UI稿已经更新了，请查看', 'last_message_time': '2026-03-23T12:15:00Z', 'unread_count': 1, 'project_title': '企业官网改版'},
        {'id': 'conv_003', 'peer_id': 'user_203', 'peer_name': '王产品', 'peer_avatar': null, 'last_message': '需求文档已确认，可以开始开发了', 'last_message_time': '2026-03-22T18:00:00Z', 'unread_count': 0, 'project_title': 'AI写作助手'},
        {'id': 'conv_004', 'peer_id': 'user_204', 'peer_name': '赵测试', 'peer_avatar': null, 'last_message': '发现了一个bug，详情见截图', 'last_message_time': '2026-03-22T10:30:00Z', 'unread_count': 0, 'project_title': '智能客服系统'},
        {'id': 'conv_005', 'peer_id': 'user_205', 'peer_name': 'Kaizo 小助手', 'peer_avatar': null, 'last_message': '你的项目已成功发布，快来看看吧', 'last_message_time': '2026-03-21T09:00:00Z', 'unread_count': 0, 'project_title': null},
      ],
    };
  }

  static Map<String, dynamic> _messages(RequestOptions options) {
    return {
      'code': 0,
      'data': [
        {'id': 'msg_001', 'sender_id': 'user_201', 'content': '你好，我对这个项目很感兴趣', 'type': 'text', 'status': 'sent', 'created_at': '2026-03-23T10:00:00Z'},
        {'id': 'msg_002', 'sender_id': 'me', 'content': '欢迎！请问你有Flutter开发经验吗？', 'type': 'text', 'status': 'sent', 'created_at': '2026-03-23T10:05:00Z'},
        {'id': 'msg_003', 'sender_id': 'user_201', 'content': '有的，5年Flutter经验，做过多个大型项目', 'type': 'text', 'status': 'sent', 'created_at': '2026-03-23T10:10:00Z'},
        {'id': 'msg_004', 'sender_id': 'me', 'content': '那太好了，我们来聊聊具体的技术方案吧', 'type': 'text', 'status': 'sent', 'created_at': '2026-03-23T10:15:00Z'},
        {'id': 'msg_005', 'sender_id': 'user_201', 'content': '', 'type': 'task_card', 'status': 'sent', 'created_at': '2026-03-23T10:20:00Z', 'extra': {'task_id': 't3', 'task_title': 'API对接-认证模块', 'task_type': 'event', 'task_status': 'in_progress', 'task_summary': '对接后端认证接口'}},
        {'id': 'msg_006', 'sender_id': 'user_201', 'content': '看板功能什么时候能完成？', 'type': 'text', 'status': 'sent', 'created_at': '2026-03-23T14:00:00Z'},
        {'id': 'msg_007', 'sender_id': 'me', 'content': '预计明天就可以提交验收了，今天在做最后的测试', 'type': 'text', 'status': 'sent', 'created_at': '2026-03-23T14:05:00Z'},
        {'id': 'msg_008', 'sender_id': 'user_201', 'content': '好的，我今天先完成看板页面的开发', 'type': 'text', 'status': 'sent', 'created_at': '2026-03-23T14:30:00Z'},
      ],
    };
  }

  static Map<String, dynamic> _sendMessage(RequestOptions options) {
    return {
      'code': 0,
      'message': 'ok',
      'data': {
        'id': 'msg_new_${DateTime.now().millisecondsSinceEpoch}',
        'status': 'sent',
      },
    };
  }

  static Map<String, dynamic> _markRead() {
    return {'code': 0, 'message': 'ok'};
  }
}
