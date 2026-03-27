import 'package:dio/dio.dart';
import '../mock_interceptor.dart';

class CommentMock {
  CommentMock._();

  static final Map<String, List<Map<String, dynamic>>> _projectComments = {};

  static List<Map<String, dynamic>> _defaultComments() {
    return [
      {
        'id': 'cmt_001',
        'user_id': 'user_301',
        'user_name': '陈工',
        'avatar': null,
        'content': '这个项目的技术选型很有想法，Flutter + WebRTC 的组合值得期待！',
        'created_at': '2026-03-21T10:30:00Z',
        'like_count': 5,
        'is_liked': false,
      },
      {
        'id': 'cmt_002',
        'user_id': 'user_302',
        'user_name': '小张',
        'avatar': null,
        'content': '预算范围挺合理的，工期上建议多预留一些测试时间。',
        'created_at': '2026-03-21T08:15:00Z',
        'like_count': 3,
        'is_liked': false,
      },
      {
        'id': 'cmt_003',
        'user_id': 'user_303',
        'user_name': '刘设计',
        'avatar': null,
        'content': '建议把交互原型先做出来，方便后续开发对齐需求。',
        'created_at': '2026-03-20T16:45:00Z',
        'like_count': 8,
        'is_liked': true,
      },
      {
        'id': 'cmt_004',
        'user_id': 'user_304',
        'user_name': '赵产品',
        'avatar': null,
        'content': '类似项目之前做过，有几点踩坑经验可以分享。',
        'created_at': '2026-03-20T11:20:00Z',
        'like_count': 12,
        'is_liked': false,
      },
    ];
  }

  static void register(Map<String, MockHandler> handlers) {
    handlers['GET:/api/v1/projects/:id/comments'] = MockHandler(
      delayMs: 300,
      handler: (options) => _getComments(options),
    );

    handlers['POST:/api/v1/projects/:id/comments'] = MockHandler(
      delayMs: 400,
      handler: (options) => _postComment(options),
    );
  }

  static Map<String, dynamic> _getComments(RequestOptions options) {
    final path = options.path;
    final segments = path.split('/');
    final projectId = segments[segments.length - 2];

    final comments =
        _projectComments[projectId] ?? List.from(_defaultComments());
    _projectComments[projectId] = comments;

    return {
      'code': 0,
      'message': 'ok',
      'data': comments,
    };
  }

  static Map<String, dynamic> _postComment(RequestOptions options) {
    final path = options.path;
    final segments = path.split('/');
    final projectId = segments[segments.length - 2];

    final content = (options.data as Map<String, dynamic>?)?['content'] ?? '';
    final newId = 'cmt_${DateTime.now().millisecondsSinceEpoch}';

    final newComment = {
      'id': newId,
      'user_id': 'user_me',
      'user_name': '我',
      'avatar': null,
      'content': content,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'like_count': 0,
      'is_liked': false,
    };

    final comments =
        _projectComments[projectId] ?? List.from(_defaultComments());
    comments.insert(0, newComment);
    _projectComments[projectId] = comments;

    return {
      'code': 0,
      'message': '评论成功',
      'data': newComment,
    };
  }
}
