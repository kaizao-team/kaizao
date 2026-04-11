import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../shared/models/vibe_level.dart' show vibeLevelLabel;
import '../../../shared/widgets/vcc_avatar.dart';
import '../../../shared/widgets/vcc_tag.dart';
import '../models/match_models.dart';

class BidCard extends StatelessWidget {
  final BidItem bid;
  final VoidCallback? onViewDetail;
  final VoidCallback? onAccept;
  final VoidCallback? onWithdraw;
  final bool isOwner;

  const BidCard({
    super.key,
    required this.bid,
    this.onViewDetail,
    this.onAccept,
    this.onWithdraw,
    this.isOwner = false,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.gray200, width: 0.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md - 0.5),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (bid.isAiRecommended)
                Container(width: 2.5, color: AppColors.accent),
              Expanded(
                child: Container(
                  color: AppColors.surfaceRaised,
                  padding: const EdgeInsets.all(AppSpacing.base),
                  child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (bid.isAiRecommended)
            Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
              child: Text(
                'AI 推荐',
                style: AppTextStyles.caption.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
            ),
          Row(
            children: [
              VccAvatar(
                imageUrl: bid.isTeamBid
                    ? bid.teamAvatarUrl
                    : bid.avatar,
                size: VccAvatarSize.medium,
                fallbackText: (bid.isTeamBid
                            ? bid.teamName ?? bid.userName
                            : bid.userName)
                        .isNotEmpty
                    ? (bid.isTeamBid
                            ? bid.teamName ?? bid.userName
                            : bid.userName)
                        .substring(0, 1)
                    : 'U',
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            bid.isTeamBid
                                ? (bid.teamName ?? bid.userName)
                                : bid.userName,
                            style: AppTextStyles.body2.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.black,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (bid.isTeamBid) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.gray100,
                              borderRadius: BorderRadius.circular(AppRadius.xs),
                            ),
                            child: Text(
                              '团队',
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 10,
                                color: AppColors.gray500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_formatLevelDisplay(bid)} · 完成率${bid.completionRate}%',
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.gray500),
                    ),
                  ],
                ),
              ),
              if (bid.matchScore > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentLight,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    '匹配 ${bid.matchScore}%',
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '¥${bid.bidAmount.toStringAsFixed(0)}',
                style: AppTextStyles.body1.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${bid.durationDays}天',
                style: AppTextStyles.body2.copyWith(color: AppColors.gray500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            bid.proposal,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body2.copyWith(
              height: 1.5,
              color: AppColors.gray600,
            ),
          ),
          if (bid.skills.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: bid.skills.map((s) => VccTag(label: s)).toList(),
            ),
          ],
          if (bid.isTeamBid && bid.teamMembers.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _TeamMemberRow(members: bid.teamMembers),
          ],
          if (!bid.isPending) ...[
            const SizedBox(height: AppSpacing.md),
            _BidStatusBadge(status: bid.status),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _ActionButton(
                label: '查看详情',
                isPrimary: false,
                onTap: onViewDetail,
              ),
              if (isOwner && bid.canWithdraw) ...[
                const SizedBox(width: 8),
                _ActionButton(
                  label: '撤回',
                  isPrimary: false,
                  onTap: onWithdraw,
                ),
              ],
              if (!isOwner && bid.isPending) ...[
                const SizedBox(width: 8),
                if (bid.isAiRecommended)
                  _ActionButton(
                    label: '等待团队确认',
                    isPrimary: false,
                    onTap: null,
                  )
                else
                  _ActionButton(
                    label: '选 TA',
                    isPrimary: true,
                    onTap: onAccept,
                  ),
              ],
            ],
          ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  ),
);
  }
}

class _TeamMemberRow extends StatelessWidget {
  final List<TeamMember> members;
  const _TeamMemberRow({required this.members});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.group_outlined, size: 14, color: AppColors.gray400),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            members.map((m) => '${m.name}(${m.role})').join(' · '),
            style: AppTextStyles.caption.copyWith(color: AppColors.gray500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _BidStatusBadge extends StatelessWidget {
  final BidStatus status;
  const _BidStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    if (status == BidStatus.pending) return const SizedBox.shrink();


    final (Color bg, Color fg) = switch (status) {
      BidStatus.accepted => (AppColors.statusAcceptedBg, AppColors.statusAcceptedFg),
      BidStatus.rejected => (AppColors.statusRejectedBg, AppColors.statusRejectedFg),
      BidStatus.withdrawn => (AppColors.gray100, AppColors.gray500),
      _ => (AppColors.gray100, AppColors.gray500),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Text(
        status.label,
        style: AppTextStyles.caption.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: fg,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final bool isPrimary;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.label,
    required this.isPrimary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.black : AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border:
              isPrimary ? null : Border.all(color: AppColors.gray300),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isPrimary ? AppColors.white : AppColors.gray700,
          ),
        ),
      ),
    );
  }
}

String _formatLevelDisplay(BidItem bid) {
  final code = bid.vibeLevel ?? 'vc-T1';
  final label = bid.levelName ?? vibeLevelLabel(code);
  return '$code $label';
}
