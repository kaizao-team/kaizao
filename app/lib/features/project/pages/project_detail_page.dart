import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../shared/widgets/vcc_avatar.dart';
import '../../../shared/widgets/vcc_button.dart';
import '../../../shared/widgets/vcc_card.dart';
import '../../../shared/widgets/vcc_section_label.dart';
import '../../../shared/widgets/vcc_tag.dart';
import '../../../shared/widgets/vcc_toast.dart';
import '../../auth/providers/auth_provider.dart';
import '../../favorite/providers/favorite_provider.dart';
import '../providers/project_detail_provider.dart';
import '../providers/project_list_provider.dart';

const double _kProjectPageHorizontalPadding = 20;
const double _kProjectSectionGap = 28;

class ProjectDetailPage extends ConsumerWidget {
  final String? projectId;

  const ProjectDetailPage({super.key, this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = projectId ?? '';
    if (id.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('项目详情')),
        body: const Center(child: Text('无效的项目ID')),
      );
    }

    final state = ref.watch(projectDetailProvider(id));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: state.isLoading
            ? const Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.black),
                  ),
                ),
              )
            : state.data == null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        state.errorMessage != null
                            ? '加载失败: ${state.errorMessage}'
                            : '加载失败',
                        style: const TextStyle(color: AppColors.gray500),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : _DetailContent(state: state, projectId: id),
        bottomNavigationBar: state.data != null
            ? _BottomActions(projectId: id, state: state)
            : null,
      ),
    );
  }
}

class _BottomActions extends ConsumerWidget {
  final String projectId;
  final ProjectDetailState state;

  const _BottomActions({required this.projectId, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final isDemander = authState.userRole != 2;

    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: isDemander
              ? _buildDemanderActions(context, ref)
              : _buildProviderActions(context, ref),
        ),
      ),
    );
  }

  /// 项目方底部按钮
  Widget _buildDemanderActions(BuildContext context, WidgetRef ref) {
    if (state.status <= 2) {
      return Row(
        children: [
          Expanded(
            child: _buildChatButton(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: VccButton(
              text: '查看投标',
              onPressed: () => context.push('/projects/$projectId/bids'),
            ),
          ),
        ],
      );
    }
    if (state.status == 3) {
      final alreadyAligned = state.data?['owner_aligned'] == true;
      return VccButton(
        text: alreadyAligned
            ? '已确认，等待团队方确认'
            : (state.isConfirmingAlignment ? '确认中…' : '确认需求对齐'),
        onPressed: alreadyAligned || state.isConfirmingAlignment
            ? null
            : () async {
                final ok = await ref
                    .read(projectDetailProvider(projectId).notifier)
                    .confirmAlignment();
                if (context.mounted && ok) {
                  VccToast.show(context, message: '已确认需求对齐');
                  ref.invalidate(projectListProvider);
                }
              },
      );
    }
    if (state.status == 4) {
      return VccButton(
        text: state.isStartingProject ? '启动中…' : '启动项目',
        onPressed: state.isStartingProject
            ? null
            : () async {
                final ok = await ref
                    .read(projectDetailProvider(projectId).notifier)
                    .startProject();
                if (context.mounted && ok) {
                  VccToast.show(context, message: '项目已启动');
                  ref.invalidate(projectListProvider);
                }
              },
      );
    }
    if (state.status == 6) {
      return Row(
        children: [
          Expanded(
            child: VccButton(
              text: '查看进度',
              type: VccButtonType.secondary,
              onPressed: () => context.push('/projects/$projectId/manage'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: VccButton(
              text: '验收通过',
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('确认验收'),
                    content: const Text('确认验收该项目？验收后项目将标记为已完成。'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('取消'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('确认验收'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && context.mounted) {
                  final ok = await ref
                      .read(projectDetailProvider(projectId).notifier)
                      .acceptProject();
                  if (context.mounted && ok) {
                    VccToast.show(context, message: '项目验收通过');
                    ref.invalidate(projectListProvider);
                  }
                }
              },
            ),
          ),
        ],
      );
    }
    if (state.status == 7) {
      final hasReviewed = state.data?['has_reviewed'] == true;
      if (hasReviewed) {
        return const VccButton(text: '已评价', onPressed: null);
      }
      final revieweeId = state.data?['provider_id']?.toString() ?? '';
      return VccButton(
        text: '去评价',
        onPressed: () async {
          await context.push(
            '${RoutePaths.rate}?projectId=$projectId&revieweeId=$revieweeId&isDemander=true',
          );
          if (context.mounted) {
            ref.invalidate(projectDetailProvider(projectId));
          }
        },
      );
    }
    // status >= 5
    return VccButton(
      text: '查看进度',
      onPressed: () => context.push('/projects/$projectId/manage'),
    );
  }

  /// 团队方底部按钮
  Widget _buildProviderActions(BuildContext context, WidgetRef ref) {
    // status=2 且有 bid（被推荐待确认）
    if (state.status == 2 && state.hasBid && state.bidId != null) {
      return Row(
        children: [
          Expanded(
            child: VccButton(
              text: state.isRejectingBid ? '拒绝中…' : '拒绝',
              type: VccButtonType.secondary,
              onPressed: state.isRejectingBid || state.isConfirmingBid
                  ? null
                  : () async {
                      final ok = await ref
                          .read(projectDetailProvider(projectId).notifier)
                          .rejectBid();
                      if (context.mounted && ok) {
                        VccToast.show(context, message: '已拒绝推荐');
                        ref.invalidate(projectListProvider);
                      }
                    },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: VccButton(
              text: state.isConfirmingBid ? '确认中…' : '确认接受',
              onPressed: state.isConfirmingBid || state.isRejectingBid
                  ? null
                  : () async {
                      final ok = await ref
                          .read(projectDetailProvider(projectId).notifier)
                          .confirmBid();
                      if (context.mounted && ok) {
                        VccToast.show(context, message: '已确认接受');
                        ref.invalidate(projectListProvider);
                      }
                    },
            ),
          ),
        ],
      );
    }
    // status=2 已投标
    if (state.status == 2 && state.hasBid) {
      return Row(
        children: [
          Expanded(child: _buildChatButton()),
          const SizedBox(width: 12),
          const Expanded(
            child: VccButton(
              text: '已投标',
              onPressed: null,
            ),
          ),
        ],
      );
    }
    // status=2 无 bid
    if (state.status == 2) {
      return Row(
        children: [
          Expanded(child: _buildChatButton()),
          const SizedBox(width: 12),
          Expanded(
            child: VccButton(
              text: '投标',
              onPressed: () async {
                await context.push('/projects/$projectId/bid');
                if (context.mounted) {
                  ref.invalidate(projectDetailProvider(projectId));
                }
              },
            ),
          ),
        ],
      );
    }
    // status=3 团队方也需要确认需求对齐
    if (state.status == 3) {
      final alreadyAligned = state.data?['provider_aligned'] == true;
      return VccButton(
        text: alreadyAligned
            ? '已确认，等待项目方确认'
            : (state.isConfirmingAlignment ? '确认中…' : '确认需求对齐'),
        onPressed: alreadyAligned || state.isConfirmingAlignment
            ? null
            : () async {
                final ok = await ref
                    .read(projectDetailProvider(projectId).notifier)
                    .confirmAlignment();
                if (context.mounted && ok) {
                  VccToast.show(context, message: '已确认需求对齐');
                  ref.invalidate(projectListProvider);
                }
              },
      );
    }
    // status=4 等待项目方启动
    if (state.status == 4) {
      return const VccButton(
        text: '等待项目方启动',
        onPressed: null,
      );
    }
    if (state.status == 6) {
      return const VccButton(text: '等待项目方验收', onPressed: null);
    }
    if (state.status == 7) {
      return const VccButton(text: '项目交付完毕', onPressed: null);
    }
    // status >= 5
    return VccButton(
      text: '进入看板',
      onPressed: () => context.push('/projects/$projectId/manage'),
    );
  }

  Widget _buildChatButton() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const VccButton(
          text: '沟通',
          type: VccButtonType.secondary,
          onPressed: null,
        ),
        Positioned(
          right: -4,
          top: -8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.gray500,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '即将开放',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppColors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailContent extends StatefulWidget {
  final ProjectDetailState state;
  final String projectId;

  const _DetailContent({required this.state, required this.projectId});

  @override
  State<_DetailContent> createState() => _DetailContentState();
}

class _DetailContentState extends State<_DetailContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enterController;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = CurvedAnimation(
      parent: _enterController,
      curve: Curves.easeOut,
    );
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.03),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _enterController,
      curve: Curves.easeOutCubic,
    ));
    _enterController.forward();
  }

  @override
  void dispose() {
    _enterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final projectId = widget.projectId;

    return FadeTransition(
      opacity: _fadeIn,
      child: SlideTransition(
        position: _slideUp,
        child: CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        _ProjectHeroSliver(state: s, projectId: projectId),
        if (s.status == 3 || s.status == 4)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              _kProjectPageHorizontalPadding,
              18,
              _kProjectPageHorizontalPadding,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: _MatchStatusBanner(status: s.status),
            ),
          ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            _kProjectPageHorizontalPadding,
            (s.status == 3 || s.status == 4) ? 12 : 18,
            _kProjectPageHorizontalPadding,
            48,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              VccPageSection(
                label: '概览',
                child: _buildOverviewCard(s),
              ),
              if (s.prdSummary.isNotEmpty) ...[
                const SizedBox(height: _kProjectSectionGap),
                VccPageSection(
                  label: '需求摘要',
                  child: _buildPrdSection(s),
                ),
              ],
              if (s.prdItems.isNotEmpty) ...[
                const SizedBox(height: _kProjectSectionGap),
                VccPageSection(
                  label: '需求条目',
                  trailing: Text(
                    '${s.prdItems.length} 条',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.gray400,
                    ),
                  ),
                  child: _buildPrdItemCards(s.prdItems),
                ),
              ],
              if (s.ownerName.isNotEmpty) ...[
                const SizedBox(height: _kProjectSectionGap),
                VccPageSection(
                  label: '项目方',
                  child: _buildOwnerCard(context, s),
                ),
              ],
            ]),
          ),
        ),
      ],
    ),
    ),
    );
  }

  Widget _buildOwnerCard(BuildContext context, ProjectDetailState s) {
    final canOpen = s.ownerId.isNotEmpty;

    return VccSurfaceCard(
      onTap: canOpen
          ? () => context.push(
                RoutePaths.profileView.replaceFirst(':userId', s.ownerId),
              )
          : null,
      child: Row(
        children: [
          VccAvatar(
            size: VccAvatarSize.large,
            fallbackText:
                s.ownerName.isNotEmpty ? s.ownerName.substring(0, 1) : '?',
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.ownerName,
                  style: AppTextStyles.h3.copyWith(
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '项目方',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.gray400,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Text(
              canOpen ? '查看主页' : '项目方',
              style: AppTextStyles.caption.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.gray500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(ProjectDetailState s) {
    return VccSurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
            child: Text(
              '项目概要',
              style: AppTextStyles.h3.copyWith(
                fontSize: 16,
                color: AppColors.onSurface,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
            child: Text(
              s.description.isNotEmpty ? s.description : '暂无项目描述',
              style: AppTextStyles.body1.copyWith(
                fontSize: 15,
                height: 1.72,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
            child: Column(
              children: [
                Container(
                  height: 1,
                  color: AppColors.outlineVariant,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: _ProjectInfoStrip(
                    items: [
                      _ProjectInfoSpec(
                        label: '分类',
                        value: s.categoryName,
                      ),
                      _ProjectInfoSpec(
                        label: '发布于',
                        value: s.timeAgo.isNotEmpty ? s.timeAgo : '刚刚',
                      ),
                      _ProjectInfoSpec(
                        label: '状态',
                        value: s.statusName,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (s.techRequirements.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
              child: Container(
                height: 1,
                color: AppColors.outlineVariant,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '技术要求',
                    style: AppTextStyles.overline.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.8,
                      color: AppColors.gray400,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: s.techRequirements
                        .map((t) => VccTag(label: t))
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPrdSection(ProjectDetailState s) {
    return VccSurfaceCard(
      child: Text(
        s.prdSummary,
        style: AppTextStyles.body1.copyWith(
          fontSize: 15,
          height: 1.72,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildPrdItemCards(List<Map<String, dynamic>> items) {
    return Column(
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final title = item['title']?.toString() ?? '';
        final description = item['description']?.toString() ?? '';
        final itemId = item['item_id']?.toString() ?? '';
        final moduleName = item['module_name']?.toString() ?? '';
        final priority = item['priority']?.toString().toUpperCase() ?? '';

        return Padding(
          padding: EdgeInsets.only(top: index == 0 ? 0 : 10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.outlineVariant,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (priority.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _priorityColor(priority).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          priority,
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _priorityColor(priority),
                          ),
                        ),
                      ),
                    if (priority.isNotEmpty) const SizedBox(width: 8),
                    if (moduleName.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          moduleName,
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gray500,
                          ),
                        ),
                      ),
                    const Spacer(),
                    if (itemId.isNotEmpty)
                      Text(
                        itemId,
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 11,
                          color: AppColors.gray400,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: AppTextStyles.body1.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: AppTextStyles.body2.copyWith(
                      fontSize: 13,
                      height: 1.6,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEarsTaskCards(List<Map<String, dynamic>> tasks) {
    return Column(
      children: tasks.asMap().entries.map((entry) {
        final index = entry.key;
        final task = entry.value;
        final title = task['title']?.toString() ?? '';
        final earsType = task['description']?.toString() ?? '';
        final priority = task['priority']?.toString().toUpperCase() ?? '';
        final effortHours = task['effort_hours'];
        final status = task['status']?.toString() ?? 'todo';

        return Padding(
          padding: EdgeInsets.only(top: index == 0 ? 0 : 10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.outlineVariant,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (priority.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _priorityColor(priority).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          priority,
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _priorityColor(priority),
                          ),
                        ),
                      ),
                    if (priority.isNotEmpty) const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _earsStatusColor(status).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _earsStatusLabel(status),
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _earsStatusColor(status),
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (effortHours != null)
                      Text(
                        '${effortHours}h',
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 11,
                          color: AppColors.gray400,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: AppTextStyles.body1.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                if (earsType.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    earsType,
                    style: AppTextStyles.body2.copyWith(
                      fontSize: 13,
                      height: 1.6,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _earsStatusColor(String status) {
    switch (status) {
      case 'in_progress':
        return AppColors.accent;
      case 'completed':
        return AppColors.success;
      default:
        return AppColors.gray400;
    }
  }

  String _earsStatusLabel(String status) {
    switch (status) {
      case 'in_progress':
        return '进行中';
      case 'completed':
        return '已完成';
      default:
        return '待开始';
    }
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'P0':
        return AppColors.error;
      case 'P1':
        return AppColors.warning;
      default:
        return AppColors.gray400;
    }
  }

  Widget _buildMilestoneSection(ProjectDetailState s) {
    return VccSurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          ...s.milestones.asMap().entries.map(
                (entry) => _buildMilestone(
                  entry.key,
                  entry.value,
                  isLast: entry.key == s.milestones.length - 1,
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildMilestone(
    int index,
    Map<String, dynamic> milestone, {
    bool isLast = false,
  }) {
    final title = milestone['title']?.toString() ?? '';
    final description = milestone['description']?.toString() ?? '';
    final status = milestone['status']?.toString() ?? 'pending';
    final progress = milestone['progress'] as int? ?? 0;
    final estimatedDays = (milestone['estimated_days'] as num?)?.toDouble();
    final paymentRatio = (milestone['payment_ratio'] as num?)?.toDouble();
    final phases = (milestone['phases'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .toList() ??
        [];
    final featureItemIds = (milestone['feature_item_ids'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    final isCompleted = status == 'completed';
    final isActive = status == 'in_progress';

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: AppColors.outlineVariant),
              ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppColors.success
                  : isActive
                      ? AppColors.black
                      : AppColors.surfaceAlt,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: isCompleted
                ? const Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: AppColors.white,
                  )
                : Text(
                    '${index + 1}',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isActive ? AppColors.white : AppColors.gray500,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.isNotEmpty ? title : '未命名里程碑',
                  style: AppTextStyles.body1.copyWith(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color:
                        isCompleted ? AppColors.gray400 : AppColors.onSurface,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: AppTextStyles.body2.copyWith(
                      fontSize: 12,
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _milestoneMetaTag(
                      _milestoneMetaText(status, progress),
                    ),
                    if (estimatedDays != null)
                      _milestoneMetaTag(
                        '${estimatedDays.toStringAsFixed(estimatedDays == estimatedDays.roundToDouble() ? 0 : 1)} 天',
                      ),
                    if (paymentRatio != null && paymentRatio > 0)
                      _milestoneMetaTag(
                        '${(paymentRatio * 100).toStringAsFixed(0)}%',
                      ),
                  ],
                ),
                if (phases.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: phases.map((phase) {
                      final phaseName = phase['name']?.toString() ?? '';
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          phaseName,
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.gray500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                if (featureItemIds.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: featureItemIds.map((id) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.outlineVariant,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          id,
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 10,
                            color: AppColors.gray400,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          if (isActive && progress > 0)
            Container(
              margin: const EdgeInsets.only(left: 10),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(
                '$progress%',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _milestoneMetaTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(
          fontSize: 11,
          color: AppColors.gray400,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  String _milestoneMetaText(String status, int progress) {
    switch (status) {
      case 'completed':
        return '已完成';
      case 'in_progress':
        return progress > 0 ? '进行中 · $progress%' : '进行中';
      default:
        return '待开始';
    }
  }
}

class _MatchStatusBanner extends StatelessWidget {
  final int status;

  const _MatchStatusBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    final bool isAligned = status == 4;
    final title = isAligned ? '需求已对齐' : '撮合成功';
    final subtitle = isAligned
        ? '需求细节已确认，可以启动项目进入正式履约。'
        : '已为你匹配到团队，平台正在介入对齐需求细节。\n确认需求对齐后，可启动项目进入履约阶段。';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.handshake_outlined,
            size: 22,
            color: AppColors.white,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.h3.copyWith(
                    fontSize: 16,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: AppTextStyles.body2.copyWith(
                    fontSize: 13,
                    height: 1.6,
                    color: Colors.white.withValues(alpha: 0.7),
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

class _ProjectInfoSpec {
  final String label;
  final String value;

  const _ProjectInfoSpec({
    required this.label,
    required this.value,
  });
}

class _ProjectInfoStrip extends StatelessWidget {
  final List<_ProjectInfoSpec> items;

  const _ProjectInfoStrip({required this.items});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: items.asMap().entries.expand((entry) {
        final index = entry.key;
        final item = entry.value;
        final children = <Widget>[
          Expanded(
            child: _ProjectInfoStripItem(
              spec: item,
              alignment: CrossAxisAlignment.center,
              textAlign: TextAlign.center,
            ),
          ),
        ];

        if (index != items.length - 1) {
          children.add(
            Container(
              width: 1,
              height: 28,
              color: AppColors.outlineVariant,
            ),
          );
        }

        return children;
      }).toList(),
    );
  }
}

class _ProjectInfoStripItem extends StatelessWidget {
  final _ProjectInfoSpec spec;
  final CrossAxisAlignment alignment;
  final TextAlign textAlign;

  const _ProjectInfoStripItem({
    required this.spec,
    required this.alignment,
    required this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Text(
            spec.label,
            textAlign: textAlign,
            style: AppTextStyles.overline.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.gray400,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            spec.value,
            textAlign: textAlign,
            style: AppTextStyles.caption.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectHeroSliver extends StatelessWidget {
  final ProjectDetailState state;
  final String projectId;

  const _ProjectHeroSliver({required this.state, required this.projectId});

  @override
  Widget build(BuildContext context) {
    final s = state;
    final publishedLabel = s.timeAgo.isNotEmpty ? s.timeAgo : '刚刚';

    return SliverToBoxAdapter(
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F0F0F), Color(0xFF1E1E1E)],
              ),
            ),
            child: Stack(
              children: [
                const Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _ProjectHeroGridPainter(),
                    ),
                  ),
                ),
                Positioned(
                  top: 18,
                  right: -24,
                  child: Transform.rotate(
                    angle: -0.18,
                    child: Container(
                      width: 148,
                      height: 112,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 24,
                  top: 126,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 26),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (Navigator.of(context).canPop()) {
                                  Navigator.of(context).maybePop();
                                } else {
                                  context.go('/home');
                                }
                              },
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.08),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.08),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.08),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                              ),
                              child: _FavoriteButton(projectId: projectId),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            VccStatusTag(
                              label: s.statusName,
                              type: VccTagType.status,
                              status: _statusTagType(s.status),
                            ),
                            _HeroMetaChip(label: s.categoryName),
                            _HeroMetaChip(label: publishedLabel),
                            if (s.matchScore > 0) ...[
                              _HeroMetaChip(label: '匹配 ${s.matchScore}%'),
                            ],
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(
                          s.title,
                          style: AppTextStyles.h1.copyWith(
                            fontSize: 30,
                            color: Colors.white,
                            height: 1.14,
                            letterSpacing: -0.6,
                          ),
                        ),
                        const SizedBox(height: 34),
                        Container(
                          padding: const EdgeInsets.only(top: 16),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                          ),
                          child: IntrinsicHeight(
                            child: Row(
                              children: [
                                Expanded(
                                  child: _HeroStat(
                                    value: s.budgetDisplay,
                                    label: '预算',
                                    alignment: CrossAxisAlignment.center,
                                    textAlign: TextAlign.center,
                                    staggerIndex: 0,
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                                Expanded(
                                  child: _HeroStat(
                                    value: s.viewCount.toString(),
                                    label: '浏览',
                                    alignment: CrossAxisAlignment.center,
                                    textAlign: TextAlign.center,
                                    staggerIndex: 1,
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                                Expanded(
                                  child: _HeroStat(
                                    value: s.bidCount.toString(),
                                    label: '投标',
                                    alignment: CrossAxisAlignment.center,
                                    textAlign: TextAlign.center,
                                    staggerIndex: 2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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

class _HeroMetaChip extends StatelessWidget {
  final String label;

  const _HeroMetaChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: 0.76),
        ),
      ),
    );
  }
}

String _statusTagType(int status) {
  switch (status) {
    case 3:
    case 4:
      return 'pending';
    case 5:
      return 'in_progress';
    case 6:
      return 'pending';
    case 7:
      return 'completed';
    case 8:
      return 'completed';
    case 9:
      return 'at_risk';
    default:
      return 'not_started';
  }
}

class _ProjectHeroGridPainter extends CustomPainter {
  const _ProjectHeroGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x09FFFFFF)
      ..strokeWidth = 0.5;

    const spacing = 18.0;
    for (double x = 0; x <= size.width; x += spacing) {
      for (double y = 0; y <= size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 0.85, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HeroStat extends StatelessWidget {
  final String value;
  final String label;
  final CrossAxisAlignment alignment;
  final TextAlign textAlign;
  final int staggerIndex;

  const _HeroStat({
    required this.value,
    required this.label,
    required this.alignment,
    required this.textAlign,
    required this.staggerIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          SizedBox(
            height: 32,
            child: Align(
              alignment: _textAlignment(),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: _textAlignment(),
                child: _AnimatedHeroMetricValue(
                  value: value,
                  staggerIndex: staggerIndex,
                  textAlign: textAlign,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: textAlign,
            style: AppTextStyles.overline.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.46),
              letterSpacing: 1.8,
            ),
          ),
        ],
      ),
    );
  }

  Alignment _textAlignment() {
    switch (textAlign) {
      case TextAlign.right:
      case TextAlign.end:
        return Alignment.centerRight;
      case TextAlign.center:
        return Alignment.center;
      default:
        return Alignment.centerLeft;
    }
  }
}

class _AnimatedHeroMetricValue extends StatefulWidget {
  final String value;
  final int staggerIndex;
  final TextAlign textAlign;

  const _AnimatedHeroMetricValue({
    required this.value,
    required this.staggerIndex,
    required this.textAlign,
  });

  @override
  State<_AnimatedHeroMetricValue> createState() =>
      _AnimatedHeroMetricValueState();
}

class _AnimatedHeroMetricValueState extends State<_AnimatedHeroMetricValue>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _delayTimer;

  bool get _canAnimate => RegExp(r'\d').hasMatch(widget.value);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 960),
    );
    _restartAnimation();
  }

  @override
  void didUpdateWidget(covariant _AnimatedHeroMetricValue oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value ||
        oldWidget.staggerIndex != widget.staggerIndex) {
      _restartAnimation();
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _restartAnimation() {
    _delayTimer?.cancel();
    if (!_canAnimate) {
      _controller.value = 1;
      return;
    }

    _controller.reset();
    _delayTimer = Timer(
      Duration(milliseconds: widget.staggerIndex * 80),
      () {
        if (!mounted) return;
        _controller.forward();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.num2.copyWith(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: Colors.white,
      letterSpacing: -0.3,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    if (!_canAnimate) {
      return Text(
        widget.value,
        textAlign: widget.textAlign,
        maxLines: 1,
        style: style,
      );
    }

    final chars = widget.value.split('');
    final digitIndexes = <int>[];
    for (var i = 0; i < chars.length; i++) {
      if (_isDigit(chars[i])) digitIndexes.add(i);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(chars.length, (charIndex) {
            final char = chars[charIndex];
            if (!_isDigit(char)) {
              return Text(char, style: style);
            }

            final digitOrder = digitIndexes.indexOf(charIndex);
            final start = digitOrder * 0.08;
            final interval = Interval(
              start.clamp(0.0, 0.72),
              1.0,
              curve: Curves.easeOutCubic,
            );

            return _RollingHeroDigit(
              digit: int.parse(char),
              progress: interval.transform(_controller.value),
              style: style,
              loops: 2 + (digitOrder % 2),
            );
          }),
        );
      },
    );
  }

  bool _isDigit(String value) =>
      value.codeUnitAt(0) >= 48 && value.codeUnitAt(0) <= 57;
}

class _RollingHeroDigit extends StatelessWidget {
  final int digit;
  final double progress;
  final TextStyle style;
  final int loops;

  const _RollingHeroDigit({
    required this.digit,
    required this.progress,
    required this.style,
    required this.loops,
  });

  @override
  Widget build(BuildContext context) {
    final height = (style.fontSize ?? 22) * (style.height ?? 1.2);
    final width = (style.fontSize ?? 22) * 0.68;
    final travel = (loops * 10) + digit;
    final position = travel * progress;
    final whole = position.floor();
    final fraction = position - whole;
    final current = whole % 10;
    final next = (current + 1) % 10;

    return SizedBox(
      width: width,
      height: height,
      child: ClipRect(
        child: OverflowBox(
          minWidth: width,
          maxWidth: width,
          minHeight: height * 2,
          maxHeight: height * 2,
          alignment: Alignment.topCenter,
          child: Transform.translate(
            offset: Offset(0, -fraction * height),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: height,
                  child: Center(child: Text('$current', style: style)),
                ),
                SizedBox(
                  height: height,
                  child: Center(child: Text('$next', style: style)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FavoriteButton extends ConsumerStatefulWidget {
  final String projectId;
  const _FavoriteButton({required this.projectId});

  @override
  ConsumerState<_FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends ConsumerState<_FavoriteButton> {
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    final projectId = widget.projectId;
    final detailState = ref.watch(projectDetailProvider(projectId));
    final toggleState = ref.watch(favoriteToggleProvider);

    if (!_initialized && detailState.data != null) {
      _initialized = true;
      if (detailState.isFavorited) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(favoriteToggleProvider.notifier).markFavorited(projectId);
        });
      }
    }

    final isFav = toggleState.isFavorited(projectId);
    final isLoading = toggleState.isLoading(projectId);

    return GestureDetector(
      onTap: isLoading
          ? null
          : () async {
              final ok = await ref
                  .read(favoriteToggleProvider.notifier)
                  .toggle(targetType: 'project', targetId: projectId);
              if (!context.mounted) return;
              if (ok) {
                final newFav =
                    ref.read(favoriteToggleProvider).isFavorited(projectId);
                VccToast.show(context, message: newFav ? '已收藏' : '已取消收藏');
              }
            },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white38),
                ),
              )
            : Icon(
                isFav ? Icons.bookmark : Icons.bookmark_border,
                size: 22,
                color: isFav ? Colors.white : Colors.white54,
              ),
      ),
    );
  }
}
