import 'package:shared_preferences/shared_preferences.dart';

/// 本地存储服务
/// Web模式下统一使用 SharedPreferences（localStorage）
/// 原生模式下可扩展为 FlutterSecureStorage
class StorageService {
  static StorageService? _instance;
  SharedPreferences? _prefs;

  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyUserId = 'user_id';
  static const String _keyUserRole = 'user_role';
  static const String _keyIsFirstLaunch = 'is_first_launch';
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyOnboardingCompleted = 'onboarding_completed';
  static const String _keyOnboardingStep = 'onboarding_step';
  static const String _keyOnboardingRole = 'onboarding_role';
  static const String _keyOnboardingDraft = 'onboarding_draft';

  StorageService._();

  factory StorageService() {
    _instance ??= StorageService._();
    return _instance!;
  }

  bool get isReady => _prefs != null;

  /// 在 main() 中调用，确保 SharedPreferences 在路由初始化前就绑就绪
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<void> saveAccessToken(String token) async {
    final prefs = await _preferences;
    await prefs.setString(_keyAccessToken, token);
  }

  Future<String?> getAccessToken() async {
    final prefs = await _preferences;
    return prefs.getString(_keyAccessToken);
  }

  Future<void> saveRefreshToken(String token) async {
    final prefs = await _preferences;
    await prefs.setString(_keyRefreshToken, token);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await _preferences;
    return prefs.getString(_keyRefreshToken);
  }

  Future<void> clearTokens() async {
    final prefs = await _preferences;
    await prefs.remove(_keyAccessToken);
    await prefs.remove(_keyRefreshToken);
  }

  Future<void> clearAuthSession() async {
    final prefs = await _preferences;
    await prefs.remove(_keyAccessToken);
    await prefs.remove(_keyRefreshToken);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserRole);
  }

  Future<void> saveUserId(String userId) async {
    final prefs = await _preferences;
    await prefs.setString(_keyUserId, userId);
  }

  Future<String?> getUserId() async {
    final prefs = await _preferences;
    return prefs.getString(_keyUserId);
  }

  Future<void> saveUserRole(int role) async {
    final prefs = await _preferences;
    await prefs.setInt(_keyUserRole, role);
  }

  Future<int> getUserRole() async {
    final prefs = await _preferences;
    return prefs.getInt(_keyUserRole) ?? 0;
  }

  Future<bool> isFirstLaunch() async {
    final prefs = await _preferences;
    return prefs.getBool(_keyIsFirstLaunch) ?? true;
  }

  Future<void> setFirstLaunchDone() async {
    final prefs = await _preferences;
    await prefs.setBool(_keyIsFirstLaunch, false);
  }

  Future<void> saveThemeMode(String mode) async {
    final prefs = await _preferences;
    await prefs.setString(_keyThemeMode, mode);
  }

  Future<String> getThemeMode() async {
    final prefs = await _preferences;
    return prefs.getString(_keyThemeMode) ?? 'system';
  }

  // Onboarding
  Future<bool> isOnboardingCompleted() async {
    final prefs = await _preferences;
    return prefs.getBool(_keyOnboardingCompleted) ?? false;
  }

  Future<void> setOnboardingCompleted() async {
    final prefs = await _preferences;
    await prefs.setBool(_keyOnboardingCompleted, true);
  }

  Future<void> saveOnboardingStep(int step) async {
    final prefs = await _preferences;
    await prefs.setInt(_keyOnboardingStep, step);
  }

  Future<int> getOnboardingStep() async {
    final prefs = await _preferences;
    return prefs.getInt(_keyOnboardingStep) ?? 0;
  }

  Future<void> saveOnboardingRole(String role) async {
    final prefs = await _preferences;
    await prefs.setString(_keyOnboardingRole, role);
  }

  Future<String?> getOnboardingRole() async {
    final prefs = await _preferences;
    return prefs.getString(_keyOnboardingRole);
  }

  Future<void> saveOnboardingDraft(String json) async {
    final prefs = await _preferences;
    await prefs.setString(_keyOnboardingDraft, json);
  }

  Future<String?> getOnboardingDraft() async {
    final prefs = await _preferences;
    return prefs.getString(_keyOnboardingDraft);
  }

  Future<void> clearOnboardingDraft() async {
    final prefs = await _preferences;
    await prefs.remove(_keyOnboardingDraft);
  }

  Future<void> clearOnboardingState() async {
    final prefs = await _preferences;
    await prefs.remove(_keyOnboardingCompleted);
    await prefs.remove(_keyOnboardingStep);
    await prefs.remove(_keyOnboardingRole);
    await prefs.remove(_keyOnboardingDraft);
  }

  Future<void> clearAll() async {
    final prefs = await _preferences;
    final isFirst = prefs.getBool(_keyIsFirstLaunch);
    await prefs.clear();
    if (isFirst != null) {
      await prefs.setBool(_keyIsFirstLaunch, isFirst);
    }
  }
}
