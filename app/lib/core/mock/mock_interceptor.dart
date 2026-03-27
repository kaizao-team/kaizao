import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/app_env.dart';
import 'mock_data/auth_mock.dart';
import 'mock_data/user_mock.dart';
import 'mock_data/project_mock.dart';
import 'mock_data/home_mock.dart';
import 'mock_data/market_mock.dart';
import 'mock_data/post_mock.dart';
import 'mock_data/prd_mock.dart';
import 'mock_data/match_mock.dart';
import 'mock_data/project_kanban_mock.dart';
import 'mock_data/chat_mock.dart';
import 'mock_data/acceptance_mock.dart';
import 'mock_data/payment_mock.dart';
import 'mock_data/profile_mock.dart';
import 'mock_data/wallet_mock.dart';
import 'mock_data/team_mock.dart';
import 'mock_data/rate_mock.dart';
import 'mock_data/comment_mock.dart';
import 'mock_data/notification_mock.dart';

/// Mock 拦截器 — 开发环境拦截 API 请求并返回模拟数据
/// 通过 useMock 参数控制是否启用
class MockInterceptor extends Interceptor {
  static bool useMock = AppEnv.useMock;

  final Map<String, MockHandler> _handlers = {};

  MockInterceptor() {
    _registerHandlers();
  }

  void _registerHandlers() {
    AuthMock.register(_handlers);
    UserMock.register(_handlers);
    ProjectMock.register(_handlers);
    HomeMock.register(_handlers);
    MarketMock.register(_handlers);
    PostMock.register(_handlers);
    PrdMock.register(_handlers);
    MatchMock.register(_handlers);
    ProjectKanbanMock.register(_handlers);
    ChatMock.register(_handlers);
    AcceptanceMock.register(_handlers);
    PaymentMock.register(_handlers);
    ProfileMock.register(_handlers);
    WalletMock.register(_handlers);
    TeamMock.register(_handlers);
    RateMock.register(_handlers);
    CommentMock.register(_handlers);
    NotificationMock.register(_handlers);
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!useMock) {
      handler.next(options);
      return;
    }

    final path = options.path;
    final method = options.method.toUpperCase();
    final key = '$method:$path';

    // exact match
    MockHandler? mockHandler = _handlers[key];

    // pattern match (path params)
    if (mockHandler == null) {
      for (final entry in _handlers.entries) {
        if (_matchPath(entry.key, key)) {
          mockHandler = entry.value;
          break;
        }
      }
    }

    if (mockHandler != null) {
      Future.delayed(
        Duration(milliseconds: mockHandler.delayMs),
        () {
          final responseData = mockHandler!.handler(options);
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: responseData,
            ),
          );
        },
      );
    } else {
      debugPrint('[Mock] No handler for $key, passing through');
      handler.next(options);
    }
  }

  bool _matchPath(String pattern, String actual) {
    final patternParts = pattern.split('/');
    final actualParts = actual.split('/');
    if (patternParts.length != actualParts.length) return false;

    for (int i = 0; i < patternParts.length; i++) {
      if (patternParts[i].startsWith(':') || patternParts[i].startsWith('{')) {
        continue;
      }
      if (patternParts[i] != actualParts[i]) return false;
    }
    return true;
  }
}

class MockHandler {
  final Map<String, dynamic> Function(RequestOptions options) handler;
  final int delayMs;

  const MockHandler({required this.handler, this.delayMs = 300});
}
