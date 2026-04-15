import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/providers/home_provider.dart';
import '../../onboarding/providers/onboarding_provider.dart';
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
    final authState = ref.watch(authStateProvider);
    final profileState = ref.watch(profileProvider('me'));
    final profile = profileState.profile;
    final topPadding = MediaQuery.of(context).padding.top;

    final currentRoleName = authState.userRole == 2 ? '团队方' : '项目方';
    final phoneTrailing = profileState.isLoading && profile == null
        ? '加载中...'
        : _formatMaskedPhone(profile?.phone);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: CustomScrollView(
        slivers: [
          // — Hero header —
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.only(top: topPadding),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF111111), Color(0xFF3C3B3B)],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -30,
                    top: -10,
                    child: CustomPaint(
                      size: const Size(160, 160),
                      painter: _DotGridPainter(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 12, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              behavior: HitTestBehavior.opaque,
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(
                                  Icons.arrow_back_ios,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const Spacer(),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          '设置',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.4),
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          '设置',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.5,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // — 账号与安全 —
                _buildSectionLabel('账号与安全'),
                const SizedBox(height: 10),
                _buildCard([
                  _SettingsRow(
                    label: '当前角色',
                    trailing: _RoleBadge(name: currentRoleName),
                    showArrow: false,
                  ),
                  _SettingsRow(
                    label: '手机号',
                    trailingText: phoneTrailing,
                  ),
                  // _SettingsRow(
                  //   label: '微信绑定',
                  //   trailing: _StatusDot(
                  //     text: wechatTrailing,
                  //     active: profile?.wechatBound == true,
                  //   ),
                  // ),
                  // _SettingsRow(
                  //   label: '实名认证',
                  //   trailing: _StatusDot(
                  //     text: verifyTrailing,
                  //     active: profile?.isVerified == true,
                  //   ),
                  //   trailingColor: verifyColor,
                  // ),
                ]),

                const SizedBox(height: 32),

                // — 通用 —
                _buildSectionLabel('通用'),
                const SizedBox(height: 10),
                _buildCard([
                  _SettingsRow(
                    label: '我的收藏',
                    onTap: () => context.push(RoutePaths.favorites),
                  ),
                  _SettingsSwitchRow(
                    label: '消息通知',
                    value: _notificationsEnabled,
                    onChanged: (v) => setState(() => _notificationsEnabled = v),
                  ),
                  const _SettingsRow(
                    label: '语言',
                    trailingText: '简体中文',
                    showArrow: false,
                  ),
                ]),

                const SizedBox(height: 32),

                // — 关于 —
                _buildSectionLabel('关于'),
                const SizedBox(height: 10),
                _buildCard([
                  _SettingsRow(
                    label: '用户协议',
                    onTap: () => context.push(RoutePaths.userAgreement),
                  ),
                  _SettingsRow(
                    label: '隐私政策',
                    onTap: () => context.push(RoutePaths.privacyPolicy),
                  ),
                  _SettingsRow(
                    label: '关于 KAIZO',
                    onTap: () => context.push(RoutePaths.about),
                  ),
                ]),

                const SizedBox(height: 48),

                // — 底部操作 —
                _LogoutButton(
                  onTap: () async {
                    final confirmed = await _showLogoutConfirm(context);
                    if (confirmed != true) return;
                    if (!context.mounted) return;
                    await ref.read(authStateProvider.notifier).logout();
                    ref.invalidate(profileProvider('me'));
                    ref.invalidate(homeStateProvider);
                    ref.invalidate(onboardingProvider);
                  },
                ),
                const SizedBox(height: 14),
                Center(
                  child: GestureDetector(
                    onTap: () => _showDeactivateConfirm(context),
                    child: const Text(
                      '注销账号',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.gray400,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Center(
                  child: Text(
                    'v1.0.0  ·  Build 42',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.gray300,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 56),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.gray400,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Future<bool?> _showLogoutConfirm(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.white,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      enableDrag: true,
      showDragHandle: false,
      builder: (ctx) {
        final bottomPadding = MediaQuery.of(ctx).padding.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 16 + bottomPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '确认退出',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1C1C),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '退出后需要重新登录',
                style: TextStyle(fontSize: 14, color: AppColors.gray400),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '退出登录',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFF3F3F3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '取消',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.gray600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showDeactivateConfirm(BuildContext context) async {
    final passwordController = TextEditingController();
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.white,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final bottomPadding = MediaQuery.of(ctx).padding.bottom;
        final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 16 + bottomPadding + bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '注销账号',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1C1C),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '注销后账号数据将无法恢复。\n请输入密码确认注销。',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.gray400),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: '请输入密码',
                  hintStyle: const TextStyle(color: AppColors.gray300),
                  filled: true,
                  fillColor: const Color(0xFFF3F3F3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    if (passwordController.text.trim().isNotEmpty) {
                      Navigator.pop(ctx, true);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '确认注销',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFF3F3F3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '取消',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.gray600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
    if (confirmed != true) return;
    if (!context.mounted) return;

    final password = passwordController.text.trim();
    final success = await ref.read(authStateProvider.notifier).deactivateAccount(password);
    if (!context.mounted) return;
    if (success) {
      ref.invalidate(profileProvider('me'));
      ref.invalidate(homeStateProvider);
      ref.invalidate(onboardingProvider);
      context.go(RoutePaths.login);
    } else {
      final error = ref.read(authStateProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? '注销失败，请重试')),
      );
    }
    passwordController.dispose();
  }
}

// ────────────────────────────────────────────
// Composable row widgets
// ────────────────────────────────────────────

class _SettingsRow extends StatelessWidget {
  final String label;
  final String? trailingText;
  final Widget? trailing;
  final bool showArrow;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.label,
    this.trailingText,
    this.trailing,
    this.showArrow = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF1A1C1C),
                  height: 1.3,
                ),
              ),
            ),
            if (trailing != null) trailing!,
            if (trailing == null && trailingText != null)
              Text(
                trailingText!,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.gray400,
                ),
              ),
            if (showArrow) ...[
              const SizedBox(width: 6),
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

class _SettingsSwitchRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF1A1C1C),
                height: 1.3,
              ),
            ),
          ),
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

// ────────────────────────────────────────────
// Micro-components
// ────────────────────────────────────────────

class _RoleBadge extends StatelessWidget {
  final String name;
  const _RoleBadge({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F3),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        name,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1A1C1C),
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;
  const _LogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.error.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: const Text(
          '退出登录',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.error,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────
// Background pattern painter
// ────────────────────────────────────────────

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;

    const step = 16.0;
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 1, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
