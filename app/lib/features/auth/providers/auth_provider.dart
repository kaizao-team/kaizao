import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/auth_repository.dart';
import '../../../core/storage/storage_service.dart';

/// 认证状态
class AuthState {
  final bool isLoggedIn;
  final bool isLoading;
  final String? userId;
  final int userRole;
  final String? errorMessage;

  const AuthState({
    this.isLoggedIn = false,
    this.isLoading = false,
    this.userId,
    this.userRole = 0,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    bool? isLoading,
    String? userId,
    int? userRole,
    String? errorMessage,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isLoading: isLoading ?? this.isLoading,
      userId: userId ?? this.userId,
      userRole: userRole ?? this.userRole,
      errorMessage: errorMessage,
    );
  }
}

/// 认证状态 Provider
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final StorageService _storage;

  AuthNotifier(this._repository, this._storage) : super(const AuthState()) {
    _init();
  }

  Future<void> _init() async {
    final token = await _storage.getAccessToken();
    final userId = await _storage.getUserId();
    final role = await _storage.getUserRole();

    if (token != null && token.isNotEmpty) {
      state = state.copyWith(
        isLoggedIn: true,
        userId: userId,
        userRole: role,
      );
    }
  }

  /// 发送验证码
  Future<bool> sendSmsCode(String phone) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.sendSmsCode(phone);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  /// 手机号验证码登录
  Future<bool> loginWithPhone(String phone, String code) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final result = await _repository.loginWithPhone(phone, code);
      await _storage.saveAccessToken(result.accessToken);
      await _storage.saveRefreshToken(result.refreshToken);
      await _storage.saveUserId(result.userId);
      await _storage.saveUserRole(result.userRole);

      state = AuthState(
        isLoggedIn: true,
        userId: result.userId,
        userRole: result.userRole,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  /// 微信登录
  Future<bool> loginWithWechat(String code) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final result = await _repository.loginWithWechat(code);
      await _storage.saveAccessToken(result.accessToken);
      await _storage.saveRefreshToken(result.refreshToken);
      await _storage.saveUserId(result.userId);
      await _storage.saveUserRole(result.userRole);

      state = AuthState(
        isLoggedIn: true,
        userId: result.userId,
        userRole: result.userRole,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  /// 选择角色
  Future<bool> selectRole(int role) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.selectRole(role);
      await _storage.saveUserRole(role);
      state = state.copyWith(isLoading: false, userRole: role);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  /// 退出登录
  Future<void> logout() async {
    try {
      await _repository.logout();
    } catch (_) {
      // 即使服务端退出失败，本地也要清除
    }
    await _storage.clearAll();
    state = const AuthState();
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository, StorageService());
});
