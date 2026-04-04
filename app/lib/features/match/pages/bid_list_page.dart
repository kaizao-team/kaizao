import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/vcc_toast.dart';
import '../../auth/providers/auth_provider.dart';
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
                            onViewDetail: () {},
                            onAccept: () {
                              AcceptBidDialog.show(
                                context,
                                bid: bid,
                                onConfirm: () async {
                                  await ref
                                      .read(
                                          bidListProvider(projectId).notifier)
                                      .acceptBid(bid.id);
                                  if (context.mounted) {
                                    VccToast.show(context,
                                        message: '已选定 ${bid.userName}',
                                        type: VccToastType.success);
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
