import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/vcc_avatar.dart';
import '../models/team_models.dart';

class TeamPostCard extends StatelessWidget {
  final TeamPost post;
  final VoidCallback? onTap;

  const TeamPostCard({super.key, required this.post, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: post.isAiRecommended
                ? AppColors.accent.withValues(alpha: 0.3)
                : AppColors.gray200,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (post.isAiRecommended)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '最佳匹配',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                Expanded(
                  child: Text(
                    post.projectName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: post.filledCount == post.totalCount
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    post.progressText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: post.filledCount == post.totalCount
                          ? AppColors.success
                          : AppColors.accent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              post.description,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.gray500,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: post.neededRoles.map((role) {
                return _RoleChip(role: role);
              }).toList(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                VccAvatar(
                  size: VccAvatarSize.small,
                  imageUrl: post.creator.avatar,
                  fallbackText: post.creator.nickname.isNotEmpty
                      ? post.creator.nickname[0]
                      : '?',
                ),
                const SizedBox(width: 6),
                Text(
                  post.creator.nickname,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.gray500,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatTime(post.createdAt),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.gray400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String isoDate) {
    if (isoDate.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoDate);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
      if (diff.inHours < 24) return '${diff.inHours}小时前';
      if (diff.inDays < 7) return '${diff.inDays}天前';
      return '${dt.month}月${dt.day}日';
    } catch (_) {
      return isoDate;
    }
  }
}

class _RoleChip extends StatelessWidget {
  final TeamRoleSlot role;

  const _RoleChip({required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: role.filled
            ? AppColors.success.withValues(alpha: 0.08)
            : AppColors.gray100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color:
              role.filled ? AppColors.success.withValues(alpha: 0.3) : AppColors.gray200,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (role.filled)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(Icons.check, size: 12, color: AppColors.success),
            ),
          Text(
            '${role.name} ${role.ratio}%',
            style: TextStyle(
              fontSize: 12,
              color: role.filled ? AppColors.success : AppColors.gray600,
              fontWeight: role.filled ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
