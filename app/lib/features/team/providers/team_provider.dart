import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/team_models.dart';
import '../models/team_profile.dart';
import '../repositories/team_repository.dart';

// ---------- Team Hall (list) ----------

class TeamHallState {
  final bool isLoading;
  final List<TeamPost> aiRecommended;
  final List<TeamPost> posts;
  final String? roleFilter;
  final String? errorMessage;

  const TeamHallState({
    this.isLoading = false,
    this.aiRecommended = const [],
    this.posts = const [],
    this.roleFilter,
    this.errorMessage,
  });

  TeamHallState copyWith({
    bool? isLoading,
    List<TeamPost>? aiRecommended,
    List<TeamPost>? posts,
    String? Function()? roleFilter,
    String? Function()? errorMessage,
  }) {
    return TeamHallState(
      isLoading: isLoading ?? this.isLoading,
      aiRecommended: aiRecommended ?? this.aiRecommended,
      posts: posts ?? this.posts,
      roleFilter: roleFilter != null ? roleFilter() : this.roleFilter,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }
}

class TeamHallNotifier extends StateNotifier<TeamHallState> {
  final TeamRepository _repository;

  TeamHallNotifier(this._repository) : super(const TeamHallState()) {
    loadPosts();
  }

  Future<void> loadPosts() async {
    state = state.copyWith(isLoading: true, errorMessage: () => null);
    try {
      final data =
          await _repository.fetchTeamHall(roleFilter: state.roleFilter);
      if (!mounted) return;

      final aiList = (data['ai_recommended'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((e) => TeamPost.fromJson(e))
          .toList();
      final postList = (data['posts'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((e) => TeamPost.fromJson(e))
          .toList();

      state = state.copyWith(
        isLoading: false,
        aiRecommended: aiList,
        posts: postList,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: () => e.toString(),
      );
    }
  }

  void setRoleFilter(String? role) {
    state = state.copyWith(roleFilter: () => role);
    loadPosts();
  }

  Future<bool> createPost(Map<String, dynamic> data) async {
    try {
      await _repository.createTeamPost(data);
      if (!mounted) return false;
      await loadPosts();
      if (!mounted) return false;
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(errorMessage: () => e.toString());
      return false;
    }
  }
}

final teamHallProvider =
    StateNotifierProvider.autoDispose<TeamHallNotifier, TeamHallState>((ref) {
  return TeamHallNotifier(TeamRepository());
});

// ---------- Team Detail (confirm / split) ----------

class TeamDetailState {
  final bool isLoading;
  final TeamDetail? detail;
  final bool isSubmitting;
  final String? errorMessage;

  const TeamDetailState({
    this.isLoading = false,
    this.detail,
    this.isSubmitting = false,
    this.errorMessage,
  });

  TeamDetailState copyWith({
    bool? isLoading,
    TeamDetail? detail,
    bool? isSubmitting,
    String? Function()? errorMessage,
  }) {
    return TeamDetailState(
      isLoading: isLoading ?? this.isLoading,
      detail: detail ?? this.detail,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }
}

class TeamDetailNotifier extends StateNotifier<TeamDetailState> {
  final TeamRepository _repository;
  final String _teamId;

  TeamDetailNotifier(this._repository, this._teamId)
      : super(const TeamDetailState()) {
    _load();
  }

  Future<void> _load() async {
    state = state.copyWith(isLoading: true, errorMessage: () => null);
    try {
      final detail = await _repository.fetchTeamDetail(_teamId);
      if (!mounted) return;
      state = state.copyWith(isLoading: false, detail: detail);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: () => e.toString(),
      );
    }
  }

  void updateMemberRatio(String memberId, int newRatio) {
    final d = state.detail;
    if (d == null) return;
    final updated = d.members.map((m) {
      if (m.id == memberId) return m.copyWith(ratio: newRatio);
      return m;
    }).toList();
    state = state.copyWith(
      detail: TeamDetail(
        id: d.id,
        projectName: d.projectName,
        projectId: d.projectId,
        status: d.status,
        members: updated,
        createdAt: d.createdAt,
      ),
    );
  }

  Future<bool> confirmTeam() async {
    final d = state.detail;
    if (d == null || !d.isRatioValid) return false;

    state = state.copyWith(isSubmitting: true, errorMessage: () => null);
    try {
      await _repository.updateSplitRatio(
        _teamId,
        d.members
            .map((m) => {'member_id': m.id, 'ratio': m.ratio})
            .toList(),
      );
      if (!mounted) return false;
      await _repository.confirmTeam(_teamId);
      if (!mounted) return false;
      state = state.copyWith(isSubmitting: false);
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: () => e.toString(),
      );
      return false;
    }
  }
}

final teamDetailProvider = StateNotifierProvider.autoDispose
    .family<TeamDetailNotifier, TeamDetailState, String>((ref, teamId) {
  return TeamDetailNotifier(TeamRepository(), teamId);
});

// ---------- Team Public Profile ----------

class TeamProfileState {
  final bool isLoading;
  final TeamProfile? profile;
  final String? errorMessage;

  const TeamProfileState({
    this.isLoading = false,
    this.profile,
    this.errorMessage,
  });

  TeamProfileState copyWith({
    bool? isLoading,
    TeamProfile? profile,
    String? Function()? errorMessage,
  }) {
    return TeamProfileState(
      isLoading: isLoading ?? this.isLoading,
      profile: profile ?? this.profile,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }
}

class TeamProfileNotifier extends StateNotifier<TeamProfileState> {
  final TeamRepository _repository;
  final String _teamId;

  TeamProfileNotifier(this._repository, this._teamId)
      : super(const TeamProfileState()) {
    _load();
  }

  Future<void> _load() async {
    state = state.copyWith(isLoading: true, errorMessage: () => null);
    try {
      final profile = await _repository.fetchTeamProfile(_teamId);
      if (!mounted) return;
      state = state.copyWith(isLoading: false, profile: profile);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: () => e.toString(),
      );
    }
  }
}

final teamProfileProvider = StateNotifierProvider.autoDispose
    .family<TeamProfileNotifier, TeamProfileState, String>((ref, teamId) {
  return TeamProfileNotifier(TeamRepository(), teamId);
});
