import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/vcc_button.dart';
import '../../../shared/widgets/vcc_loading.dart';
import '../../../shared/widgets/vcc_toast.dart';
import '../providers/team_provider.dart';
import '../widgets/team_member_row.dart';
import '../widgets/split_ratio_editor.dart';

class TeamConfirmPage extends ConsumerWidget {
  final String teamId;

  const TeamConfirmPage({super.key, required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(teamDetailProvider(teamId));

    if (state.isLoading && state.detail == null) {
      return const Scaffold(body: VccLoading());
    }

    final detail = state.detail;
    if (detail == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('加载失败')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '组队确认',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.gray50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail.projectName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.group, size: 16, color: AppColors.gray400),
                    const SizedBox(width: 4),
                    Text(
                      '${detail.members.length} 名成员',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.gray500,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        detail.status == 'confirmed' ? '已确认' : '待确认',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '团队成员',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 8),
          ...detail.members.map((m) => TeamMemberRow(member: m)),
          const SizedBox(height: 24),
          const Divider(color: AppColors.gray200),
          const SizedBox(height: 16),
          SplitRatioEditor(
            members: detail.members,
            onRatioChanged: (entry) {
              ref
                  .read(teamDetailProvider(teamId).notifier)
                  .updateMemberRatio(entry.key, entry.value);
            },
          ),
          const SizedBox(height: 32),
          VccButton(
            text: '确认组队',
            isLoading: state.isSubmitting,
            onPressed: detail.isRatioValid
                ? () => _confirm(context, ref)
                : null,
          ),
          if (!detail.isRatioValid)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                '分成比例总和必须等于100%才能确认',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.error),
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    final success =
        await ref.read(teamDetailProvider(teamId).notifier).confirmTeam();
    if (!context.mounted) return;
    if (success) {
      VccToast.show(context,
          message: '组队确认成功', type: VccToastType.success);
      Navigator.pop(context);
    } else {
      VccToast.show(context,
          message: '确认失败，请重试', type: VccToastType.error);
    }
  }
}
