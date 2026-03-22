import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/app.dart';
import '../../../app/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          // 账号分组
          _buildGroupTitle('账号'),
          _buildSettingItem(context, '手机号', trailing: '138****8888'),
          _buildSettingItem(context, '微信绑定', trailing: '已绑定'),
          _buildSettingItem(context, '实名认证', trailing: '已认证', trailingColor: AppColors.success),
          const SizedBox(height: 24),

          // 偏好分组
          _buildGroupTitle('偏好'),
          _buildSwitchItem(
            context,
            '深色模式',
            Theme.of(context).brightness == Brightness.dark,
            (value) {
              ref.read(themeModeProvider.notifier).state =
                  value ? ThemeMode.dark : ThemeMode.light;
            },
          ),
          _buildSettingItem(context, '通知设置'),
          _buildSettingItem(context, '隐私设置'),
          _buildSettingItem(context, '语言', trailing: '简体中文'),
          const SizedBox(height: 24),

          // 关于分组
          _buildGroupTitle('关于'),
          _buildSettingItem(context, '帮助与反馈'),
          _buildSettingItem(context, '关于开造'),
          _buildSettingItem(context, '版本', trailing: 'v1.0.0', showArrow: false),
          const SizedBox(height: 24),

          // 退出登录
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextButton(
              onPressed: () async {
                await ref.read(authStateProvider.notifier).logout();
              },
              child: const Text(
                '退出登录',
                style: TextStyle(fontSize: 16, color: AppColors.error),
              ),
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildGroupTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.gray400, letterSpacing: 1),
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context,
    String title, {
    String? trailing,
    Color? trailingColor,
    bool showArrow = true,
  }) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.gray200, width: 0.5)),
      ),
      child: Row(
        children: [
          Text(title, style: const TextStyle(fontSize: 16, color: AppColors.gray800)),
          const Spacer(),
          if (trailing != null)
            Text(
              trailing,
              style: TextStyle(fontSize: 14, color: trailingColor ?? AppColors.gray400),
            ),
          if (showArrow) ...[
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 16, color: AppColors.gray300),
          ],
        ],
      ),
    );
  }

  Widget _buildSwitchItem(BuildContext context, String title, bool value, ValueChanged<bool> onChanged) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.gray200, width: 0.5)),
      ),
      child: Row(
        children: [
          Text(title, style: const TextStyle(fontSize: 16, color: AppColors.gray800)),
          const Spacer(),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
