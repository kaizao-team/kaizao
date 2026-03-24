import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/project_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../repositories/project_repository.dart';

class ProjectListState {
  final bool isLoading;
  final List<ProjectModel> projects;
  final String? errorMessage;

  const ProjectListState({
    this.isLoading = false,
    this.projects = const [],
    this.errorMessage,
  });

  ProjectListState copyWith({
    bool? isLoading,
    List<ProjectModel>? projects,
    String? Function()? errorMessage,
  }) {
    return ProjectListState(
      isLoading: isLoading ?? this.isLoading,
      projects: projects ?? this.projects,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }
}

class ProjectListNotifier extends StateNotifier<ProjectListState> {
  final ProjectRepository _repository;
  final int _userRole;

  ProjectListNotifier(this._repository, this._userRole)
      : super(const ProjectListState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, errorMessage: () => null);
    try {
      final projects = await _repository.fetchMyProjects(role: _userRole);
      if (!mounted) return;
      state = state.copyWith(isLoading: false, projects: projects);
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

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return ProjectRepository();
});

final projectListProvider =
    StateNotifierProvider<ProjectListNotifier, ProjectListState>((ref) {
  final repository = ref.watch(projectRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  return ProjectListNotifier(repository, authState.userRole);
});
