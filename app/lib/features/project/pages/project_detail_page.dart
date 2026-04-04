import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/vcc_avatar.dart';
import '../../../shared/widgets/vcc_button.dart';
import '../../../shared/widgets/vcc_tag.dart';
import '../../auth/providers/auth_provider.dart';
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
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text(
          state.title.isNotEmpty ? state.title : '项目详情',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1C1C),
          ),
        ),
        actions: const [],
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
                  child: Text(
                    '加载失败',
                    style: TextStyle(color: AppColors.gray500),
                  ),
                )
              : _DetailContent(state: state, projectId: id),
      bottomNavigationBar: state.data != null
          ? _BottomActions(projectId: id, state: state)
          : null,
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
          child: Row(
            children: [
              Expanded(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    VccButton(
                      text: '沟通',
                      type: VccButtonType.secondary,
                      onPressed: null,
                    ),
                    Positioned(
                      right: -4,
                      top: -8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
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
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: VccButton(
                  text: _rightButtonText(isDemander),
                  onPressed: () => _rightButtonAction(context, isDemander),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _rightButtonText(bool isDemander) {
    if (isDemander) {
      if (state.status <= 2) return '查看投标';
      return '查看进度';
    } else {
      if (state.status >= 5) return '进入看板';
      return '投标';
    }
  }

  void _rightButtonAction(BuildContext context, bool isDemander) {
    if (isDemander) {
      if (state.status <= 2) {
        context.push('/projects/$projectId/bids');
      } else {
        context.push('/projects/$projectId/manage');
      }
    } else {
      if (state.status >= 5) {
        context.push('/projects/$projectId/manage');
      } else {
        context.push('/projects/$projectId/bid');
      }
    }
  }
}

class _DetailContent extends StatelessWidget {
  final ProjectDetailState state;
  final String projectId;

  const _DetailContent({required this.state, required this.projectId});

  @override
  Widget build(BuildContext context) {
    final s = state;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroSection(s),
          const SizedBox(height: 8),
          if (s.ownerName.isNotEmpty) ...[
            _buildOwnerCard(s),
            const SizedBox(height: 8),
          ],
          _buildDescriptionSection(s),
          if (s.prdSummary.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildPrdSection(s),
          ],
          if (s.milestones.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildMilestoneSection(s),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeroSection(ProjectDetailState s) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              VccStatusTag(
                label: s.statusName,
                type: VccTagType.status,
                status: _statusTagType(s.status),
              ),
              const Spacer(),
              Text(
                s.budgetDisplay,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1C1C),
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            s.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1C1C),
              height: 1.3,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F3F3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  s.categoryName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF666666),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (s.timeAgo.isNotEmpty) ...[
                const SizedBox(width: 10),
                Text(
                  s.timeAgo,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.gray400,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildMetaItem(Icons.visibility_outlined, '${s.viewCount}'),
              const SizedBox(width: 20),
              _buildMetaItem(Icons.gavel_outlined, '${s.bidCount} 投标'),
              if (s.matchScore > 0) ...[
                const SizedBox(width: 20),
                _buildMetaItem(Icons.auto_awesome_outlined,
                    '匹配 ${s.matchScore}%'),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.gray400),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 12, color: AppColors.gray400),
        ),
      ],
    );
  }

  Widget _buildOwnerCard(ProjectDetailState s) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          VccAvatar(
            size: VccAvatarSize.small,
            fallbackText:
                s.ownerName.isNotEmpty ? s.ownerName.substring(0, 1) : '?',
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.ownerName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1C1C),
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  '项目方',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.gray400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection(ProjectDetailState s) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('项目描述'),
          const SizedBox(height: 10),
          Text(
            s.description,
            style: const TextStyle(
              fontSize: 15,
              height: 1.7,
              color: Color(0xFF444444),
            ),
          ),
          if (s.techRequirements.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: s.techRequirements
                  .map((t) => VccTag(label: t))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPrdSection(ProjectDetailState s) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('PRD 摘要'),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F3F3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              s.prdSummary,
              style: const TextStyle(
                fontSize: 14,
                height: 1.7,
                color: Color(0xFF555555),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneSection(ProjectDetailState s) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _SectionLabel('里程碑'),
              if (s.progress > 0) ...[
                const SizedBox(width: 8),
                Text(
                  '${s.progress}%',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray500,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          ...s.milestones.asMap().entries.map(
                (entry) => _buildMilestone(
                  entry.value,
                  isLast: entry.key == s.milestones.length - 1,
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildMilestone(Map<String, dynamic> milestone,
      {bool isLast = false}) {
    final title = milestone['title']?.toString() ?? '';
    final status = milestone['status']?.toString() ?? 'pending';
    final progress = milestone['progress'] as int? ?? 0;

    final isCompleted = status == 'completed';
    final isActive = status == 'in_progress';

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
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
                      : const Color(0xFFE8E8E8),
              borderRadius: BorderRadius.circular(8),
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
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isCompleted
                    ? AppColors.gray400
                    : const Color(0xFF1A1C1C),
                decoration:
                    isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          if (isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F3F3),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$progress%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1C1C),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _statusTagType(int status) {
    switch (status) {
      case 5:
        return 'in_progress';
      case 6:
        return 'pending';
      case 7:
        return 'completed';
      case 9:
        return 'at_risk';
      default:
        return 'not_started';
    }
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1A1C1C),
        letterSpacing: -0.2,
      ),
    );
  }
}
