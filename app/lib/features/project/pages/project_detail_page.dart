import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/vcc_button.dart';
import '../../../shared/widgets/vcc_tag.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/comment_models.dart';
import '../providers/comment_provider.dart';
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

    return SafeArea(
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

class _DetailContent extends ConsumerStatefulWidget {
  final ProjectDetailState state;
  final String projectId;

  const _DetailContent({required this.state, required this.projectId});

  @override
  ConsumerState<_DetailContent> createState() => _DetailContentState();
}

class _DetailContentState extends ConsumerState<_DetailContent> {
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final commentState = ref.watch(commentListProvider(widget.projectId));

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              VccStatusTag(
                label: widget.state.statusName,
                type: VccTagType.status,
                status: _statusTagType(widget.state.status),
              ),
              const Spacer(),
              Text(
                widget.state.budgetDisplay,
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
            widget.state.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.state.description,
            style: const TextStyle(
              fontSize: 15,
              height: 1.6,
              color: AppColors.gray600,
            ),
          ),
          if (widget.state.techRequirements.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.state.techRequirements
                  .map((t) => VccTag(label: t))
                  .toList(),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.visibility_outlined,
                  size: 14, color: AppColors.gray400),
              const SizedBox(width: 4),
              Text('${widget.state.viewCount}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.gray400)),
              const SizedBox(width: 16),
              const Icon(Icons.gavel_outlined,
                  size: 14, color: AppColors.gray400),
              const SizedBox(width: 4),
              Text('${widget.state.bidCount}投标',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.gray400)),
            ],
          ),
          const Divider(height: 32),
          if (widget.state.prdSummary.isNotEmpty) ...[
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
                widget.state.prdSummary,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: AppColors.gray700,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
          if (widget.state.milestones.isNotEmpty) ...[
            const Text(
              '里程碑',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 12),
            ...widget.state.milestones.map((m) => _buildMilestone(m)),
            const SizedBox(height: 8),
          ],
          const Divider(height: 32),
          _buildCommentSection(commentState),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildCommentSection(CommentListState commentState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '评论',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ),
            ),
            const SizedBox(width: 6),
            if (commentState.comments.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${commentState.comments.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _buildCommentInput(commentState),
        const SizedBox(height: 16),
        if (commentState.isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.gray400),
                ),
              ),
            ),
          )
        else if (commentState.comments.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                '暂无评论，来说两句吧',
                style: TextStyle(fontSize: 13, color: AppColors.gray400),
              ),
            ),
          )
        else
          ...commentState.comments.map(
            (comment) => _buildCommentItem(comment),
          ),
      ],
    );
  }

  Widget _buildCommentInput(CommentListState commentState) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.gray50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.gray200),
            ),
            child: TextField(
              controller: _commentController,
              style: const TextStyle(fontSize: 14, color: AppColors.black),
              decoration: const InputDecoration(
                hintText: '写评论…',
                hintStyle: TextStyle(fontSize: 14, color: AppColors.gray400),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: InputBorder.none,
                isDense: true,
              ),
              maxLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _submitComment(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: commentState.isSubmitting ? null : _submitComment,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: commentState.isSubmitting
                  ? AppColors.gray200
                  : AppColors.black,
              borderRadius: BorderRadius.circular(10),
            ),
            child: commentState.isSubmitting
                ? const Padding(
                    padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.white),
                    ),
                  )
                : const Icon(Icons.send_rounded,
                    size: 18, color: AppColors.white),
          ),
        ),
      ],
    );
  }

  Future<void> _submitComment() async {
    final text = _commentController.text;
    if (text.trim().isEmpty) return;

    final success = await ref
        .read(commentListProvider(widget.projectId).notifier)
        .addComment(text);
    if (success && mounted) {
      _commentController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  Widget _buildCommentItem(CommentItem comment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.gray200,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                comment.userName.isNotEmpty
                    ? comment.userName.substring(0, 1)
                    : '?',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.userName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      comment.timeAgo,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.gray400,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.content,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: AppColors.gray700,
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => ref
                      .read(
                          commentListProvider(widget.projectId).notifier)
                      .toggleLike(comment.id),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        comment.isLiked
                            ? Icons.favorite
                            : Icons.favorite_border,
                        size: 14,
                        color: comment.isLiked
                            ? AppColors.error
                            : AppColors.gray400,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${comment.likeCount}',
                        style: TextStyle(
                          fontSize: 12,
                          color: comment.isLiked
                              ? AppColors.error
                              : AppColors.gray400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
