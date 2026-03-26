import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/providers/profile_provider.dart';

String _formatMaskedPhone(String? phone) {
  if (phone == null || phone.isEmpty) return '未设置';
  if (phone.contains('*')) return phone;
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.length >= 7) {
    return '${digits.substring(0, 3)}****${digits.substring(digits.length - 4)}';
  }
  return phone;
}

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
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
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F9),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          '设置',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1C1C),
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, size: 18,
              color: Color(0xFF1A1C1C)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          const SizedBox(height: 8),

          _buildGroupLabel('账号与安全'),
          _buildCardGroup([
            _buildIconItem(
              Icons.smartphone_outlined,
              '手机号',
              trailing: phoneTrailing,
              showArrow: true,
            ),
            _buildIconItem(
              Icons.chat_bubble_outline,
              '微信绑定',
              trailing: wechatTrailing,
              trailingColor: AppColors.success,
              showArrow: true,
            ),
            _buildIconItem(
              Icons.verified_user_outlined,
              '实名认证',
              trailing: verifyTrailing,
              trailingColor: verifyColor,
              showArrow: true,
            ),
          ]),

          const SizedBox(height: 24),
          _buildGroupLabel('通用'),
          _buildCardGroup([
            _buildSwitchItem(
              Icons.notifications_outlined,
              '消息通知',
              value: _notificationsEnabled,
              onChanged: (v) => setState(() => _notificationsEnabled = v),
            ),
            _buildIconItem(
              Icons.language_outlined,
              '语言',
              trailing: '简体中文',
              showArrow: true,
            ),
            _buildIconItem(
              Icons.storage_outlined,
              '存储空间',
              showArrow: true,
            ),
          ]),

          const SizedBox(height: 24),
          _buildGroupLabel('关于'),
          _buildCardGroup([
            _buildIconItem(
              Icons.help_outline,
              '帮助与反馈',
              showArrow: true,
            ),
            _buildIconItem(
              Icons.description_outlined,
              '用户协议',
              showArrow: true,
            ),
            _buildIconItem(
              Icons.privacy_tip_outlined,
              '隐私政策',
              showArrow: true,
            ),
            _buildIconItem(
              Icons.code_outlined,
              '开源许可',
              showArrow: true,
            ),
          ]),

          const SizedBox(height: 40),

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

          const SizedBox(height: 8),
          Center(
            child: GestureDetector(
              onTap: () {},
              child: const Text(
                '注销账号',
                style: TextStyle(fontSize: 12, color: AppColors.gray400),
              ),
            ),
          ),

          const SizedBox(height: 16),
          const Center(
            child: Text(
              'v1.0.0 (Build 42)',
              style: TextStyle(fontSize: 11, color: AppColors.gray300),
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

  Widget _buildGroupLabel(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.gray400,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildCardGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: List.generate(children.length, (i) {
          return Column(
            children: [
              children[i],
              if (i < children.length - 1)
                Container(
                  margin: const EdgeInsets.only(left: 52),
                  height: 1,
                  color: const Color(0xFFF3F3F3),
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildIconItem(
    IconData icon,
    String title, {
    String? trailing,
    Color? trailingColor,
    bool showArrow = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.gray500),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF1A1C1C),
              ),
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
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.gray300,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchItem(
    IconData icon,
    String title, {
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.gray500),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF1A1C1C),
            ),
          ),
          const Spacer(),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.black,
          ),
        ],
      ),
    );
  }
}
