import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_endpoints.dart';
import 'api_response.dart';
import '../auth/auth_session_manager.dart';
import '../storage/storage_service.dart';
import '../mock/mock_interceptor.dart';

/// Dio 网络客户端封装
/// JWT 拦截器、队列式 Token 刷新、统一错误处理
class ApiClient {
  static ApiClient? _instance;
  late final Dio _dio;
  final StorageService _storage = StorageService();

  Completer<bool>? _refreshCompleter;

  ApiClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      if (MockInterceptor.useMock) MockInterceptor(),
      _authInterceptor(),
      _errorInterceptor(),
      if (kDebugMode) _logInterceptor(),
    ]);
  }

  factory ApiClient() {
    _instance ??= ApiClient._();
    return _instance!;
  }

  Dio get dio => _dio;

  InterceptorsWrapper _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        final noAuthPaths = [
          ApiEndpoints.sendSmsCode,
          ApiEndpoints.login,
          ApiEndpoints.register,
          ApiEndpoints.refreshToken,
          ApiEndpoints.passwordKey,
          ApiEndpoints.captcha,
          ApiEndpoints.loginPassword,
          ApiEndpoints.registerPassword,
        ];

        final needsAuth = !noAuthPaths.any(
          (path) => options.path.contains(path),
        );

        if (needsAuth) {
          final token = await _storage.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }

        options.headers['X-Device-Type'] = defaultTargetPlatform == TargetPlatform.iOS
            ? 'ios'
            : 'android';
        options.headers['X-App-Version'] = '1.0.0';

        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final refreshed = await _tryRefreshToken();
          if (refreshed) {
            final token = await _storage.getAccessToken();
            error.requestOptions.headers['Authorization'] = 'Bearer $token';
            try {
              final response = await _dio.fetch(error.requestOptions);
              handler.resolve(response);
              return;
            } catch (e) {
              handler.reject(error);
              return;
            }
          }
          await AuthSessionManager().forceLogout();
        }
        handler.next(error);
      },
    );
  }

  /// Queue-based token refresh: concurrent 401s share a single refresh attempt
  Future<bool> _tryRefreshToken() async {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<bool>();

    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        _refreshCompleter!.complete(false);
        return false;
      }

      final refreshDio = Dio(BaseOptions(baseUrl: ApiEndpoints.baseUrl));
      if (MockInterceptor.useMock) {
        refreshDio.interceptors.add(MockInterceptor());
      }

      final response = await refreshDio.post(
        ApiEndpoints.refreshToken,
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200 && response.data['code'] == 0) {
        final data = response.data['data'];
        if (data is! Map<String, dynamic>) {
          _refreshCompleter!.complete(false);
          return false;
        }
        final newAccessToken = data['access_token'] as String?;
        final newRefreshToken = data['refresh_token'] as String?;
        if (newAccessToken == null || newRefreshToken == null) {
          _refreshCompleter!.complete(false);
          return false;
        }

        await _storage.saveAccessToken(newAccessToken);
        await _storage.saveRefreshToken(newRefreshToken);

        _refreshCompleter!.complete(true);
        return true;
      }
      _refreshCompleter!.complete(false);
      return false;
    } catch (e) {
      debugPrint('Token 刷新失败: $e');
      _refreshCompleter!.complete(false);
      return false;
    } finally {
      _refreshCompleter = null;
    }
  }

  InterceptorsWrapper _errorInterceptor() {
    return InterceptorsWrapper(
      onResponse: (response, handler) {
        final data = response.data;
        if (data is Map && data['code'] != null && data['code'] != 0) {
          handler.reject(
            DioException(
              requestOptions: response.requestOptions,
              response: response,
              type: DioExceptionType.badResponse,
              message: data['message'] ?? '未知错误',
            ),
          );
          return;
        }
        handler.next(response);
      },
      onError: (error, handler) {
        String message;
        switch (error.type) {
          case DioExceptionType.connectionTimeout:
          case DioExceptionType.sendTimeout:
          case DioExceptionType.receiveTimeout:
            message = '网络连接超时，请稍后重试';
          case DioExceptionType.connectionError:
            message = '网络连接失败，请检查网络设置';
          case DioExceptionType.badResponse:
            final statusCode = error.response?.statusCode;
            final responseData = error.response?.data;
            if (responseData is Map && responseData['message'] != null) {
              message = responseData['message'];
            } else {
              message = switch (statusCode) {
                400 => '请求参数错误',
                401 => '登录已过期，请重新登录',
                403 => '暂无权限',
                404 => '请求的资源不存在',
                429 => '请求过于频繁，请稍后重试',
                500 => '服务器开小差了，请稍后重试',
                _ => '请求失败（$statusCode）',
              };
            }
          case DioExceptionType.cancel:
            message = '请求已取消';
          default:
            message = '网络异常，请稍后重试';
        }
        debugPrint('API Error: ${error.requestOptions.path} -> $message');
        handler.next(error.copyWith(message: message));
      },
    );
  }

  LogInterceptor _logInterceptor() {
    return LogInterceptor(
      request: true,
      requestBody: true,
      responseBody: true,
      requestHeader: true,
      responseHeader: true,
      logPrint: (obj) => debugPrint(obj.toString()),
    );
  }

  // ============================================================
  // 便捷请求方法
  // ============================================================

  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    final response = await _dio.get(path, queryParameters: queryParameters);
    return ApiResponse.fromJson(response.data, fromJson);
  }

  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    T Function(dynamic)? fromJson,
  }) async {
    final response = await _dio.post(path, data: data);
    return ApiResponse.fromJson(response.data, fromJson);
  }

  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    T Function(dynamic)? fromJson,
  }) async {
    final response = await _dio.put(path, data: data);
    return ApiResponse.fromJson(response.data, fromJson);
  }

  Future<ApiResponse<T>> delete<T>(
    String path, {
    dynamic data,
    T Function(dynamic)? fromJson,
  }) async {
    final response = await _dio.delete(path, data: data);
    return ApiResponse.fromJson(response.data, fromJson);
  }

  Future<ApiResponse<T>> upload<T>(
    String path, {
    required String filePath,
    String fieldName = 'file',
    Map<String, dynamic>? extraFields,
    T Function(dynamic)? fromJson,
    void Function(int, int)? onSendProgress,
  }) async {
    final formData = FormData.fromMap({
      fieldName: await MultipartFile.fromFile(filePath),
      ...?extraFields,
    });
    final response = await _dio.post(
      path,
      data: formData,
      onSendProgress: onSendProgress,
    );
    return ApiResponse.fromJson(response.data, fromJson);
  }
}
