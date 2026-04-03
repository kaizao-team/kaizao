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

const _postStepLabels = ['分类', 'AI 对话', '项目概览', '预算', '匹配团队', '等待确认'];

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
    title: '等待团队方确认',
    subtitle: '你已确认这个团队，正在等待对方回复。',
    compactTitle: '等待确认',
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

double _footerHeight(PostState state) {
  if (state.currentStep == 0) return 0;
  if (state.currentStep == 5) return 104;
  if (state.currentStep == 1) {
    if (_isRequirementReviewMode(state)) return 104;
    if (!_shouldShowRequirementConfirm(state)) return 0;
    return state.isConfirmingRequirement ? 132 : 88;
  }
  return 104;
}

Widget? _buildFooter({
  required PostState state,
  required WidgetRef ref,
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
        label: '下一步',
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
        isConfirming: state.isConfirmingMatch,
        onConfirm: () =>
            ref.read(postStateProvider.notifier).confirmTeamMatch(),
        onReMatch: () => ref.read(postStateProvider.notifier).reMatch(),
      );
    case 5:
      return VccFlowFooterBar(
        label: '返回首页',
        onPressed: () => ref.read(postStateProvider.notifier).goToStep(0),
      );
  }
  return null;
}

List<Widget> _buildPostSlivers({
  required PostState state,
  required WidgetRef ref,
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
      slivers.addAll(
        _buildAiChatSlivers(state: state, ref: ref),
      );
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
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 18, 20, 32),
          sliver: SliverToBoxAdapter(
            child: _WaitForTeamStage(),
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

  const PostPage({super.key, this.initialCategory});

  @override
  ConsumerState<PostPage> createState() => _PostPageState();
}

class _PostPageState extends ConsumerState<PostPage> {
  final _flowScrollController = ScrollController();

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
    // Step 5 (waiting) should not go back to step 4
    if (state.currentStep == 5) {
      _confirmClose(state);
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
    _confirmClose(state);
  }

  @override
  Widget build(BuildContext context) {
    final postState = ref.watch(postStateProvider);
    final visibleStep = _visibleStepIndex(postState);
    final meta = _postStepMetas[
        postState.currentStep.clamp(0, _postStepMetas.length - 1)];
    final titleTag = postState.currentStep == 1
        ? ({
              'data': '数据',
              'dev': '研发',
              'design': '视觉设计',
              'solution': '解决方案',
            }[postState.category] ??
            '项目方向')
        : null;

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
      if (error != null && error != previous?.errorMessage && mounted) {
        VccToast.show(context, message: error, type: VccToastType.error);
      }
    });

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
        state: postState,
        ref: ref,
      ),
      footerHeight: _footerHeight(postState),
      slivers: _buildPostSlivers(
        state: postState,
        ref: ref,
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
        const _InlineStepIntro(
          eyebrow: '项目概览',
          title: '确认已锁定的发布摘要',
          body:
              '这里展示的是当前对话里已经确认的需求方向。正式 requirement.md 会在撮合成功并确认合作后，由后端触发 EARS 拆解生成。',
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
                data.title,
                style: AppTextStyles.h3.copyWith(color: AppColors.black),
              ),
              const SizedBox(height: 12),
              Text(
                data.summary,
                style: AppTextStyles.body2.copyWith(
                  height: 1.7,
                  color: AppColors.gray700,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.gray200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 16,
                      color: AppColors.gray500,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '当前后端只完成 PRD 确认。正式需求文档与 EARS 任务拆解会在后续撮合成功、确认合作后生成。',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.gray600,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (data.budgetSuggestion != null) ...[
          const SizedBox(height: 12),
          VccCard(
            padding: const EdgeInsets.all(18),
            backgroundColor: AppColors.gray100,
            border: Border.all(color: AppColors.gray200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '预算提醒',
                  style: AppTextStyles.onboardingMeta.copyWith(
                    color: AppColors.gray600,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '推荐区间 ${_formatBudget(data.budgetSuggestion!.min, data.budgetSuggestion!.max)}',
                  style: AppTextStyles.h3.copyWith(color: AppColors.black),
                ),
                const SizedBox(height: 6),
                Text(
                  data.budgetSuggestion!.reason,
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
            max: 50000,
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
            title: '正在为你匹配团队',
            body: '平台正在根据项目特征筛选最合适的团队。',
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
                  '正在匹配…',
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
        title: '暂无推荐',
        body: '未能匹配到合适的团队，请稍后重试。',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _InlineStepIntro(
          eyebrow: '推荐团队',
          title: '平台推荐了一个团队',
          body: '根据项目分类、预算和交付节奏自动匹配，确认后等待团队方回复。',
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
  final bool isConfirming;
  final VoidCallback onConfirm;
  final VoidCallback onReMatch;

  const _MatchTeamFooter({
    required this.team,
    required this.isLoading,
    required this.isConfirming,
    required this.onConfirm,
    required this.onReMatch,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const SizedBox.shrink();

    return VccFlowFooterShell(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          VccButton(
            text: '确认团队',
            onPressed: team != null && !isConfirming ? onConfirm : null,
            isLoading: isConfirming,
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: isConfirming ? null : onReMatch,
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
        ],
      ),
    );
  }
}

// =============================================================================
// Step 5: Wait for team confirmation
// =============================================================================

class _WaitForTeamStage extends StatelessWidget {
  const _WaitForTeamStage();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _InlineStepIntro(
          eyebrow: '等待确认',
          title: '团队方正在确认中',
          body: '你已选定团队，正在等待对方确认合作意向。确认后即可正式启动项目。',
        ),
        const SizedBox(height: 24),
        VccCard(
          padding: const EdgeInsets.all(24),
          backgroundColor: AppColors.onboardingSurface,
          border: Border.all(color: AppColors.gray200),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.hourglass_top_rounded,
                  size: 28,
                  color: AppColors.gray500,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '等待团队方确认',
                style: AppTextStyles.h3.copyWith(color: AppColors.black),
              ),
              const SizedBox(height: 8),
              Text(
                '通常在 24 小时内会收到回复，届时会通过消息通知你。',
                textAlign: TextAlign.center,
                style: AppTextStyles.body2.copyWith(
                  height: 1.6,
                  color: AppColors.gray500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _formatBudget(double min, double max) {
  return '¥${min.toStringAsFixed(0)} - ¥${max.toStringAsFixed(0)}';
}
