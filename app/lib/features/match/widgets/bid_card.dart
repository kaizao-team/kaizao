import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bid.isAiRecommended ? AppColors.accentLight : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: bid.isAiRecommended ? AppColors.accent : AppColors.gray200,
          width: bid.isAiRecommended ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (bid.isAiRecommended)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'AI 推荐',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
            ),
          Row(
            children: [
              VccAvatar(
                size: VccAvatarSize.medium,
                fallbackText: bid.userName.isNotEmpty
                    ? bid.userName.substring(0, 1)
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
                            bid.userName,
                            style: const TextStyle(
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
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '团队',
                              style: TextStyle(
                                  fontSize: 10, color: AppColors.gray500),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 14, color: AppColors.accentGold),
                        const SizedBox(width: 2),
                        Text(
                          '${bid.rating} · 完成率${bid.completionRate}%',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.gray500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '匹配 ${bid.matchScore}%',
                  style: const TextStyle(
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
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${bid.durationDays}天',
                style: const TextStyle(
                    fontSize: 14, color: AppColors.gray500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            bid.proposal,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.gray600,
            ),
          ),
          if (bid.skills.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: bid.skills.map((s) => VccTag(label: s)).toList(),
            ),
          ],
          if (bid.isTeamBid && bid.teamMembers.isNotEmpty) ...[
            const SizedBox(height: 10),
            _TeamMemberRow(members: bid.teamMembers),
          ],
          if (!bid.isPending) ...[
            const SizedBox(height: 10),
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
            style: const TextStyle(fontSize: 12, color: AppColors.gray500),
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
      BidStatus.accepted => (const Color(0xFFE8F5E9), const Color(0xFF2E7D32)),
      BidStatus.rejected => (const Color(0xFFFBE9E7), const Color(0xFFC62828)),
      BidStatus.withdrawn => (AppColors.gray100, AppColors.gray500),
      _ => (AppColors.gray100, AppColors.gray500),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: fg),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.black : AppColors.white,
          borderRadius: BorderRadius.circular(8),
          border:
              isPrimary ? null : Border.all(color: AppColors.gray300),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isPrimary ? AppColors.white : AppColors.gray700,
          ),
        ),
      ),
    );
  }
}
