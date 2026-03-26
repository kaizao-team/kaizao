import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/routes.dart';
import '../../../shared/widgets/vcc_loading.dart';
import '../../../shared/widgets/vcc_empty_state.dart';
import '../providers/team_provider.dart';
import '../widgets/team_post_card.dart';
import '../widgets/role_filter_chips.dart';

class TeamHallPage extends ConsumerWidget {
  const TeamHallPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(teamHallProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '组队大厅',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, size: 24),
            onPressed: () => context.push(RoutePaths.createTeamPost),
          ),
        ],
      ),
      body: state.isLoading && state.posts.isEmpty
          ? const VccLoading()
          : RefreshIndicator(
              color: AppColors.black,
              onRefresh: () =>
                  ref.read(teamHallProvider.notifier).loadPosts(),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 12),
                      child: RoleFilterChips(
                        selectedRole: state.roleFilter,
                        onSelected: (role) => ref
                            .read(teamHallProvider.notifier)
                            .setRoleFilter(role),
                      ),
                    ),
                  ),
                  if (state.aiRecommended.isNotEmpty) ...[
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
                        child: Text(
                          'AI 推荐',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.black,
                          ),
                        ),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final post = state.aiRecommended[index];
                          return TeamPostCard(
                            post: post,
                            onTap: () => _navigateToDetail(context, post.id),
                          );
                        },
                        childCount: state.aiRecommended.length,
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          '全部寻人帖',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (state.posts.isEmpty && state.aiRecommended.isEmpty)
                    const SliverFillRemaining(
                      child: VccEmptyState(
                        icon: Icons.group_outlined,
                        title: '暂无寻人帖',
                        subtitle: '发布第一个寻人帖，开始组队吧',
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final post = state.posts[index];
                          return TeamPostCard(
                            post: post,
                            onTap: () => _navigateToDetail(context, post.id),
                          );
                        },
                        childCount: state.posts.length,
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
                ],
              ),
            ),
    );
  }

  void _navigateToDetail(BuildContext context, String postId) {
    context.push(
      RoutePaths.teamConfirm.replaceFirst(':teamId', postId),
    );
  }
}
