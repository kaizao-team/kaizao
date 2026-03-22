import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_endpoints.dart';
import 'api_response.dart';
import '../storage/storage_service.dart';



/// Dio 网络客户端封装
/// 包含 JWT 拦截器、自动刷新 Token、统一错误处理
class ApiClient {
  static ApiClient? _instance;
  late final Dio _dio;
  final StorageService _storage = StorageService();

  // Token 刷新锁，防止并发刷新
  bool _isRefreshing = false;
  final List<void Function(String)> _pendingRequests = [];

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

    // 添加拦截器
    _dio.interceptors.addAll([
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

  /// JWT 认证拦截器
  InterceptorsWrapper _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        // 不需要认证的接口
        final noAuthPaths = [
          ApiEndpoints.sendSmsCode,
          ApiEndpoints.login,
          ApiEndpoints.register,
          ApiEndpoints.wechatLogin,
          ApiEndpoints.refreshToken,
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

        // 添加设备信息头
        options.headers['X-Device-Type'] = defaultTargetPlatform == TargetPlatform.iOS
            ? 'ios'
            : 'android';
        options.headers['X-App-Version'] = '1.0.0';

        handler.next(options);
      },
      onError: (error, handler) async {
        // 401 错误 -> 尝试刷新 Token
        if (error.response?.statusCode == 401) {
          final refreshed = await _tryRefreshToken();
          if (refreshed) {
            // 重新发起原始请求
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
          // 刷新失败 -> 清除登录态
          await _storage.clearTokens();
        }
        handler.next(error);
      },
    );
  }

  /// 尝试刷新 Token
  Future<bool> _tryRefreshToken() async {
    if (_isRefreshing) {
      // 已经在刷新中，等待完成
      return false;
    }

    _isRefreshing = true;

    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        return false;
      }

      // 使用独立的Dio实例刷新Token，避免循环拦截
      final refreshDio = Dio(BaseOptions(baseUrl: ApiEndpoints.baseUrl));
      final response = await refreshDio.post(
        ApiEndpoints.refreshToken,
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200 && response.data['code'] == 0) {
        final newAccessToken = response.data['data']['access_token'] as String;
        final newRefreshToken = response.data['data']['refresh_token'] as String;

        await _storage.saveAccessToken(newAccessToken);
        await _storage.saveRefreshToken(newRefreshToken);

        // 通知所有等待的请求
        for (final callback in _pendingRequests) {
          callback(newAccessToken);
        }
        _pendingRequests.clear();

        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Token 刷新失败: $e');
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  /// 统一错误拦截器
  InterceptorsWrapper _errorInterceptor() {
    return InterceptorsWrapper(
      onResponse: (response, handler) {
        // 统一处理业务错误码
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
            break;
          case DioExceptionType.connectionError:
            message = '网络连接失败，请检查网络设置';
            break;
          case DioExceptionType.badResponse:
            final statusCode = error.response?.statusCode;
            final responseData = error.response?.data;
            if (responseData is Map && responseData['message'] != null) {
              message = responseData['message'];
            } else {
              switch (statusCode) {
                case 400:
                  message = '请求参数错误';
                  break;
                case 401:
                  message = '登录已过期，请重新登录';
                  break;
                case 403:
                  message = '暂无权限';
                  break;
                case 404:
                  message = '请求的资源不存在';
                  break;
                case 429:
                  message = '请求过于频繁，请稍后重试';
                  break;
                case 500:
                  message = '服务器开小差了，请稍后重试';
                  break;
                default:
                  message = '请求失败（$statusCode）';
              }
            }
            break;
          case DioExceptionType.cancel:
            message = '请求已取消';
            break;
          default:
            message = '网络异常，请稍后重试';
        }
        debugPrint('API Error: ${error.requestOptions.path} -> $message');
        handler.next(error.copyWith(message: message));
      },
    );
  }

  /// 日志拦截器（仅Debug模式）
  LogInterceptor _logInterceptor() {
    return LogInterceptor(
      requestBody: true,
      responseBody: true,
      requestHeader: false,
      responseHeader: false,
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
    T Function(dynamic)? fromJson,
  }) async {
    final response = await _dio.delete(path);
    return ApiResponse.fromJson(response.data, fromJson);
  }

  /// 文件上传
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
