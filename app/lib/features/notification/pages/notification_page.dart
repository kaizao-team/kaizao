import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../shared/widgets/vcc_editorial_app_bar.dart';
import '../../../shared/widgets/vcc_filter_chip_bar.dart';
import '../../../shared/widgets/vcc_toast.dart';
import '../models/notification_models.dart';
import '../providers/notification_provider.dart';

enum _NotificationFilter {
  all('全部'),
  unread('未读'),
  newBid('新投标', NotificationKind.newBid),
  matchSuccess('合作确认', NotificationKind.matchSuccess),
  payment('支付提醒', NotificationKind.payReminder),
  delivery('验收提醒', NotificationKind.milestoneDelivered),
  system('系统提醒', NotificationKind.system);

  final String label;
  final NotificationKind? kind;

  const _NotificationFilter(this.label, [this.kind]);
}

class _NotificationGroup {
  final NotificationKind kind;
  final List<NotificationItem> items;

  const _NotificationGroup({
    required this.kind,
    required this.items,
  });
}

class NotificationPage extends ConsumerStatefulWidget {
  const NotificationPage({super.key});

  @override
  ConsumerState<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends ConsumerState<NotificationPage> {
  final ScrollController _scrollController = ScrollController();
  _NotificationFilter _filter = _NotificationFilter.all;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 180) {
      ref.read(notificationProvider.notifier).loadMore();
    }
  }

  List<NotificationItem> _applyFilter(List<NotificationItem> items) {
    return items.where((item) {
      switch (_filter) {
        case _NotificationFilter.all:
          return true;
        case _NotificationFilter.unread:
          return !item.isRead;
        case _NotificationFilter.payment:
        case _NotificationFilter.delivery:
        case _NotificationFilter.newBid:
        case _NotificationFilter.matchSuccess:
        case _NotificationFilter.system:
          return item.kind == _filter.kind;
      }
    }).toList(growable: false);
  }

  List<_NotificationGroup> _buildGroups(List<NotificationItem> items) {
    final buckets = <NotificationKind, List<NotificationItem>>{};
    for (final item in items) {
      buckets.putIfAbsent(item.kind, () => <NotificationItem>[]).add(item);
    }

    final groups = buckets.entries
        .map(
          (entry) => _NotificationGroup(
            kind: entry.key,
            items: entry.value,
          ),
        )
        .toList(growable: false);

    groups.sort((a, b) => a.kind.displayOrder.compareTo(b.kind.displayOrder));
    return groups;
  }

  Future<void> _onNotificationTap(NotificationItem item) async {
    await ref.read(notificationProvider.notifier).markAsRead(item.id);
    if (!mounted) return;

    if (!item.hasTarget) return;

    if (item.canOpenTarget && item.targetType == 'project') {
      context.push('/projects/${item.targetId}');
      return;
    }

    final message = item.unsupportedTargetMessage;
    if (message != null) {
      VccToast.show(
        context,
        message: message,
        type: VccToastType.warning,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationProvider);
    final filtered = _applyFilter(state.notifications);
    final groups = _buildGroups(filtered);
    final showGroupHeaders = _filter == _NotificationFilter.all ||
        _filter == _NotificationFilter.unread;

    final filterOptions = _NotificationFilter.values
        .map(
          (item) => VccFilterChipOption<_NotificationFilter>(
            value: item,
            label: item.label,
          ),
        )
        .toList(growable: false);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        color: AppColors.black,
        onRefresh: () => ref.read(notificationProvider.notifier).refresh(),
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            VccEditorialAppBar(
              title: '通知',
              subtitle:
                  state.unreadCount > 0 ? '${state.unreadCount} 条未读' : null,
              trailing: state.unreadCount > 0
                  ? TextButton(
                      onPressed: () => ref
                          .read(notificationProvider.notifier)
                          .markAllAsRead(),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        '全部标为已读',
                        style: AppTextStyles.body2.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : null,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: VccFilterChipBar<_NotificationFilter>(
                  options: filterOptions,
                  selectedValue: _filter,
                  onSelected: (next) => setState(() => _filter = next),
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
            if (state.isLoading && state.notifications.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _NotificationLoadingState(),
              )
            else if (state.errorMessage != null && state.notifications.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _NotificationErrorState(
                  message: state.errorMessage!,
                  onRetry: () =>
                      ref.read(notificationProvider.notifier).refresh(),
                ),
              )
            else if (filtered.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _NotificationEmptyState(
                  isFiltered: _filter != _NotificationFilter.all,
                  onResetFilter: _filter == _NotificationFilter.all
                      ? null
                      : () => setState(() => _filter = _NotificationFilter.all),
                ),
              )
            else ...[
              for (var index = 0; index < groups.length; index++) ...[
                if (showGroupHeaders || groups.length > 1)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        index == 0 ? 8 : 22,
                        20,
                        10,
                      ),
                      child: _SectionHeader(
                        label: groups[index].kind.label,
                        count: groups[index].items.length,
                      ),
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  sliver: SliverList.separated(
                    itemCount: groups[index].items.length,
                    itemBuilder: (context, itemIndex) {
                      final item = groups[index].items[itemIndex];
                      return _NotificationRow(
                        item: item,
                        onTap: () => _onNotificationTap(item),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                  ),
                ),
              ],
              SliverToBoxAdapter(
                child: _LoadMoreFooter(state: state),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final int? count;

  const _SectionHeader({
    required this.label,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    final suffix = count != null ? ' · $count' : '';
    return Text(
      '$label$suffix',
      style: AppTextStyles.caption.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.gray400,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  final NotificationItem item;
  final VoidCallback onTap;

  const _NotificationRow({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final unsupported = item.unsupportedTargetMessage != null;

    return Material(
      color: AppColors.surfaceRaised,
      borderRadius: BorderRadius.circular(AppRadius.xxl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.xxl),
            color: AppColors.surfaceRaised,
            border: Border.all(
              color: item.isRead ? AppColors.gray200 : AppColors.gray300,
              width: 0.5,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _NotificationGlyph(item: item),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: AppTextStyles.body1.copyWith(
                              height: 1.35,
                              fontWeight: item.isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                              color: AppColors.black,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          item.timeAgo,
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                    if (item.body.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        item.body,
                        style: AppTextStyles.body2.copyWith(
                          height: 1.6,
                          color: AppColors.gray600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (!item.isRead)
                          const _MetaPill(
                            label: '未读',
                            foreground: AppColors.black,
                            background: AppColors.gray100,
                          ),
                        if (item.canOpenTarget && item.actionLabel != null)
                          _MetaPill(
                            label: item.actionLabel!,
                            foreground: AppColors.black,
                            background: AppColors.gray100,
                            icon: Icons.arrow_outward_rounded,
                          ),
                        if (unsupported)
                          const _MetaPill(
                            label: '仅提醒',
                            foreground: AppColors.gray500,
                            background: AppColors.gray100,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationGlyph extends StatelessWidget {
  final NotificationItem item;

  const _NotificationGlyph({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Icon(
        _icon,
        size: 20,
        color: _foreground,
      ),
    );
  }

  IconData get _icon {
    switch (item.kind) {
      case NotificationKind.newBid:
        return Icons.gavel_rounded;
      case NotificationKind.matchSuccess:
        return Icons.handshake_outlined;
      case NotificationKind.payReminder:
        return Icons.receipt_long_outlined;
      case NotificationKind.milestoneDelivered:
        return Icons.flag_outlined;
      case NotificationKind.system:
        return Icons.notifications_none_rounded;
    }
  }

  Color get _background {
    switch (item.kind) {
      case NotificationKind.newBid:
      case NotificationKind.matchSuccess:
        return AppColors.accentLight;
      case NotificationKind.payReminder:
        return AppColors.warningBg;
      case NotificationKind.milestoneDelivered:
        return AppColors.infoBg;
      case NotificationKind.system:
        return AppColors.gray100;
    }
  }

  Color get _foreground {
    switch (item.kind) {
      case NotificationKind.newBid:
      case NotificationKind.matchSuccess:
        return AppColors.accentDark;
      case NotificationKind.payReminder:
        return AppColors.warningForeground;
      case NotificationKind.milestoneDelivered:
        return AppColors.infoForeground;
      case NotificationKind.system:
        return AppColors.gray600;
    }
  }
}

class _MetaPill extends StatelessWidget {
  final String label;
  final Color foreground;
  final Color background;
  final IconData? icon;

  const _MetaPill({
    required this.label,
    required this.foreground,
    required this.background,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: foreground),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationLoadingState extends StatelessWidget {
  const _NotificationLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 26,
        height: 26,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.black),
        ),
      ),
    );
  }
}

class _NotificationErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _NotificationErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '通知加载失败',
            style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            style: AppTextStyles.body2.copyWith(
              height: 1.7,
            ),
          ),
          const SizedBox(height: 22),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.black,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
            child: const Text('重新加载'),
          ),
        ],
      ),
    );
  }
}

class _NotificationEmptyState extends StatelessWidget {
  final bool isFiltered;
  final VoidCallback? onResetFilter;

  const _NotificationEmptyState({
    required this.isFiltered,
    required this.onResetFilter,
  });

  @override
  Widget build(BuildContext context) {
    final title = isFiltered ? '这个筛选下还没有内容' : '暂时没有新的提醒';
    final subtitle =
        isFiltered ? '换一个筛选看看，或者稍后再回来。' : '新投标、合作确认、支付和验收进展，会逐步汇总到这里。';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised,
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: AppColors.gray400,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            subtitle,
            style: AppTextStyles.body2.copyWith(height: 1.7),
          ),
          if (onResetFilter != null) ...[
            const SizedBox(height: 20),
            TextButton(
              onPressed: onResetFilter,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
              ),
              child: Text(
                '查看全部通知',
                style: AppTextStyles.body2.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LoadMoreFooter extends StatelessWidget {
  final NotificationState state;

  const _LoadMoreFooter({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.gray400),
            ),
          ),
        ),
      );
    }

    if (!state.hasMore && state.notifications.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 36),
        child: Center(
          child: Text(
            '没有更多通知了',
            style: AppTextStyles.body2.copyWith(
              color: AppColors.gray400,
            ),
          ),
        ),
      );
    }

    return const SizedBox(height: 24);
  }
}
