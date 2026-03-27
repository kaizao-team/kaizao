import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/market_expert.dart';
import '../models/market_filter.dart';
import '../repositories/market_repository.dart';

class MarketState {
  final List<MarketProjectItem> projects;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final String selectedCategory;
  final String sortBy;
  final double? budgetMin;
  final double? budgetMax;
  final String? errorMessage;

  const MarketState({
    this.projects = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.selectedCategory = 'all',
    this.sortBy = 'latest',
    this.budgetMin,
    this.budgetMax,
    this.errorMessage,
  });

  MarketState copyWith({
    List<MarketProjectItem>? projects,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    String? selectedCategory,
    String? sortBy,
    double? Function()? budgetMin,
    double? Function()? budgetMax,
    String? Function()? errorMessage,
  }) {
    return MarketState(
      projects: projects ?? this.projects,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      sortBy: sortBy ?? this.sortBy,
      budgetMin: budgetMin != null ? budgetMin() : this.budgetMin,
      budgetMax: budgetMax != null ? budgetMax() : this.budgetMax,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }
}

class MarketNotifier extends StateNotifier<MarketState> {
  final MarketRepository _repository;

  MarketNotifier(this._repository, {String? initialCategory})
    : super(
        MarketState(selectedCategory: normalizeMarketCategory(initialCategory)),
      ) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    state = state.copyWith(
      isLoading: true,
      currentPage: 1,
      projects: [],
      hasMore: true,
      errorMessage: () => null,
    );
    try {
      final result = await _repository.fetchProjects(
        page: 1,
        category: state.selectedCategory,
        sort: state.sortBy,
        budgetMin: state.budgetMin,
        budgetMax: state.budgetMax,
      );
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        projects: result.list,
        hasMore: result.meta.hasMore,
        currentPage: 1,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: () => e.toString(),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final nextPage = state.currentPage + 1;
      final result = await _repository.fetchProjects(
        page: nextPage,
        category: state.selectedCategory,
        sort: state.sortBy,
        budgetMin: state.budgetMin,
        budgetMax: state.budgetMax,
      );
      if (!mounted) return;
      state = state.copyWith(
        isLoadingMore: false,
        projects: [...state.projects, ...result.list],
        hasMore: result.meta.hasMore,
        currentPage: nextPage,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: () => e.toString(),
      );
    }
  }

  void setCategory(String category) {
    final normalizedCategory = normalizeMarketCategory(category);
    if (state.selectedCategory == normalizedCategory) return;
    state = state.copyWith(selectedCategory: normalizedCategory);
    loadInitial();
  }

  void setSort(String sort) {
    if (state.sortBy == sort) return;
    state = state.copyWith(sortBy: sort);
    loadInitial();
  }

  void setBudgetRange(double? min, double? max) {
    state = state.copyWith(budgetMin: () => min, budgetMax: () => max);
    loadInitial();
  }

  Future<void> refresh() async {
    await loadInitial();
  }
}

final marketRepositoryProvider = Provider<MarketRepository>((ref) {
  return MarketRepository();
});

final marketStateProvider =
    StateNotifierProvider.family<MarketNotifier, MarketState, String?>((
      ref,
      initialCategory,
    ) {
      final repository = ref.watch(marketRepositoryProvider);
      return MarketNotifier(repository, initialCategory: initialCategory);
    });

class ExpertListState {
  final bool isLoading;
  final List<MarketExpertItem> experts;
  final String? errorMessage;

  const ExpertListState({
    this.isLoading = false,
    this.experts = const [],
    this.errorMessage,
  });

  ExpertListState copyWith({
    bool? isLoading,
    List<MarketExpertItem>? experts,
    String? Function()? errorMessage,
  }) {
    return ExpertListState(
      isLoading: isLoading ?? this.isLoading,
      experts: experts ?? this.experts,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }
}

class ExpertListNotifier extends StateNotifier<ExpertListState> {
  final MarketRepository _repository;

  ExpertListNotifier(this._repository) : super(const ExpertListState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, errorMessage: () => null);
    try {
      final experts = await _repository.fetchExperts();
      if (!mounted) return;
      state = state.copyWith(isLoading: false, experts: experts);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: () => e.toString(),
      );
    }
  }

  Future<void> refresh() async => load();
}

final expertListProvider =
    StateNotifierProvider<ExpertListNotifier, ExpertListState>((ref) {
      final repository = ref.watch(marketRepositoryProvider);
      return ExpertListNotifier(repository);
    });
