import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/storage_service.dart';

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

  OnboardingNotifier(this._storage) : super(const OnboardingState()) {
    _restore();
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
    state = state.copyWith(isCompleted: true);
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
}

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  return OnboardingNotifier(StorageService());
});
