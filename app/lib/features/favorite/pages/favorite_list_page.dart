import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/vcc_avatar.dart';
import '../../../shared/widgets/vcc_empty_state.dart';
import '../../../shared/widgets/vcc_loading.dart';
import '../../../shared/widgets/vcc_toast.dart';
import '../models/favorite_models.dart';
import '../providers/favorite_provider.dart';

class FavoriteListPage extends ConsumerWidget {
  const FavoriteListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(favoriteListProvider);
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.only(top: topPadding),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      behavior: HitTestBehavior.opaque,
                      child: const Padding(
                        padding: EdgeInsets.all(16),
                        child: Icon(Icons.arrow_back_ios,
                            size: 18, color: Color(0xFF1A1C1C)),
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        '我的收藏',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1C1C),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                _FilterBar(currentFilter: state.filterType),
              ],
            ),
          ),
          Expanded(child: _buildBody(context, ref, state)),
        ],
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, WidgetRef ref, FavoriteListState state) {
    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: VccLoading());
    }

    if (state.items.isEmpty) {
      return const Center(
        child: VccEmptyState(
          title: '还没有收藏',
          subtitle: '去广场发现感兴趣的项目和团队方吧',
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.black,
      onRefresh: () =>
          ref.read(favoriteListProvider.notifier).loadFavorites(),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        itemCount: state.items.length + (state.hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index >= state.items.length) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(favoriteListProvider.notifier).loadMore();
            });
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: VccLoading()),
            );
          }
          final item = state.items[index];
          return item.isProject
              ? _ProjectFavoriteCard(item: item)
              : _ExpertFavoriteCard(item: item);
        },
      ),
    );
  }
}

class _FilterBar extends ConsumerWidget {
  final String? currentFilter;
  const _FilterBar({this.currentFilter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          _FilterChip(
            label: '全部',
            selected: currentFilter == null,
            onTap: () =>
                ref.read(favoriteListProvider.notifier).setFilter(null),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: '项目',
            selected: currentFilter == 'project',
            onTap: () =>
                ref.read(favoriteListProvider.notifier).setFilter('project'),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: '团队方',
            selected: currentFilter == 'expert',
            onTap: () =>
                ref.read(favoriteListProvider.notifier).setFilter('expert'),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.black : const Color(0xFFF3F3F3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : AppColors.gray600,
          ),
        ),
      ),
    );
  }
}

class _ProjectFavoriteCard extends ConsumerWidget {
  final FavoriteItem item;
  const _ProjectFavoriteCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toggleState = ref.watch(favoriteToggleProvider);
    final isRemoving = toggleState.isLoading(item.targetId);

    return GestureDetector(
      onTap: () => context.push(
        RoutePaths.projectDetail.replaceFirst(':projectId', item.targetId),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F3F3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '项目',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: AppColors.gray500,
                          ),
                        ),
                      ),
                      if (item.category != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          item.category!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.gray400,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.title ?? '未命名项目',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1C1C),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.displayBudget,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1C1C),
                    ),
                  ),
                ],
              ),
            ),
            _UnfavoriteButton(
              isLoading: isRemoving,
              onTap: () => _handleUnfavorite(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleUnfavorite(BuildContext context, WidgetRef ref) async {
    final ok = await ref.read(favoriteToggleProvider.notifier).toggle(
          targetType: item.targetType.name,
          targetId: item.targetId,
        );
    if (!context.mounted) return;
    if (ok) {
      VccToast.show(context, message: '已取消收藏');
      ref.read(favoriteListProvider.notifier).loadFavorites();
    }
  }
}

class _ExpertFavoriteCard extends ConsumerWidget {
  final FavoriteItem item;
  const _ExpertFavoriteCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toggleState = ref.watch(favoriteToggleProvider);
    final isRemoving = toggleState.isLoading(item.targetId);

    return GestureDetector(
      onTap: () => context.push(
        RoutePaths.expertProfileView
            .replaceFirst(':userId', item.targetId),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            VccAvatar(
              size: VccAvatarSize.medium,
              imageUrl: item.avatarUrl,
              fallbackText: (item.nickname ?? 'U').isNotEmpty
                  ? (item.nickname ?? 'U').substring(0, 1)
                  : 'U',
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.nickname ?? '未知用户',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1C1C),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (item.rating != null)
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 14, color: AppColors.accentGold),
                        const SizedBox(width: 2),
                        Text(
                          item.rating!.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.gray500,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F3F3),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '团队方',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: AppColors.gray500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _UnfavoriteButton(
              isLoading: isRemoving,
              onTap: () => _handleUnfavorite(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleUnfavorite(BuildContext context, WidgetRef ref) async {
    final ok = await ref.read(favoriteToggleProvider.notifier).toggle(
          targetType: item.targetType.name,
          targetId: item.targetId,
        );
    if (!context.mounted) return;
    if (ok) {
      VccToast.show(context, message: '已取消收藏');
      ref.read(favoriteListProvider.notifier).loadFavorites();
    }
  }
}

class _UnfavoriteButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const _UnfavoriteButton({
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.gray400),
                ),
              )
            : const Icon(
                Icons.bookmark,
                size: 20,
                color: AppColors.black,
              ),
      ),
    );
  }
}
