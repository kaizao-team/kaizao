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

  static int _statusPriority(int status) {
    switch (status) {
      case 5: return 0; // 进行中
      case 6: return 1; // 验收中
      case 9: return 2; // 争议中
      case 4: return 3; // 需求对齐中
      case 3: return 4; // 已撮合
      case 2: return 5; // 已发布
      case 1: return 6; // 草稿
      case 7: return 7; // 已完成
      case 8: return 8; // 已关闭
      default: return 9;
    }
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, errorMessage: () => null);
    try {
      final projects = await _repository.fetchMyProjects(role: _userRole);
      if (!mounted) return;
      final sorted = List<ProjectModel>.from(projects)
        ..sort((a, b) {
          final pa = _statusPriority(a.status);
          final pb = _statusPriority(b.status);
          if (pa != pb) return pa.compareTo(pb);
          return b.createdAt.compareTo(a.createdAt);
        });
      state = state.copyWith(isLoading: false, projects: sorted);
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
