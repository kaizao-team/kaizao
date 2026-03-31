import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/config/app_env.dart';
import '../../../core/network/ai_agent_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/sse_client.dart';
import '../models/ai_agent_response.dart';
import '../models/post_models.dart';
import '../repositories/post_repository.dart';

class PostState {
  final int currentStep;
  final String? category;
  final String? projectId;
  final String? sessionId;
  final String? subStage;
  final List<AiChatMessage> messages;
  final AiStreamPhase aiStreamPhase;
  final bool canGeneratePrd;
  final int completenessScore;
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
    this.projectId,
    this.sessionId,
    this.subStage,
    this.messages = const [],
    this.aiStreamPhase = AiStreamPhase.idle,
    this.canGeneratePrd = false,
    this.completenessScore = 0,
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

  /// Backward-compatible getter — UI code that checks `isAiTyping` still works.
  bool get isAiTyping => aiStreamPhase != AiStreamPhase.idle;

  PostState copyWith({
    int? currentStep,
    String? Function()? category,
    String? Function()? projectId,
    String? Function()? sessionId,
    String? Function()? subStage,
    List<AiChatMessage>? messages,
    AiStreamPhase? aiStreamPhase,
    bool? canGeneratePrd,
    int? completenessScore,
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
      projectId: projectId != null ? projectId() : this.projectId,
      sessionId: sessionId != null ? sessionId() : this.sessionId,
      subStage: subStage != null ? subStage() : this.subStage,
      messages: messages ?? this.messages,
      aiStreamPhase: aiStreamPhase ?? this.aiStreamPhase,
      canGeneratePrd: canGeneratePrd ?? this.canGeneratePrd,
      completenessScore: completenessScore ?? this.completenessScore,
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
  final AiAgentClient _aiAgent;
  CancelToken? _sseCancelToken;

  PostNotifier(this._repository, {AiAgentClient? aiAgent})
      : _aiAgent = aiAgent ?? AiAgentClient(),
        super(const PostState());

  @override
  void dispose() {
    _sseCancelToken?.cancel('PostNotifier disposed');
    super.dispose();
  }

  void selectCategory(String category) {
    state = state.copyWith(
      category: () => category,
      currentStep: 1,
      completenessScore: 0,
      canGeneratePrd: false,
    );
  }

  Future<void> sendMessage(String content) async {
    // Mock path — unchanged synchronous logic
    if (AppEnv.useMock) {
      return _sendMessageMock(content);
    }
    return _sendMessageSse(content);
  }

  // ---------------------------------------------------------------------------
  // SSE streaming path
  // ---------------------------------------------------------------------------

  Future<void> _sendMessageSse(String content) async {
    // 1. Add user message + empty AI placeholder, enter thinking phase
    final userMsg = AiChatMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      content: content,
      isUser: true,
      timestamp: DateTime.now(),
    );
    final aiPlaceholder = AiChatMessage(
      id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
      content: '',
      isUser: false,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg, aiPlaceholder],
      aiStreamPhase: AiStreamPhase.thinking,
      errorMessage: () => null,
    );

    // 2. Choose endpoint based on whether we have a projectId
    _sseCancelToken?.cancel('new message');
    _sseCancelToken = CancelToken();

    final String path;
    final Map<String, dynamic> data;

    if (state.projectId == null) {
      final newProjectId = const Uuid().v4();
      path = ApiEndpoints.aiAgentStartStream;
      data = {'project_id': newProjectId, 'message': content};
    } else {
      path = ApiEndpoints.aiAgentMessageStream(state.projectId!);
      data = {'message': content};
    }

    // 3. Consume SSE events
    try {
      debugPrint('[SSE] Starting stream to $path');
      final stream = _aiAgent.postSseStream(
        path,
        data: data,
        cancelToken: _sseCancelToken,
      );

      await for (final event in stream) {
        debugPrint('[SSE] event=${event.event} data=${event.data.length > 80 ? '${event.data.substring(0, 80)}...' : event.data}');
        if (!mounted) return;
        _handleSseEvent(event);
      }
      debugPrint('[SSE] Stream ended normally');

      // Stream ended normally — ensure we're idle
      if (mounted && state.aiStreamPhase != AiStreamPhase.idle) {
        state = state.copyWith(aiStreamPhase: AiStreamPhase.idle);
      }
    } on DioException catch (e) {
      debugPrint('[SSE] DioException: ${e.type} ${e.message}');
      if (e.type == DioExceptionType.cancel) {
        // Remove the empty AI placeholder left by the cancelled stream
        if (mounted) _removeEmptyTrailingAiMessage();
        return;
      }
      if (!mounted) return;
      _removeEmptyTrailingAiMessage();
      state = state.copyWith(
        aiStreamPhase: AiStreamPhase.idle,
        errorMessage: () => e.message ?? 'Network error',
      );
    } catch (e, st) {
      debugPrint('[SSE] Error: $e\n$st');
      if (!mounted) return;
      _removeEmptyTrailingAiMessage();
      state = state.copyWith(
        aiStreamPhase: AiStreamPhase.idle,
        errorMessage: () => e.toString(),
      );
    }
  }

  void _handleSseEvent(SseEvent event) {
    switch (event.event) {
      case 'init':
        // Backend sends project_id/session_id immediately on connection
        _parseInitPayload(event.data);

      case 'thinking':
        state = state.copyWith(aiStreamPhase: AiStreamPhase.thinking);

      case 'text':
        state = state.copyWith(aiStreamPhase: AiStreamPhase.receiving);
        _appendToLastAiMessage(event.data);

      case 'tool_call':
        state = state.copyWith(aiStreamPhase: AiStreamPhase.toolCall);

      case 'tool_result':
        // tool_result is informational; stay in toolCall phase
        break;

      case 'done':
        state = state.copyWith(aiStreamPhase: AiStreamPhase.idle);
        _parseDonePayload(event.data);

      case 'stage_info':
        _parseStageInfo(event.data);

      case 'error':
        state = state.copyWith(
          aiStreamPhase: AiStreamPhase.idle,
          errorMessage: () => event.data,
        );

      default:
        debugPrint('[SSE] Unknown event: ${event.event}');
    }
  }

  /// Remove trailing empty AI message left by a cancelled/failed stream.
  void _removeEmptyTrailingAiMessage() {
    final msgs = state.messages;
    if (msgs.isNotEmpty && !msgs.last.isUser && msgs.last.content.isEmpty) {
      state = state.copyWith(messages: msgs.sublist(0, msgs.length - 1));
    }
  }

  void _appendToLastAiMessage(String chunk) {
    final msgs = [...state.messages];
    if (msgs.isEmpty) return;
    final last = msgs.last;
    msgs[msgs.length - 1] = last.copyWith(content: last.content + chunk);
    state = state.copyWith(messages: msgs);
  }

  void _parseInitPayload(String rawData) {
    try {
      final json = jsonDecode(rawData) as Map<String, dynamic>;
      final projectId = json['project_id'] as String?;
      final sessionId = json['session_id'] as String?;
      debugPrint('[SSE] init: projectId=$projectId sessionId=$sessionId');
      state = state.copyWith(
        projectId: projectId != null ? () => projectId : null,
        sessionId: sessionId != null ? () => sessionId : null,
      );
    } catch (_) {
      // best-effort
    }
  }

  void _parseDonePayload(String rawData) {
    try {
      final json = jsonDecode(rawData) as Map<String, dynamic>;
      final projectId = json['project_id'] as String?;
      final sessionId = json['session_id'] as String?;
      state = state.copyWith(
        projectId: projectId != null ? () => projectId : null,
        sessionId: sessionId != null ? () => sessionId : null,
      );
    } catch (_) {
      // done data may not be valid JSON — that's fine
    }
  }

  void _parseStageInfo(String rawData) {
    try {
      final json = jsonDecode(rawData) as Map<String, dynamic>;
      final subStage = json['sub_stage'] as String?;
      final score = json['completeness_score'] as int?;
      final canPrd = subStage == 'prd_draft' || (score != null && score >= 60);
      state = state.copyWith(
        subStage: subStage != null ? () => subStage : null,
        completenessScore: score,
        canGeneratePrd: canPrd,
      );
    } catch (_) {
      // best-effort parsing
    }
  }

  // ---------------------------------------------------------------------------
  // Mock path — original synchronous logic
  // ---------------------------------------------------------------------------

  Future<void> _sendMessageMock(String content) async {
    final userMsg = AiChatMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      content: content,
      isUser: true,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg],
      aiStreamPhase: AiStreamPhase.thinking,
      errorMessage: () => null,
    );

    try {
      final AiAgentResponse response;
      if (state.projectId == null) {
        final newProjectId = const Uuid().v4();
        response = await _repository.startRequirement(newProjectId, content);
      } else {
        response = await _repository.sendMessage(state.projectId!, content);
      }
      if (!mounted) return;

      final aiMsg = AiChatMessage(
        id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
        content: response.agentMessage,
        isUser: false,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, aiMsg],
        aiStreamPhase: AiStreamPhase.idle,
        canGeneratePrd: response.canGeneratePrd,
        completenessScore: response.completenessScore,
        subStage: () => response.subStage,
        projectId: () => response.projectId,
        sessionId: () => response.sessionId,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        aiStreamPhase: AiStreamPhase.idle,
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
