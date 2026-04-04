import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../storage/storage_service.dart';

/// 全局认证会话管理器
/// 网络层检测到 token 不可恢复时调用 [forceLogout]，
/// 统一完成「清缓存 → 重置状态 → 触发路由跳转」。
class AuthSessionManager {
  static AuthSessionManager? _instance;

  WidgetRef? _ref;
  bool _isLoggingOut = false;
  bool _sessionRevoked = false;
  String? _pendingMessage;

  AuthSessionManager._();

  factory AuthSessionManager() {
    _instance ??= AuthSessionManager._();
    return _instance!;
  }

  /// 由 VccApp.build 注入，使网络层可以间接触达 Riverpod 状态。
  void init(WidgetRef ref) {
    _ref = ref;
  }

  /// 同步标记：onRequest 拦截器可检查此值跳过无效请求。
  bool get isSessionRevoked => _sessionRevoked;

  /// 待显示的过期提示，登录页读取后置空。
  String? consumePendingMessage() {
    final msg = _pendingMessage;
    _pendingMessage = null;
    return msg;
  }

  /// 强制登出：清 storage → 重置 AuthState → 通知 GoRouter redirect。
  /// 内置防重入，并发 401 只执行一次。
  Future<void> forceLogout() async {
    if (_isLoggingOut) return;
    _isLoggingOut = true;
    _sessionRevoked = true;

    try {
      debugPrint('[AuthSessionManager] forceLogout triggered');

      final storage = StorageService();
      try {
        await storage.clearAll();
      } catch (e) {
        debugPrint('[AuthSessionManager] clearAll failed: $e');
      }

      _pendingMessage = '登录已过期，请重新登录';

      final ref = _ref;
      if (ref != null) {
        ref.read(authStateProvider.notifier).forceReset();
      }
    } catch (e) {
      debugPrint('[AuthSessionManager] forceLogout error: $e');
    } finally {
      _isLoggingOut = false;
      _sessionRevoked = false;
    }
  }
}
