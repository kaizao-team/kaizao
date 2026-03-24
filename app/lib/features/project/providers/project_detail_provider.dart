import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../market/repositories/market_repository.dart';

class ProjectDetailState {
  final bool isLoading;
  final Map<String, dynamic>? data;
  final String? errorMessage;

  const ProjectDetailState({
    this.isLoading = false,
    this.data,
    this.errorMessage,
  });

  ProjectDetailState copyWith({
    bool? isLoading,
    Map<String, dynamic>? data,
    String? Function()? errorMessage,
  }) {
    return ProjectDetailState(
      isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  String get title => data?['title'] as String? ?? '';
  String get description => data?['description'] as String? ?? '';
  String get category => data?['category'] as String? ?? '';
  String get prdSummary => data?['prd_summary'] as String? ?? '';
  double get budgetMin => (data?['budget_min'] as num?)?.toDouble() ?? 0;
  double get budgetMax => (data?['budget_max'] as num?)?.toDouble() ?? 0;
  int get status => data?['status'] as int? ?? 0;
  int get viewCount => data?['view_count'] as int? ?? 0;
  int get bidCount => data?['bid_count'] as int? ?? 0;
  List<String> get techRequirements =>
      (data?['tech_requirements'] as List?)
          ?.map((e) => e?.toString() ?? '')
          .toList() ??
      [];
  List<Map<String, dynamic>> get milestones =>
      (data?['milestones'] as List?)?.whereType<Map<String, dynamic>>().toList() ??
      [];

  String get budgetDisplay =>
      '¥${budgetMin.toStringAsFixed(0)}-${budgetMax.toStringAsFixed(0)}';

  String get statusName {
    switch (status) {
      case 1: return '草稿';
      case 2: return '已发布';
      case 3: return '匹配中';
      case 4: return '已匹配';
      case 5: return '进行中';
      case 6: return '验收中';
      case 7: return '已完成';
      case 8: return '已关闭';
      case 9: return '争议中';
      default: return '未知';
    }
  }
}

class ProjectDetailNotifier extends StateNotifier<ProjectDetailState> {
  final MarketRepository _repository;
  final String projectId;

  ProjectDetailNotifier(this._repository, this.projectId)
      : super(const ProjectDetailState()) {
    loadDetail();
  }

  Future<void> loadDetail() async {
    state = state.copyWith(isLoading: true, errorMessage: () => null);
    try {
      final data = await _repository.fetchProjectDetail(projectId);
      if (!mounted) return;
      state = state.copyWith(isLoading: false, data: data);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: () => e.toString(),
      );
    }
  }
}

final projectDetailProvider = StateNotifierProvider.autoDispose.family<
    ProjectDetailNotifier, ProjectDetailState, String>((ref, id) {
  final repository = MarketRepository();
  return ProjectDetailNotifier(repository, id);
});
