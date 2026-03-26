import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/routes.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../profile/widgets/role_switch_dialog.dart';
import 'notification_settings_page.dart';
import 'about_page.dart';

String _formatMaskedPhone(String? phone) {
  if (phone == null || phone.isEmpty) return '未设置';
  if (phone.contains('*')) return phone;
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.length >= 7) {
    return '${digits.substring(0, 3)}****${digits.substring(digits.length - 4)}';
  }
  return phone;
}

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider('me'));
    final profile = profileState.profile;

    final phoneTrailing = profileState.isLoading && profile == null
        ? '加载中...'
        : _formatMaskedPhone(profile?.phone);

    final wechatTrailing = profileState.isLoading && profile == null
        ? '加载中...'
        : profile == null
            ? '--'
            : (profile.wechatBound ? '已绑定' : '未绑定');

    final verifyTrailing = profileState.isLoading && profile == null
        ? '加载中...'
        : profile == null
            ? '--'
            : (profile.isVerified ? '已认证' : '未认证');
    final verifyColor =
        profile?.isVerified == true ? AppColors.success : AppColors.gray400;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          '设置',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon:
              const Icon(Icons.arrow_back_ios, size: 18, color: AppColors.black),
        ),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),

          // Profile actions
          _buildGroupTitle('个人'),
          _buildSettingItem(
            context,
            '编辑资料',
            onTap: () => context.push(RoutePaths.editProfile),
          ),
          _buildSettingItem(
            context,
            '切换角色',
            trailing: profile?.isDemander == true ? '发起人' : '造物者',
            onTap: () {
              if (profile == null) return;
              showDialog(
                context: context,
                builder: (_) => RoleSwitchDialog(
                  currentRole: profile.role,
                  onConfirm: () async {
                    final newRole = profile.role == 1 ? 2 : 1;
                    await ref
                        .read(authStateProvider.notifier)
                        .selectRole(newRole);
                  },
                ),
              );
            },
          ),

          _buildSeparator(),

          // Account
          _buildGroupTitle('账号与安全'),
          _buildSettingItem(
            context,
            '手机号',
            trailing: phoneTrailing,
            showArrow: false,
          ),
          _buildSettingItem(
            context,
            '微信绑定',
            trailing: wechatTrailing,
            showArrow: false,
          ),
          _buildSettingItem(
            context,
            '实名认证',
            trailing: verifyTrailing,
            trailingColor: verifyColor,
            showArrow: false,
          ),

          _buildSeparator(),

          // Preferences
          _buildGroupTitle('通用'),
          _buildSettingItem(
            context,
            '通知设置',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const NotificationSettingsPage(),
              ),
            ),
          ),
          _buildSettingItem(
            context,
            '语言',
            trailing: '简体中文',
            showArrow: false,
          ),

          _buildSeparator(),

          // About
          _buildGroupTitle('关于'),
          _buildSettingItem(
            context,
            '帮助与反馈',
            onTap: () {},
          ),
          _buildSettingItem(
            context,
            '关于开造',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AboutPage()),
            ),
          ),
          _buildSettingItem(
            context,
            '版本',
            trailing: 'v1.0.0',
            showArrow: false,
          ),

          const SizedBox(height: 32),

          // Logout
          Center(
            child: TextButton(
              onPressed: () async {
                final confirmed = await _showLogoutConfirm(context);
                if (confirmed != true) return;
                if (!context.mounted) return;
                await ref.read(authStateProvider.notifier).logout();
              },
              child: const Text(
                '退出登录',
                style: TextStyle(fontSize: 14, color: AppColors.error),
              ),
            ),
          ),

          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Future<bool?> _showLogoutConfirm(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(
          '确认退出',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        content: const Text(
          '退出后需要重新登录',
          style: TextStyle(fontSize: 14, color: AppColors.gray500),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              '取消',
              style: TextStyle(color: AppColors.gray500),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              '退出',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeparator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      height: 1,
      color: const Color(0xFFF0F0F0),
    );
  }

  Widget _buildGroupTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.gray400,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context,
    String title, {
    String? trailing,
    Color? trailingColor,
    bool showArrow = true,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 15, color: AppColors.gray700),
            ),
            const Spacer(),
            if (trailing != null)
              Text(
                trailing,
                style: TextStyle(
                  fontSize: 14,
                  color: trailingColor ?? AppColors.gray400,
                ),
              ),
            if (showArrow) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
                size: 16,
                color: AppColors.gray300,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
