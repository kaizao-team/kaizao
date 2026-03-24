import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_response.dart';
import '../models/market_filter.dart';

class MarketRepository {
  final ApiClient _client = ApiClient();

  Future<PaginatedResponse<MarketProjectItem>> fetchProjects({
    int page = 1,
    int pageSize = 10,
    String? category,
    String sort = 'latest',
    double? budgetMin,
    double? budgetMax,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
      'sort': sort,
    };
    if (category != null && category.isNotEmpty && category != 'all') {
      queryParams['category'] = category;
    }
    if (budgetMin != null) queryParams['budget_min'] = budgetMin;
    if (budgetMax != null) queryParams['budget_max'] = budgetMax;

    final response = await _client.get<List<dynamic>>(
      ApiEndpoints.marketProjects,
      queryParameters: queryParams,
      fromJson: (data) => data as List<dynamic>,
    );

    final items = (response.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map((e) => MarketProjectItem.fromJson(e))
        .toList();

    return PaginatedResponse(
      list: items,
      meta: response.meta ?? const PaginationMeta(page: 1, pageSize: 10, total: 0, totalPages: 0),
    );
  }

  Future<Map<String, dynamic>> fetchProjectDetail(String id) async {
    final response = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.projectDetail(id),
      fromJson: (data) => data as Map<String, dynamic>,
    );
    return response.data ?? {};
  }
}
