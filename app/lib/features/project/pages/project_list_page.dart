import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/routes.dart';
import '../../../shared/widgets/vcc_card.dart';
import '../../../shared/widgets/vcc_empty_state.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/project_list_provider.dart';

class ProjectListPage extends ConsumerWidget {
  const ProjectListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final listState = ref.watch(projectListProvider);
    final isDemander = authState.userRole != 2;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(
          '我的项目',
          style: AppTextStyles.h3,
        ),
        actions: [
          if (isDemander)
            IconButton(
              icon: const Icon(Icons.add, size: 22),
              onPressed: () => context.push(RoutePaths.publishProject),
            ),
        ],
      ),
      body: listState.isLoading
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
          : listState.errorMessage != null
              ? VccEmptyState(
                  icon: Icons.cloud_off_outlined,
                  title: '加载失败',
                  subtitle: listState.errorMessage,
                  buttonText: '重试',
                  onButtonPressed: () =>
                      ref.read(projectListProvider.notifier).refresh(),
                )
              : listState.projects.isEmpty
                  ? VccEmptyState(
                      icon: isDemander
                          ? Icons.description_outlined
                          : Icons.explore_outlined,
                      title: '还没有项目',
                      subtitle: isDemander ? '创建你的第一个项目' : '去广场看看好项目',
                      buttonText: isDemander ? '创建项目' : '去广场',
                      onButtonPressed: () => isDemander
                          ? context.push(RoutePaths.publishProject)
                          : context.go(RoutePaths.square),
                    )
                  : RefreshIndicator(
                      color: AppColors.black,
                      onRefresh: () =>
                          ref.read(projectListProvider.notifier).refresh(),
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.base,
                        ),
                        itemCount: listState.projects.length,
                        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, index) {
                          final proj = listState.projects[index];
                          return VccCard(
                            onTap: () {
                              if (proj.status == 5) {
                                context.push(
                                    '/projects/${proj.routingId}/manage');
                              } else {
                                context.push('/projects/${proj.routingId}');
                              }
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        proj.title,
                                        style: AppTextStyles.body1.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.black,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: _statusBgColor(proj.status),
                                        borderRadius: BorderRadius.circular(AppRadius.sm),
                                      ),
                                      child: Text(
                                        proj.statusName,
                                        style: AppTextStyles.overline.copyWith(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: _statusColor(proj.status),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  proj.budgetDisplay,
                                  style: AppTextStyles.body2.copyWith(
                                    color: AppColors.gray600,
                                  ),
                                ),
                                if (proj.progress > 0) ...[
                                  const SizedBox(height: AppSpacing.sm),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(AppRadius.xs),
                                          child: LinearProgressIndicator(
                                            value: proj.progress / 100,
                                            backgroundColor: AppColors.gray200,
                                            valueColor:
                                                const AlwaysStoppedAnimation<
                                                    Color>(AppColors.accent),
                                            minHeight: 4,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${proj.progress}%',
                                        style: AppTextStyles.caption.copyWith(
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.gray600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  Color _statusColor(int status) {
    switch (status) {
      case 2:
        return AppColors.accent;
      case 5:
        return AppColors.success;
      case 7:
        return AppColors.gray500;
      default:
        return AppColors.gray500;
    }
  }

  Color _statusBgColor(int status) {
    switch (status) {
      case 2:
        return AppColors.accentLight;
      case 5:
        return AppColors.successBg;
      case 7:
        return AppColors.gray100;
      default:
        return AppColors.gray100;
    }
  }
}
