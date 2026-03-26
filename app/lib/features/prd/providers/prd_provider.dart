import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/prd_models.dart';
import '../repositories/prd_repository.dart';

class PrdState {
  final bool isLoading;
  final PrdData? data;
  final PrdViewMode viewMode;
  final String? expandedCardId;
  final String? roleFilter;
  final String? errorMessage;

  const PrdState({
    this.isLoading = false,
    this.data,
    this.viewMode = PrdViewMode.overview,
    this.expandedCardId,
    this.roleFilter,
    this.errorMessage,
  });

  PrdState copyWith({
    bool? isLoading,
    PrdData? data,
    PrdViewMode? viewMode,
    String? Function()? expandedCardId,
    String? Function()? roleFilter,
    String? Function()? errorMessage,
  }) {
    return PrdState(
      isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      viewMode: viewMode ?? this.viewMode,
      expandedCardId: expandedCardId != null ? expandedCardId() : this.expandedCardId,
      roleFilter: roleFilter != null ? roleFilter() : this.roleFilter,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  List<EarsCard> get filteredCards {
    if (data == null) return [];
    final all = data!.modules.expand((m) => m.cards).toList();
    if (roleFilter == null) return all;
    return all.where((c) => c.roles.contains(roleFilter)).toList();
  }

  List<EarsCard> get activeCards =>
      filteredCards.where((c) => c.status != 'completed').toList();

  List<EarsCard> get completedCards =>
      filteredCards.where((c) => c.status == 'completed').toList();
}

class PrdNotifier extends StateNotifier<PrdState> {
  final PrdRepository _repository;
  final String projectId;

  PrdNotifier(this._repository, this.projectId) : super(const PrdState()) {
    loadPrd();
  }

  Future<void> loadPrd() async {
    state = state.copyWith(isLoading: true, errorMessage: () => null);
    try {
      final json = await _repository.fetchPrd(projectId);
      if (!mounted) return;
      final prdData = PrdData.fromJson(json);
      state = state.copyWith(isLoading: false, data: prdData);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: () => e.toString(),
      );
    }
  }

  void toggleViewMode() {
    state = state.copyWith(
      viewMode: state.viewMode == PrdViewMode.overview
          ? PrdViewMode.cards
          : PrdViewMode.overview,
    );
  }

  void expandCard(String? cardId) {
    state = state.copyWith(
      expandedCardId: () =>
          state.expandedCardId == cardId ? null : cardId,
    );
  }

  void setRoleFilter(String? role) {
    state = state.copyWith(
      roleFilter: () => state.roleFilter == role ? null : role,
    );
  }

  Future<void> toggleCriteria(String cardId, String criteriaId) async {
    final data = state.data;
    if (data == null) return;

    final updatedModules = data.modules.map((module) {
      final updatedCards = module.cards.map((card) {
        if (card.id != cardId) return card;
        final updatedCriteria = card.acceptanceCriteria.map((c) {
          if (c.id != criteriaId) return c;
          return c.copyWith(checked: !c.checked);
        }).toList();

        final allChecked = updatedCriteria.every((c) => c.checked);

        return EarsCard(
          id: card.id,
          moduleId: card.moduleId,
          title: card.title,
          type: card.type,
          priority: card.priority,
          description: card.description,
          event: card.event,
          action: card.action,
          response: card.response,
          stateChange: card.stateChange,
          acceptanceCriteria: updatedCriteria,
          roles: card.roles,
          effortHours: card.effortHours,
          dependencies: card.dependencies,
          techTags: card.techTags,
          status: allChecked ? 'completed' : card.status == 'completed' ? 'in_progress' : card.status,
        );
      }).toList();

      return PrdModule(
        id: module.id,
        name: module.name,
        icon: module.icon,
        order: module.order,
        cards: updatedCards,
      );
    }).toList();

    state = state.copyWith(
      data: PrdData(
        prdId: data.prdId,
        projectId: data.projectId,
        title: data.title,
        version: data.version,
        createdAt: data.createdAt,
        modules: updatedModules,
      ),
    );

    try {
      await _repository.updateCard(projectId, cardId, {
        'criteria_id': criteriaId,
      });
    } catch (_) {
      // best-effort sync
    }
  }
}

final prdRepositoryProvider = Provider<PrdRepository>((ref) {
  return PrdRepository();
});

final prdStateProvider = StateNotifierProvider.autoDispose
    .family<PrdNotifier, PrdState, String>((ref, projectId) {
  final repository = ref.watch(prdRepositoryProvider);
  return PrdNotifier(repository, projectId);
});
