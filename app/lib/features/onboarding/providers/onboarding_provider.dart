import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/storage_service.dart';
import '../repositories/demander_onboarding_repository.dart';
import '../repositories/expert_onboarding_repository.dart';

enum OnboardingRole { demander, expert }

class OnboardingState {
  final OnboardingRole? role;
  final int currentStep;
  final int totalSteps;
  final bool isCompleted;
  final bool isLoading;
  final Map<String, dynamic> draft;
  final String? errorMessage;

  const OnboardingState({
    this.role,
    this.currentStep = 0,
    this.totalSteps = 4,
    this.isCompleted = false,
    this.isLoading = false,
    this.draft = const {},
    this.errorMessage,
  });

  int get totalStepsForRole => role == OnboardingRole.demander ? 4 : 3;

  OnboardingState copyWith({
    OnboardingRole? role,
    int? currentStep,
    int? totalSteps,
    bool? isCompleted,
    bool? isLoading,
    Map<String, dynamic>? draft,
    String? errorMessage,
  }) {
    return OnboardingState(
      role: role ?? this.role,
      currentStep: currentStep ?? this.currentStep,
      totalSteps: totalSteps ?? this.totalSteps,
      isCompleted: isCompleted ?? this.isCompleted,
      isLoading: isLoading ?? this.isLoading,
      draft: draft ?? this.draft,
      errorMessage: errorMessage,
    );
  }
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final StorageService _storage;
  final DemanderOnboardingRepository _demanderRepository;
  final ExpertOnboardingRepository _expertRepository;

  OnboardingNotifier(
    this._storage,
    this._demanderRepository,
    this._expertRepository,
  ) : super(const OnboardingState()) {
    _restore();
  }

  String _normalizeError(Object error) {
    final message = error.toString();
    return message.startsWith('Exception: ')
        ? message.substring('Exception: '.length)
        : message;
  }

  String? _readProjectId(Map<String, dynamic> data) {
    final candidates = [
      data['uuid'],
      data['project_uuid'],
      data['draft_id'],
      data['id'],
      state.draft['project_uuid'],
      state.draft['id'],
    ];
    for (final value in candidates) {
      final text = value?.toString().trim();
      if (text != null && text.isNotEmpty) {
        return text;
      }
    }
    return null;
  }

  bool _isMissingPublishEndpoint(Object error) {
    if (error is DioException) {
      if (error.response?.statusCode == 404) {
        return true;
      }

      final responseData = error.response?.data;
      if (responseData is String &&
          responseData.toLowerCase().contains('404 page not found')) {
        return true;
      }
    }

    final message = error.toString().toLowerCase();
    return message.contains('404') || message.contains('not found');
  }

  int? _mapAvailabilityStatus(String availability) {
    switch (availability) {
      case '随时':
        return 1;
      case '1周内':
        return 1;
      case '1-2周':
        return 2;
      case '1个月内':
        return 3;
      default:
        return null;
    }
  }

  String _categoryForExpertSkill(String value) {
    switch (value) {
      case 'Flutter':
      case 'React':
      case 'Vue.js':
        return 'framework';
      case 'Python':
      case 'Go':
      case 'Rust':
        return 'language';
      case 'UI设计':
        return 'design';
      case 'AI/ML':
        return 'tool';
      case '后端':
      case '全栈':
        return 'other';
      case 'Figma':
        return 'design';
      default:
        return 'tool';
    }
  }

  List<ExpertSkillDraft> _buildExpertSkills({
    required List<String> skills,
    required List<String> tools,
  }) {
    final items = <ExpertSkillDraft>[];
    final seen = <String>{};

    void add(String value) {
      final name = value.trim();
      if (name.isEmpty || seen.contains(name)) return;
      seen.add(name);
      items.add(
        ExpertSkillDraft(
          name: name,
          category: _categoryForExpertSkill(name),
          isPrimary: items.isEmpty,
        ),
      );
    }

    for (final skill in skills) {
      add(skill);
    }
    for (final tool in tools) {
      add(tool);
    }

    return items;
  }

  Future<String?> _ensureDemanderProjectDraft() async {
    final existing = _readProjectId(state.draft);
    if (existing != null) {
      return existing;
    }

    final draft = await _demanderRepository.createProjectDraft();
    final projectId = _readProjectId(draft);
    if (projectId == null) {
      throw Exception('草稿创建成功，但接口没有返回项目 ID');
    }

    await saveDraft({
      ...draft,
      'project_uuid': projectId,
    });
    return projectId;
  }

  Future<void> _restore() async {
    final roleStr = await _storage.getOnboardingRole();
    final step = await _storage.getOnboardingStep();
    final completed = await _storage.isOnboardingCompleted();
    final draftJson = await _storage.getOnboardingDraft();
    if (!mounted) return;

    OnboardingRole? role;
    if (roleStr == 'demander') role = OnboardingRole.demander;
    if (roleStr == 'expert') role = OnboardingRole.expert;

    Map<String, dynamic> draft = {};
    if (draftJson != null) {
      try {
        draft = jsonDecode(draftJson) as Map<String, dynamic>;
      } catch (_) {}
    }

    state = OnboardingState(
      role: role,
      currentStep: step,
      totalSteps: role == OnboardingRole.expert ? 3 : 4,
      isCompleted: completed,
      draft: draft,
    );
  }

  Future<void> setRole(OnboardingRole role) async {
    final totalSteps = role == OnboardingRole.demander ? 4 : 3;
    await _storage.saveOnboardingRole(
      role == OnboardingRole.demander ? 'demander' : 'expert',
    );
    if (!mounted) return;
    state = state.copyWith(role: role, totalSteps: totalSteps, currentStep: 0);
  }

  Future<void> nextStep() async {
    final next = state.currentStep + 1;
    await _storage.saveOnboardingStep(next);
    if (!mounted) return;
    state = state.copyWith(currentStep: next);
  }

  Future<void> goToStep(int step) async {
    await _storage.saveOnboardingStep(step);
    if (!mounted) return;
    state = state.copyWith(currentStep: step);
  }

  Future<void> saveDraft(Map<String, dynamic> data) async {
    final merged = {...state.draft, ...data};
    await _storage.saveOnboardingDraft(jsonEncode(merged));
    if (!mounted) return;
    state = state.copyWith(draft: merged);
  }

  Future<void> complete() async {
    await _storage.setOnboardingCompleted();
    await _storage.clearOnboardingDraft();
    if (!mounted) return;
    state = state.copyWith(isCompleted: true, draft: const {});
  }

  Future<void> reset() async {
    await _storage.clearOnboardingState();
    if (!mounted) return;
    state = const OnboardingState();
  }

  Future<bool> submitData(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await saveDraft(data);
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return false;
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      await saveDraft(data);
      if (!mounted) return false;
      state = state.copyWith(
        isLoading: false,
        errorMessage: '保存失败，已记录草稿',
      );
      return false;
    }
  }

  Future<bool> submitDemanderProfile({
    required String nickname,
    String? avatarUrl,
    String? contactPhone,
  }) async {
    final phone =
        (contactPhone != null && contactPhone.isNotEmpty) ? contactPhone : null;
    final payload = {
      'nickname': nickname,
      'avatar_url': avatarUrl,
      if (phone != null) 'contact_phone': phone,
    };

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _demanderRepository.updateProfile(
        nickname: nickname,
        avatarUrl: avatarUrl,
        contactPhone: phone,
      );
      await saveDraft(payload);
      if (!mounted) return false;
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      await saveDraft(payload);
      if (!mounted) return false;
      state = state.copyWith(
        isLoading: false,
        errorMessage: _normalizeError(e),
      );
      return false;
    }
  }

  Future<bool> submitExpertProfile({
    required String nickname,
    required List<String> skills,
    required List<String> tools,
    required int selfRating,
    required String availability,
    required double rateMin,
    required double rateMax,
    String? contactPhone,
  }) async {
    final phone =
        (contactPhone != null && contactPhone.isNotEmpty) ? contactPhone : null;
    final payload = {
      'nickname': nickname,
      'skills': skills,
      'tools': tools,
      'self_rating': selfRating,
      'availability': availability,
      'rate_min': rateMin,
      'rate_max': rateMax,
      if (phone != null) 'contact_phone': phone,
    };

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _expertRepository.updateProfile(
        nickname: nickname,
        hourlyRate: rateMin,
        availableStatus: _mapAvailabilityStatus(availability),
        role: 2,
        contactPhone: phone,
      );
      await _expertRepository.updateSkills(
        _buildExpertSkills(skills: skills, tools: tools),
      );
      await saveDraft(payload);
      if (!mounted) return false;
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      await saveDraft(payload);
      if (!mounted) return false;
      state = state.copyWith(
        isLoading: false,
        errorMessage: _normalizeError(e),
      );
      return false;
    }
  }

  Future<bool> submitExpertSupplement({
    required String bio,
  }) async {
    final payload = {'bio': bio};

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _expertRepository.updateProfile(bio: bio);
      await saveDraft(payload);
      if (!mounted) return false;
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      await saveDraft(payload);
      if (!mounted) return false;
      state = state.copyWith(
        isLoading: false,
        errorMessage: _normalizeError(e),
      );
      return false;
    }
  }

  Future<String?> createDemanderProjectDraft() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final projectId = await _ensureDemanderProjectDraft();
      if (!mounted) return null;
      state = state.copyWith(isLoading: false);
      return projectId;
    } catch (e) {
      if (!mounted) return null;
      state = state.copyWith(
        isLoading: false,
        errorMessage: _normalizeError(e),
      );
      return null;
    }
  }

  Future<String?> publishDemanderProject({
    required String title,
    required String description,
    required String category,
    required String categoryLabel,
    required double budgetMin,
    required double budgetMax,
  }) async {
    final localDraft = {
      'project_title': title,
      'project_desc': description,
      'category': category,
      'category_label': categoryLabel,
      'budget_min': budgetMin,
      'budget_max': budgetMax,
    };

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final projectId = await _ensureDemanderProjectDraft();
      if (projectId == null) {
        throw Exception('项目草稿创建失败');
      }

      final updated = await _demanderRepository.updateProjectDraft(projectId, {
        'title': title,
        'description': description,
        'category': category,
        'budget_min': budgetMin,
        'budget_max': budgetMax,
        'match_mode': 1,
      });
      late final Map<String, dynamic> published;
      try {
        published = await _demanderRepository.publishProject(projectId);
      } catch (error) {
        if (!_isMissingPublishEndpoint(error)) {
          rethrow;
        }

        published = await _demanderRepository.createProject(
          title: title,
          description: description,
          category: category,
          budgetMin: budgetMin,
          budgetMax: budgetMax,
        );
      }
      final resolvedProjectId =
          _readProjectId(published) ?? _readProjectId(updated) ?? projectId;

      await saveDraft({
        ...localDraft,
        ...updated,
        ...published,
        'project_uuid': resolvedProjectId,
      });
      if (!mounted) return null;
      state = state.copyWith(isLoading: false);
      return resolvedProjectId;
    } catch (e) {
      await saveDraft(localDraft);
      if (!mounted) return null;
      state = state.copyWith(
        isLoading: false,
        errorMessage: _normalizeError(e),
      );
      return null;
    }
  }
}

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  final repository = ref.watch(demanderOnboardingRepositoryProvider);
  final expertRepository = ref.watch(expertOnboardingRepositoryProvider);
  return OnboardingNotifier(StorageService(), repository, expertRepository);
});
