import 'package:flutter/foundation.dart';
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

  StorageService._();

  factory StorageService() {
    _instance ??= StorageService._();
    return _instance!;
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

  Future<void> clearAll() async {
    final prefs = await _preferences;
    final isFirst = prefs.getBool(_keyIsFirstLaunch);
    await prefs.clear();
    if (isFirst != null) {
      await prefs.setBool(_keyIsFirstLaunch, isFirst);
    }
  }
}
