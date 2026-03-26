import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/acceptance_models.dart';
import '../repositories/acceptance_repository.dart';

class AcceptanceState {
  final bool isLoading;
  final bool isSubmitting;
  final AcceptanceChecklist? checklist;
  final String? errorMessage;

  const AcceptanceState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.checklist,
    this.errorMessage,
  });

  AcceptanceState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    AcceptanceChecklist? checklist,
    String? Function()? errorMessage,
  }) {
    return AcceptanceState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      checklist: checklist ?? this.checklist,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }
}

class AcceptanceNotifier extends StateNotifier<AcceptanceState> {
  final AcceptanceRepository _repository;
  final String milestoneId;

  AcceptanceNotifier(this._repository, this.milestoneId)
      : super(const AcceptanceState()) {
    loadChecklist();
  }

  Future<void> loadChecklist() async {
    state = state.copyWith(isLoading: true, errorMessage: () => null);
    try {
      final checklist = await _repository.fetchChecklist(milestoneId);
      if (!mounted) return;
      state = state.copyWith(isLoading: false, checklist: checklist);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: () => e.toString(),
      );
    }
  }

  void toggleItem(String itemId) {
    final cl = state.checklist;
    if (cl == null) return;
    final updated = cl.items.map((item) {
      if (item.id == itemId) return item.copyWith(isChecked: !item.isChecked);
      return item;
    }).toList();
    state = state.copyWith(checklist: cl.copyWith(items: updated));
  }

  Future<bool> confirmAcceptance() async {
    state = state.copyWith(isSubmitting: true, errorMessage: () => null);
    try {
      await _repository.confirmAcceptance(milestoneId);
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

  Future<bool> submitRevision(
      String description, List<String> relatedItemIds) async {
    state = state.copyWith(isSubmitting: true, errorMessage: () => null);
    try {
      await _repository.submitRevision(
        milestoneId: milestoneId,
        description: description,
        relatedItemIds: relatedItemIds,
      );
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

final acceptanceProvider = StateNotifierProvider.autoDispose
    .family<AcceptanceNotifier, AcceptanceState, String>(
        (ref, milestoneId) {
  return AcceptanceNotifier(AcceptanceRepository(), milestoneId);
});
