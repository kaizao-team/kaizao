import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../shared/widgets/vcc_avatar.dart';
import '../../../shared/widgets/vcc_tag.dart';
import '../../../shared/widgets/vcc_toast.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/providers/home_provider.dart';
import '../../notification/providers/notification_provider.dart';
import '../../project/providers/project_list_provider.dart';
import '../models/match_models.dart';
import '../providers/match_provider.dart';
import '../widgets/bid_card.dart';
import '../widgets/accept_bid_dialog.dart';

class BidListPage extends ConsumerWidget {
  final String projectId;

  const BidListPage({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bidListProvider(projectId));
    final authState = ref.watch(authStateProvider);
    final currentUserId = authState.userId;

    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        title: Text(
          '收到的投标 (${state.bids.length})',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
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
          : state.errorMessage != null && state.bids.isEmpty
              ? _buildError(context, ref, state.errorMessage!)
              : state.bids.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      color: AppColors.black,
                      onRefresh: () => ref
                          .read(bidListProvider(projectId).notifier)
                          .loadBids(),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.bids.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final bid = state.bids[index];
                          final isBidOwner = bid.userId == currentUserId;
                          return BidCard(
                            bid: bid,
                            isOwner: isBidOwner,
                            onViewDetail: () =>
                                _showBidDetail(context, bid),
                            onAccept: () {
                              AcceptBidDialog.show(
                                context,
                                bid: bid,
                                onConfirm: () async {
                                  final ok = await ref
                                      .read(
                                          bidListProvider(projectId).notifier)
                                      .acceptBid(bid.id);
                                  if (context.mounted) {
                                    VccToast.show(context,
                                        message: ok
                                            ? '已选定 ${bid.userName}，撮合成功'
                                            : '操作失败，请重试',
                                        type: ok
                                            ? VccToastType.success
                                            : VccToastType.error);
                                    if (ok) {
                                      ref
                                          .read(
                                              projectListProvider.notifier)
                                          .refresh();
                                      ref
                                          .read(
                                              notificationProvider.notifier)
                                          .loadNotifications();
                                      ref
                                          .read(
                                              homeStateProvider.notifier)
                                          .refresh();
                                      if (context.mounted) {
                                        context.go(RoutePaths.home);
                                      }
                                    }
                                  }
                                },
                              );
                            },
                            onWithdraw: () => _confirmWithdraw(
                              context,
                              ref,
                              bid.id,
                              bid.userName,
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  void _showBidDetail(BuildContext context, BidItem bid) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final bottomPadding = MediaQuery.of(ctx).padding.bottom;
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: EdgeInsets.only(bottom: bottomPadding),
              child: CustomScrollView(
                controller: scrollController,
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            margin: const EdgeInsets.only(top: 12, bottom: 16),
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.gray300,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  VccAvatar(
                                    size: VccAvatarSize.large,
                                    fallbackText: bid.userName.isNotEmpty
                                        ? bid.userName.substring(0, 1)
                                        : 'U',
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                bid.userName,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.black,
                                                ),
                                                overflow:
                                                    TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (bid.isTeamBid) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.gray100,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: const Text(
                                                  '团队',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: AppColors.gray500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.star_rounded,
                                                size: 16,
                                                color: AppColors.accentGold),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${bid.rating}',
                                              style: AppTextStyles.body2
                                                  .copyWith(
                                                color: AppColors.gray600,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              '完成率 ${bid.completionRate}%',
                                              style: AppTextStyles.body2
                                                  .copyWith(
                                                color: AppColors.gray500,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              '匹配 ${bid.matchScore}%',
                                              style: AppTextStyles.body2
                                                  .copyWith(
                                                color: AppColors.accent,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              _DetailSection(
                                title: '报价与周期',
                                child: Row(
                                  children: [
                                    Text(
                                      '¥${bid.bidAmount.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.black,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Text(
                                      '${bid.durationDays} 天交付',
                                      style: AppTextStyles.body1.copyWith(
                                        color: AppColors.gray600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              _DetailSection(
                                title: '投标方案',
                                child: Text(
                                  bid.proposal,
                                  style: AppTextStyles.body2.copyWith(
                                    height: 1.7,
                                    color: AppColors.gray700,
                                  ),
                                ),
                              ),
                              if (bid.skills.isNotEmpty) ...[
                                const SizedBox(height: 20),
                                _DetailSection(
                                  title: '技能标签',
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: bid.skills
                                        .map((s) => VccTag(label: s))
                                        .toList(),
                                  ),
                                ),
                              ],
                              if (bid.isTeamBid &&
                                  bid.teamMembers.isNotEmpty) ...[
                                const SizedBox(height: 20),
                                _DetailSection(
                                  title: '团队成员',
                                  child: Column(
                                    children: bid.teamMembers.map((m) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                            bottom: 8),
                                        child: Row(
                                          children: [
                                            VccAvatar(
                                              size: VccAvatarSize.small,
                                              fallbackText: m.name.isNotEmpty
                                                  ? m.name.substring(0, 1)
                                                  : '?',
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              m.name,
                                              style: AppTextStyles.body2
                                                  .copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.black,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              m.role,
                                              style: AppTextStyles.caption
                                                  .copyWith(
                                                color: AppColors.gray500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                              if (!bid.isPending) ...[
                                const SizedBox(height: 20),
                                _DetailSection(
                                  title: '状态',
                                  child: Text(
                                    bid.status.label,
                                    style: AppTextStyles.body1.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: bid.status == BidStatus.accepted
                                          ? const Color(0xFF2E7D32)
                                          : bid.status == BidStatus.rejected
                                              ? const Color(0xFFC62828)
                                              : AppColors.gray500,
                                    ),
                                  ),
                                ),
                              ],
                              if (bid.isAiRecommended) ...[
                                const SizedBox(height: 20),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentLight,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppColors.accent.withValues(
                                          alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.auto_awesome_rounded,
                                        size: 18,
                                        color: AppColors.accent,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'AI 推荐此投标，综合评分较高',
                                          style: AppTextStyles.body2.copyWith(
                                            color: AppColors.accent,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmWithdraw(
    BuildContext context,
    WidgetRef ref,
    String bidId,
    String userName,
  ) {
    showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final bottomPadding = MediaQuery.of(ctx).padding.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 16 + bottomPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '撤回投标',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1C1C),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '撤回后将无法恢复，确定要撤回这条投标吗？',
                style: TextStyle(fontSize: 14, color: AppColors.gray500),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final ok = await ref
                        .read(bidListProvider(projectId).notifier)
                        .withdrawBid(bidId);
                    if (context.mounted) {
                      VccToast.show(
                        context,
                        message: ok ? '投标已撤回' : '撤回失败，请重试',
                        type: ok ? VccToastType.success : VccToastType.error,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('确认撤回',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFF3F3F3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('取消',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.gray600,
                      )),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: AppColors.gray300),
          SizedBox(height: 12),
          Text('暂无投标',
              style: TextStyle(fontSize: 15, color: AppColors.gray500)),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined,
              size: 48, color: AppColors.gray400),
          const SizedBox(height: 16),
          const Text('加载失败',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.gray600)),
          const SizedBox(height: 8),
          Text(message,
              style:
                  const TextStyle(fontSize: 13, color: AppColors.gray400),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () =>
                ref.read(bidListProvider(projectId).notifier).loadBids(),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('重试',
                  style: TextStyle(fontSize: 14, color: AppColors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _DetailSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.overline.copyWith(
            color: AppColors.gray500,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
