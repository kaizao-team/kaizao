import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/profile_models.dart';
import '../repositories/profile_repository.dart';

class ProfileState {
  final bool isLoading;
  final UserProfile? profile;
  final List<SkillTag> skills;
  final List<PortfolioItem> portfolios;
  final String? errorMessage;

  const ProfileState({
    this.isLoading = false,
    this.profile,
    this.skills = const [],
    this.portfolios = const [],
    this.errorMessage,
  });

  ProfileState copyWith({
    bool? isLoading,
    UserProfile? profile,
    List<SkillTag>? skills,
    List<PortfolioItem>? portfolios,
    String? Function()? errorMessage,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      profile: profile ?? this.profile,
      skills: skills ?? this.skills,
      portfolios: portfolios ?? this.portfolios,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  final ProfileRepository _repository;
  final String _userId;

  ProfileNotifier(this._repository, this._userId)
      : super(const ProfileState()) {
    loadProfile();
  }

  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, errorMessage: () => null);
    try {
      final profile = _userId == 'me'
          ? await _repository.fetchCurrentUser()
          : await _repository.fetchProfile(_userId);
      if (!mounted) return;

      final effectiveId = profile.id;
      final results = await Future.wait([
        _repository.fetchSkills(effectiveId),
        _repository.fetchPortfolios(effectiveId),
      ]);
      if (!mounted) return;

      state = state.copyWith(
        isLoading: false,
        profile: profile,
        skills: results[0] as List<SkillTag>,
        portfolios: results[1] as List<PortfolioItem>,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: () => e.toString(),
      );
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      final userId = state.profile?.id ?? _userId;
      await _repository.updateProfile(userId, data);
      if (!mounted) return false;
      await loadProfile();
      if (!mounted) return false;
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(errorMessage: () => e.toString());
      return false;
    }
  }

  Future<bool> updateSkills(List<SkillTag> skills) async {
    try {
      final userId = state.profile?.id ?? _userId;
      await _repository.updateSkills(userId, skills);
      if (!mounted) return false;
      state = state.copyWith(skills: skills);
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(errorMessage: () => e.toString());
      return false;
    }
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

final profileProvider = StateNotifierProvider.autoDispose
    .family<ProfileNotifier, ProfileState, String>((ref, userId) {
  if (userId == 'me') {
    ref.keepAlive();
  }
  final repository = ref.watch(profileRepositoryProvider);
  return ProfileNotifier(repository, userId);
});
