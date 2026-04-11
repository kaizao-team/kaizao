import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/ai_agent_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/project_models.dart';
import '../repositories/project_repository.dart';

class ProjectManageState {
  final bool isLoading;
  final ProjectTab currentTab;
  final List<KanbanTask> tasks;
  final List<Milestone> milestones;
  final List<DailyReport> reports;
  final List<Map<String, dynamic>> prdItems;
  final String? errorMessage;

  const ProjectManageState({
    this.isLoading = false,
    this.currentTab = ProjectTab.kanban,
    this.tasks = const [],
    this.milestones = const [],
    this.reports = const [],
    this.prdItems = const [],
    this.errorMessage,
  });

  ProjectManageState copyWith({
    bool? isLoading,
    ProjectTab? currentTab,
    List<KanbanTask>? tasks,
    List<Milestone>? milestones,
    List<DailyReport>? reports,
    List<Map<String, dynamic>>? prdItems,
    String? Function()? errorMessage,
  }) {
    return ProjectManageState(
      isLoading: isLoading ?? this.isLoading,
      currentTab: currentTab ?? this.currentTab,
      tasks: tasks ?? this.tasks,
      milestones: milestones ?? this.milestones,
      reports: reports ?? this.reports,
      prdItems: prdItems ?? this.prdItems,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  List<KanbanTask> get todoTasks => tasks.where((t) => t.isTodo).toList();
  List<KanbanTask> get inProgressTasks =>
      tasks.where((t) => t.isInProgress).toList();
  List<KanbanTask> get completedTasks =>
      tasks.where((t) => t.isCompleted).toList();

  int get totalProgress {
    if (tasks.isEmpty) return 0;
    return (completedTasks.length / tasks.length * 100).round();
  }

  bool get hasRisks => tasks.any((t) => t.isAtRisk);
  int get riskCount => tasks.where((t) => t.isAtRisk).length;
}

class ProjectManageNotifier extends StateNotifier<ProjectManageState> {
  final ProjectRepository _repository;
  final String projectId;

  ProjectManageNotifier(this._repository, this.projectId)
      : super(const ProjectManageState()) {
    loadAll();
  }

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, errorMessage: () => null);
    try {
      final tasksFuture = _repository.fetchTasks(projectId);
      final milestonesFuture = _repository.fetchMilestones(projectId);
      final reportsFuture = _repository.fetchDailyReports(projectId);
      final prdItemsFuture = _fetchPrdItems();

      final tasks = await tasksFuture;
      final milestones = await milestonesFuture;
      final reports = await reportsFuture;
      final prdItems = await prdItemsFuture;
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        tasks: tasks,
        milestones: milestones,
        reports: reports,
        prdItems: prdItems,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: () => e.toString(),
      );
    }
  }

  Future<List<Map<String, dynamic>>> _fetchPrdItems() async {
    try {
      final aiClient = AiAgentClient();
      final overview = await aiClient.get(ApiEndpoints.pipelineOverview(projectId));
      final overviewData = overview['data'];
      if (overviewData is Map && overviewData['prd_items'] is List) {
        return (overviewData['prd_items'] as List)
            .whereType<Map<String, dynamic>>()
            .toList();
      }
    } catch (e) {
      debugPrint('[ProjectManage] fetchPrdItems error: $e');
    }
    return [];
  }

  void switchTab(ProjectTab tab) {
    state = state.copyWith(currentTab: tab);
  }

  Future<bool> completeMilestone(String milestoneId) async {
    try {
      await _repository.completeMilestone(milestoneId);
      await loadAll();
      return true;
    } catch (e) {
      debugPrint('[ProjectManage] completeMilestone error: $e');
      return false;
    }
  }

  Future<bool> deliverProject({String? note, String? previewUrl}) async {
    try {
      await _repository.deliverProject(projectId,
          note: note, previewUrl: previewUrl);
      await loadAll();
      return true;
    } catch (e) {
      debugPrint('[ProjectManage] deliverProject error: $e');
      return false;
    }
  }

  bool get canDeliverProject {
    return state.milestones.isNotEmpty &&
        state.milestones.every((m) => m.isCompleted);
  }

  Future<void> moveTask(String taskId, String newStatus) async {
    final updatedTasks = state.tasks.map((t) {
      if (t.id == taskId) return t.copyWith(status: newStatus);
      return t;
    }).toList();
    state = state.copyWith(tasks: updatedTasks);

    try {
      await _repository.updateTaskStatus(taskId, newStatus);
    } catch (_) {
      if (!mounted) return;
      await loadAll();
    }
  }
}

final projectManageProvider = StateNotifierProvider.autoDispose
    .family<ProjectManageNotifier, ProjectManageState, String>(
        (ref, projectId) {
  return ProjectManageNotifier(ProjectRepository(), projectId);
});
