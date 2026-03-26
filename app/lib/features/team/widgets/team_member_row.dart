import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/vcc_avatar.dart';
import '../models/team_models.dart';

class TeamMemberRow extends StatelessWidget {
  final TeamMember member;

  const TeamMemberRow({super.key, required this.member});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          VccAvatar(
            size: VccAvatarSize.medium,
            imageUrl: member.avatar,
            fallbackText: member.nickname.isNotEmpty
                ? member.nickname[0]
                : '?',
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      member.nickname,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.black,
                      ),
                    ),
                    if (member.isLeader) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentGold.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '队长',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accentGold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  member.role,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.gray400,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${member.ratio}%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                ),
              ),
              Text(
                _statusLabel(member.status),
                style: TextStyle(
                  fontSize: 11,
                  color: _statusColor(member.status),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    return switch (status) {
      'accepted' => '已接受',
      'pending' => '等待中',
      'rejected' => '已拒绝',
      _ => status,
    };
  }

  Color _statusColor(String status) {
    return switch (status) {
      'accepted' => AppColors.success,
      'rejected' => AppColors.error,
      _ => AppColors.gray400,
    };
  }
}
