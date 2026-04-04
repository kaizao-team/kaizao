import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/favorite_models.dart';
import '../repositories/favorite_repository.dart';

class FavoriteListState {
  final bool isLoading;
  final List<FavoriteItem> items;
  final FavoriteListMeta meta;
  final String? filterType;
  final String? errorMessage;

  const FavoriteListState({
    this.isLoading = false,
    this.items = const [],
    this.meta = const FavoriteListMeta(),
    this.filterType,
    this.errorMessage,
  });

  bool get hasMore => meta.page < meta.totalPages;

  FavoriteListState copyWith({
    bool? isLoading,
    List<FavoriteItem>? items,
    FavoriteListMeta? meta,
    String? Function()? filterType,
    String? Function()? errorMessage,
  }) {
    return FavoriteListState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      meta: meta ?? this.meta,
      filterType: filterType != null ? filterType() : this.filterType,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }
}

class FavoriteListNotifier extends StateNotifier<FavoriteListState> {
  final FavoriteRepository _repository;

  FavoriteListNotifier(this._repository) : super(const FavoriteListState()) {
    loadFavorites();
  }

  Future<void> loadFavorites({bool refresh = true}) async {
    final page = refresh ? 1 : (state.meta.page + 1);
    state = state.copyWith(isLoading: true, errorMessage: () => null);

    try {
      final result = await _repository.fetchMyFavorites(
        page: page,
        targetType: state.filterType,
      );
      if (!mounted) return;

      state = state.copyWith(
        isLoading: false,
        items: refresh ? result.items : [...state.items, ...result.items],
        meta: result.meta,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: () => e.toString(),
      );
    }
  }

  void setFilter(String? type) {
    state = state.copyWith(filterType: () => type);
    loadFavorites();
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoading) return;
    await loadFavorites(refresh: false);
  }
}

final favoriteRepositoryProvider = Provider<FavoriteRepository>((ref) {
  return FavoriteRepository();
});

final favoriteListProvider =
    StateNotifierProvider.autoDispose<FavoriteListNotifier, FavoriteListState>(
        (ref) {
  return FavoriteListNotifier(ref.watch(favoriteRepositoryProvider));
});

class FavoriteToggleState {
  final Set<String> favorited;
  final Set<String> loading;

  const FavoriteToggleState({
    this.favorited = const {},
    this.loading = const {},
  });

  bool isFavorited(String targetId) => favorited.contains(targetId);
  bool isLoading(String targetId) => loading.contains(targetId);
}

class FavoriteToggleNotifier extends StateNotifier<FavoriteToggleState> {
  final FavoriteRepository _repository;

  FavoriteToggleNotifier(this._repository)
      : super(const FavoriteToggleState());

  void markFavorited(String targetId) {
    state = FavoriteToggleState(
      favorited: {...state.favorited, targetId},
      loading: state.loading,
    );
  }

  void markUnfavorited(String targetId) {
    state = FavoriteToggleState(
      favorited: {...state.favorited}..remove(targetId),
      loading: state.loading,
    );
  }

  Future<bool> toggle({
    required String targetType,
    required String targetId,
  }) async {
    if (state.isLoading(targetId)) return false;

    state = FavoriteToggleState(
      favorited: state.favorited,
      loading: {...state.loading, targetId},
    );

    try {
      if (state.isFavorited(targetId)) {
        await _repository.removeFavorite(
            targetType: targetType, targetId: targetId);
        if (!mounted) return false;
        markUnfavorited(targetId);
      } else {
        await _repository.addFavorite(
            targetType: targetType, targetId: targetId);
        if (!mounted) return false;
        markFavorited(targetId);
      }

      state = FavoriteToggleState(
        favorited: state.favorited,
        loading: {...state.loading}..remove(targetId),
      );
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = FavoriteToggleState(
        favorited: state.favorited,
        loading: {...state.loading}..remove(targetId),
      );
      return false;
    }
  }
}

final favoriteToggleProvider =
    StateNotifierProvider<FavoriteToggleNotifier, FavoriteToggleState>((ref) {
  return FavoriteToggleNotifier(ref.watch(favoriteRepositoryProvider));
});
