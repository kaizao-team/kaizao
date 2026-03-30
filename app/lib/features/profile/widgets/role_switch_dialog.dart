import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/vcc_button.dart';

class RoleSwitchDialog extends StatelessWidget {
  final int currentRole;
  final VoidCallback onConfirm;

  const RoleSwitchDialog({
    super.key,
    required this.currentRole,
    required this.onConfirm,
  });

  String get _targetRoleName => currentRole == 1 ? '团队方' : '项目方';
  String get _targetRoleDesc => currentRole == 1
      ? '切换后将显示团队方视图，包括接单、投标等功能'
      : '切换后将显示项目方视图，包括创建项目、管理项目等功能';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.swap_horiz_rounded,
                size: 28,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '切换为$_targetRoleName',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _targetRoleDesc,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.gray500,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: VccButton(
                    text: '取消',
                    type: VccButtonType.secondary,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: VccButton(
                    text: '确认切换',
                    onPressed: () {
                      Navigator.pop(context);
                      onConfirm();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
