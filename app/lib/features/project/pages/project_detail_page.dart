import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/vcc_button.dart';
import '../../../shared/widgets/vcc_tag.dart';
import '../providers/project_detail_provider.dart';

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

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(
          state.title.isNotEmpty ? state.title : '项目详情',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 22),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, size: 22),
            onPressed: () {},
          ),
        ],
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
          : state.data == null
              ? const Center(
                  child: Text('加载失败',
                      style: TextStyle(color: AppColors.gray500)),
                )
              : _DetailContent(state: state),
      bottomNavigationBar: state.data != null
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: VccButton(
                        text: '沟通',
                        type: VccButtonType.secondary,
                        onPressed: () {},
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: VccButton(
                        text: state.status == 2 ? '投标' : '查看进度',
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}

class _DetailContent extends StatelessWidget {
  final ProjectDetailState state;

  const _DetailContent({required this.state});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              VccStatusTag(
                label: state.statusName,
                type: VccTagType.status,
                status: _statusTagType(state.status),
              ),
              const Spacer(),
              Text(
                state.budgetDisplay,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            state.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            state.description,
            style: const TextStyle(
              fontSize: 15,
              height: 1.6,
              color: AppColors.gray600,
            ),
          ),
          if (state.techRequirements.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: state.techRequirements
                  .map((t) => VccTag(label: t))
                  .toList(),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.visibility_outlined,
                  size: 14, color: AppColors.gray400),
              const SizedBox(width: 4),
              Text('${state.viewCount}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.gray400)),
              const SizedBox(width: 16),
              Icon(Icons.gavel_outlined,
                  size: 14, color: AppColors.gray400),
              const SizedBox(width: 4),
              Text('${state.bidCount}投标',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.gray400)),
            ],
          ),
          const Divider(height: 32),
          if (state.prdSummary.isNotEmpty) ...[
            const Text(
              'PRD 摘要',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.gray50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.gray200),
              ),
              child: Text(
                state.prdSummary,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: AppColors.gray700,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
          if (state.milestones.isNotEmpty) ...[
            const Text(
              '里程碑',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 12),
            ...state.milestones.map((m) => _buildMilestone(m)),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildMilestone(Map<String, dynamic> milestone) {
    final title = milestone['title'] as String? ?? '';
    final status = milestone['status'] as String? ?? 'pending';
    final progress = milestone['progress'] as int? ?? 0;

    final isCompleted = status == 'completed';
    final isActive = status == 'in_progress';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppColors.success
                  : isActive
                      ? AppColors.black
                      : AppColors.gray200,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted ? Icons.check : Icons.circle,
              size: isCompleted ? 16 : 8,
              color: isCompleted || isActive
                  ? AppColors.white
                  : AppColors.gray400,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight:
                    isActive ? FontWeight.w600 : FontWeight.w400,
                color: isCompleted
                    ? AppColors.gray400
                    : AppColors.black,
                decoration: isCompleted
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
          ),
          if (isActive)
            Text(
              '$progress%',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.accent,
              ),
            ),
        ],
      ),
    );
  }

  String _statusTagType(int status) {
    switch (status) {
      case 5: return 'in_progress';
      case 6: return 'pending';
      case 7: return 'completed';
      case 9: return 'at_risk';
      default: return 'not_started';
    }
  }
}
