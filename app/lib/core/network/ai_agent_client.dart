import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../auth/auth_session_manager.dart';
import '../config/app_env.dart';
import '../storage/storage_service.dart';
import 'sse_client.dart';

/// Dedicated Dio client for the AI Agent (Python) service.
/// Keeps the longer SSE-friendly timeouts while reusing app auth headers.
class AiAgentClient {
  static AiAgentClient? _instance;
  late final Dio _dio;
  final StorageService _storage = StorageService();

  AiAgentClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppEnv.aiAgentBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          options.headers['X-Device-Type'] =
              defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
          options.headers['X-App-Version'] = '1.0.0';
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await AuthSessionManager().forceLogout();
          }
          handler.next(error);
        },
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: false,
          responseHeader: false,
          logPrint: (obj) => debugPrint('[AiAgent] $obj'),
        ),
      );
    }
  }

  factory AiAgentClient() {
    _instance ??= AiAgentClient._();
    return _instance!;
  }

  Dio get dio => _dio;

  Map<String, dynamic> _expectJsonMap(
    dynamic body, {
    required String method,
    required String path,
  }) {
    if (body is Map<String, dynamic>) return body;
    if (body is Map) return Map<String, dynamic>.from(body);
    throw FormatException(
      '$method $path expected JSON object but got ${body.runtimeType}',
    );
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    final response = await _dio.post(path, data: data);
    return _expectJsonMap(response.data, method: 'POST', path: path);
  }

  Future<Map<String, dynamic>> get(String path) async {
    final response = await _dio.get(path);
    return _expectJsonMap(response.data, method: 'GET', path: path);
  }

  /// Open an SSE stream via POST. Returns parsed [SseEvent]s.
  ///
  /// The caller should use `await for` to consume events and pass a
  /// [CancelToken] to abort the stream when navigating away.
  Stream<SseEvent> postSseStream(
    String path, {
    Map<String, dynamic>? data,
    CancelToken? cancelToken,
  }) async* {
    final response = await _dio.post<ResponseBody>(
      path,
      data: data,
      options: Options(
        responseType: ResponseType.stream,
        // SSE is a long-lived connection — disable receive timeout
        receiveTimeout: Duration.zero,
        headers: {'Accept': 'text/event-stream'},
      ),
      cancelToken: cancelToken,
    );
    yield* SseClient.parse(response.data!.stream);
  }
}
