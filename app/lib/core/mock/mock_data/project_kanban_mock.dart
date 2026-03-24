import 'package:dio/dio.dart';
import '../mock_interceptor.dart';

class ProjectKanbanMock {
  ProjectKanbanMock._();

  static void register(Map<String, MockHandler> handlers) {
    handlers['GET:/api/v1/projects/:id/tasks'] = MockHandler(
      delayMs: 400,
      handler: (options) => _tasks(options),
    );

    handlers['PUT:/api/v1/tasks/:id/status'] = MockHandler(
      delayMs: 300,
      handler: (options) => _updateTaskStatus(options),
    );

    handlers['GET:/api/v1/projects/:id/milestones'] = MockHandler(
      delayMs: 300,
      handler: (options) => _milestones(options),
    );

    handlers['GET:/api/v1/projects/:id/daily-reports'] = MockHandler(
      delayMs: 400,
      handler: (options) => _dailyReports(options),
    );
  }

  static Map<String, dynamic> _tasks(RequestOptions options) {
    return {
      'code': 0,
      'message': 'ok',
      'data': [
        {'id': 't1', 'title': '用户认证模块', 'description': '实现手机号登录和JWT认证', 'status': 'completed', 'priority': 'P0', 'assignee': '张开发', 'milestone_id': 'm1', 'effort_hours': 8, 'is_at_risk': false, 'created_at': '2026-03-15T10:00:00Z', 'completed_at': '2026-03-17T15:00:00Z'},
        {'id': 't2', 'title': '首页UI开发', 'description': '实现需求方和专家双首页', 'status': 'completed', 'priority': 'P0', 'assignee': '张开发', 'milestone_id': 'm1', 'effort_hours': 12, 'is_at_risk': false, 'created_at': '2026-03-15T10:00:00Z', 'completed_at': '2026-03-19T12:00:00Z'},
        {'id': 't3', 'title': 'API对接-认证模块', 'description': '对接后端认证接口', 'status': 'in_progress', 'priority': 'P0', 'assignee': '张开发', 'milestone_id': 'm2', 'effort_hours': 6, 'is_at_risk': false, 'created_at': '2026-03-18T10:00:00Z', 'completed_at': null},
        {'id': 't4', 'title': '需求广场页面', 'description': '实现项目列表和筛选功能', 'status': 'in_progress', 'priority': 'P1', 'assignee': '张开发', 'milestone_id': 'm2', 'effort_hours': 10, 'is_at_risk': true, 'created_at': '2026-03-19T10:00:00Z', 'completed_at': null},
        {'id': 't5', 'title': '发布需求流程', 'description': 'AI对话式需求发布全流程', 'status': 'in_progress', 'priority': 'P0', 'assignee': '张开发', 'milestone_id': 'm2', 'effort_hours': 16, 'is_at_risk': false, 'created_at': '2026-03-20T10:00:00Z', 'completed_at': null},
        {'id': 't6', 'title': '聊天功能', 'description': '实时消息和消息列表', 'status': 'todo', 'priority': 'P1', 'assignee': null, 'milestone_id': 'm3', 'effort_hours': 14, 'is_at_risk': false, 'created_at': '2026-03-20T10:00:00Z', 'completed_at': null},
        {'id': 't7', 'title': '支付流程', 'description': '托管支付和分账', 'status': 'todo', 'priority': 'P0', 'assignee': null, 'milestone_id': 'm3', 'effort_hours': 12, 'is_at_risk': false, 'created_at': '2026-03-20T10:00:00Z', 'completed_at': null},
        {'id': 't8', 'title': '验收功能', 'description': '里程碑验收和评价', 'status': 'todo', 'priority': 'P1', 'assignee': null, 'milestone_id': 'm4', 'effort_hours': 8, 'is_at_risk': false, 'created_at': '2026-03-20T10:00:00Z', 'completed_at': null},
        {'id': 't9', 'title': '个人主页', 'description': '个人资料和作品集展示', 'status': 'todo', 'priority': 'P2', 'assignee': null, 'milestone_id': 'm4', 'effort_hours': 10, 'is_at_risk': false, 'created_at': '2026-03-20T10:00:00Z', 'completed_at': null},
      ],
    };
  }

  static Map<String, dynamic> _updateTaskStatus(RequestOptions options) {
    return {
      'code': 0,
      'message': '状态已更新',
      'data': options.data,
    };
  }

  static Map<String, dynamic> _milestones(RequestOptions options) {
    return {
      'code': 0,
      'message': 'ok',
      'data': [
        {'id': 'm1', 'title': '需求确认 & 基础框架', 'status': 'completed', 'progress': 100, 'due_date': '2026-03-17', 'amount': 1500, 'task_count': 2, 'completed_task_count': 2},
        {'id': 'm2', 'title': '核心功能开发', 'status': 'in_progress', 'progress': 40, 'due_date': '2026-03-28', 'amount': 3000, 'task_count': 3, 'completed_task_count': 0},
        {'id': 'm3', 'title': '通信 & 支付模块', 'status': 'pending', 'progress': 0, 'due_date': '2026-04-05', 'amount': 2000, 'task_count': 2, 'completed_task_count': 0},
        {'id': 'm4', 'title': '测试 & 上线', 'status': 'pending', 'progress': 0, 'due_date': '2026-04-12', 'amount': 1500, 'task_count': 2, 'completed_task_count': 0},
      ],
    };
  }

  static Map<String, dynamic> _dailyReports(RequestOptions options) {
    return {
      'code': 0,
      'message': 'ok',
      'data': [
        {
          'id': 'rpt_001',
          'date': '2026-03-22',
          'summary': '今日完成了首页UI骨架搭建，包括需求方和专家双首页的差异化布局。需求广场筛选逻辑开发中。',
          'completed_tasks': ['t2'],
          'in_progress_tasks': ['t3', 't4', 't5'],
          'risk_items': ['t4 — 需求广场筛选交互较复杂，可能延期1天'],
          'tomorrow_plan': '继续推进需求广场页面和API认证模块对接',
        },
        {
          'id': 'rpt_002',
          'date': '2026-03-21',
          'summary': '完成认证模块的前端逻辑和Mock数据对接，登录流程已可走通。开始首页开发。',
          'completed_tasks': ['t1'],
          'in_progress_tasks': ['t2', 't3'],
          'risk_items': [],
          'tomorrow_plan': '完成首页双角色差异化布局',
        },
      ],
    };
  }
}
