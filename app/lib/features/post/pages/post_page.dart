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
import '../widgets/post_ai_chat.dart';
import '../widgets/post_category_step.dart';
import '../widgets/post_match_mode.dart';
import '../widgets/post_prd_loading.dart';

const _postStepLabels = ['分类', 'AI 对话', 'PRD', '预算', '撮合'];

const _categoryLabels = <String, String>{
  'data': '数据',
  'dev': '研发',
  'design': '视觉设计',
  'solution': '解决方案',
};

const _categoryDescriptions = <String, String>{
  'data': '适合指标分析、BI 报表、策略研究与业务洞察类项目。',
  'dev': '适合产品开发、功能交付、系统搭建与技术实现类项目。',
  'design': '适合品牌视觉、界面设计、交互表达与体验优化类项目。',
  'solution': '适合前期梳理、方案拆解、策略咨询与落地路径设计类项目。',
};

const _categoryPrompts = <String, List<String>>{
  'data': ['这次最想解决的核心业务问题是什么？', '现在有哪些数据源，口径是否已经稳定？', '最终需要报表、看板，还是分析结论？'],
  'dev': ['第一版必须上线的功能有哪些？', '目标用户是谁，他们最先会完成什么动作？', '交付时间、平台和技术约束分别是什么？'],
  'design': [
    '这次设计最先要解决的是品牌、界面还是转化？',
    '有没有现成品牌资产、风格参考或限制条件？',
    '最终交付需要高保真页面、设计规范，还是完整视觉包？',
  ],
  'solution': [
    '你现在最卡的是方向判断、执行方案，还是资源组织？',
    '这次输出希望偏策略文档、实施路径，还是陪跑拆解？',
    '项目当前有哪些已知前提和关键风险？',
  ],
};

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
    title: '确认这份项目定义',
    subtitle: '先把范围、模块和交付边界看清楚，再往预算和撮合走。',
    compactTitle: '项目定义',
  ),
  _PostFlowStepMeta(
    title: '把预算区间定下来',
    subtitle: '预算不是报价单，它决定平台之后推荐团队的精度和节奏。',
    compactTitle: '预算设置',
  ),
  _PostFlowStepMeta(
    title: '决定这次怎么开始匹配',
    subtitle: '你可以交给平台先筛一轮，也可以公开发布或定向邀请团队。',
    compactTitle: '撮合方式',
  ),
];

const _postLoadingMeta = _PostFlowStepMeta(
  title: '正在整理这份项目定义',
  subtitle: '先把结构沉淀下来，后面的预算判断和团队匹配才会更准。',
  compactTitle: '生成 PRD',
);

double _footerHeight(PostState state) {
  if (state.isGeneratingPrd || state.currentStep == 0) return 0;
  if (state.currentStep == 1) return state.canGeneratePrd ? 192 : 136;
  return 104;
}

Widget? _buildFooter({
  required PostState state,
  required WidgetRef ref,
  required TextEditingController controller,
  required FocusNode focusNode,
  required VoidCallback onSend,
  required VoidCallback onPublish,
}) {
  if (state.isGeneratingPrd || state.currentStep == 0) return null;

  switch (state.currentStep) {
    case 1:
      return _AiComposerFooter(
        controller: controller,
        focusNode: focusNode,
        isAiTyping: state.isAiTyping,
        canGeneratePrd: state.canGeneratePrd,
        onSend: onSend,
        onGeneratePrd: () => ref.read(postStateProvider.notifier).generatePrd(),
      );
    case 2:
      return VccFlowFooterBar(
        label: '确认 PRD，设置预算',
        onPressed: state.prdData == null
            ? null
            : () => ref.read(postStateProvider.notifier).goToStep(3),
      );
    case 3:
      return VccFlowFooterBar(
        label: '下一步',
        onPressed: state.budgetMin != null && state.budgetMax != null
            ? () => ref.read(postStateProvider.notifier).goToStep(4)
            : null,
      );
    case 4:
      return VccFlowFooterBar(
        label: '创建项目',
        onPressed: state.canPublish && !state.isPublishing ? onPublish : null,
        isLoading: state.isPublishing,
      );
  }

  return null;
}

List<Widget> _buildPostSlivers({
  required PostState state,
  required WidgetRef ref,
  required ScrollController chatScrollController,
  required ValueChanged<String> onPromptSelected,
}) {
  if (state.isGeneratingPrd) {
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        sliver: SliverToBoxAdapter(
          child: PostPrdLoading(progress: state.prdProgress),
        ),
      ),
    ];
  }

  final slivers = <Widget>[
    if (state.currentStep >= 1 && state.currentStep <= 3)
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Align(
            alignment: Alignment.centerRight,
            child: _DraftShortcut(
              onTap: () => ref.read(postStateProvider.notifier).saveDraft(),
            ),
          ),
        ),
      ),
  ];

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
        _buildAiChatSlivers(
          state: state,
          chatScrollController: chatScrollController,
          onPromptSelected: onPromptSelected,
        ),
      );
    case 2:
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
          sliver: SliverToBoxAdapter(
            child: _PrdDefinitionStage(prdData: state.prdData),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _InlineStepIntro(
                  eyebrow: '开始匹配',
                  title: '决定这次项目怎么起步',
                  body: '如果你还没有候选团队，用平台先帮你筛一轮会更省时间；如果你已经有对象，直接邀请更直接。',
                ),
                const SizedBox(height: 18),
                PostMatchMode(
                  selected: state.matchMode,
                  onSelect: (mode) =>
                      ref.read(postStateProvider.notifier).setMatchMode(mode),
                ),
              ],
            ),
          ),
        ),
      );
  }

  return slivers;
}

List<Widget> _buildAiChatSlivers({
  required PostState state,
  required ScrollController chatScrollController,
  required ValueChanged<String> onPromptSelected,
}) {
  final categoryLabel = _categoryLabels[state.category] ?? '项目方向';
  final categoryDescription =
      _categoryDescriptions[state.category] ?? '先把这次项目的方向说清楚。';
  final prompts = _categoryPrompts[state.category] ??
      const ['这次项目最想先解决什么问题？', '目标用户是谁？', '这次的时间和预算限制是什么？'];

  return [
    SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VccCard(
              padding: const EdgeInsets.all(18),
              backgroundColor: AppColors.onboardingSurface,
              border: Border.all(color: AppColors.gray200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '已锁定方向',
                    style: AppTextStyles.onboardingMeta.copyWith(
                      color: AppColors.gray500,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gray100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          categoryLabel,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.black,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          categoryDescription,
                          style: AppTextStyles.body2.copyWith(
                            height: 1.6,
                            color: AppColors.gray600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (state.messages.isEmpty) ...[
              const SizedBox(height: 16),
              const _InlineStepIntro(
                eyebrow: '建议开场',
                title: '先把目标、用户和限制说出来',
                body: '你不需要一开始就写成正式 PRD。先把关键信息讲清楚，AI 会边聊边替你归拢结构。',
              ),
              const SizedBox(height: 12),
              ...prompts.map((prompt) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: VccCard(
                    onTap: () => onPromptSelected(prompt),
                    padding: const EdgeInsets.all(16),
                    backgroundColor: AppColors.onboardingSurface,
                    border: Border.all(color: AppColors.gray200),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.gray100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.arrow_outward_rounded,
                            size: 16,
                            color: AppColors.black,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            prompt,
                            style: AppTextStyles.body1.copyWith(
                              color: AppColors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    ),
    SliverFillRemaining(
      hasScrollBody: true,
      child: PostAiChat(
        scrollController: chatScrollController,
        showFooter: false,
      ),
    ),
  ];
}

class PostPage extends ConsumerStatefulWidget {
  final String? initialCategory;

  const PostPage({super.key, this.initialCategory});

  @override
  ConsumerState<PostPage> createState() => _PostPageState();
}

class _PostPageState extends ConsumerState<PostPage> {
  final _flowScrollController = ScrollController();
  final _chatScrollController = ScrollController();
  final _messageController = TextEditingController();
  final _messageFocusNode = FocusNode();

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
    _chatScrollController.dispose();
    _messageController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  int _visibleStepIndex(PostState state) =>
      state.isGeneratingPrd ? 2 : state.currentStep;

  bool _hasProgress(PostState state) {
    return state.category != null ||
        state.messages.isNotEmpty ||
        state.prdData != null ||
        state.budgetMin != null ||
        state.budgetMax != null ||
        state.matchMode != null;
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
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
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
    _messageFocusNode.unfocus();
    if (state.currentStep > 0) {
      ref.read(postStateProvider.notifier).goToStep(state.currentStep - 1);
      return;
    }
    _confirmClose(state);
  }

  void _handleClose(PostState state) {
    _messageFocusNode.unfocus();
    _confirmClose(state);
  }

  void _applyPrompt(String prompt) {
    ref.read(postStateProvider.notifier).sendMessage(prompt);
    _scrollToBottom();
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;
    _messageController.clear();
    ref.read(postStateProvider.notifier).sendMessage(content);
    _scrollToBottom();
  }

  Future<void> _handlePublish() async {
    final notifier = ref.read(postStateProvider.notifier);
    final errors = notifier.validate();
    if (errors.isNotEmpty) {
      const errorMessages = <String, String>{
        'category': '请选择分类',
        'prd': '请先生成 PRD',
        'budget': '请设置预算范围',
        'matchMode': '请选择撮合模式',
      };
      if (mounted) {
        VccToast.show(
          context,
          message: errorMessages[errors.keys.first] ?? '请先补全项目信息',
          type: VccToastType.warning,
        );
      }
      return;
    }

    final projectId = await notifier.publish();
    if (projectId != null && mounted) {
      VccToast.show(context, message: '项目创建成功', type: VccToastType.success);
      context.go('/projects/$projectId');
    }
  }

  @override
  Widget build(BuildContext context) {
    final postState = ref.watch(postStateProvider);
    final visibleStep = _visibleStepIndex(postState);
    final meta = postState.isGeneratingPrd
        ? _postLoadingMeta
        : _postStepMetas[postState.currentStep];

    ref.listen<PostState>(postStateProvider, (previous, next) {
      if (_visibleStepIndex(previous ?? next) != _visibleStepIndex(next)) {
        _scrollToTop();
      }

      if (next.currentStep == 1 &&
          ((previous?.messages.length ?? 0) != next.messages.length ||
              previous?.isAiTyping != next.isAiTyping)) {
        _scrollToBottom();
      }

      final error = next.errorMessage;
      if (error != null && error != previous?.errorMessage && mounted) {
        VccToast.show(context, message: '操作失败，请稍后再试', type: VccToastType.error);
      }
    });

    return VccFlowScaffold(
      stepIndex: visibleStep,
      stepCount: _postStepLabels.length,
      stepLabels: _postStepLabels,
      title: meta.title,
      subtitle: meta.subtitle,
      compactTitle: meta.compactTitle,
      onBack: postState.isGeneratingPrd ? null : () => _handleBack(postState),
      onClose: () => _handleClose(postState),
      scrollController: _flowScrollController,
      footer: _buildFooter(
        state: postState,
        ref: ref,
        controller: _messageController,
        focusNode: _messageFocusNode,
        onSend: _sendMessage,
        onPublish: () {
          _handlePublish();
        },
      ),
      footerHeight: _footerHeight(postState),
      slivers: _buildPostSlivers(
        state: postState,
        ref: ref,
        chatScrollController: _chatScrollController,
        onPromptSelected: _applyPrompt,
      ),
    );
  }
}

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

class _DraftShortcut extends StatelessWidget {
  final VoidCallback onTap;

  const _DraftShortcut({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.bookmark_border_rounded,
              size: 16,
              color: AppColors.gray500,
            ),
            const SizedBox(width: 6),
            Text(
              '保存草稿',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.gray500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
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

class _AiComposerFooter extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isAiTyping;
  final bool canGeneratePrd;
  final VoidCallback onSend;
  final VoidCallback onGeneratePrd;

  const _AiComposerFooter({
    required this.controller,
    required this.focusNode,
    required this.isAiTyping,
    required this.canGeneratePrd,
    required this.onSend,
    required this.onGeneratePrd,
  });

  @override
  Widget build(BuildContext context) {
    return VccFlowFooterShell(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (canGeneratePrd) ...[
            VccButton(
              text: '信息已经够了，生成 PRD',
              onPressed: onGeneratePrd,
              icon: Icons.auto_awesome_rounded,
            ),
            const SizedBox(height: 12),
          ],
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            decoration: BoxDecoration(
              color: AppColors.gray100,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    enabled: !isAiTyping,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onSend(),
                    minLines: 1,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: '描述目标、用户、功能或限制……',
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: AppColors.gray400,
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: AppColors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: isAiTyping ? null : onSend,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: isAiTyping ? AppColors.gray300 : AppColors.black,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      isAiTyping
                          ? Icons.hourglass_top_rounded
                          : Icons.arrow_upward_rounded,
                      size: 18,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrdDefinitionStage extends StatelessWidget {
  final PrdGeneratedData? prdData;

  const _PrdDefinitionStage({required this.prdData});

  @override
  Widget build(BuildContext context) {
    if (prdData == null) {
      return const _InlineStepIntro(
        eyebrow: '项目定义',
        title: '还没有生成项目定义',
        body: '先回到上一页补充需求对话，等信息足够之后再生成 PRD。',
      );
    }

    final data = prdData!;
    final totalCards =
        data.modules.fold<int>(0, (sum, module) => sum + module.cardCount);

    Widget metric(String label, String value) {
      return VccCard(
        padding: const EdgeInsets.all(16),
        backgroundColor: AppColors.onboardingSurface,
        border: Border.all(color: AppColors.gray200),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.onboardingMeta.copyWith(
                color: AppColors.gray500,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTextStyles.num2.copyWith(color: AppColors.black),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _InlineStepIntro(
          eyebrow: '项目定义',
          title: '确认模块和交付边界',
          body: '先检查模块划分和卡片数量是否合理。这里确认得越准，预算和后续撮合越稳。',
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
                data.title.isEmpty ? '已生成项目定义' : data.title,
                style: AppTextStyles.h3.copyWith(color: AppColors.black),
              ),
              const SizedBox(height: 8),
              Text(
                '${data.modules.length} 个模块 · $totalCards 张需求卡片',
                style: AppTextStyles.body2.copyWith(color: AppColors.gray500),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: metric('模块数', '${data.modules.length}')),
            const SizedBox(width: 12),
            Expanded(child: metric('需求卡片', '$totalCards')),
          ],
        ),
        const SizedBox(height: 12),
        ...data.modules.asMap().entries.map((entry) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: entry.key == data.modules.length - 1 ? 0 : 10,
            ),
            child: VccCard(
              padding: const EdgeInsets.all(16),
              backgroundColor: AppColors.onboardingSurface,
              border: Border.all(color: AppColors.gray200),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.gray100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        '${entry.key + 1}'.padLeft(2, '0'),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.black,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.value.name,
                          style: AppTextStyles.h3.copyWith(
                            color: AppColors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${entry.value.cardCount} 张需求卡片',
                          style: AppTextStyles.body2
                              .copyWith(color: AppColors.gray500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
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

String _formatBudget(double min, double max) {
  return '¥${min.toStringAsFixed(0)} - ¥${max.toStringAsFixed(0)}';
}
