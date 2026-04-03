import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/sse_client.dart';
import '../models/ai_agent_response.dart';
import '../models/post_models.dart';
import '../repositories/post_repository.dart';

const _categoryLabels = <String, String>{
  'data': '数据',
  'dev': '研发',
  'design': '视觉设计',
  'visual': '视觉设计',
  'solution': '解决方案',
};

String _normalizePostCategoryKey(String? value) {
  final normalized = value?.trim().toLowerCase() ?? '';
  switch (normalized) {
    case 'visual':
    case 'design':
      return 'design';
    case 'app':
    case 'web':
    case 'miniprogram':
    case 'backend':
      return 'dev';
    case 'data':
    case 'dev':
    case 'solution':
      return normalized;
    default:
      return '';
  }
}

class PostState {
  final int currentStep;
  final String? category;
  final String? projectId;
  final String? sessionId;
  final String? subStage;
  final bool? analysisComplete;
  final List<AiChatMessage> messages;
  final AiStreamPhase aiStreamPhase;
  final int completenessScore;

  // Requirement confirmation
  final bool canConfirmRequirement;
  final bool isConfirmingRequirement;

  // Project overview (replaces PRD)
  final ProjectOverviewData? overviewData;

  // Budget
  final double? budgetMin;
  final double? budgetMax;
  final BudgetSuggestion? budgetSuggestion;
  final bool isProjectPublished;

  // Team matching
  final RecommendedTeam? recommendedTeam;
  final bool isLoadingMatch;
  final bool isConfirmingMatch;

  final String? errorMessage;
  final Map<String, bool> validationErrors;

  const PostState({
    this.currentStep = 0,
    this.category,
    this.projectId,
    this.sessionId,
    this.subStage,
    this.analysisComplete,
    this.messages = const [],
    this.aiStreamPhase = AiStreamPhase.idle,
    this.completenessScore = 0,
    this.canConfirmRequirement = false,
    this.isConfirmingRequirement = false,
    this.overviewData,
    this.budgetMin,
    this.budgetMax,
    this.budgetSuggestion,
    this.isProjectPublished = false,
    this.recommendedTeam,
    this.isLoadingMatch = false,
    this.isConfirmingMatch = false,
    this.errorMessage,
    this.validationErrors = const {},
  });

  bool get isAiTyping => aiStreamPhase != AiStreamPhase.idle;

  PostState copyWith({
    int? currentStep,
    String? Function()? category,
    String? Function()? projectId,
    String? Function()? sessionId,
    String? Function()? subStage,
    bool? Function()? analysisComplete,
    List<AiChatMessage>? messages,
    AiStreamPhase? aiStreamPhase,
    int? completenessScore,
    bool? canConfirmRequirement,
    bool? isConfirmingRequirement,
    ProjectOverviewData? Function()? overviewData,
    double? Function()? budgetMin,
    double? Function()? budgetMax,
    BudgetSuggestion? Function()? budgetSuggestion,
    bool? isProjectPublished,
    RecommendedTeam? Function()? recommendedTeam,
    bool? isLoadingMatch,
    bool? isConfirmingMatch,
    String? Function()? errorMessage,
    Map<String, bool>? validationErrors,
  }) {
    return PostState(
      currentStep: currentStep ?? this.currentStep,
      category: category != null ? category() : this.category,
      projectId: projectId != null ? projectId() : this.projectId,
      sessionId: sessionId != null ? sessionId() : this.sessionId,
      subStage: subStage != null ? subStage() : this.subStage,
      analysisComplete:
          analysisComplete != null ? analysisComplete() : this.analysisComplete,
      messages: messages ?? this.messages,
      aiStreamPhase: aiStreamPhase ?? this.aiStreamPhase,
      completenessScore: completenessScore ?? this.completenessScore,
      canConfirmRequirement:
          canConfirmRequirement ?? this.canConfirmRequirement,
      isConfirmingRequirement:
          isConfirmingRequirement ?? this.isConfirmingRequirement,
      overviewData: overviewData != null ? overviewData() : this.overviewData,
      budgetMin: budgetMin != null ? budgetMin() : this.budgetMin,
      budgetMax: budgetMax != null ? budgetMax() : this.budgetMax,
      budgetSuggestion:
          budgetSuggestion != null ? budgetSuggestion() : this.budgetSuggestion,
      isProjectPublished: isProjectPublished ?? this.isProjectPublished,
      recommendedTeam:
          recommendedTeam != null ? recommendedTeam() : this.recommendedTeam,
      isLoadingMatch: isLoadingMatch ?? this.isLoadingMatch,
      isConfirmingMatch: isConfirmingMatch ?? this.isConfirmingMatch,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      validationErrors: validationErrors ?? this.validationErrors,
    );
  }
}

class PostNotifier extends StateNotifier<PostState> {
  final PostRepository _repository;
  CancelToken? _sseCancelToken;
  int _requestGeneration = 0;
  int _streamingGeneration = 0; // cancel stale _simulateStreaming loops
  bool _expectsFreshAiMessage = false;
  String? _pendingCategory;

  PostNotifier(this._repository) : super(const PostState());

  @override
  void dispose() {
    _sseCancelToken?.cancel('PostNotifier disposed');
    super.dispose();
  }

  String? _readProjectId(Map<String, dynamic> data) {
    final candidates = [
      data['project_id'],
      data['uuid'],
      data['project_uuid'],
      data['draft_id'],
      data['id'],
      state.projectId,
    ];

    for (final value in candidates) {
      final text = value?.toString().trim();
      if (text != null && text.isNotEmpty) {
        return text;
      }
    }
    return null;
  }

  Future<String> _ensureRealProjectId({
    String? category,
    int? step,
  }) async {
    final existing = state.projectId?.trim();
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final draft = await _repository.createProjectDraft(
      category: category ?? state.category,
      budgetMin: state.budgetMin,
      budgetMax: state.budgetMax,
      step: step ?? state.currentStep,
    );
    final projectId = _readProjectId(draft);
    if (projectId == null) {
      throw Exception('Go /api/v1/projects/draft 未返回可用 project id');
    }

    if (!mounted) return projectId;
    state = state.copyWith(projectId: () => projectId);
    return projectId;
  }

  Future<String> _publishProjectForMatch() async {
    if (state.isProjectPublished) {
      final existingProjectId = state.projectId?.trim();
      if (existingProjectId != null && existingProjectId.isNotEmpty) {
        return existingProjectId;
      }
    }

    final draftProjectId = await _ensureRealProjectId(
      step: state.currentStep == 0 ? 1 : state.currentStep,
    );
    final published = await _repository.publishDraftProject(draftProjectId);
    final publishedProjectId = _readProjectId(published);
    if (publishedProjectId == null) {
      throw const FormatException(
        'Go /api/v1/projects/{id}/publish 未返回可用 project id',
      );
    }

    final status = _asInt(published['status']);
    if (status != 2) {
      throw const FormatException(
        'Go /api/v1/projects/{id}/publish 未返回 status=2',
      );
    }

    if (!mounted) return publishedProjectId;
    state = state.copyWith(
      projectId: () => publishedProjectId,
      isProjectPublished: true,
    );
    return publishedProjectId;
  }

  // ---------------------------------------------------------------------------
  // Step 0 → Step 1: select category, auto-start SSE conversation
  // ---------------------------------------------------------------------------

  void selectCategory(String category) {
    final normalizedCategory = _normalizePostCategoryKey(category);
    if (normalizedCategory.isEmpty) return;
    if (state.category == normalizedCategory) return;

    final hasProgressToLose = state.messages.isNotEmpty ||
        state.overviewData != null ||
        state.budgetMin != null ||
        state.budgetMax != null ||
        state.recommendedTeam != null;

    if (hasProgressToLose) {
      _pendingCategory = normalizedCategory;
      state = state.copyWith(
        errorMessage: () => '__confirm_category_change__',
      );
      return;
    }

    _applyCategory(normalizedCategory);
  }

  void confirmCategoryChange() {
    final pendingCategory = _pendingCategory;
    if (pendingCategory == null) return;
    _pendingCategory = null;
    _applyCategory(pendingCategory);
  }

  void cancelCategoryChange() {
    _pendingCategory = null;
    state = state.copyWith(errorMessage: () => null);
  }

  void _applyCategory(String normalizedCategory) {
    state = state.copyWith(
      category: () => normalizedCategory,
      currentStep: 1,
      projectId: () => null,
      sessionId: () => null,
      subStage: () => null,
      analysisComplete: () => null,
      messages: const [],
      aiStreamPhase: AiStreamPhase.idle,
      completenessScore: 0,
      canConfirmRequirement: false,
      isConfirmingRequirement: false,
      overviewData: () => null,
      budgetMin: () => null,
      budgetMax: () => null,
      budgetSuggestion: () => null,
      isProjectPublished: false,
      recommendedTeam: () => null,
      isLoadingMatch: false,
      isConfirmingMatch: false,
      errorMessage: () => null,
      validationErrors: const {},
    );

    _initConversation(normalizedCategory);
  }

  Future<void> _initConversation(String category) async {
    return _initConversationSse(category);
  }

  Future<void> _initConversationSse(String category) async {
    final label = _categoryLabels[category] ?? category;
    final initialMessage = '我想做一个$label类的项目';
    final requestGeneration = ++_requestGeneration;

    _sseCancelToken?.cancel('new conversation');
    _sseCancelToken = CancelToken();

    state = state.copyWith(
      messages: const [],
      aiStreamPhase: AiStreamPhase.thinking,
      errorMessage: () => null,
    );

    try {
      final newProjectId = await _ensureRealProjectId(
        category: category,
        step: 1,
      );
      if (!mounted || requestGeneration != _requestGeneration) return;
      state = state.copyWith(projectId: () => newProjectId);
    } catch (e) {
      debugPrint('[SSE] create draft failed: $e');
      if (!mounted || requestGeneration != _requestGeneration) return;
      state = state.copyWith(
        aiStreamPhase: AiStreamPhase.idle,
        errorMessage: () => e.toString(),
      );
      return;
    }

    final pid = state.projectId!;
    try {
      final stream = _repository.startRequirementStream(
        pid,
        initialMessage,
        cancelToken: _sseCancelToken,
      );

      await for (final event in stream) {
        debugPrint(
          '[SSE] event=${event.event} data=${event.data.length > 80 ? '${event.data.substring(0, 80)}...' : event.data}',
        );
        if (!mounted || requestGeneration != _requestGeneration) return;
        _handleSseEvent(event);
      }

      if (mounted &&
          requestGeneration == _requestGeneration &&
          state.aiStreamPhase != AiStreamPhase.idle) {
        state = state.copyWith(aiStreamPhase: AiStreamPhase.idle);
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        if (mounted) _removeEmptyTrailingAiMessage();
        return;
      }
      if (!mounted || requestGeneration != _requestGeneration) return;
      _removeEmptyTrailingAiMessage();
      state = state.copyWith(
        aiStreamPhase: AiStreamPhase.idle,
        errorMessage: () => e.message ?? 'Network error',
      );
    } catch (e, st) {
      debugPrint('[SSE] Error: $e\n$st');
      if (!mounted || requestGeneration != _requestGeneration) return;
      _removeEmptyTrailingAiMessage();
      state = state.copyWith(
        aiStreamPhase: AiStreamPhase.idle,
        errorMessage: () => e.toString(),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // SSE option selection (options come from backend via SSE text event)
  // ---------------------------------------------------------------------------

  void selectSseOption(String messageId, AiChatOption option) {
    final targetIndex = state.messages.indexWhere((m) => m.id == messageId);
    if (targetIndex == -1) return;

    final target = state.messages[targetIndex];
    if (target.optionSelected != null) return;

    final updated = [...state.messages];
    updated[targetIndex] = target.copyWith(
      optionSelected: () => option,
    );
    state = state.copyWith(messages: updated);

    if (_isRequirementAnalysisComplete()) return;

    _sendMessageSse(option.label, appendUserMessage: false);
  }

  void submitCustomSseOption(String messageId, String text) {
    final normalized = text.trim();
    if (normalized.isEmpty) return;

    final targetIndex = state.messages.indexWhere((m) => m.id == messageId);
    if (targetIndex == -1) {
      _sendMessageSse(normalized);
      return;
    }

    final target = state.messages[targetIndex];
    if (target.optionSelected != null) return;

    AiChatOption? customBase;
    for (final option in target.options ?? const <AiChatOption>[]) {
      if (option.isCustom) {
        customBase = option;
        break;
      }
    }

    final updated = [...state.messages];
    updated[targetIndex] = target.copyWith(
      optionSelected: () => AiChatOption(
        key: customBase?.key ?? 'Z',
        label: normalized,
        isCustom: true,
      ),
    );
    state = state.copyWith(messages: updated);

    if (_isRequirementAnalysisComplete()) return;

    _sendMessageSse(normalized, appendUserMessage: false);
  }

  void submitMultiSseOptions(
    String messageId,
    List<AiChatOption> selectedOptions,
  ) {
    if (selectedOptions.isEmpty) return;

    final targetIndex = state.messages.indexWhere((m) => m.id == messageId);
    if (targetIndex == -1) return;

    final target = state.messages[targetIndex];
    if (target.optionsSelected != null && target.optionsSelected!.isNotEmpty) {
      return;
    }

    final normalized = <AiChatOption>[];
    final seen = <String>{};
    for (final option in selectedOptions) {
      final key = '${option.key}::${option.label}';
      if (seen.add(key)) {
        normalized.add(option);
      }
    }
    if (normalized.isEmpty) return;

    final userContent = normalized.map((option) => option.label).join('、');
    final updated = [...state.messages];
    updated[targetIndex] = target.copyWith(
      optionsSelected: () => normalized,
    );
    state = state.copyWith(messages: updated);

    if (_isRequirementAnalysisComplete()) return;

    _sendMessageSse(userContent, appendUserMessage: false);
  }

  void submitFreeTextSseReply(String messageId, String text) {
    final normalized = text.trim();
    if (normalized.isEmpty) return;

    final targetIndex = state.messages.indexWhere((m) => m.id == messageId);
    if (targetIndex == -1) {
      _sendMessageSse(normalized);
      return;
    }

    final target = state.messages[targetIndex];
    if (target.isAnswered) return;

    final updated = [...state.messages];
    updated[targetIndex] = target.copyWith(
      freeTextAnswer: () => normalized,
    );
    state = state.copyWith(messages: updated);

    if (_isRequirementAnalysisComplete()) return;

    _sendMessageSse(normalized, appendUserMessage: false);
  }

  // ---------------------------------------------------------------------------
  // Free-text message sending
  // ---------------------------------------------------------------------------

  Future<void> sendMessage(String content) async {
    return _sendMessageSse(content);
  }

  Future<void> _sendMessageSse(
    String content, {
    bool appendUserMessage = true,
  }) async {
    final requestGeneration = ++_requestGeneration;
    _streamingGeneration++; // cancel any running streaming

    // Add user message — no AI placeholder yet (added on first text event)
    final msgs = [...state.messages];
    _expectsFreshAiMessage = !appendUserMessage;

    // Only add user message if the last message isn't already this user message
    final needsUserMsg =
        msgs.isEmpty || !msgs.last.isUser || msgs.last.content != content;
    if (appendUserMessage && needsUserMsg) {
      msgs.add(
        AiChatMessage(
          id: 'user_${DateTime.now().millisecondsSinceEpoch}',
          content: content,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
    }

    state = state.copyWith(
      messages: msgs,
      aiStreamPhase: AiStreamPhase.thinking,
      analysisComplete: () => null,
      canConfirmRequirement: false,
      errorMessage: () => null,
    );

    _sseCancelToken?.cancel('new message');
    _sseCancelToken = CancelToken();
    final hadProjectId = state.projectId?.trim().isNotEmpty == true;

    if (!hadProjectId) {
      try {
        final newProjectId = await _ensureRealProjectId(
          step: state.currentStep == 0 ? 1 : state.currentStep,
        );
        if (!mounted || requestGeneration != _requestGeneration) return;
        state = state.copyWith(projectId: () => newProjectId);
      } catch (e) {
        debugPrint('[SSE] create draft failed: $e');
        if (!mounted || requestGeneration != _requestGeneration) return;
        state = state.copyWith(
          aiStreamPhase: AiStreamPhase.idle,
          errorMessage: () => e.toString(),
        );
        return;
      }
    }

    try {
      final stream = !hadProjectId
          ? _repository.startRequirementStream(
              state.projectId!,
              content,
              cancelToken: _sseCancelToken,
            )
          : _repository.sendRequirementMessageStream(
              state.projectId!,
              content,
              cancelToken: _sseCancelToken,
            );

      await for (final event in stream) {
        debugPrint(
          '[SSE] event=${event.event} data=${event.data.length > 80 ? '${event.data.substring(0, 80)}...' : event.data}',
        );
        if (!mounted || requestGeneration != _requestGeneration) return;
        _handleSseEvent(event);
      }

      if (mounted &&
          requestGeneration == _requestGeneration &&
          state.aiStreamPhase != AiStreamPhase.idle) {
        state = state.copyWith(aiStreamPhase: AiStreamPhase.idle);
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        if (mounted) _removeEmptyTrailingAiMessage();
        return;
      }
      if (!mounted || requestGeneration != _requestGeneration) return;
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

  // ---------------------------------------------------------------------------
  // SSE event handling
  // ---------------------------------------------------------------------------

  void _handleSseEvent(SseEvent event) {
    switch (event.event) {
      case 'init':
        _parseInitPayload(event.data);

      case 'thinking':
        state = state.copyWith(aiStreamPhase: AiStreamPhase.thinking);

      case 'text':
        state = state.copyWith(aiStreamPhase: AiStreamPhase.receiving);
        _handleTextEvent(event.data);

      case 'tool_call':
        state = state.copyWith(aiStreamPhase: AiStreamPhase.toolCall);

      case 'tool_result':
        break;

      case 'done':
        state = state.copyWith(aiStreamPhase: AiStreamPhase.idle);
        _parseDonePayload(event.data);

      case 'stage_info':
        _parseStageInfo(event.data);

      case 'error':
        _removeEmptyTrailingAiMessage();
        state = state.copyWith(
          aiStreamPhase: AiStreamPhase.idle,
          errorMessage: () => event.data,
        );

      default:
        debugPrint('[SSE] Unknown event: ${event.event}');
    }
  }

  /// Ensure there is an AI placeholder as the last message.
  /// Returns true if a new one was created.
  bool _ensureAiPlaceholder() {
    final msgs = state.messages;
    if (_expectsFreshAiMessage) {
      _expectsFreshAiMessage = false;
      state = state.copyWith(
        messages: [
          ...msgs,
          AiChatMessage(
            id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
            content: '',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        ],
      );
      return true;
    }
    if (msgs.isNotEmpty && !msgs.last.isUser) return false;
    state = state.copyWith(
      messages: [
        ...msgs,
        AiChatMessage(
          id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
          content: '',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      ],
    );
    return true;
  }

  bool _isRequirementAnalysisComplete() {
    return state.analysisComplete ?? state.canConfirmRequirement;
  }

  bool _canConfirmFromProgress({
    String? subStage,
    int? completenessScore,
  }) {
    return subStage == 'prd_draft' ||
        (completenessScore != null && completenessScore >= 60);
  }

  String _buildOverviewTitle() {
    final categoryLabel = state.category != null
        ? _categoryLabels[state.category!] ?? state.category!
        : null;
    if (categoryLabel != null && categoryLabel.isNotEmpty) {
      return '$categoryLabel项目需求';
    }
    return '项目需求';
  }

  String _buildOverviewSummaryFromMessages() {
    for (final message in state.messages.reversed) {
      if (message.isUser) continue;
      final content = message.content.trim();
      if (content.isEmpty) continue;
      if (message.hasOptions) continue;
      return content;
    }
    return 'PRD 已确认。当前阶段只锁定需求范围与方向，正式 requirement.md 会在撮合成功并确认合作后由后端触发 EARS 拆解生成。';
  }

  int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  String _normalizeQuestionText(String text) {
    return text.trim();
  }

  Map<String, dynamic>? _asJsonMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, mapValue) => MapEntry('$key', mapValue));
    }
    return null;
  }

  bool _isCustomLikeLabel(Object? value) {
    final text = value?.toString().trim().toLowerCase();
    if (text == null || text.isEmpty) return false;
    return text == '其他' ||
        text == '其它' ||
        text == 'other' ||
        text.startsWith('其他') ||
        text.startsWith('其它');
  }

  List<AiChatOption> _parseOptions(
    Object? rawOptions, {
    bool allowCustom = false,
  }) {
    final options = <AiChatOption>[];
    final seen = <String>{};

    if (rawOptions is List) {
      for (int i = 0; i < rawOptions.length; i++) {
        final raw = rawOptions[i];
        if (raw is String) {
          final label = raw.trim();
          if (label.isEmpty) continue;
          final option = AiChatOption(
            key: String.fromCharCode(65 + i),
            label: label,
            isCustom: _isCustomLikeLabel(label),
          );
          final dedupeKey = option.isCustom
              ? '__custom__'
              : '${option.key.toUpperCase()}::$label';
          if (seen.add(dedupeKey)) {
            options.add(option);
          }
          continue;
        }

        final optionJson = _asJsonMap(raw);
        if (optionJson == null) continue;

        final label = optionJson['label']?.toString().trim() ?? '';
        if (label.isEmpty) continue;
        final option = AiChatOption(
          key: optionJson['key'] as String? ?? String.fromCharCode(65 + i),
          label: label,
          isCustom: (optionJson['is_custom'] as bool? ?? false) ||
              _isCustomLikeLabel(label),
        );
        final dedupeKey = option.isCustom
            ? '__custom__'
            : '${option.key.toUpperCase()}::$label';
        if (seen.add(dedupeKey)) {
          options.add(option);
        }
      }
    }

    if (allowCustom && !options.any((option) => option.isCustom)) {
      options.add(const AiChatOption(key: 'Z', label: '其他', isCustom: true));
    }

    return options;
  }

  AiChatInputType _parseInputType(
    Map<String, dynamic> payload, [
    Map<String, dynamic>? question,
  ]) {
    final rawInputType =
        (question?['input_type'] ?? payload['input_type']) as String?;
    final parsed = AiChatInputType.fromBackend(rawInputType);
    if (parsed != AiChatInputType.unknown) return parsed;

    final rawOptions = question?['options'] ?? payload['options'];
    if (rawOptions is List && rawOptions.isNotEmpty) {
      return AiChatInputType.singleChoice;
    }

    return AiChatInputType.unknown;
  }

  void _upsertStructuredAiMessage({
    String? messageId,
    required String content,
    required List<AiChatOption> options,
    required AiChatInputType inputType,
    int? minSelections,
    int? maxSelections,
    String? placeholder,
  }) {
    final msgs = [...state.messages];

    if (_expectsFreshAiMessage) {
      _expectsFreshAiMessage = false;
    } else if (msgs.isNotEmpty && !msgs.last.isUser) {
      final current = msgs.last;
      msgs[msgs.length - 1] = current.copyWith(
        content: content.isNotEmpty ? content : current.content,
        inputType: inputType,
        options: () => options,
        minSelections: () => minSelections,
        maxSelections: () => maxSelections,
        placeholder: () => placeholder,
      );
      state = state.copyWith(messages: msgs);
      return;
    }

    if (content.isEmpty && options.isEmpty) return;

    msgs.add(
      AiChatMessage(
        id: messageId ?? 'ai_${DateTime.now().millisecondsSinceEpoch}',
        content: content,
        isUser: false,
        timestamp: DateTime.now(),
        inputType: inputType,
        options: options,
        minSelections: minSelections,
        maxSelections: maxSelections,
        placeholder: placeholder,
      ),
    );
    state = state.copyWith(messages: msgs);
  }

  /// Handle SSE text event: try JSON with options, fallback to plain text.
  void _handleTextEvent(String data) {
    // Cancel any running _simulateStreaming loop from a previous text event
    _streamingGeneration++;

    _ensureAiPlaceholder();

    try {
      final json = jsonDecode(data) as Map<String, dynamic>;
      final question = _asJsonMap(json['question']);
      final rawContent =
          (question?['content'] ?? json['content'])?.toString() ?? '';
      final content = _normalizeQuestionText(rawContent);
      final allowCustom =
          (question?['allow_custom'] ?? json['allow_custom']) as bool? ?? false;
      final placeholder =
          (question?['placeholder'] ?? json['placeholder'])?.toString().trim();
      final inputType = _parseInputType(json, question);
      final options = _parseOptions(
        question?['options'] ?? json['options'],
        allowCustom: allowCustom,
      );

      if (question != null || inputType != AiChatInputType.unknown) {
        _upsertStructuredAiMessage(
          content: content,
          options: options,
          inputType: inputType,
          minSelections: _asInt(question?['min_select'] ?? json['min_select']),
          maxSelections: _asInt(question?['max_select'] ?? json['max_select']),
          placeholder: placeholder,
        );
        return;
      }

      // JSON but no options — treat content as plain text
      if (content.isNotEmpty) {
        _simulateStreaming(content);
      }
    } catch (_) {
      // Not JSON — plain text streaming (original behavior)
      _simulateStreaming(data);
    }
  }

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

  void _simulateStreaming(String text) {
    const chunkSize = 2;
    const chunkDelay = Duration(milliseconds: 25);
    final gen = _streamingGeneration; // capture current generation
    int offset = 0;
    Future.doWhile(() async {
      // Stop if disposed, generation changed (new text event), or done
      if (!mounted || gen != _streamingGeneration || offset >= text.length) {
        return false;
      }
      final end = (offset + chunkSize).clamp(0, text.length);
      _appendToLastAiMessage(text.substring(offset, end));
      offset = end;
      if (offset < text.length) {
        await Future.delayed(chunkDelay);
      }
      return offset < text.length && mounted && gen == _streamingGeneration;
    });
  }

  void _parseInitPayload(String rawData) {
    try {
      final payload = AiAgentSsePayload.fromJson(
        jsonDecode(rawData) as Map<String, dynamic>,
      );
      final projectId = payload.projectId;
      final sessionId = payload.sessionId;
      debugPrint('[SSE] init: projectId=$projectId sessionId=$sessionId');
      state = state.copyWith(
        projectId: projectId != null ? () => projectId : null,
        sessionId: sessionId != null ? () => sessionId : null,
      );
    } catch (_) {}
  }

  void _parseDonePayload(String rawData) {
    try {
      final json = jsonDecode(rawData) as Map<String, dynamic>;
      final payload = AiAgentSsePayload.fromJson(json);
      final projectId = payload.projectId;
      final sessionId = payload.sessionId;
      final subStage = payload.subStage;
      final score = payload.completenessScore;
      final analysisComplete = payload.analysisComplete;
      final nextSubStage = subStage ?? state.subStage;
      final nextScore = score ?? state.completenessScore;
      final canConfirm = analysisComplete ??
          _canConfirmFromProgress(
            subStage: nextSubStage,
            completenessScore: nextScore,
          );

      state = state.copyWith(
        projectId: projectId != null ? () => projectId : null,
        sessionId: sessionId != null ? () => sessionId : null,
        subStage: subStage != null ? () => subStage : null,
        analysisComplete:
            analysisComplete != null ? () => analysisComplete : null,
        completenessScore: nextScore,
        canConfirmRequirement: canConfirm,
      );

      final question = payload.question;
      if (question == null) return;

      final rawContent =
          (question['content'] ?? json['content'])?.toString() ?? '';
      final content = _normalizeQuestionText(rawContent);
      final allowCustom =
          (question['allow_custom'] ?? json['allow_custom']) as bool? ?? false;
      final placeholder =
          (question['placeholder'] ?? json['placeholder'])?.toString().trim();
      final options = _parseOptions(
        question['options'] ?? json['options'],
        allowCustom: allowCustom,
      );

      if (content.isEmpty && options.isEmpty) return;

      _upsertStructuredAiMessage(
        messageId: question['id'] as String?,
        content: content,
        options: options,
        inputType: _parseInputType(json, question),
        minSelections: _asInt(question['min_select'] ?? json['min_select']),
        maxSelections: _asInt(question['max_select'] ?? json['max_select']),
        placeholder: placeholder,
      );
    } catch (_) {}
  }

  void _parseStageInfo(String rawData) {
    try {
      final payload = AiAgentSsePayload.fromJson(
        jsonDecode(rawData) as Map<String, dynamic>,
      );
      final subStage = payload.subStage;
      final score = payload.completenessScore;
      final nextSubStage = subStage ?? state.subStage;
      final nextScore = score ?? state.completenessScore;
      final canConfirm = state.analysisComplete ??
          _canConfirmFromProgress(
            subStage: nextSubStage,
            completenessScore: nextScore,
          );
      state = state.copyWith(
        subStage: subStage != null ? () => subStage : null,
        completenessScore: nextScore,
        canConfirmRequirement: canConfirm,
      );
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // Step 1 → Step 2: confirm requirement → project overview
  // ---------------------------------------------------------------------------

  Future<void> confirmRequirement() async {
    // Kill any running SSE stream first
    _sseCancelToken?.cancel('confirm requirement');
    _sseCancelToken = null;
    _requestGeneration++;
    _streamingGeneration++;

    state = state.copyWith(
      isConfirmingRequirement: true,
      aiStreamPhase: AiStreamPhase.idle,
      errorMessage: () => null,
    );

    try {
      final pid = state.projectId;
      if (pid == null) throw Exception('No project ID');

      final confirmResult = await _repository.confirmRequirement(pid);
      if (!mounted) return;

      final subStage = confirmResult['sub_stage']?.toString();
      final score = _asInt(confirmResult['completeness_score']) ?? 100;

      state = state.copyWith(
        isConfirmingRequirement: false,
        subStage: subStage != null ? () => subStage : null,
        completenessScore: score,
        analysisComplete: () => true,
        canConfirmRequirement: false,
        overviewData: () => ProjectOverviewData(
          projectId: pid,
          title: _buildOverviewTitle(),
          summary: _buildOverviewSummaryFromMessages(),
        ),
        currentStep: 2,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isConfirmingRequirement: false,
        errorMessage: () => '确认需求失败: $e',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Step 2 → Step 3: budget
  // ---------------------------------------------------------------------------

  void setBudget(double min, double max) {
    state = state.copyWith(
      budgetMin: () => min,
      budgetMax: () => max,
    );
  }

  // ---------------------------------------------------------------------------
  // Step 3 → Step 4: auto-match team
  // ---------------------------------------------------------------------------

  Future<void> requestMatch() async {
    state = state.copyWith(
      isLoadingMatch: true,
      recommendedTeam: () => null,
      errorMessage: () => null,
    );

    try {
      final pid = await _publishProjectForMatch();

      final result = await _repository.recommendTeam(pid);
      if (!mounted) return;

      final recommendations = result['recommendations'];
      if (recommendations is! List) {
        throw const FormatException(
          'GET /api/v1/projects/{id}/recommendations 未返回 recommendations 列表',
        );
      }

      if (recommendations.isNotEmpty) {
        final team = RecommendedTeam.fromJson(
          Map<String, dynamic>.from(
            recommendations.first as Map<dynamic, dynamic>,
          ),
        );
        state = state.copyWith(
          isLoadingMatch: false,
          recommendedTeam: () => team,
        );
      } else {
        final noMatchReason = result['no_match_reason']?.toString().trim();
        state = state.copyWith(
          isLoadingMatch: false,
          errorMessage: () =>
              noMatchReason?.isNotEmpty == true ? noMatchReason : '未匹配到可用团队',
        );
      }
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoadingMatch: false,
        errorMessage: () => '匹配团队失败: $e',
      );
    }
  }

  Future<void> reMatch() async => requestMatch();

  // ---------------------------------------------------------------------------
  // Step 4 → Step 5: confirm team match
  // ---------------------------------------------------------------------------

  Future<void> confirmTeamMatch() async {
    final team = state.recommendedTeam;
    if (team == null) return;

    state = state.copyWith(isConfirmingMatch: true, errorMessage: () => null);

    try {
      await _repository.confirmMatch(state.projectId ?? '');
      if (!mounted) return;

      state = state.copyWith(
        isConfirmingMatch: false,
        currentStep: 5,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isConfirmingMatch: false,
        errorMessage: () => e.toString(),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Navigation + utility
  // ---------------------------------------------------------------------------

  void goToStep(int step) {
    if (step >= 0 && step <= 5) {
      state = state.copyWith(currentStep: step);
    }
  }

  Future<void> saveDraft() async {
    try {
      await _repository.saveDraft({
        'category': state.category,
        'budget_min': state.budgetMin,
        'budget_max': state.budgetMax,
        'step': state.currentStep,
      });
    } catch (_) {}
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
