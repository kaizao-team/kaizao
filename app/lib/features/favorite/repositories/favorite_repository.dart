import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/favorite_models.dart';

class FavoriteRepository {
  final ApiClient _client = ApiClient();

  Future<void> addFavorite({
    required String targetType,
    required String targetId,
  }) async {
    await _client.post(
      ApiEndpoints.favorites,
      data: {'target_type': targetType, 'target_id': targetId},
    );
  }

  Future<void> removeFavorite({
    required String targetType,
    required String targetId,
  }) async {
    await _client.delete(
      ApiEndpoints.favorites,
      data: {'target_type': targetType, 'target_id': targetId},
    );
  }

  Future<({List<FavoriteItem> items, FavoriteListMeta meta})> fetchMyFavorites({
    int page = 1,
    int pageSize = 20,
    String? targetType,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
      if (targetType != null) 'target_type': targetType,
    };

    final response = await _client.get(
      ApiEndpoints.myFavorites,
      queryParameters: params,
    );

    final rawData = response.data;
    final List<FavoriteItem> items;
    final FavoriteListMeta meta;

    if (rawData is Map<String, dynamic>) {
      final list = rawData['items'] as List? ?? rawData['data'] as List? ?? [];
      items = list
          .whereType<Map<String, dynamic>>()
          .map((e) => FavoriteItem.fromJson(e))
          .toList();
      final metaRaw = rawData['meta'] as Map<String, dynamic>?;
      meta = metaRaw != null
          ? FavoriteListMeta.fromJson(metaRaw)
          : FavoriteListMeta(page: page, total: items.length);
    } else if (rawData is List) {
      items = rawData
          .whereType<Map<String, dynamic>>()
          .map((e) => FavoriteItem.fromJson(e))
          .toList();
      meta = FavoriteListMeta(page: page, total: items.length);
    } else {
      items = [];
      meta = const FavoriteListMeta();
    }

    return (items: items, meta: meta);
  }
}
