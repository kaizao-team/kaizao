import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/project_models.dart';
import '../repositories/project_repository.dart';

class ProjectManageState {
  final bool isLoading;
  final ProjectTab currentTab;
  final List<KanbanTask> tasks;
  final List<Milestone> milestones;
  final List<DailyReport> reports;
  final String? errorMessage;

  const ProjectManageState({
    this.isLoading = false,
    this.currentTab = ProjectTab.kanban,
    this.tasks = const [],
    this.milestones = const [],
    this.reports = const [],
    this.errorMessage,
  });

  ProjectManageState copyWith({
    bool? isLoading,
    ProjectTab? currentTab,
    List<KanbanTask>? tasks,
    List<Milestone>? milestones,
    List<DailyReport>? reports,
    String? Function()? errorMessage,
  }) {
    return ProjectManageState(
      isLoading: isLoading ?? this.isLoading,
      currentTab: currentTab ?? this.currentTab,
      tasks: tasks ?? this.tasks,
      milestones: milestones ?? this.milestones,
      reports: reports ?? this.reports,
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

      final tasks = await tasksFuture;
      final milestones = await milestonesFuture;
      final reports = await reportsFuture;
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        tasks: tasks,
        milestones: milestones,
        reports: reports,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: () => e.toString(),
      );
    }
  }

  void switchTab(ProjectTab tab) {
    state = state.copyWith(currentTab: tab);
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
