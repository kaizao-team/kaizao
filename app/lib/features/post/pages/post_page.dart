import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../shared/widgets/vcc_button.dart';
import '../../../shared/widgets/vcc_card.dart';
import '../../../shared/widgets/vcc_flow_scaffold.dart';
import '../../../shared/widgets/vcc_toast.dart';
import '../../market/widgets/market_budget_slider.dart';
import '../models/post_models.dart';
import '../providers/post_provider.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/post_category_step.dart';

const _postStepLabels = ['分类', 'AI 对话', '项目概览', '预算', '匹配团队', '发布完成'];

const _postStepMetas = [
  _PostFlowStepMeta(
    title: '先定项目方向',
    subtitle: '从 4 类成果里先选 1 类，AI 会按这个方向继续整理项目。',
    compactTitle: '项目方向',
  ),
  _PostFlowStepMeta(
    title: '把需求讲到能开始做',
    subtitle: '像和搭档开会一样，把目标、用户、范围和限制逐步说清楚。',
    compactTitle: '需求对话',
  ),
  _PostFlowStepMeta(
    title: '确认项目概览',
    subtitle: 'AI 已整理出项目摘要，确认后进入预算设置。',
    compactTitle: '项目概览',
  ),
  _PostFlowStepMeta(
    title: '把预算区间定下来',
    subtitle: '预算不是报价单，它决定平台之后推荐团队的精度和节奏。',
    compactTitle: '预算设置',
  ),
  _PostFlowStepMeta(
    title: '平台为你推荐了一个团队',
    subtitle: '根据项目特征自动匹配，不满意可以换一个。',
    compactTitle: '匹配团队',
  ),
  _PostFlowStepMeta(
    title: '发布完成',
    subtitle: '项目已经发布成功，接下来你可以继续查看项目详情或回到首页。',
    compactTitle: '发布完成',
  ),
];

bool _shouldShowRequirementConfirm(PostState state) {
  return state.currentStep == 1 &&
      (state.canConfirmRequirement || state.isConfirmingRequirement);
}

bool _isRequirementReviewMode(PostState state) {
  return state.currentStep == 1 && state.overviewData != null;
}

String? _activeInlineReplyMessageId(PostState state) {
  if (state.currentStep != 1 ||
      state.overviewData != null ||
      state.isAiTyping ||
      state.canConfirmRequirement ||
      state.isConfirmingRequirement) {
    return null;
  }

  for (final msg in state.messages.reversed) {
    if (!msg.isUser) {
      return msg.id;
    }
  }

  return null;
}

PostPublishResultType _resolvedPublishResultType(PostState state) {
  return state.publishResultType ??
      (state.recommendedTeam != null
          ? PostPublishResultType.awaitingTeamConfirmation
          : PostPublishResultType.publishedWithoutMatch);
}

_PostFlowStepMeta _metaForState(PostState state) {
  if (state.currentStep != 5) {
    return _postStepMetas[state.currentStep.clamp(
      0,
      _postStepMetas.length - 1,
    )];
  }

  switch (_resolvedPublishResultType(state)) {
    case PostPublishResultType.awaitingTeamConfirmation:
      final teamName = state.recommendedTeam?.name.trim();
      return _PostFlowStepMeta(
        title: '发布完成',
        subtitle: teamName == null || teamName.isEmpty
            ? '项目已发布，推荐结果已发出。'
            : '项目已发布，已发送给 $teamName。',
        compactTitle: '发布完成',
      );
    case PostPublishResultType.publishedWithoutMatch:
      return const _PostFlowStepMeta(
        title: '发布完成',
        subtitle: '项目已发布，当前还没有匹配到合适团队。',
        compactTitle: '发布完成',
      );
  }
}

String? _titleTagForState(PostState state) {
  if (state.currentStep == 1) {
    return ({
          'data': '数据',
          'dev': '研发',
          'design': '视觉设计',
          'visual': '视觉设计',
          'solution': '解决方案',
        }[state.category] ??
        '项目方向');
  }

  if (state.currentStep == 5) {
    return switch (_resolvedPublishResultType(state)) {
      PostPublishResultType.awaitingTeamConfirmation => '待确认',
      PostPublishResultType.publishedWithoutMatch => '未匹配',
    };
  }

  return null;
}

double _footerHeight(PostState state) {
  if (state.currentStep == 0) return 0;
  if (state.currentStep == 5) {
    return switch (_resolvedPublishResultType(state)) {
      PostPublishResultType.awaitingTeamConfirmation => 142,
      PostPublishResultType.publishedWithoutMatch => 186,
    };
  }
  if (state.currentStep == 1) {
    if (_isRequirementReviewMode(state)) return 104;
    if (!_shouldShowRequirementConfirm(state)) return 0;
    return state.isConfirmingRequirement ? 132 : 88;
  }
  return 104;
}

Widget? _buildFooter({
  required BuildContext context,
  required PostState state,
  required WidgetRef ref,
  VoidCallback? onViewProject,
  VoidCallback? onGoHome,
  VoidCallback? onRetryMatch,
}) {
  if (state.currentStep == 0) return null;

  switch (state.currentStep) {
    case 1:
      if (_isRequirementReviewMode(state)) {
        return VccFlowFooterBar(
          label: '返回概览',
          onPressed: () => ref.read(postStateProvider.notifier).goToStep(2),
        );
      }
      if (!_shouldShowRequirementConfirm(state)) return null;
      return VccFlowFooterShell(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
        child: _ConfirmRequirementButton(
          isLoading: state.isConfirmingRequirement,
          onPressed: state.isConfirmingRequirement
              ? null
              : () => ref.read(postStateProvider.notifier).confirmRequirement(),
        ),
      );
    case 2:
      return VccFlowFooterBar(
        label: '确认概览，设置预算',
        onPressed: state.overviewData == null
            ? null
            : () => ref.read(postStateProvider.notifier).goToStep(3),
      );
    case 3:
      return VccFlowFooterBar(
        label: '发布项目并匹配',
        onPressed: state.budgetMin != null && state.budgetMax != null
            ? () {
                ref.read(postStateProvider.notifier)
                  ..goToStep(4)
                  ..requestMatch();
              }
            : null,
      );
    case 4:
      return _MatchTeamFooter(
        team: state.recommendedTeam,
        isLoading: state.isLoadingMatch,
        isSubmitting: state.isConfirmingMatch,
        noTeamPrimaryLabel: state.isProjectPublished ? '回到发布结果' : '直接发布项目',
        onConfirm: () =>
            ref.read(postStateProvider.notifier).confirmTeamMatch(),
        onReMatch: () => ref.read(postStateProvider.notifier).reMatch(),
        onSkip: () {
          if (state.isProjectPublished) {
            ref.read(postStateProvider.notifier).goToStep(5);
            return;
          }
          ref.read(postStateProvider.notifier).publishWithoutMatch();
        },
      );
    case 5:
      return _PublishResultFooter(
        resultType: _resolvedPublishResultType(state),
        onViewProject: state.projectId?.trim().isNotEmpty == true
            ? () => onViewProject?.call()
            : null,
        onGoHome: onGoHome,
        onRetryMatch: onRetryMatch,
      );
  }
  return null;
}

List<Widget> _buildPostSlivers({
  required PostState state,
  required WidgetRef ref,
  VoidCallback? onViewProject,
  VoidCallback? onGoHome,
  VoidCallback? onRetryMatch,
}) {
  final slivers = <Widget>[];

  switch (state.currentStep) {
    case 0:
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _InlineStepIntro(
                  eyebrow: '当前步骤',
                  title: '先选 1 个方向',
                  body: '方向不是技术栈，而是这次项目准备交付的成果类型。',
                ),
                const SizedBox(height: 14),
                PostCategoryStep(
                  selected: state.category,
                  onSelect: (category) => ref
                      .read(postStateProvider.notifier)
                      .selectCategory(category),
                ),
              ],
            ),
          ),
        ),
      );
    case 1:
      slivers.addAll(_buildAiChatSlivers(state: state, ref: ref));
    case 2:
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
          sliver: SliverToBoxAdapter(
            child: _ProjectOverviewStage(overviewData: state.overviewData),
          ),
        ),
      );
    case 3:
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
          sliver: SliverToBoxAdapter(
            child: _BudgetStage(
              budgetMin: state.budgetMin,
              budgetMax: state.budgetMax,
              suggestion: state.budgetSuggestion,
              onChanged: (range) => ref
                  .read(postStateProvider.notifier)
                  .setBudget(range.start, range.end),
            ),
          ),
        ),
      );
    case 4:
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
          sliver: SliverToBoxAdapter(
            child: _MatchTeamStage(
              team: state.recommendedTeam,
              isLoading: state.isLoadingMatch,
            ),
          ),
        ),
      );
    case 5:
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          sliver: SliverToBoxAdapter(
            child: _PublishResultStage(
              resultType: _resolvedPublishResultType(state),
            ),
          ),
        ),
      );
  }

  return slivers;
}

List<Widget> _buildAiChatSlivers({
  required PostState state,
  required WidgetRef ref,
}) {
  final showTypingIndicator = state.aiStreamPhase == AiStreamPhase.thinking ||
      state.aiStreamPhase == AiStreamPhase.toolCall;
  final activeInlineReplyId = _activeInlineReplyMessageId(state);

  final slivers = <Widget>[];

  // Chat messages + typing indicator
  slivers.add(
    SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index < state.messages.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: ChatBubble(
                key: ValueKey(state.messages[index].id),
                message: state.messages[index],
                onOptionSelected: (messageId, option) => ref
                    .read(postStateProvider.notifier)
                    .selectSseOption(messageId, option),
                onCustomOptionSubmitted: (messageId, text) {
                  ref
                      .read(postStateProvider.notifier)
                      .submitCustomSseOption(messageId, text);
                },
                onMultiOptionsSubmitted: (messageId, options) => ref
                    .read(postStateProvider.notifier)
                    .submitMultiSseOptions(messageId, options),
                onFreeTextSubmitted: (messageId, text) => ref
                    .read(postStateProvider.notifier)
                    .submitFreeTextSseReply(messageId, text),
                isReadOnly: _isRequirementReviewMode(state),
                showFreeTextReply:
                    state.messages[index].id == activeInlineReplyId,
              ),
            );
          }

          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: AiTypingIndicator(),
          );
        },
        childCount: state.messages.length + (showTypingIndicator ? 1 : 0),
      ),
    ),
  );

  slivers.add(
    const SliverToBoxAdapter(child: SizedBox(height: 16)),
  );

  return slivers;
}

class PostPage extends ConsumerStatefulWidget {
  final String? initialCategory;
  final VoidCallback? onCompleted;

  const PostPage({super.key, this.initialCategory, this.onCompleted});

  @override
  ConsumerState<PostPage> createState() => _PostPageState();
}

class _PostPageState extends ConsumerState<PostPage> {
  final _flowScrollController = ScrollController();
  String? _lastPublishToastKey;

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(postStateProvider.notifier)
            .selectCategory(widget.initialCategory!);
      });
    }
  }

  @override
  void dispose() {
    _flowScrollController.dispose();
    super.dispose();
  }

  int _visibleStepIndex(PostState state) => state.currentStep;

  bool _hasProgress(PostState state) {
    return state.category != null ||
        state.messages.isNotEmpty ||
        state.overviewData != null ||
        state.budgetMin != null ||
        state.budgetMax != null;
  }

  void _scrollToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_flowScrollController.hasClients) {
        _flowScrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_flowScrollController.hasClients) {
        _flowScrollController.animateTo(
          _flowScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _maybeShowPublishToast(PostState state) {
    if (!mounted || state.currentStep != 5 || !state.isProjectPublished) {
      return;
    }

    final toastKey =
        '${state.projectId ?? 'no-project'}:${_resolvedPublishResultType(state).name}';
    if (_lastPublishToastKey == toastKey) {
      return;
    }
    _lastPublishToastKey = toastKey;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      VccToast.show(
        context,
        message: '项目已发布成功',
        type: VccToastType.success,
      );
    });
  }

  Future<void> _confirmClose(PostState state) async {
    if (!_hasProgress(state)) {
      if (mounted && context.canPop()) {
        context.pop();
      }
      return;
    }

    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            '确认离开？',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          content: const Text('当前步骤里的内容还没有完成，离开后不会保留这次编辑。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text(
                '继续填写',
                style: TextStyle(color: AppColors.gray500),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child:
                  const Text('离开页面', style: TextStyle(color: AppColors.error)),
            ),
          ],
        );
      },
    );

    if (shouldLeave == true && mounted && context.canPop()) {
      context.pop();
    }
  }

  void _handleBack(PostState state) {
    if (state.currentStep == 5 && state.isProjectPublished) {
      _exitCompletedFlow();
      return;
    }
    if (state.currentStep > 0) {
      // Step 1 back to step 0: confirm if there's conversation history
      if (state.currentStep == 1 && state.messages.isNotEmpty) {
        _confirmClose(state);
        return;
      }
      ref.read(postStateProvider.notifier).goToStep(state.currentStep - 1);
      return;
    }
    _confirmClose(state);
  }

  void _handleClose(PostState state) {
    if (state.currentStep == 5 && state.isProjectPublished) {
      _exitCompletedFlow();
      return;
    }
    _confirmClose(state);
  }

  void _exitCompletedFlow() {
    if (widget.onCompleted != null) {
      widget.onCompleted!();
      return;
    }
    context.go('/home');
  }

  void _goToProjectDetail(PostState state) {
    final projectId = state.projectId?.trim();
    if (projectId == null || projectId.isEmpty) {
      VccToast.show(
        context,
        message: '当前项目还没有可用的详情页 ID',
        type: VccToastType.error,
      );
      return;
    }
    context.go('/projects/$projectId');
  }

  void _showCategoryChangeConfirm() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            '切换分类？',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          content: const Text('切换后会清空当前已整理的需求、预算和匹配结果。'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                ref.read(postStateProvider.notifier).cancelCategoryChange();
              },
              child: const Text(
                '继续当前分类',
                style: TextStyle(color: AppColors.gray500),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                ref.read(postStateProvider.notifier).confirmCategoryChange();
              },
              child: const Text(
                '确认切换',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final postState = ref.watch(postStateProvider);
    final visibleStep = _visibleStepIndex(postState);
    final meta = _metaForState(postState);
    final titleTag = _titleTagForState(postState);

    ref.listen<PostState>(postStateProvider, (previous, next) {
      if (_visibleStepIndex(previous ?? next) != _visibleStepIndex(next)) {
        _scrollToTop();
      }

      if (next.currentStep == 1 &&
          ((previous?.messages.length ?? 0) != next.messages.length ||
              previous?.aiStreamPhase != next.aiStreamPhase ||
              (next.messages.isNotEmpty &&
                  previous?.messages.isNotEmpty == true &&
                  next.messages.last.content !=
                      previous!.messages.last.content))) {
        _scrollToBottom();
      }

      final error = next.errorMessage;
      if (error == '__confirm_category_change__' &&
          error != previous?.errorMessage &&
          mounted) {
        _showCategoryChangeConfirm();
        return;
      }
      if (error != null && error != previous?.errorMessage && mounted) {
        VccToast.show(context, message: error, type: VccToastType.error);
      }

      if (previous?.currentStep != next.currentStep && next.currentStep == 5) {
        _maybeShowPublishToast(next);
      }
    });

    _maybeShowPublishToast(postState);

    return VccFlowScaffold(
      stepIndex: visibleStep,
      stepCount: _postStepLabels.length,
      stepLabels: _postStepLabels,
      title: meta.title,
      subtitle: meta.subtitle,
      compactTitle: meta.compactTitle,
      titleTag: titleTag,
      onBack: () => _handleBack(postState),
      onClose: () => _handleClose(postState),
      scrollController: _flowScrollController,
      footer: _buildFooter(
        context: context,
        state: postState,
        ref: ref,
        onViewProject: () => _goToProjectDetail(postState),
        onGoHome: _exitCompletedFlow,
        onRetryMatch: () {
          ref.read(postStateProvider.notifier)
            ..goToStep(4)
            ..requestMatch();
        },
      ),
      footerHeight: _footerHeight(postState),
      slivers: _buildPostSlivers(
        state: postState,
        ref: ref,
        onViewProject: () => _goToProjectDetail(postState),
        onGoHome: _exitCompletedFlow,
        onRetryMatch: () {
          ref.read(postStateProvider.notifier)
            ..goToStep(4)
            ..requestMatch();
        },
      ),
    );
  }
}

// =============================================================================
// Private widgets
// =============================================================================

class _PostFlowStepMeta {
  final String title;
  final String subtitle;
  final String compactTitle;

  const _PostFlowStepMeta({
    required this.title,
    required this.subtitle,
    required this.compactTitle,
  });
}

class _InlineStepIntro extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String body;

  const _InlineStepIntro({
    required this.eyebrow,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: AppTextStyles.onboardingMeta.copyWith(
            color: AppColors.gray500,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        Text(title, style: AppTextStyles.h2.copyWith(color: AppColors.black)),
        const SizedBox(height: 6),
        Text(
          body,
          style: AppTextStyles.body2
              .copyWith(height: 1.6, color: AppColors.gray600),
        ),
      ],
    );
  }
}

// =============================================================================
// Confirm Requirement Button — animated loading state
// =============================================================================

class _ConfirmRequirementButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback? onPressed;

  const _ConfirmRequirementButton({
    required this.isLoading,
    required this.onPressed,
  });

  @override
  State<_ConfirmRequirementButton> createState() =>
      _ConfirmRequirementButtonState();
}

class _ConfirmRequirementButtonState extends State<_ConfirmRequirementButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loadingController;
  late final Animation<double> _progressAlignment;

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _progressAlignment = Tween<double>(begin: -1.0, end: 1.0).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant _ConfirmRequirementButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading && !oldWidget.isLoading) {
      _loadingController.repeat(reverse: true);
    } else if (!widget.isLoading && oldWidget.isLoading) {
      _loadingController.stop();
      _loadingController.reset();
    }
  }

  @override
  void dispose() {
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: widget.isLoading ? _buildLoadingCard() : _buildIdleButton(),
    );
  }

  Widget _buildIdleButton() {
    return GestureDetector(
      key: const ValueKey('idle'),
      onTap: widget.onPressed,
      child: Container(
        height: 48,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.black,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                color: AppColors.white,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                '确认需求，生成概览',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      key: const ValueKey('loading'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.gray900, AppColors.black],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(17, 17, 17, 0.16),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.white.withValues(alpha: 0.82),
                        ),
                      ),
                    ),
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 14,
                      color: AppColors.white.withValues(alpha: 0.96),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '正在确认当前 PRD',
                      style: AppTextStyles.body1.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '这是轻量确认操作，不再等待 requirement.md 生成',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.white.withValues(alpha: 0.72),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '处理中',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.white.withValues(alpha: 0.82),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 6,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: AppColors.white.withValues(alpha: 0.12),
                  ),
                  AnimatedBuilder(
                    animation: _progressAlignment,
                    builder: (context, child) {
                      return Align(
                        alignment: Alignment(_progressAlignment.value, 0),
                        child: FractionallySizedBox(
                          widthFactor: 0.34,
                          child: child,
                        ),
                      );
                    },
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.white.withValues(alpha: 0.26),
                            AppColors.white,
                            AppColors.white.withValues(alpha: 0.42),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Step 2: Project Overview
// =============================================================================

class _ProjectOverviewStage extends StatelessWidget {
  final ProjectOverviewData? overviewData;

  const _ProjectOverviewStage({required this.overviewData});

  @override
  Widget build(BuildContext context) {
    if (overviewData == null) {
      return const _InlineStepIntro(
        eyebrow: '项目概览',
        title: '还没有可确认的发布摘要',
        body: '先完成需求对话并确认 PRD，这里才会展示已锁定的摘要。',
      );
    }

    final data = overviewData!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '项目摘要',
          style: AppTextStyles.onboardingMeta.copyWith(
            color: AppColors.gray500,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          data.title,
          style: AppTextStyles.h2.copyWith(
            color: AppColors.black,
            fontWeight: FontWeight.w700,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          data.summary,
          style: AppTextStyles.body1.copyWith(
            color: AppColors.gray700,
            height: 1.75,
          ),
        ),
        if (data.hasHighlights) ...[
          const SizedBox(height: 20),
          _OverviewMetricStrip(data: data),
        ],
        if (data.hasDetailSections) ...[
          if (data.targetUsers.isNotEmpty) ...[
            const SizedBox(height: 32),
            const _OverviewSectionTitle('目标用户'),
            const SizedBox(height: 14),
            ...data.targetUsers.asMap().entries.map((entry) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: entry.key == data.targetUsers.length - 1 ? 0 : 12,
                ),
                child: _OverviewInfoRow(
                  label: entry.value.role,
                  value: entry.value.description,
                ),
              );
            }),
          ],
          if (data.hasTechSummary) ...[
            const SizedBox(height: 32),
            const _OverviewSectionTitle('技术要求'),
            const SizedBox(height: 14),
            if (data.techRequirements?.platform != null)
              _OverviewInfoRow(
                label: '平台',
                value: data.techRequirements!.platform!,
              ),
            if (data.techRequirements?.platform != null &&
                data.techRequirements?.techStack != null)
              const SizedBox(height: 12),
            if (data.techRequirements?.techStack != null)
              _OverviewInfoRow(
                label: '技术栈',
                value: data.techRequirements!.techStack!,
              ),
            if ((data.techRequirements?.platform != null ||
                    data.techRequirements?.techStack != null) &&
                data.techRequirements!.thirdParty.isNotEmpty)
              const SizedBox(height: 12),
            if (data.techRequirements != null &&
                data.techRequirements!.thirdParty.isNotEmpty)
              _OverviewInfoRow(
                label: '第三方',
                value: data.techRequirements!.thirdParty.join(' / '),
              ),
          ],
          if (data.nonFunctionalRequirements.isNotEmpty) ...[
            const SizedBox(height: 32),
            const _OverviewSectionTitle('非功能要求'),
            const SizedBox(height: 14),
            ...data.nonFunctionalRequirements.entries
                .toList()
                .asMap()
                .entries
                .map(
              (entry) {
                final item = entry.value;
                return Padding(
                  padding: EdgeInsets.only(
                    bottom:
                        entry.key == data.nonFunctionalRequirements.length - 1
                            ? 0
                            : 12,
                  ),
                  child: _OverviewInfoRow(
                    label: _formatRequirementKey(item.key),
                    value: item.value,
                  ),
                );
              },
            ),
          ],
        ],
        if (data.prdItems.isNotEmpty) ...[
          const SizedBox(height: 36),
          _OverviewSectionTitle(
            '需求条目',
            suffix: data.itemCount != null ? '共 ${data.itemCount} 条' : null,
          ),
          const SizedBox(height: 16),
          DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.gray200),
                bottom: BorderSide(color: AppColors.gray200),
              ),
            ),
            child: Column(
              children: data.prdItems.asMap().entries.map((entry) {
                final item = entry.value;
                final isLast = entry.key == data.prdItems.length - 1;
                return _OverviewPrdItem(
                  item: item,
                  isLast: isLast,
                );
              }).toList(),
            ),
          ),
        ],
        if (data.budgetSuggestion != null) ...[
          const SizedBox(height: 32),
          const _OverviewSectionTitle('预算提醒'),
          const SizedBox(height: 12),
          Text(
            '推荐区间 ${_formatBudget(data.budgetSuggestion!.min, data.budgetSuggestion!.max)}',
            style: AppTextStyles.h3.copyWith(color: AppColors.black),
          ),
          const SizedBox(height: 6),
          Text(
            data.budgetSuggestion!.reason,
            style: AppTextStyles.body2.copyWith(
              height: 1.65,
              color: AppColors.gray600,
            ),
          ),
        ],
      ],
    );
  }
}

class _OverviewSectionTitle extends StatelessWidget {
  final String title;
  final String? suffix;

  const _OverviewSectionTitle(this.title, {this.suffix});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.onboardingMeta.copyWith(
              color: AppColors.gray500,
              letterSpacing: 0.8,
            ),
          ),
        ),
        if (suffix != null)
          Text(
            suffix!,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.gray500,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

class _OverviewMetricStrip extends StatelessWidget {
  final ProjectOverviewData data;

  const _OverviewMetricStrip({required this.data});

  @override
  Widget build(BuildContext context) {
    final metrics = <({String label, String value})>[
      if (data.complexity != null)
        (label: '复杂度', value: _formatComplexity(data.complexity!)),
      if (data.moduleCount != null)
        (label: '模块', value: '${data.moduleCount} 个'),
      if (data.itemCount != null) (label: '条目', value: '${data.itemCount} 条'),
    ];

    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.gray200),
          bottom: BorderSide(color: AppColors.gray200),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            for (var index = 0; index < metrics.length; index++) ...[
              Expanded(
                child: _OverviewMetricColumn(
                  label: metrics[index].label,
                  value: metrics[index].value,
                ),
              ),
              if (index != metrics.length - 1)
                Container(
                  width: 1,
                  height: 32,
                  color: AppColors.gray200,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OverviewMetricColumn extends StatelessWidget {
  final String label;
  final String value;

  const _OverviewMetricColumn({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.gray500,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.body1.copyWith(
              color: AppColors.black,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewPrdItem extends StatelessWidget {
  final ProjectOverviewPrdItem item;
  final bool isLast;

  const _OverviewPrdItem({
    required this.item,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: AppTextStyles.body1.copyWith(
                        color: AppColors.black,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.itemId} · ${item.moduleName}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.gray500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (item.priority != null)
                _OverviewPriorityTag(priority: item.priority!),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.description,
            style: AppTextStyles.body2.copyWith(
              color: AppColors.gray700,
              height: 1.7,
            ),
          ),
          if (item.acceptanceSummary != null) ...[
            const SizedBox(height: 10),
            Text(
              '验收：${item.acceptanceSummary!}',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.gray600,
                height: 1.6,
              ),
            ),
          ],
          if (!isLast) ...[
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.gray200),
          ],
        ],
      ),
    );
  }
}

class _OverviewInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _OverviewInfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.gray500,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.body2.copyWith(
              color: AppColors.gray700,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }
}

class _OverviewPriorityTag extends StatelessWidget {
  final String priority;

  const _OverviewPriorityTag({required this.priority});

  @override
  Widget build(BuildContext context) {
    final tone = switch (priority.trim().toUpperCase()) {
      'P0' => (bg: AppColors.errorBg, text: AppColors.error),
      'P1' => (bg: AppColors.warningBg, text: AppColors.warning),
      'P2' => (bg: AppColors.infoBg, text: AppColors.info),
      _ => (bg: AppColors.gray100, text: AppColors.gray500),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tone.bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        priority,
        style: AppTextStyles.caption.copyWith(
          color: tone.text,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String _formatComplexity(String value) {
  switch (value.trim().toUpperCase()) {
    case 'S':
      return 'S · 1-3天';
    case 'M':
      return 'M · 3-7天';
    case 'L':
      return 'L · 7-15天';
    case 'XL':
      return 'XL · 15-30天';
    default:
      return value;
  }
}

String _formatRequirementKey(String key) {
  switch (key.trim().toLowerCase()) {
    case 'performance':
      return '性能';
    case 'security':
      return '安全';
    case 'availability':
      return '可用性';
    case 'reliability':
      return '可靠性';
    default:
      return key;
  }
}

// =============================================================================
// Step 3: Budget (unchanged)
// =============================================================================

class _BudgetStage extends StatelessWidget {
  final double? budgetMin;
  final double? budgetMax;
  final BudgetSuggestion? suggestion;
  final ValueChanged<RangeValues> onChanged;

  const _BudgetStage({
    required this.budgetMin,
    required this.budgetMax,
    required this.suggestion,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasRange = budgetMin != null && budgetMax != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _InlineStepIntro(
          eyebrow: '预算设置',
          title: '先把可执行区间定下来',
          body: '预算不需要一次精确到报价，但它要足够接近真实预期，这样后面平台给出的匹配结果才不会失真。',
        ),
        const SizedBox(height: 16),
        VccCard(
          padding: const EdgeInsets.all(18),
          backgroundColor: AppColors.onboardingSurface,
          border: Border.all(color: AppColors.gray200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '当前预算区间',
                style: AppTextStyles.onboardingMeta.copyWith(
                  color: AppColors.gray500,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                hasRange ? _formatBudget(budgetMin!, budgetMax!) : '先拖动下面的区间滑杆',
                style: AppTextStyles.h2.copyWith(color: AppColors.black),
              ),
              const SizedBox(height: 8),
              Text(
                '范围越接近真实预期，平台推荐的团队规模、经验层级和推进节奏就越可靠。',
                style: AppTextStyles.body2
                    .copyWith(height: 1.6, color: AppColors.gray600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        VccCard(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          backgroundColor: AppColors.onboardingSurface,
          border: Border.all(color: AppColors.gray200),
          child: MarketBudgetSlider(
            min: 0,
            max: 500000,
            currentMin: budgetMin,
            currentMax: budgetMax,
            onChanged: onChanged,
          ),
        ),
        if (suggestion != null) ...[
          const SizedBox(height: 12),
          VccCard(
            padding: const EdgeInsets.all(18),
            backgroundColor: AppColors.gray100,
            border: Border.all(color: AppColors.gray200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '平台建议',
                  style: AppTextStyles.onboardingMeta.copyWith(
                    color: AppColors.gray600,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _formatBudget(suggestion!.min, suggestion!.max),
                  style: AppTextStyles.h3.copyWith(color: AppColors.black),
                ),
                const SizedBox(height: 6),
                Text(
                  suggestion!.reason,
                  style: AppTextStyles.body2
                      .copyWith(height: 1.6, color: AppColors.gray600),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// =============================================================================
// Step 4: Match Team
// =============================================================================

class _MatchTeamStage extends StatelessWidget {
  final RecommendedTeam? team;
  final bool isLoading;

  const _MatchTeamStage({
    required this.team,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InlineStepIntro(
            eyebrow: '匹配中',
            title: '正在发布项目并匹配团队',
            body: '平台正在先发布项目，再根据项目特征筛选最合适的团队。',
          ),
          SizedBox(height: 32),
          Center(
            child: Column(
              children: [
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.gray800,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  '正在发布并匹配…',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.gray500,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (team == null) {
      return const _InlineStepIntro(
        eyebrow: '匹配团队',
        title: '暂无推荐团队',
        body: '当前没有匹配到合适的团队，你可以跳过此步骤直接发布项目，或稍后重试匹配。',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _InlineStepIntro(
          eyebrow: '推荐团队',
          title: '平台生成了当前推荐',
          body: '根据项目分类、预算和交付节奏自动匹配，采用后将按这条默认推荐发起快速撮合。',
        ),
        const SizedBox(height: 16),
        VccCard(
          padding: const EdgeInsets.all(18),
          backgroundColor: AppColors.onboardingSurface,
          border: Border.all(color: AppColors.gray200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.gray100,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: team!.avatar != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              team!.avatar!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.groups_rounded,
                                color: AppColors.gray500,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.groups_rounded,
                            color: AppColors.gray500,
                          ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          team!.name,
                          style: AppTextStyles.h3.copyWith(
                            color: AppColors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.gray100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                team!.level,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.gray700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '匹配度 ${team!.matchScore}%',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.gray500,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (team!.skills.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: team!.skills.map((skill) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.gray100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        skill,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.gray700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              if (team!.reason != null) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.gray100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    team!.reason!,
                    style: AppTextStyles.body2.copyWith(
                      height: 1.6,
                      color: AppColors.gray600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MatchTeamFooter extends StatelessWidget {
  final RecommendedTeam? team;
  final bool isLoading;
  final bool isSubmitting;
  final String noTeamPrimaryLabel;
  final VoidCallback onConfirm;
  final VoidCallback onReMatch;
  final VoidCallback? onSkip;

  const _MatchTeamFooter({
    required this.team,
    required this.isLoading,
    required this.isSubmitting,
    required this.noTeamPrimaryLabel,
    required this.onConfirm,
    required this.onReMatch,
    this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const SizedBox.shrink();

    return VccFlowFooterShell(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (team != null) ...[
            VccButton(
              text: '采用当前推荐',
              onPressed: !isSubmitting ? onConfirm : null,
              isLoading: isSubmitting,
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: isSubmitting ? null : onReMatch,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  '换一个团队',
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.gray500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ] else ...[
            VccButton(
              text: noTeamPrimaryLabel,
              onPressed: !isSubmitting ? onSkip : null,
              isLoading: isSubmitting,
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: isSubmitting ? null : onReMatch,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  '重新匹配',
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.gray500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// Step 5: Publish result
// =============================================================================

class _PublishResultStage extends StatelessWidget {
  final PostPublishResultType resultType;

  const _PublishResultStage({
    required this.resultType,
  });

  @override
  Widget build(BuildContext context) {
    final isAwaiting =
        resultType == PostPublishResultType.awaitingTeamConfirmation;
    final stageHeight = (MediaQuery.sizeOf(context).height * 0.46)
        .clamp(340.0, 460.0)
        .toDouble();
    final outcome = isAwaiting ? '当前正在等待团队确认' : '当前还没有匹配到团队';
    final supporting =
        isAwaiting ? '推荐已经发出，团队确认后平台会继续通知你。' : '你可以先离开这个页面，之后再回来继续匹配团队。';

    return SizedBox(
      height: stageHeight,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _PublishResultBadge(),
            const SizedBox(height: 24),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 260),
              child: Text(
                outcome,
                textAlign: TextAlign.center,
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.black,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Text(
                supporting,
                textAlign: TextAlign.center,
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.gray500,
                  height: 1.7,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PublishResultFooter extends StatelessWidget {
  final PostPublishResultType resultType;
  final VoidCallback? onViewProject;
  final VoidCallback? onGoHome;
  final VoidCallback? onRetryMatch;

  const _PublishResultFooter({
    required this.resultType,
    this.onViewProject,
    this.onGoHome,
    this.onRetryMatch,
  });

  @override
  Widget build(BuildContext context) {
    final isAwaiting =
        resultType == PostPublishResultType.awaitingTeamConfirmation;

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.onboardingBackground,
        border: Border(top: BorderSide(color: AppColors.gray200)),
      ),
      child: SafeArea(
        top: false,
        minimum: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              VccButton(
                text: '查看项目详情',
                onPressed: onViewProject,
                icon: Icons.arrow_outward_rounded,
              ),
              const SizedBox(height: 10),
              VccButton(
                text: isAwaiting ? '返回首页' : '再次匹配团队',
                type: VccButtonType.secondary,
                onPressed: isAwaiting ? onGoHome : onRetryMatch,
              ),
              if (!isAwaiting) ...[
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: onGoHome,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      '返回首页',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.gray500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PublishResultBadge extends StatelessWidget {
  const _PublishResultBadge();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.92, end: 1),
      duration: const Duration(milliseconds: 480),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0, 1),
          child: Transform.scale(
            scale: value,
            child: child,
          ),
        );
      },
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: AppColors.black,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Icon(
          Icons.check_rounded,
          size: 36,
          color: AppColors.white,
        ),
      ),
    );
  }
}

String _formatBudget(double min, double max) {
  return '¥${min.toStringAsFixed(0)} - ¥${max.toStringAsFixed(0)}';
}
