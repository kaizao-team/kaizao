import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/project_models.dart';
import '../repositories/project_repository.dart';

class ProjectManageState {
  final bool isLoading;
  final ProjectTab currentTab;
  final List<KanbanTask> tasks;
  final List<Milestone> milestones;
  final List<ProjectFile> files;
  final String selectedFileKind;
  final bool isMilestoneActing;
  final String? errorMessage;

  const ProjectManageState({
    this.isLoading = false,
    this.currentTab = ProjectTab.tasks,
    this.tasks = const [],
    this.milestones = const [],
    this.files = const [],
    this.selectedFileKind = 'reference',
    this.isMilestoneActing = false,
    this.errorMessage,
  });

  ProjectManageState copyWith({
    bool? isLoading,
    ProjectTab? currentTab,
    List<KanbanTask>? tasks,
    List<Milestone>? milestones,
    List<ProjectFile>? files,
    String? selectedFileKind,
    bool? isMilestoneActing,
    String? Function()? errorMessage,
  }) {
    return ProjectManageState(
      isLoading: isLoading ?? this.isLoading,
      currentTab: currentTab ?? this.currentTab,
      tasks: tasks ?? this.tasks,
      milestones: milestones ?? this.milestones,
      files: files ?? this.files,
      selectedFileKind: selectedFileKind ?? this.selectedFileKind,
      isMilestoneActing: isMilestoneActing ?? this.isMilestoneActing,
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

  List<ProjectFile> get filteredFiles =>
      files.where((f) => f.fileKind == selectedFileKind).toList();
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
      final tasks = await _repository.fetchTasks(projectId);
      final milestones = await _repository.fetchMilestones(projectId);
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        tasks: tasks,
        milestones: milestones,
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
    if (tab == ProjectTab.files && state.files.isEmpty) {
      loadFiles();
    }
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

  Future<void> deliverMilestone(String milestoneId,
      {String? note, String? previewUrl}) async {
    state = state.copyWith(isMilestoneActing: true);
    try {
      await _repository.deliverMilestone(milestoneId,
          note: note, previewUrl: previewUrl);
      if (!mounted) return;
      await _reloadMilestones();
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
          isMilestoneActing: false, errorMessage: () => e.toString());
    }
  }

  Future<void> acceptMilestone(String milestoneId) async {
    state = state.copyWith(isMilestoneActing: true);
    try {
      await _repository.acceptMilestone(milestoneId);
      if (!mounted) return;
      await _reloadMilestones();
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
          isMilestoneActing: false, errorMessage: () => e.toString());
    }
  }

  Future<void> requestRevision(String milestoneId, {String? reason}) async {
    state = state.copyWith(isMilestoneActing: true);
    try {
      await _repository.requestRevision(milestoneId, reason: reason);
      if (!mounted) return;
      await _reloadMilestones();
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
          isMilestoneActing: false, errorMessage: () => e.toString());
    }
  }

  Future<void> _reloadMilestones() async {
    final milestones = await _repository.fetchMilestones(projectId);
    if (!mounted) return;
    state = state.copyWith(isMilestoneActing: false, milestones: milestones);
  }

  Future<void> loadFiles() async {
    try {
      final files = await _repository.fetchFiles(projectId);
      if (!mounted) return;
      state = state.copyWith(files: files);
    } catch (_) {}
  }

  void setFileKind(String kind) {
    state = state.copyWith(selectedFileKind: kind);
  }

  Future<String> fetchDownloadUrl(String uuid) async {
    return _repository.fetchFileDownloadUrl(projectId, uuid);
  }
}

final projectManageProvider = StateNotifierProvider.autoDispose
    .family<ProjectManageNotifier, ProjectManageState, String>(
        (ref, projectId) {
  return ProjectManageNotifier(ProjectRepository(), projectId);
});
