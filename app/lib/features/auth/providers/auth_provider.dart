import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/auth_repository.dart';
import '../../../core/storage/storage_service.dart';

/// 认证状态
class AuthState {
  final bool isInitialized;
  final bool isLoggedIn;
  final bool isLoading;
  final String? userId;
  final int userRole;
  final bool isNewUser;
  final bool isFirstLaunch;
  final String? errorMessage;

  const AuthState({
    this.isInitialized = false,
    this.isLoggedIn = false,
    this.isLoading = false,
    this.userId,
    this.userRole = 0,
    this.isNewUser = false,
    this.isFirstLaunch = true,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isInitialized,
    bool? isLoggedIn,
    bool? isLoading,
    String? userId,
    int? userRole,
    bool? isNewUser,
    bool? isFirstLaunch,
    String? Function()? errorMessage,
  }) {
    return AuthState(
      isInitialized: isInitialized ?? this.isInitialized,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isLoading: isLoading ?? this.isLoading,
      userId: userId ?? this.userId,
      userRole: userRole ?? this.userRole,
      isNewUser: isNewUser ?? this.isNewUser,
      isFirstLaunch: isFirstLaunch ?? this.isFirstLaunch,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }
}

/// 用于 GoRouter 的 refreshListenable
class AuthChangeNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

/// 认证状态 Provider
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final StorageService _storage;
  final AuthChangeNotifier changeNotifier;

  AuthNotifier(this._repository, this._storage, this.changeNotifier)
      : super(const AuthState()) {
    _init();
  }

  Future<void> _init() async {
    final token = await _storage.getAccessToken();
    final userId = await _storage.getUserId();
    final role = await _storage.getUserRole();
    final isFirst = await _storage.isFirstLaunch();
    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      state = AuthState(
        isInitialized: true,
        isLoggedIn: true,
        userId: userId,
        userRole: role,
        isFirstLaunch: isFirst,
      );
    } else {
      state = AuthState(isInitialized: true, isFirstLaunch: isFirst);
    }
    changeNotifier.notify();
  }

  Future<bool> sendSmsCode(String phone) async {
    state = state.copyWith(isLoading: true, errorMessage: () => null);
    try {
      await _repository.sendSmsCode(phone);
      if (!mounted) return false;
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      if (!mounted) return false;
      state =
          state.copyWith(isLoading: false, errorMessage: () => e.toString());
      return false;
    }
  }

  Future<bool> loginWithPhone(String phone, String code) async {
    state = state.copyWith(isLoading: true, errorMessage: () => null);
    try {
      final result = await _repository.loginWithPhone(phone, code);
      await _storage.saveAccessToken(result.accessToken);
      await _storage.saveRefreshToken(result.refreshToken);
      await _storage.saveUserId(result.userId);
      await _storage.saveUserRole(result.userRole);
      if (!mounted) return false;

      state = AuthState(
        isInitialized: true,
        isLoggedIn: true,
        userId: result.userId,
        userRole: result.userRole,
        isNewUser: result.isNewUser,
      );
      changeNotifier.notify();
      return true;
    } catch (e) {
      if (!mounted) return false;
      state =
          state.copyWith(isLoading: false, errorMessage: () => e.toString());
      return false;
    }
  }

  Future<bool> selectRole(int role) async {
    state = state.copyWith(isLoading: true, errorMessage: () => null);
    try {
      await _repository.selectRole(role);
      await _storage.saveUserRole(role);
      if (!mounted) return false;
      state = state.copyWith(isLoading: false, userRole: role);
      changeNotifier.notify();
      return true;
    } catch (e) {
      if (!mounted) return false;
      state =
          state.copyWith(isLoading: false, errorMessage: () => e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _repository.logout();
    } catch (_) {}
    await _storage.clearAll();
    if (!mounted) return;
    state = const AuthState(isInitialized: true);
    changeNotifier.notify();
  }

  Future<void> resetForFreshStart() async {
    final isFirstLaunch = await _storage.isFirstLaunch();
    await _storage.clearAuthSession();
    await _storage.clearOnboardingState();
    if (!mounted) return;
    state = AuthState(
      isInitialized: true,
      isLoggedIn: false,
      isFirstLaunch: isFirstLaunch,
    );
    changeNotifier.notify();
  }
}

final authChangeNotifierProvider = Provider<AuthChangeNotifier>((ref) {
  return AuthChangeNotifier();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final changeNotifier = ref.watch(authChangeNotifierProvider);
  return AuthNotifier(repository, StorageService(), changeNotifier);
});
