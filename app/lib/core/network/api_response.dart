/// 统一 API 响应模型
class ApiResponse<T> {
  final int code;
  final String message;
  final T? data;
  final PaginationMeta? meta;
  final String? requestId;

  const ApiResponse({
    required this.code,
    required this.message,
    this.data,
    this.meta,
    this.requestId,
  });

  bool get isSuccess => code == 0;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJson,
  ) {
    return ApiResponse<T>(
      code: json['code'] as int? ?? -1,
      message: json['message'] as String? ?? '',
      data: json['data'] != null && fromJson != null
          ? fromJson(json['data'])
          : json['data'] as T?,
      meta: json['meta'] != null
          ? PaginationMeta.fromJson(json['meta'])
          : null,
      requestId: json['request_id'] as String?,
    );
  }
}

/// 分页元数据
class PaginationMeta {
  final int page;
  final int pageSize;
  final int total;
  final int totalPages;

  const PaginationMeta({
    required this.page,
    required this.pageSize,
    required this.total,
    required this.totalPages,
  });

  bool get hasMore => page < totalPages;

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      page: json['page'] as int? ?? 1,
      pageSize: json['page_size'] as int? ?? 20,
      total: json['total'] as int? ?? 0,
      totalPages: json['total_pages'] as int? ?? 0,
    );
  }
}

/// 分页列表响应
class PaginatedResponse<T> {
  final List<T> list;
  final PaginationMeta meta;

  const PaginatedResponse({
    required this.list,
    required this.meta,
  });
}
