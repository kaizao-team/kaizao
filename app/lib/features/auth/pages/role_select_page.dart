import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/routes.dart';
import '../../../shared/widgets/vcc_button.dart';
import '../../../shared/widgets/vcc_toast.dart';
import '../providers/auth_provider.dart';
import '../../onboarding/providers/onboarding_provider.dart';

/// FE-AUTH-006: 角色选择页 — 需求方 / 专家
class RoleSelectPage extends ConsumerStatefulWidget {
  const RoleSelectPage({super.key});

  @override
  ConsumerState<RoleSelectPage> createState() => _RoleSelectPageState();
}

class _RoleSelectPageState extends ConsumerState<RoleSelectPage> {
  int? _selectedRole;

  Future<void> _confirm() async {
    if (_selectedRole == null) {
      VccToast.show(context, message: '请选择一个角色', type: VccToastType.warning);
      return;
    }
    final success = await ref.read(authStateProvider.notifier).selectRole(_selectedRole!);
    if (success && mounted) {
      final onboardingNotifier = ref.read(onboardingProvider.notifier);
      if (_selectedRole == 1) {
        await onboardingNotifier.setRole(OnboardingRole.demander);
        if (mounted) context.go(RoutePaths.demanderOnboarding1);
      } else {
        await onboardingNotifier.setRole(OnboardingRole.expert);
        if (mounted) context.go(RoutePaths.expertOnboarding1);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authStateProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              const Text(
                '选择你的角色',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '不同角色将看到不同的功能和内容',
                style: TextStyle(fontSize: 15, color: AppColors.gray500),
              ),
              const SizedBox(height: 40),

              _RoleCard(
                icon: Icons.lightbulb_outline,
                title: '我有需求',
                description: '我有想法和项目需求，想找专家帮我实现',
                isSelected: _selectedRole == 1,
                onTap: () => setState(() => _selectedRole = 1),
              ),
              const SizedBox(height: 16),
              _RoleCard(
                icon: Icons.code,
                title: '我是专家',
                description: '我擅长 Vibe Coding，想接项目展示能力',
                isSelected: _selectedRole == 2,
                onTap: () => setState(() => _selectedRole = 2),
              ),

              const Spacer(),

              VccButton(
                text: '下一步',
                onPressed: _selectedRole != null ? _confirm : null,
                isLoading: isLoading,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gray50 : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.black : AppColors.gray200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.black : AppColors.gray100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 24,
                color: isSelected ? AppColors.white : AppColors.gray500,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.black : AppColors.gray700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected ? AppColors.gray600 : AppColors.gray400,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.black : AppColors.white,
                border: Border.all(
                  color: isSelected ? AppColors.black : AppColors.gray300,
                  width: isSelected ? 0 : 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: AppColors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
