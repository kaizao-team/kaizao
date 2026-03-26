import 'package:dio/dio.dart';
import '../mock_interceptor.dart';

class AcceptanceMock {
  AcceptanceMock._();

  static void register(Map<String, MockHandler> handlers) {
    handlers['GET:/api/v1/milestones/:id/acceptance'] = MockHandler(
      delayMs: 400,
      handler: (_) => _acceptanceChecklist(),
    );

    handlers['POST:/api/v1/milestones/:id/accept'] = MockHandler(
      delayMs: 500,
      handler: (_) => _confirmAcceptance(),
    );

    handlers['POST:/api/v1/milestones/:id/revision'] = MockHandler(
      delayMs: 400,
      handler: (options) => _submitRevision(options),
    );
  }

  static Map<String, dynamic> _acceptanceChecklist() {
    return {
      'code': 0,
      'data': {
        'milestone_id': 'm1',
        'milestone_title': '需求确认 & 基础框架',
        'amount': 1500,
        'payee_name': '张开发',
        'preview_url': 'https://preview.vibebuild.com/proj_001/m1',
        'items': [
          {'id': 'ac_001', 'description': '用户可通过手机号+验证码登录', 'is_checked': true, 'source_card': 'FE-AUTH-001'},
          {'id': 'ac_002', 'description': '登录后自动跳转首页', 'is_checked': true, 'source_card': 'FE-AUTH-001'},
          {'id': 'ac_003', 'description': '角色选择页支持需求方/专家切换', 'is_checked': false, 'source_card': 'FE-AUTH-002'},
          {'id': 'ac_004', 'description': '引导页展示品牌介绍和功能亮点', 'is_checked': false, 'source_card': 'FE-ONBOARD-001'},
          {'id': 'ac_005', 'description': '需求方引导4步表单正常提交', 'is_checked': false, 'source_card': 'FE-ONBOARD-003'},
          {'id': 'ac_006', 'description': '断点续传：退出后重新进入保留进度', 'is_checked': false, 'source_card': 'FE-ONBOARD-006'},
        ],
      },
    };
  }

  static Map<String, dynamic> _confirmAcceptance() {
    return {
      'code': 0,
      'message': '验收通过，款项已释放',
      'data': {'status': 'accepted', 'released_amount': 1500},
    };
  }

  static Map<String, dynamic> _submitRevision(RequestOptions options) {
    return {
      'code': 0,
      'message': '修改请求已提交',
      'data': {'revision_id': 'rev_001', 'status': 'revision_requested'},
    };
  }
}
