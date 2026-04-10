import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/ai_agent_client.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../auth/providers/auth_provider.dart';
import '../../market/repositories/market_repository.dart';
import '../../match/repositories/match_repository.dart';
import '../repositories/project_repository.dart';

class ProjectDetailState {
  final bool isLoading;
  final Map<String, dynamic>? data;
  final String? errorMessage;
  final bool hasBid;
  final List<Map<String, dynamic>> prdItems;
  final List<Map<String, dynamic>> earsTasks;
  final bool isConfirmingBid;
  final bool isRejectingBid;
  final bool isConfirmingAlignment;
  final bool isStartingProject;

  const ProjectDetailState({
    this.isLoading = false,
    this.data,
    this.errorMessage,
    this.hasBid = false,
    this.prdItems = const [],
    this.earsTasks = const [],
    this.isConfirmingBid = false,
    this.isRejectingBid = false,
    this.isConfirmingAlignment = false,
    this.isStartingProject = false,
  });

  ProjectDetailState copyWith({
    bool? isLoading,
    Map<String, dynamic>? data,
    String? Function()? errorMessage,
    bool? hasBid,
    List<Map<String, dynamic>>? prdItems,
    List<Map<String, dynamic>>? earsTasks,
    bool? isConfirmingBid,
    bool? isRejectingBid,
    bool? isConfirmingAlignment,
    bool? isStartingProject,
  }) {
    return ProjectDetailState(
      isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      hasBid: hasBid ?? this.hasBid,
      prdItems: prdItems ?? this.prdItems,
      earsTasks: earsTasks ?? this.earsTasks,
      isConfirmingBid: isConfirmingBid ?? this.isConfirmingBid,
      isRejectingBid: isRejectingBid ?? this.isRejectingBid,
      isConfirmingAlignment: isConfirmingAlignment ?? this.isConfirmingAlignment,
      isStartingProject: isStartingProject ?? this.isStartingProject,
    );
  }

  String get title => data?['title']?.toString() ?? '';
  String get description => data?['description']?.toString() ?? '';
  String get category => data?['category']?.toString() ?? '';
  String get prdSummary => data?['prd_summary']?.toString() ?? '';
  double get budgetMin => (data?['budget_min'] as num?)?.toDouble() ?? 0;
  double get budgetMax => (data?['budget_max'] as num?)?.toDouble() ?? 0;
  int get status => data?['status'] as int? ?? 0;
  int get viewCount => data?['view_count'] as int? ?? 0;
  int get bidCount => data?['bid_count'] as int? ?? 0;
  int get progress => data?['progress'] as int? ?? 0;
  int get matchScore => data?['match_score'] as int? ?? 0;
  String get ownerName => data?['owner_name']?.toString() ?? '';
  String get ownerId => data?['owner_id']?.toString() ?? '';
  String get createdAt => data?['created_at']?.toString() ?? '';
  List<String> get techRequirements =>
      (data?['tech_requirements'] as List?)
          ?.map((e) => e?.toString() ?? '')
          .toList() ??
      [];
  List<Map<String, dynamic>> get milestones =>
      (data?['milestones'] as List?)?.whereType<Map<String, dynamic>>().toList() ??
      [];

  bool get hasEarsTasks => earsTasks.isNotEmpty;

  String get categoryName {
    switch (category) {
      case 'dev': return '开发';
      case 'visual': return '视觉设计';
      case 'design': return '视觉设计';
      case 'content': return '内容';
      case 'consulting': return '咨询';
      case 'data': return '数据';
      case 'solution': return '解决方案';
      default: return category.isNotEmpty ? category : '未分类';
    }
  }

  String get timeAgo {
    if (createdAt.isEmpty) return '';
    try {
      final dt = DateTime.parse(createdAt);
      final diff = DateTime.now().difference(dt);
      if (diff.inDays > 30) return '${diff.inDays ~/ 30}月前';
      if (diff.inDays > 0) return '${diff.inDays}天前';
      if (diff.inHours > 0) return '${diff.inHours}小时前';
      if (diff.inMinutes > 0) return '${diff.inMinutes}分钟前';
      return '刚刚';
    } catch (_) {
      return '';
    }
  }

  String? get bidId => data?['bid_id']?.toString();

  bool get isFavorited => data?['is_favorited'] as bool? ?? false;

  String get budgetDisplay =>
      '¥${budgetMin.toStringAsFixed(0)}-${budgetMax.toStringAsFixed(0)}';

  /// 项目状态 (与 server model.Project 对齐)
  /// 1=草稿 2=已发布 3=已撮合 4=需求对齐中 5=进行中
  /// 6=验收中 7=已完成 8=已关闭 9=争议中
  String get statusName {
    switch (status) {
      case 1: return '草稿';
      case 2: return '已发布';
      case 3: return '已撮合';
      case 4: return '需求对齐中';
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
  final MatchRepository _matchRepository;
  final ProjectRepository _projectRepository;
  final String projectId;
  final String? _currentUserId;

  ProjectDetailNotifier(
    this._repository,
    this._matchRepository,
    this._projectRepository,
    this.projectId,
    this._currentUserId,
  ) : super(const ProjectDetailState()) {
    loadDetail();
  }

  Future<void> loadDetail() async {
    state = state.copyWith(isLoading: true, errorMessage: () => null);
    try {
      final data = await _repository.fetchProjectDetail(projectId);
      if (!mounted) return;

      bool hasBid = false;
      if (_currentUserId != null && _currentUserId.isNotEmpty) {
        try {
          final bids = await _matchRepository.fetchBids(projectId);
          hasBid = bids.any((b) => b.userId == _currentUserId);
        } catch (_) {}
      }

      // Fetch prd items from AI Agent overview (best effort)
      List<Map<String, dynamic>> prdItems = [];
      try {
        final aiClient = AiAgentClient();
        final overview = await aiClient.get(ApiEndpoints.pipelineOverview(projectId));
        final overviewData = overview['data'];
        if (overviewData is Map && overviewData['prd_items'] is List) {
          prdItems = (overviewData['prd_items'] as List)
              .whereType<Map<String, dynamic>>()
              .toList();
        }
      } catch (_) {}

      // Fetch EARS tasks (best effort)
      List<Map<String, dynamic>> earsTasks = [];
      try {
        final apiClient = ApiClient();
        final tasksResp = await apiClient.get<List>(
          ApiEndpoints.projectTasks(projectId),
          fromJson: (data) => data is List ? data : [],
        );
        if (tasksResp.data != null) {
          earsTasks = tasksResp.data!
              .whereType<Map<String, dynamic>>()
              .toList();
        }
      } catch (_) {}

      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        data: data,
        hasBid: hasBid,
        prdItems: prdItems,
        earsTasks: earsTasks,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: () => e.toString(),
      );
    }
  }

  Future<bool> confirmBid() async {
    final bidId = state.bidId;
    if (bidId == null || bidId.isEmpty) return false;
    state = state.copyWith(isConfirmingBid: true);
    try {
      await _matchRepository.confirmBid(bidId);
      await loadDetail();
      return true;
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isConfirmingBid: false,
          errorMessage: () => e.toString(),
        );
      }
      return false;
    }
  }

  Future<bool> rejectBid() async {
    final bidId = state.bidId;
    if (bidId == null || bidId.isEmpty) return false;
    state = state.copyWith(isRejectingBid: true);
    try {
      await _matchRepository.rejectBid(bidId);
      await loadDetail();
      return true;
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isRejectingBid: false,
          errorMessage: () => e.toString(),
        );
      }
      return false;
    }
  }

  Future<bool> confirmAlignment() async {
    state = state.copyWith(isConfirmingAlignment: true);
    try {
      await _projectRepository.confirmAlignment(projectId);
      await loadDetail();
      return true;
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isConfirmingAlignment: false,
          errorMessage: () => e.toString(),
        );
      }
      return false;
    }
  }

  Future<bool> startProject() async {
    state = state.copyWith(isStartingProject: true);
    try {
      await _projectRepository.startProject(projectId);
      await loadDetail();
      return true;
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isStartingProject: false,
          errorMessage: () => e.toString(),
        );
      }
      return false;
    }
  }
}

final projectDetailProvider = StateNotifierProvider.autoDispose.family<
    ProjectDetailNotifier, ProjectDetailState, String>((ref, id) {
  final repository = MarketRepository();
  final matchRepository = MatchRepository();
  final projectRepository = ProjectRepository();
  final authState = ref.watch(authStateProvider);
  return ProjectDetailNotifier(
      repository, matchRepository, projectRepository, id, authState.userId,);
});
