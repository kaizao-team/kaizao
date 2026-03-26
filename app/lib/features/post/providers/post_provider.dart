import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post_models.dart';
import '../repositories/post_repository.dart';

class PostState {
  final int currentStep;
  final String? category;
  final List<AiChatMessage> messages;
  final bool isAiTyping;
  final bool canGeneratePrd;
  final PrdGeneratedData? prdData;
  final bool isGeneratingPrd;
  final int prdProgress;
  final double? budgetMin;
  final double? budgetMax;
  final BudgetSuggestion? budgetSuggestion;
  final MatchMode? matchMode;
  final bool isPublishing;
  final String? errorMessage;
  final Map<String, bool> validationErrors;

  const PostState({
    this.currentStep = 0,
    this.category,
    this.messages = const [],
    this.isAiTyping = false,
    this.canGeneratePrd = false,
    this.prdData,
    this.isGeneratingPrd = false,
    this.prdProgress = 0,
    this.budgetMin,
    this.budgetMax,
    this.budgetSuggestion,
    this.matchMode,
    this.isPublishing = false,
    this.errorMessage,
    this.validationErrors = const {},
  });

  PostState copyWith({
    int? currentStep,
    String? Function()? category,
    List<AiChatMessage>? messages,
    bool? isAiTyping,
    bool? canGeneratePrd,
    PrdGeneratedData? Function()? prdData,
    bool? isGeneratingPrd,
    int? prdProgress,
    double? Function()? budgetMin,
    double? Function()? budgetMax,
    BudgetSuggestion? Function()? budgetSuggestion,
    MatchMode? Function()? matchMode,
    bool? isPublishing,
    String? Function()? errorMessage,
    Map<String, bool>? validationErrors,
  }) {
    return PostState(
      currentStep: currentStep ?? this.currentStep,
      category: category != null ? category() : this.category,
      messages: messages ?? this.messages,
      isAiTyping: isAiTyping ?? this.isAiTyping,
      canGeneratePrd: canGeneratePrd ?? this.canGeneratePrd,
      prdData: prdData != null ? prdData() : this.prdData,
      isGeneratingPrd: isGeneratingPrd ?? this.isGeneratingPrd,
      prdProgress: prdProgress ?? this.prdProgress,
      budgetMin: budgetMin != null ? budgetMin() : this.budgetMin,
      budgetMax: budgetMax != null ? budgetMax() : this.budgetMax,
      budgetSuggestion: budgetSuggestion != null ? budgetSuggestion() : this.budgetSuggestion,
      matchMode: matchMode != null ? matchMode() : this.matchMode,
      isPublishing: isPublishing ?? this.isPublishing,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      validationErrors: validationErrors ?? this.validationErrors,
    );
  }

  bool get canPublish =>
      category != null &&
      prdData != null &&
      budgetMin != null &&
      budgetMax != null &&
      matchMode != null;
}

class PostNotifier extends StateNotifier<PostState> {
  final PostRepository _repository;

  PostNotifier(this._repository) : super(const PostState());

  void selectCategory(String category) {
    state = state.copyWith(
      category: () => category,
      currentStep: 1,
    );
  }

  Future<void> sendMessage(String content) async {
    final userMsg = AiChatMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      content: content,
      isUser: true,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isAiTyping: true,
      errorMessage: () => null,
    );

    try {
      final result = await _repository.sendAiMessage(content, state.category);
      if (!mounted) return;

      final aiMsg = AiChatMessage(
        id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
        content: result['reply'] as String? ?? '',
        isUser: false,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, aiMsg],
        isAiTyping: false,
        canGeneratePrd: result['can_generate_prd'] as bool? ?? false,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isAiTyping: false,
        errorMessage: () => e.toString(),
      );
    }
  }

  Future<void> generatePrd() async {
    state = state.copyWith(isGeneratingPrd: true, prdProgress: 0);

    final steps = ['分析需求...', '构建模块结构...', '生成EARS卡片...', '完成PRD文档'];
    for (int i = 0; i < steps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      state = state.copyWith(prdProgress: ((i + 1) / steps.length * 100).round());
    }

    try {
      final chatHistory = state.messages
          .map((m) => {'role': m.isUser ? 'user' : 'assistant', 'content': m.content})
          .toList();
      final result = await _repository.generatePrd(state.category ?? '', chatHistory);
      if (!mounted) return;

      final prdData = PrdGeneratedData.fromJson(result);
      state = state.copyWith(
        isGeneratingPrd: false,
        prdData: () => prdData,
        budgetSuggestion: () => prdData.budgetSuggestion,
        budgetMin: () => prdData.budgetSuggestion?.min,
        budgetMax: () => prdData.budgetSuggestion?.max,
        currentStep: 2,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isGeneratingPrd: false,
        errorMessage: () => e.toString(),
      );
    }
  }

  void setBudget(double min, double max) {
    state = state.copyWith(
      budgetMin: () => min,
      budgetMax: () => max,
      currentStep: 3,
    );
  }

  void setMatchMode(MatchMode mode) {
    state = state.copyWith(matchMode: () => mode);
  }

  Map<String, bool> validate() {
    final errors = <String, bool>{};
    if (state.category == null) errors['category'] = true;
    if (state.prdData == null) errors['prd'] = true;
    if (state.budgetMin == null || state.budgetMax == null) errors['budget'] = true;
    if (state.matchMode == null) errors['matchMode'] = true;
    state = state.copyWith(validationErrors: errors);
    return errors;
  }

  Future<String?> publish() async {
    final errors = validate();
    if (errors.isNotEmpty) return null;

    state = state.copyWith(isPublishing: true, errorMessage: () => null);
    try {
      final result = await _repository.publishProject({
        'category': state.category,
        'prd_id': state.prdData?.prdId,
        'budget_min': state.budgetMin,
        'budget_max': state.budgetMax,
        'match_mode': state.matchMode?.value,
      });
      if (!mounted) return null;

      state = state.copyWith(isPublishing: false);
      return result['id'] as String?;
    } catch (e) {
      if (!mounted) return null;
      state = state.copyWith(
        isPublishing: false,
        errorMessage: () => e.toString(),
      );
      return null;
    }
  }

  Future<void> saveDraft() async {
    try {
      await _repository.saveDraft({
        'category': state.category,
        'budget_min': state.budgetMin,
        'budget_max': state.budgetMax,
        'match_mode': state.matchMode?.value,
        'step': state.currentStep,
      });
    } catch (_) {
      // draft save is best-effort
    }
  }

  void goToStep(int step) {
    if (step >= 0 && step <= 4) {
      state = state.copyWith(currentStep: step);
    }
  }
}

final postRepositoryProvider = Provider<PostRepository>((ref) {
  return PostRepository();
});

final postStateProvider =
    StateNotifierProvider.autoDispose<PostNotifier, PostState>((ref) {
  final repository = ref.watch(postRepositoryProvider);
  return PostNotifier(repository);
});
